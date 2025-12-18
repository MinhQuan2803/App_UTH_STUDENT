import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/report_service.dart';
import 'custom_notification.dart';

class ReportDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'Post', 'Comment', 'User'
  final String targetName; // Tên hiển thị (username, post title, etc.)

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedReason;
  bool _isSubmitting = false;

  final Map<String, String> _reasons = {
    'spam': 'Spam',
    'harassment': 'Quấy rối',
    'hate_speech': 'Phát ngôn thù địch',
    'nudity': 'Nội dung nhạy cảm',
    'false_info': 'Thông tin sai lệch',
    'other': 'Khác',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      CustomNotification.error(context, 'Vui lòng chọn lý do báo cáo');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await _reportService.sendReport(
        targetId: widget.targetId,
        targetType: widget.targetType,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Đóng dialog
        CustomNotification.success(context, message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String targetText = '';
    IconData targetIcon = Icons.report;

    switch (widget.targetType) {
      case 'Post':
        targetText = 'bài viết';
        targetIcon = Icons.article_outlined;
        break;
      case 'Comment':
        targetText = 'bình luận';
        targetIcon = Icons.comment_outlined;
        break;
      case 'User':
        targetText = 'người dùng';
        targetIcon = Icons.person_outline;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      targetIcon,
                      color: AppColors.danger,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo $targetText',
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.targetName,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.subtitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Lý do báo cáo
              Text(
                'Vì sao bạn báo cáo $targetText này?',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Radio buttons
              ..._reasons.entries.map((entry) {
                return RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedReason,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() => _selectedReason = value);
                        },
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedReason == entry.key
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.danger,
                );
              }).toList(),

              const SizedBox(height: 16),

              // Mô tả chi tiết (optional)
              Text(
                'Mô tả chi tiết (không bắt buộc)',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Thêm thông tin để giúp chúng tôi xem xét...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.subtitle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.danger),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  counterStyle: TextStyle(fontSize: 11),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Gửi báo cáo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
