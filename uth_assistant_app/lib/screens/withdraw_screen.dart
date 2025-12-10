import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/cashout_model.dart';
import '../services/cashout_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/cashout_widgets.dart';
import 'bank_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

class WithdrawScreen extends StatefulWidget {
  final int currentBalance;

  const WithdrawScreen({
    super.key,
    required this.currentBalance,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _pointsController = TextEditingController();
  final CashoutService _cashoutService = CashoutService();

  List<BankInfo> _savedAccounts = [];
  BankInfo? _selectedAccount;
  bool _isLoading = false;
  int _selectedPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList('bank_accounts') ?? [];
      setState(() {
        _savedAccounts = accountsJson
            .map((json) => BankInfo.fromJson(jsonDecode(json)))
            .toList();
        if (_savedAccounts.isNotEmpty) {
          _selectedAccount = _savedAccounts.first;
        }
      });
    } catch (e) {
      // Ignore error
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _submitWithdraw() async {
    // Validate points
    if (_pointsController.text.isEmpty || _selectedPoints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điểm muốn rút')),
      );
      return;
    }

    if (_selectedPoints < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Số điểm rút tối thiểu là 10 điểm (10.000đ)')),
      );
      return;
    }

    if (_selectedPoints > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điểm rút vượt quá số dư hiện tại')),
      );
      return;
    }

    // Validate bank account
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng thêm tài khoản ngân hàng để rút tiền')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => WithdrawConfirmationDialog(
        points: _selectedPoints,
        moneyAmount: _selectedPoints * AppAssets.pointToVndRate,
        bankInfo: _selectedAccount!,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed != true) return;

    // Submit request
    setState(() => _isLoading = true);

    try {
      final result = await _cashoutService.createCashout(
        pointsAmount: _selectedPoints,
        bankInfo: _selectedAccount!,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Yêu cầu rút tiền đã được gửi. Vui lòng chờ Admin duyệt.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to reload balance
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModernAppBar(title: 'Rút tiền'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppAssets.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: AppAssets.paddingLarge),
                  _buildPointsInput(),
                  const SizedBox(height: AppAssets.paddingLarge),
                  _buildBankAccountSection(),
                  const SizedBox(height: AppAssets.paddingXLarge),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppAssets.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư khả dụng',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SvgPicture.asset(
                  AppAssets.iconCoin,
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                ),
              const SizedBox(width: 8),
              Text(
                _formatCurrency(widget.currentBalance),
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
        ],
      ),
    );
  }

  Widget _buildPointsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Số điểm muốn rút', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppAssets.paddingSmall),
        Text(
          'Tối thiểu 10 điểm (10.000đ)',
          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.subtitle),
        ),
        const SizedBox(height: AppAssets.paddingMedium),
        TextField(
          controller: _pointsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            setState(() {
              _selectedPoints = int.tryParse(value) ?? 0;
            });
          },
          style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'VD: 100',
            hintStyle: AppTextStyles.hintText.copyWith(fontSize: 16),
            prefixIcon:
                const Icon(Icons.monetization_on, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
        if (_selectedPoints > 0) ...[
          const SizedBox(height: AppAssets.paddingSmall),
          Container(
            padding: const EdgeInsets.all(AppAssets.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppAssets.borderRadiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Số tiền nhận về:', style: AppTextStyles.bodyBold),
                Text(
                  '${_formatCurrency(_selectedPoints * AppAssets.pointToVndRate)}đ',
                  style: AppTextStyles.priceTag.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBankAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tài khoản nhận tiền', style: AppTextStyles.sectionTitle),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankAccountScreen(),
                  ),
                );
                _loadSavedAccounts();
              },
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Quản lý'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppAssets.paddingMedium),
        if (_savedAccounts.isEmpty)
          _buildEmptyBankAccount()
        else
          _buildBankAccountSelector(),
      ],
    );
  }

  Widget _buildEmptyBankAccount() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppAssets.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 48,
            color: AppColors.subtitle,
          ),
          const SizedBox(height: AppAssets.paddingSmall),
          Text(
            'Chưa có tài khoản ngân hàng',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm tài khoản để nhận tiền',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.subtitle,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppAssets.paddingMedium),
          CustomButton(
            text: 'Thêm tài khoản',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BankAccountScreen(),
                ),
              );
              _loadSavedAccounts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSelector() {
    return Container(
      padding: const EdgeInsets.all(AppAssets.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: _savedAccounts.map((account) {
          final isSelected = _selectedAccount == account;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAccount = account;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppAssets.paddingSmall),
              padding: const EdgeInsets.all(AppAssets.paddingMedium),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppAssets.borderRadiusSmall),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppAssets.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.bankName,
                          style: AppTextStyles.bodyBold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'STK: ${account.accountNumber}',
                          style:
                              AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                        ),
                        Text(
                          account.accountName,
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.subtitle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled =
        !_isLoading && _selectedAccount != null && _selectedPoints >= 10;

    return CustomButton(
      text: 'Gửi yêu cầu rút tiền',
      onPressed: isEnabled ? _submitWithdraw : null,
      isPrimary: true,
    );
  }
}
