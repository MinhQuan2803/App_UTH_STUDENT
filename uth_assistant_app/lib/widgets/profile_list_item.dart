import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class ProfileListItem extends StatelessWidget {
  // CẬP NHẬT: iconPath là String (cho SVG), iconData là IconData (cho icon Flutter)
  final String? iconPath;
  final IconData? iconData;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const ProfileListItem({
    super.key,
    this.iconPath,
    this.iconData,
    required this.title,
    required this.onTap,
    this.color,
  }) : assert(iconPath != null || iconData != null, 'Phải cung cấp iconPath (cho SVG) hoặc iconData (cho Icon)'); // Đảm bảo có 1 icon

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textSecondary;

    // CẬP NHẬT: Logic chọn icon để hiển thị
    Widget iconWidget;
    if (iconPath != null) {
      // Nếu là SVG
      iconWidget = SvgPicture.asset(
        iconPath!,
        width: 22,
        colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
      );
    } else {
      // Nếu là IconData
      iconWidget = Icon(
        iconData!,
        color: itemColor,
        size: 22,
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            iconWidget, // Sử dụng iconWidget đã chọn
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.listItem.copyWith(color: itemColor),
              ),
            ),
            SvgPicture.asset(
              AppAssets.iconChevronRight,
              width: 20,
              colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}

