import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// Widget này giờ đây là public và có thể được gọi từ bất kỳ đâu trong ứng dụng
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: isPrimary ? AppColors.primary : AppColors.secondary,
        foregroundColor: isPrimary ? Colors.white : AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.button,
      ),
    );
  }
}
