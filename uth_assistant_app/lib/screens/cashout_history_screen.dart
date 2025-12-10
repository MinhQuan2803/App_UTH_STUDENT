import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/cashout_model.dart';
import '../services/cashout_service.dart';
import '../widgets/modern_app_bar.dart';

class CashoutHistoryScreen extends StatefulWidget {
  const CashoutHistoryScreen({super.key});

  @override
  State<CashoutHistoryScreen> createState() => _CashoutHistoryScreenState();
}

class _CashoutHistoryScreenState extends State<CashoutHistoryScreen> {
  final CashoutService _cashoutService = CashoutService();
  List<CashoutModel> _cashouts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCashoutHistory();
  }

  Future<void> _loadCashoutHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cashouts = await _cashoutService.getCashoutHistory();
      if (mounted) {
        setState(() {
          _cashouts = cashouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.subtitle;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.access_time;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModernAppBar(title: 'Lịch sử rút tiền'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _cashouts.isEmpty
                  ? _buildEmptyState()
                  : _buildCashoutList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppAssets.paddingLarge),
          Text(
            'Lỗi tải dữ liệu',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 16,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppAssets.paddingSmall),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppAssets.paddingXLarge),
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppAssets.paddingLarge),
          ElevatedButton.icon(
            onPressed: _loadCashoutHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppColors.subtitle.withOpacity(0.5),
          ),
          const SizedBox(height: AppAssets.paddingLarge),
          Text(
            'Chưa có lịch sử rút tiền',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 16,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: AppAssets.paddingSmall),
          Text(
            'Các yêu cầu rút tiền sẽ hiển thị ở đây',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashoutList() {
    return RefreshIndicator(
      onRefresh: _loadCashoutHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppAssets.paddingLarge),
        itemCount: _cashouts.length,
        itemBuilder: (context, index) {
          final cashout = _cashouts[index];
          return _buildCashoutCard(cashout);
        },
      ),
    );
  }

  Widget _buildCashoutCard(CashoutModel cashout) {
    final statusColor = _getStatusColor(cashout.status);
    final statusIcon = _getStatusIcon(cashout.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppAssets.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppAssets.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      cashout.getStatusText(),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: statusColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(cashout.createdAtLocal),
                  style: AppTextStyles.postMeta.copyWith(fontSize: 11),
                ),
              ],
            ),
            const Divider(height: AppAssets.paddingLarge),

            // Amount info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Số điểm rút:', style: AppTextStyles.bodyRegular),
                Text(
                  '${_formatCurrency(cashout.pointsAmount)} điểm',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Số tiền nhận:', style: AppTextStyles.bodyRegular),
                Text(
                  '${_formatCurrency(cashout.moneyAmount)}đ',
                  style: AppTextStyles.priceTag.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: AppAssets.paddingMedium),

            // Bank info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppAssets.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.circular(AppAssets.borderRadiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thông tin tài khoản',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cashout.bankInfo.bankName,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'STK: ${cashout.bankInfo.accountNumber}',
                    style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                  ),
                  Text(
                    cashout.bankInfo.accountName,
                    style: AppTextStyles.bodyRegular.copyWith(
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),

            // Rejection reason if rejected
            if (cashout.status == 'REJECTED' &&
                cashout.rejectionReason != null) ...[
              const SizedBox(height: AppAssets.paddingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppAssets.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppAssets.borderRadiusSmall),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lý do từ chối',
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: 12,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cashout.rejectionReason!,
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            // Processed date if approved
            if (cashout.status == 'APPROVED' &&
                cashout.processedAt != null) ...[
              const SizedBox(height: AppAssets.paddingSmall),
              Text(
                'Đã duyệt lúc: ${_formatDate(cashout.processedAt!)}',
                style: AppTextStyles.postMeta.copyWith(
                  color: AppColors.success,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
