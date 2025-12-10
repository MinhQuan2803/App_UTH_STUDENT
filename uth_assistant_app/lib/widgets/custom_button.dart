import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// Widget này giờ đây là public và có thể được gọi từ bất kỳ đâu trong ứng dụng
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Cho phép null để disable nút
  final bool isPrimary;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, height ?? 52),
        backgroundColor: isPrimary ? AppColors.primary : AppColors.secondary,
        foregroundColor: isPrimary ? Colors.white : AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        disabledBackgroundColor: AppColors.divider,
        disabledForegroundColor: AppColors.subtitle,
      ),
      child: Text(
        text,
        style: AppTextStyles.button,
      ),
    );
  }
}
