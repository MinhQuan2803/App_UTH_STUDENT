import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Quản lý trạng thái gói và phương thức được chọn
  String _selectedPackage = '100'; // Gói 100 điểm
  String _selectedMethod = 'momo'; // Phương thức Momo

  // Hàm xử lý thanh toán (sẽ được gọi bởi nút)
  void _handlePayment() {
    // TODO: Tích hợp API thanh toán điện tử (MoMo, ZaloPay...)
    // Dựa trên _selectedPackage và _selectedMethod
    print('Nạp $_selectedPackage Điểm bằng $_selectedMethod');
    
    // Hiển thị thông báo (ví dụ)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang xử lý gói nạp $_selectedPackage Điểm...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ví UTH của tôi', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.text),
        elevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ số dư
            _buildBalanceCard(),
            const SizedBox(height: 24),
            // Chọn gói nạp
            Text('Chọn gói nạp điểm', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            _buildPackageSelector(),
            const SizedBox(height: 24),
            // Chọn phương thức thanh toán
            Text('Chọn phương thức thanh toán', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 32),
            // Nút thanh toán
            CustomButton(
              text: 'Tiến hành thanh toán',
              onPressed: _handlePayment,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư hiện tại',
            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SvgPicture.asset(
                AppAssets.iconCoin, 
                width: 32, height: 32, 
                colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)
              ),
              const SizedBox(width: 10),
              // TODO: Thay 150 bằng số dư thật từ API
              Text('150', style: AppTextStyles.walletBalance.copyWith(color: AppColors.white)),
              const SizedBox(width: 8),
              Text(
                'Điểm', 
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.white, fontSize: 20)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSelector() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5, // Chiều rộng gấp 2.5 lần chiều cao
      children: [
        _buildPackageOption(points: '100', amount: '20.000đ'),
        _buildPackageOption(points: '250', amount: '50.000đ'),
        _buildPackageOption(points: '550', amount: '100.000đ'),
        _buildPackageOption(points: '1.200', amount: '200.000đ'),
      ],
    );
  }

  Widget _buildPackageOption({required String points, required String amount}) {
    final isSelected = _selectedPackage == points;
    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = points),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(AppAssets.iconCoin, width: 16, height: 16, colorFilter: const ColorFilter.mode(AppColors.coinColor, BlendMode.srcIn)),
                const SizedBox(width: 6),
                Text('$points Điểm', style: AppTextStyles.bodyBold),
              ],
            ),
            const SizedBox(height: 4),
            Text(amount, style: AppTextStyles.bodyRegular.copyWith(color: AppColors.subtitle)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _buildPaymentOption(
          logoAsset: AppAssets.iconmomo,
          title: 'Ví MoMo',
          value: 'momo',
        ),
        const SizedBox(height: 8),
        _buildPaymentOption(
          logoAsset: AppAssets.iconZalo,
          title: 'ZaloPay',
          value: 'zalopay',
        ),
      ],
    );
  }

  Widget _buildPaymentOption({required String logoAsset, required String title, required String value}) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
             color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          )
        ),
        child: Row(
          children: [
            SvgPicture.asset(logoAsset, width: 32, height: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.bodyBold)),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

