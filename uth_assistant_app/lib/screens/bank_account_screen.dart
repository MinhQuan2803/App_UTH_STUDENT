import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../models/cashout_model.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/cashout_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  List<BankInfo> _savedAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAccounts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList('bank_accounts') ?? [];
      setState(() {
        _savedAccounts = accountsJson
            .map((json) => BankInfo.fromJson(jsonDecode(json)))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = _savedAccounts
          .map((account) => jsonEncode(account.toJson()))
          .toList();
      await prefs.setStringList('bank_accounts', accountsJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi lưu thông tin tài khoản')),
        );
      }
    }
  }

  Future<void> _addAccount() async {
    if (_bankNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final newAccount = BankInfo(
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      accountName: _accountNameController.text.trim(),
    );

    setState(() {
      _savedAccounts.add(newAccount);
    });

    await _saveAccounts();

    _bankNameController.clear();
    _accountNumberController.clear();
    _accountNameController.clear();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm tài khoản ngân hàng')),
      );
    }
  }

  Future<void> _deleteAccount(int index) async {
    setState(() {
      _savedAccounts.removeAt(index);
    });
    await _saveAccounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tài khoản')),
      );
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AddBankAccountDialog(
        bankNameController: _bankNameController,
        accountNumberController: _accountNumberController,
        accountNameController: _accountNameController,
        onAdd: _addAccount,
        onCancel: () {
          _bankNameController.clear();
          _accountNumberController.clear();
          _accountNameController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModernAppBar(title: 'Tài khoản ngân hàng'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedAccounts.isEmpty
              ? _buildEmptyState()
              : _buildAccountList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('Thêm tài khoản',
            style: TextStyle(color: AppColors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.subtitle.withOpacity(0.5),
          ),
          const SizedBox(height: AppAssets.paddingLarge),
          Text(
            'Chưa có tài khoản ngân hàng',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 16,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: AppAssets.paddingSmall),
          Text(
            'Thêm tài khoản để rút tiền',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppAssets.paddingLarge),
      itemCount: _savedAccounts.length,
      itemBuilder: (context, index) {
        final account = _savedAccounts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppAssets.paddingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppAssets.paddingMedium),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppAssets.borderRadiusSmall),
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppColors.primary,
                size: AppAssets.iconSizeMedium,
              ),
            ),
            title: Text(
              account.bankName,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'STK: ${account.accountNumber}',
                  style: AppTextStyles.bodyRegular,
                ),
                Text(
                  'Chủ TK: ${account.accountName}',
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc muốn xóa tài khoản này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAccount(index);
                        },
                        child: const Text(
                          'Xóa',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
