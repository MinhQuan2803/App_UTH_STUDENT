import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

/// Widget hiển thị thẻ số dư ví với gradient
class BalanceCard extends StatelessWidget {
  final int balance; // Số dư hiện tại
  final bool isLoading; // Trạng thái đang tải
  final VoidCallback onHistoryTap; // Callback khi nhấn nút lịch sử
  final VoidCallback? onWithdrawTap; // Callback khi nhấn nút rút tiền

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.onHistoryTap,
    this.onWithdrawTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số dư hiện tại',
                style: AppTextStyles.bodyRegular
                    .copyWith(color: AppColors.white.withOpacity(0.9)),
              ),
              GestureDetector(
                onTap: onHistoryTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppAssets.borderRadiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history,
                        color: AppColors.white,
                        size: AppAssets.iconSizeSmall,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lịch sử',
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          isLoading
              ? Row(
                  children: [
                    const SizedBox(
                      width: AppAssets.iconSizeMedium,
                      height: AppAssets.iconSizeMedium,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Đang tải...',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.iconCoin,
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      balance.toString(),
                      style: AppTextStyles.walletBalance.copyWith(
                        color: AppColors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Điểm',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
          if (onWithdrawTap != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onWithdrawTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(AppAssets.borderRadiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.white,
                      size: AppAssets.iconSizeSmall,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rút tiền',
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget để chọn gói nạp điểm
class PackageOption extends StatelessWidget {
  final String points; // Số điểm của gói
  final String amount; // Số tiền tương ứng
  final bool isSelected; // Có đang được chọn không
  final VoidCallback onTap; // Callback khi nhấn

  const PackageOption({
    super.key,
    required this.points,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
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
                SvgPicture.asset(
                  AppAssets.iconCoin,
                  width: AppAssets.iconSizeSmall,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    AppColors.coinColor,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$points Điểm', style: AppTextStyles.bodyBold),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              amount,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tùy chọn phương thức thanh toán
class PaymentMethodOption extends StatelessWidget {
  final String logoAsset; // Đường dẫn logo
  final String title; // Tên phương thức
  final bool isSelected; // Có đang được chọn không
  final VoidCallback onTap; // Callback khi nhấn

  const PaymentMethodOption({
    super.key,
    required this.logoAsset,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppAssets.paddingMedium,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              logoAsset,
              width: AppAssets.iconSizeLarge,
              height: AppAssets.iconSizeLarge,
            ),
            const SizedBox(width: AppAssets.paddingMedium),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyBold),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị divider với text "HOẶC"
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.dividerLight,
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text('HOẶC', style: AppTextStyles.postMeta),
          ),
          Expanded(
            child: Divider(
              color: AppColors.dividerLight,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị section header (tiêu đề + mô tả tùy chọn)
class SectionHeader extends StatelessWidget {
  final String title; // Tiêu đề chính
  final String? subtitle; // Mô tả phụ (tùy chọn)

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget hiển thị thông tin thanh toán (thành tiền)
class PaymentSummary extends StatelessWidget {
  final int amount; // Số tiền cần thanh toán
  final String currency; // Đơn vị tiền tệ

  const PaymentSummary({
    super.key,
    required this.amount,
    this.currency = 'đ',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppAssets.paddingMedium,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusLarge),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Thành tiền:',
            style: AppTextStyles.bodyRegular.copyWith(fontSize: 15),
          ),
          Text(
            '${_formatCurrency(amount)}$currency',
            style: AppTextStyles.profileName.copyWith(
              color: AppColors.primary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

/// Widget hiển thị dialog chờ thanh toán
class PaymentWaitingDialog extends StatelessWidget {
  final VoidCallback onCancel; // Callback khi nhấn hủy

  const PaymentWaitingDialog({
    super.key,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onCancel();
        return true;
      },
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppAssets.paymentWaitingMessage,
              style: AppTextStyles.bodyRegular,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppAssets.paymentProcessingMessage,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.subtitle,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onCancel,
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}
