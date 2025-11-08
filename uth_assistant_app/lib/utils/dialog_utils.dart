import 'package:flutter/material.dart';
import '../widgets/app_dialog.dart'; // Import widget dialog

// Enum để định nghĩa các loại thông báo
enum DialogType {
  success,
  error,
  warning,
  info,
}

/// Hàm trợ giúp để hiển thị dialog tùy chỉnh một cách nhanh chóng
///
/// Ví dụ cách gọi:
/// showAppDialog(
///   context,
///   type: DialogType.success,
///   title: 'Thành công!',
///   message: 'Bài viết của bạn đã được đăng.',
///   primaryButtonText: 'Đồng ý',
///   onPrimaryPressed: () => Navigator.of(context).pop(),
/// );
Future<void> showAppDialog(
  BuildContext context, {
  required DialogType type,
  required String title,
  required String message,
  String primaryButtonText = 'Đồng ý',
  VoidCallback? onPrimaryPressed,
  String? secondaryButtonText,
  VoidCallback? onSecondaryPressed,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // Người dùng phải nhấn nút để đóng
    builder: (BuildContext dialogContext) {
      return AppDialog(
        type: type,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed ?? () => Navigator.of(dialogContext).pop(),
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
      );
    },
  );
}