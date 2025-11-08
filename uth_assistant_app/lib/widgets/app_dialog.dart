import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../utils/dialog_utils.dart'; // Import enum

class AppDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const AppDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  // Chọn màu và icon dựa trên loại dialog
  Map<String, dynamic> _getDialogProperties(DialogType type) {
    switch (type) {
      case DialogType.success:
        return {'color': AppColors.success, 'icon': AppAssets.iconSuccess};
      case DialogType.error:
        return {'color': AppColors.danger, 'icon': AppAssets.iconError};
      case DialogType.warning:
        return {'color': AppColors.warning, 'icon': AppAssets.iconWarning};
      default: // info
        return {'color': AppColors.primary, 'icon': AppAssets.iconBell}; // Tạm dùng iconBell
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = _getDialogProperties(type);
    final Color color = properties['color'];
    final String icon = properties['icon'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: AppColors.transparent,
      child: Stack(
        clipBehavior: Clip.none, // Cho phép icon hiển thị bên ngoài
        children: [
          // Thân dialog
          Container(
            padding: const EdgeInsets.only(
              top: 60, // Chừa không gian cho icon
              bottom: 16,
              left: 16,
              right: 16,
            ),
            margin: const EdgeInsets.only(top: 40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                 BoxShadow(color: AppColors.shadow, blurRadius: 15, offset: Offset(0, 5))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Giúp dialog co lại
              children: [
                Text(
                  title,
                  style: AppTextStyles.dialogTitle.copyWith(color: color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.dialogMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Nút chính
                CustomButton(
                  text: primaryButtonText,
                  onPressed: onPrimaryPressed,
                  // Tùy chỉnh màu nút dựa trên loại dialog
                  color: color, 
                  isPrimary: true, // Để có nền
                ),
                // Nút phụ (nếu có)
                if (secondaryButtonText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: CustomButton(
                      text: secondaryButtonText!,
                      onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
                      isPrimary: false, // Nút không nền
                    ),
                  ),
              ],
            ),
          ),
          
          // Icon nổi bên trên
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                  boxShadow: [
                     BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                  ]
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 40,
                    height: 40,
                    colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CẬP NHẬT: Sửa CustomButton để chấp nhận màu tùy chỉnh và chiều rộng
// (Đây là file widget/app_dialog.dart nên chúng ta có thể tạm định nghĩa CustomButton ở đây
// nếu nó chưa được tách ra, nhưng tốt nhất là file widgets/custom_button.dart nên được cập nhật)

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? color; // Thêm màu tùy chỉnh
  final double? width; // Thêm chiều rộng tùy chỉnh

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = isPrimary 
        ? (color ?? AppColors.primary) 
        : (color ?? AppColors.transparent);
        
    final effectiveForegroundColor = isPrimary 
        ? AppColors.white 
        : (color ?? AppColors.primary);

    return SizedBox(
      width: width ?? double.infinity, // Sử dụng chiều rộng tùy chỉnh hoặc full
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52), // Bỏ chiều rộng cố định
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          elevation: isPrimary ? 2 : 0, // Thêm elevation nhẹ cho nút chính
          shadowColor: isPrimary ? effectiveBackgroundColor.withOpacity(0.3) : AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: !isPrimary && color == null 
                  ? const BorderSide(color: AppColors.secondary) // Viền mặc định cho nút phụ
                  : BorderSide.none
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: isPrimary ? AppColors.white : effectiveForegroundColor
          ),
        ),
      ),
    );
  }
}