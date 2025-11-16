import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../services/payment_service.dart';
import '../models/point_history.dart';
import '../models/payment_order.dart';
import '../utils/dialog_utils.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();
  final NumberFormat _vndFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  // Points History
  List<PointHistory> _pointsHistory = [];
  bool _isLoadingPoints = true;
  int _pointsPage = 1;
  int _pointsTotalPages = 1;

  // Payment Orders
  List<PaymentOrder> _paymentOrders = [];
  bool _isLoadingOrders = true;
  int _ordersPage = 1;
  int _ordersTotalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPointsHistory();
    _loadPaymentOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPointsHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _pointsPage = 1;
        _pointsHistory.clear();
      });
    }

    setState(() => _isLoadingPoints = true);

    try {
      final response = await _paymentService.getPointsHistory(
        page: _pointsPage,
        limit: 20,
      );

      if (mounted) {
        final result = PointHistoryResponse.fromJson(response);
        setState(() {
          _pointsHistory.addAll(result.history);
          _pointsTotalPages = result.totalPages;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPoints = false);
        showAppDialog(
          context,
          type: DialogType.error,
          title: 'Lỗi tải lịch sử điểm',
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _loadPaymentOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _ordersPage = 1;
        _paymentOrders.clear();
      });
    }

    setState(() => _isLoadingOrders = true);

    try {
      final response = await _paymentService.getMyOrders(
        page: _ordersPage,
        limit: 10,
      );

      if (mounted) {
        final result = PaymentOrderResponse.fromJson(response);
        setState(() {
          _paymentOrders.addAll(result.orders);
          _ordersTotalPages = result.totalPages;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
        showAppDialog(
          context,
          type: DialogType.error,
          title: 'Lỗi tải đơn hàng',
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (_tabController.index == 0) {
      await _loadPointsHistory(refresh: true);
    } else {
      await _loadPaymentOrders(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: 'Lịch sử giao dịch',
        actions: [
          ModernIconButton(
            icon: Icons.refresh,
            onPressed: _refreshCurrentTab,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.subtitle,
              indicatorColor: AppColors.primary,
              labelStyle: AppTextStyles.bodyBold,
              unselectedLabelStyle: AppTextStyles.bodyRegular,
              tabs: const [
                Tab(text: 'Lịch sử điểm'),
                Tab(text: 'Đơn thanh toán'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPointsHistoryTab(),
                _buildPaymentOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsHistoryTab() {
    if (_isLoadingPoints && _pointsHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pointsHistory.isEmpty) {
      return _buildEmptyState('Chưa có lịch sử điểm');
    }

    return RefreshIndicator(
      onRefresh: () => _loadPointsHistory(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount:
            _pointsHistory.length + (_pointsPage < _pointsTotalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _pointsHistory.length) {
            return _buildLoadMoreButton(
              onPressed: () {
                setState(() => _pointsPage++);
                _loadPointsHistory();
              },
            );
          }

          final history = _pointsHistory[index];
          return _buildPointHistoryCard(history);
        },
      ),
    );
  }

  Widget _buildPaymentOrdersTab() {
    if (_isLoadingOrders && _paymentOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentOrders.isEmpty) {
      return _buildEmptyState('Chưa có đơn thanh toán');
    }

    return RefreshIndicator(
      onRefresh: () => _loadPaymentOrders(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount:
            _paymentOrders.length + (_ordersPage < _ordersTotalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _paymentOrders.length) {
            return _buildLoadMoreButton(
              onPressed: () {
                setState(() => _ordersPage++);
                _loadPaymentOrders();
              },
            );
          }

          final order = _paymentOrders[index];
          return _buildPaymentOrderCard(order);
        },
      ),
    );
  }

  Widget _buildPointHistoryCard(PointHistory history) {
    final bool isEarned = history.type == 'EARNED';
    final Color typeColor = isEarned ? AppColors.success : AppColors.danger;
    final IconData typeIcon = isEarned ? Icons.add_circle : Icons.remove_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, color: typeColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  history.description,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${isEarned ? '+' : '-'}${history.amount}',
                style: AppTextStyles.profileName.copyWith(
                  color: typeColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                AppAssets.iconCoin,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(typeColor, BlendMode.srcIn),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nguồn: ${_translateSource(history.source)}',
                style: AppTextStyles.bodyRegular
                    .copyWith(fontSize: 13, color: AppColors.subtitle),
              ),
              Text(
                _dateFormatter.format(history.createdAt),
                style: AppTextStyles.postMeta.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số dư trước: ${history.balanceBefore}',
                style: AppTextStyles.bodyRegular
                    .copyWith(fontSize: 13, color: AppColors.subtitle),
              ),
              Text(
                'Số dư sau: ${history.balanceAfter}',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOrderCard(PaymentOrder order) {
    final Color statusColor = _getStatusColor(order.status);
    final String statusText = _translateStatus(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _getPaymentMethodIcon(order.paymentProvider),
                    const SizedBox(width: 8),
                    Text(
                      _translatePaymentMethod(order.paymentProvider),
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số tiền:',
                style: AppTextStyles.bodyRegular
                    .copyWith(fontSize: 13, color: AppColors.subtitle),
              ),
              Text(
                _vndFormatter.format(order.amountVND),
                style: AppTextStyles.profileName.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Điểm nhận:',
                style: AppTextStyles.bodyRegular
                    .copyWith(fontSize: 13, color: AppColors.subtitle),
              ),
              Row(
                children: [
                  Text(
                    '+${order.pointsToGrant}',
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 14,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    AppAssets.iconCoin,
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.success,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ngày tạo: ${_dateFormatter.format(order.createdAt)}',
            style: AppTextStyles.postMeta.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            message,
            style:
                AppTextStyles.bodyRegular.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton({required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            'Xem thêm',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  String _translateSource(String source) {
    switch (source) {
      case 'PAYMENT':
        return 'Thanh toán';
      case 'POST':
        return 'Bài viết';
      case 'COMMENT':
        return 'Bình luận';
      case 'ADMIN':
        return 'Quản trị viên';
      default:
        return source;
    }
  }

  String _translatePaymentMethod(String method) {
    switch (method) {
      case 'VNPAY':
        return '💳 VNPay';
      case 'MOMO':
        return '📱 MoMo';
      case 'BANK_TRANSFER':
        return '🏦 Chuyển khoản';
      case 'ZALOPAY':
        return '💰 ZaloPay';
      default:
        return method;
    }
  }

  Widget _getPaymentMethodIcon(String method) {
    IconData icon;
    Color color;

    switch (method) {
      case 'VNPAY':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'MOMO':
        icon = Icons.account_balance_wallet;
        color = const Color(0xFFD82D8B); // Màu hồng MoMo
        break;
      case 'BANK_TRANSFER':
        icon = Icons.account_balance;
        color = Colors.green;
        break;
      case 'ZALOPAY':
        icon = Icons.payment;
        color = Colors.blue;
        break;
      default:
        icon = Icons.payment;
        color = AppColors.subtitle;
    }

    return Icon(icon, size: 16, color: color);
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'SUCCESS':
        return 'Thành công';
      case 'PENDING':
        return 'Đang xử lý';
      case 'FAILED':
        return 'Thất bại';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.danger;
      default:
        return AppColors.subtitle;
    }
  }
}
