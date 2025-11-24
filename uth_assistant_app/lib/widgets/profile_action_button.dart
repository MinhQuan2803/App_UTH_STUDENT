import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget nút action cho Profile Screen
/// Hỗ trợ 3 loại: Primary, Secondary, và Follow (với loading state)
class ProfileActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ProfileButtonType type;
  final bool isLoading;

  const ProfileActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ProfileButtonType.secondary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(),
        foregroundColor: _getForegroundColor(),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 0),
        fixedSize: const Size.fromHeight(AppAssets.buttonHeightSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppAssets.borderRadiusSmall),
        ),
        disabledBackgroundColor: _getBackgroundColor(),
        disabledForegroundColor: _getForegroundColor(),
      ),
      child: isLoading
          ? const SizedBox(
              width: AppAssets.iconSizeSmall,
              height: AppAssets.iconSizeSmall,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              text,
              style: AppTextStyles.profileButton.copyWith(
                fontSize: 13,
                color: _getForegroundColor(),
              ),
            ),
    );
  }

  Color _getBackgroundColor() {
    // Tất cả các nút đều dùng màu primary
    return AppColors.primaryDark;
  }

  Color _getForegroundColor() {
    // Tất cả các nút đều dùng chữ trắng
    return AppColors.white;
  }
}

/// Enum định nghĩa các loại nút trong Profile
enum ProfileButtonType {
  primary, // Nút chính (màu primary, chữ trắng)
  secondary, // Nút phụ (nền xám nhạt, chữ đen)
  follow, // Nút theo dõi (màu primary, chữ trắng)
  following, // Nút đang theo dõi (nền xám nhạt, chữ đen)
}
