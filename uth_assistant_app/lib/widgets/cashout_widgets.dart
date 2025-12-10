import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/cashout_model.dart';

/// Widget dialog xác nhận rút tiền
class WithdrawConfirmationDialog extends StatelessWidget {
  final int points;
  final int moneyAmount;
  final BankInfo bankInfo;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const WithdrawConfirmationDialog({
    super.key,
    required this.points,
    required this.moneyAmount,
    required this.bankInfo,
    required this.onConfirm,
    required this.onCancel,
  });

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppAssets.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppAssets.borderRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon & Title
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: AppAssets.iconSizeLarge,
              ),
            ),
            const SizedBox(height: AppAssets.paddingMedium),
            Text(
              'Xác nhận rút tiền',
              style: AppTextStyles.dialogTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppAssets.paddingSmall),
            Text(
              'Bạn có chắc muốn rút ${_formatCurrency(points)} điểm về tài khoản sau?',
              style: AppTextStyles.dialogMessage.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppAssets.paddingLarge),

            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppAssets.paddingMedium),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.headerGradientStart,
                    AppColors.headerGradientEnd
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(AppAssets.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on,
                          color: AppColors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatCurrency(points)} điểm',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward,
                          color: AppColors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatCurrency(moneyAmount)}đ',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.white,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppAssets.paddingLarge),

            // Bank info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppAssets.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.circular(AppAssets.borderRadiusMedium),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                              AppAssets.borderRadiusSmall),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thông tin tài khoản',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: AppAssets.paddingMedium),
                  _buildInfoRow('Ngân hàng:', bankInfo.bankName),
                  const SizedBox(height: 6),
                  _buildInfoRow('Số tài khoản:', bankInfo.accountNumber),
                  const SizedBox(height: 6),
                  _buildInfoRow('Chủ tài khoản:', bankInfo.accountName),
                ],
              ),
            ),
            const SizedBox(height: AppAssets.paddingMedium),

            // Warning message
            Container(
              padding: const EdgeInsets.all(AppAssets.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppAssets.borderRadiusSmall),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu rút tiền sẽ được Admin xem xét và duyệt trong thời gian sớm nhất.',
                      style: AppTextStyles.bodyRegular.copyWith(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppAssets.paddingLarge),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.subtitle,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppAssets.borderRadiusMedium),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: AppAssets.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppAssets.borderRadiusMedium),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Widget dialog thêm tài khoản ngân hàng
class AddBankAccountDialog extends StatelessWidget {
  final TextEditingController bankNameController;
  final TextEditingController accountNumberController;
  final TextEditingController accountNameController;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const AddBankAccountDialog({
    super.key,
    required this.bankNameController,
    required this.accountNumberController,
    required this.accountNameController,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppAssets.paddingLarge),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.headerGradientStart,
                    AppColors.headerGradientEnd
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppAssets.borderRadiusLarge),
                  topRight: Radius.circular(AppAssets.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppAssets.borderRadiusSmall),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppAssets.paddingMedium),
                  Text(
                    'Thêm tài khoản ngân hàng',
                    style: AppTextStyles.dialogTitle.copyWith(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppAssets.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bank name field
                    _buildFieldLabel('Tên ngân hàng', true),
                    const SizedBox(height: AppAssets.paddingSmall),
                    _buildTextField(
                      controller: bankNameController,
                      hintText: 'VD: Vietcombank, Techcombank...',
                      icon: Icons.account_balance,
                    ),
                    const SizedBox(height: AppAssets.paddingMedium),

                    // Account number field
                    _buildFieldLabel('Số tài khoản', true),
                    const SizedBox(height: AppAssets.paddingSmall),
                    _buildTextField(
                      controller: accountNumberController,
                      hintText: 'Nhập số tài khoản',
                      icon: Icons.credit_card,
                      isNumber: true,
                    ),
                    const SizedBox(height: AppAssets.paddingMedium),

                    // Account name field
                    _buildFieldLabel('Tên chủ tài khoản', true),
                    const SizedBox(height: AppAssets.paddingSmall),
                    _buildTextField(
                      controller: accountNameController,
                      hintText: 'Nhập tên chủ tài khoản',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: AppAssets.paddingMedium),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(AppAssets.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppAssets.borderRadiusSmall),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppAssets.paddingSmall),
                          Expanded(
                            child: Text(
                              'Vui lòng kiểm tra kỹ thông tin trước khi thêm. Thông tin này sẽ được sử dụng để nhận tiền khi rút.',
                              style: AppTextStyles.bodyRegular.copyWith(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(AppAssets.paddingLarge),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.subtitle,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppAssets.borderRadiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: AppAssets.paddingMedium),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppAssets.borderRadiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Thêm tài khoản'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isRequired) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.hintText,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: AppAssets.paddingMedium,
          ),
        ),
      ),
    );
  }
}
