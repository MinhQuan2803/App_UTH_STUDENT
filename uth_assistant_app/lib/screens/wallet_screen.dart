import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/payment_widgets.dart';
import '../services/payment_service.dart';
import '../utils/dialog_utils.dart';
import 'transaction_history_screen.dart';
import 'webview_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _pointsController = TextEditingController();
  String _selectedMethod = 'vnpay'; // Mặc định VNPay
  String? _selectedPackage; // Nullable để cho phép nhập tùy chỉnh
  bool _isLoading = false;
  bool _isLoadingBalance = true; // Trạng thái loading số dư
  int _calculatedAmount = 0;
  int _currentBalance = 0; // Số dư hiện tại

  final PaymentService _paymentService = PaymentService();
  final NumberFormat _vndFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Sử dụng constants từ AppAssets
  final Map<String, Map<String, dynamic>> _packages =
      AppAssets.defaultPaymentPackages;

  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  bool _isPollingActive = false; // Flag để track polling state
  bool _isCheckingStatus =
      false; // Flag để tránh race condition khi check status

  @override
  void initState() {
    super.initState();
    // Cập nhật listener
    _pointsController.addListener(_onPointsChanged);
    // Chọn gói mặc định từ AppAssets
    _selectPackage(AppAssets.defaultSelectedPackage);
    // Load số dư điểm
    _loadUserBalance();
  }

  /// Load số dư điểm của user
  Future<void> _loadUserBalance() async {
    setState(() => _isLoadingBalance = true);

    try {
      final result = await _paymentService.getUserPoints();
      if (result['success'] == true && mounted) {
        setState(() {
          _currentBalance = result['balance'] ?? 0;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
        showAppDialog(
          context,
          type: DialogType.error,
          title: 'Lỗi tải số dư',
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  // CẬP NHẬT: Logic khi người dùng gõ
  void _onPointsChanged() {
    final String text = _pointsController.text;
    final int points = int.tryParse(text) ?? 0;

    setState(() {
      // Sử dụng constant từ AppAssets
      _calculatedAmount = points * AppAssets.pointToVndRate;

      // Tự động kiểm tra xem số gõ vào có khớp gói nào không
      if (_packages.containsKey(text)) {
        _selectedPackage = text;
      } else {
        _selectedPackage = null; // Nếu là số tùy chỉnh, bỏ chọn tất cả gói
      }
    });
  }

  @override
  void dispose() {
    _isPollingActive = false; // Đánh dấu polling không còn active
    _pollingTimer?.cancel(); // Hủy timer khi dispose
    _pointsController.removeListener(_onPointsChanged);
    _pointsController.dispose();
    super.dispose();
  }

  // Hàm mới để chọn gói
  void _selectPackage(String pointsKey) {
    // Cập nhật text controller, việc này sẽ tự động
    // kích hoạt listener _onPointsChanged
    _pointsController.text = pointsKey;
  }

  Future<void> _handlePayment() async {
    FocusScope.of(context).unfocus();

    if (_calculatedAmount <= 0) {
      showAppDialog(context,
          type: DialogType.warning,
          title: AppAssets.invalidPointsTitle,
          message: AppAssets.invalidPointsMessage);
      return;
    }
    if (_calculatedAmount < AppAssets.minPoints * AppAssets.pointToVndRate) {
      showAppDialog(context,
          type: DialogType.warning,
          title: AppAssets.minAmountTitle,
          message: AppAssets.minAmountMessage);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Xác định provider dựa trên method được chọn
      String provider = 'VNPAY'; // Mặc định
      if (_selectedMethod == 'momo') {
        provider = 'MOMO';
      } else if (_selectedMethod == 'vnpay') {
        provider = 'VNPAY';
      }

      final paymentData = await _paymentService.createPaymentUrl(
        amount: _calculatedAmount,
        provider: provider,
      );

      final String paymentUrl = paymentData['paymentUrl'];
      final String? orderId = paymentData['orderId'];

      if (kDebugMode) {
        print('💰 Payment URL received ($provider)');
        print('🆔 Order ID from API: $orderId');
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // *** TỐI ƯU UX: BẮT ĐẦU POLLING TRƯỚC KHI MỞ WEBVIEW ***
        if (orderId != null && orderId.isNotEmpty) {
          if (kDebugMode)
            print('▶️ Starting polling IN BACKGROUND for: $orderId');
          _startPaymentPolling(orderId); // Bắt đầu chạy ngầm
        } else {
          if (kDebugMode)
            print('⚠️ Order ID is null or empty, polling skipped');
        }

        // Mở payment trong WebView (KHÔNG AWAIT - polling đã chạy ngầm)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              initialUrl: paymentUrl,
              title: 'Thanh toán $provider',
              isPayment: true, // Đánh dấu đây là màn hình thanh toán
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppDialog(context,
            type: DialogType.error,
            title: AppAssets.createPaymentErrorTitle,
            message: e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _startPaymentPolling(String orderId) {
    _pollingAttempts = 0;
    _isPollingActive = true; // Đánh dấu polling đang active
    _isCheckingStatus = false; // Reset cờ khi bắt đầu

    if (kDebugMode) print('🔄 Starting payment polling for orderId: $orderId');

    // Hủy timer cũ nếu có
    _pollingTimer?.cancel();

    // Hiển thị dialog đang chờ thanh toán bằng showAppDialog
    showAppDialog(
      context,
      type: DialogType.info,
      title: 'Đang xử lý thanh toán',
      message:
          'Vui lòng đợi trong giây lát...\nHệ thống đang xác nhận giao dịch của bạn.',
    );

    // Bắt đầu polling - sử dụng constant từ AppAssets
    _pollingTimer = Timer.periodic(
        Duration(seconds: AppAssets.pollingIntervalSeconds), (timer) async {
      // 1. KIỂM TRA nếu polling đã bị hủy, bỏ qua callback này
      if (!_isPollingActive) {
        if (kDebugMode) print('⏹️ Polling stopped, ignoring callback');
        timer.cancel();
        return;
      }

      // 2. *** FIX RACE CONDITION: KHÓA LẠI NẾU ĐANG CHECK ***
      if (_isCheckingStatus) {
        if (kDebugMode)
          print('🔒 Đang chờ kết quả check trước, bỏ qua lượt này...');
        return;
      }

      // 3. Đặt cờ khóa
      _isCheckingStatus = true;
      _pollingAttempts++;

      if (kDebugMode)
        print(
            '🔍 Polling attempt $_pollingAttempts/${AppAssets.maxPollingAttempts} for orderId: $orderId');

      try {
        final statusData = await _paymentService.checkOrderStatus(orderId);
        final String status = statusData['status'] ?? 'PENDING';

        // KIỂM TRA LẠI: Vì có thể trong lúc await, polling đã bị hủy
        if (!_isPollingActive) {
          if (kDebugMode)
            print('⏹️ Polling stopped while awaiting, ignoring result');
          return; // finally sẽ mở khóa
        }

        if (kDebugMode) print('📊 Order status: $status');

        // Chấp nhận cả SUCCESS và COMPLETED
        if (status == 'SUCCESS' || status == 'COMPLETED') {
          // Thanh toán thành công
          if (kDebugMode) print('✅ Payment SUCCESS/COMPLETED detected!');

          // HỦY TIMER NGAY để tránh xử lý trùng lặp
          _isPollingActive = false; // Set flag trước khi cancel
          timer.cancel();
          _pollingTimer?.cancel();
          _pollingTimer = null;

          if (mounted) {
            if (kDebugMode) print('🔔 Closing waiting dialog...');
            Navigator.pop(context); // Đóng dialog chờ

            // Reload balance
            if (kDebugMode) print('💰 Reloading balance...');
            await _loadUserBalance();

            // Delay nhỏ để đảm bảo dialog chờ đã đóng hoàn toàn
            await Future.delayed(
                Duration(milliseconds: AppAssets.dialogDelayMs));

            // Hiển thị thông báo thành công
            if (kDebugMode) print('🎉 Showing success dialog...');
            showAppDialog(
              context,
              type: DialogType.success,
              title: AppAssets.paymentSuccessTitle,
              message: AppAssets.paymentSuccessMessage,
            );
          }
        } else if (status == 'FAILED' ||
            status == 'CANCELLED' ||
            status == 'EXPIRED') {
          // Thanh toán thất bại
          if (kDebugMode) print('❌ Payment FAILED/CANCELLED/EXPIRED!');

          // HỦY TIMER NGAY
          _isPollingActive = false; // Set flag trước khi cancel
          timer.cancel();
          _pollingTimer?.cancel();
          _pollingTimer = null;

          if (mounted) {
            Navigator.pop(context); // Đóng dialog chờ

            // Delay nhỏ để đảm bảo dialog chờ đã đóng hoàn toàn
            await Future.delayed(
                Duration(milliseconds: AppAssets.dialogDelayMs));

            showAppDialog(
              context,
              type: DialogType.error,
              title: AppAssets.paymentFailedTitle,
              message: AppAssets.paymentFailedMessage,
            );
          }
        } else if (_pollingAttempts >= AppAssets.maxPollingAttempts) {
          // Timeout sau 3 phút
          if (kDebugMode) print('⏱️ Payment polling timeout!');

          _isPollingActive = false; // Set flag trước khi cancel
          timer.cancel();
          _pollingTimer?.cancel();
          _pollingTimer = null;
          if (mounted) {
            Navigator.pop(context); // Đóng dialog chờ

            // Delay nhỏ để đảm bảo dialog chờ đã đóng hoàn toàn
            await Future.delayed(
                Duration(milliseconds: AppAssets.dialogDelayMs));

            showAppDialog(
              context,
              type: DialogType.warning,
              title: AppAssets.paymentTimeoutTitle,
              message: AppAssets.paymentTimeoutMessage,
            );
          }
        }
        // Nếu status == 'PENDING', tiếp tục polling
      } catch (e) {
        // Lỗi khi check status, tiếp tục thử lại
        if (kDebugMode) print('❌ Polling error: $e');

        if (_pollingAttempts >= AppAssets.maxPollingAttempts) {
          _isPollingActive = false; // Set flag trước khi cancel
          timer.cancel();
          if (mounted) {
            Navigator.pop(context);
            showAppDialog(
              context,
              type: DialogType.error,
              title: AppAssets.checkStatusErrorTitle,
              message: AppAssets.checkStatusErrorMessage,
            );
          }
          // Hủy reference
          _pollingTimer?.cancel();
          _pollingTimer = null;
        }
      } finally {
        // 4. *** MỞ KHÓA sau khi xử lý xong ***
        // (Nếu polling chưa bị dừng, mở khóa để lần sau check tiếp)
        if (_isPollingActive) {
          _isCheckingStatus = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: 'Ví UTH của tôi',
        actions: [
          ModernIconButton(
            icon: Icons.refresh,
            onPressed: _loadUserBalance,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserBalance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppAssets.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sử dụng widget BalanceCard
              BalanceCard(
                balance: _currentBalance,
                isLoading: _isLoadingBalance,
                onHistoryTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppAssets.paddingLarge),

              // Sử dụng widget SectionHeader
              const SectionHeader(title: 'Chọn gói nạp điểm'),
              const SizedBox(height: AppAssets.paddingSmall),
              _buildPackageSelector(),

              // Sử dụng widget OrDivider
              const OrDivider(),

              // Phần nhập tùy chỉnh
              Text('Nhập số điểm tùy chỉnh',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Text('1 Điểm = 1.000đ',
                  style: AppTextStyles.bodyRegular
                      .copyWith(color: AppColors.subtitle)),
              const SizedBox(height: 8),
              _buildPointInput(),

              const SizedBox(height: 16),
              Text('Chọn phương thức thanh toán',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Nạp ${_vndFormatter.format(_calculatedAmount)}',
                      onPressed: _handlePayment,
                      isPrimary: true,
                    ),
              // Thêm khoảng an toàn ở dưới cùng
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  // Giao diện nhập điểm (giữ nguyên)
  Widget _buildPointInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập số điểm', style: AppTextStyles.bodyBold),
          const SizedBox(height: 6),
          CustomTextField(
            controller: _pointsController,
            hintText: 'Ví dụ: 15',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thành tiền:',
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 15)),
              Text(
                _vndFormatter.format(_calculatedAmount),
                style: AppTextStyles.profileName
                    .copyWith(color: AppColors.primary, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // THÊM LẠI: Widget chọn gói
  // Sử dụng widget PackageSelector
  Widget _buildPackageSelector() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: _packages.entries.map((entry) {
        return PackageOption(
          points: entry.key,
          amount: entry.value['label'],
          isSelected: _selectedPackage == entry.key,
          onTap: () => _selectPackage(entry.key),
        );
      }).toList(),
    );
  }

  // Sử dụng widget PaymentMethodSelector
  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        PaymentMethodOption(
          logoAsset: AppAssets.iconMomo,
          title: 'Ví MoMo',
          isSelected: _selectedMethod == 'momo',
          onTap: () => setState(() => _selectedMethod = 'momo'),
        ),
        const SizedBox(height: 6),
        PaymentMethodOption(
          logoAsset: AppAssets.iconZaloPay,
          title: 'VNPay',
          isSelected: _selectedMethod == 'vnpay',
          onTap: () => setState(() => _selectedMethod = 'vnpay'),
        ),
      ],
    );
  }
}
