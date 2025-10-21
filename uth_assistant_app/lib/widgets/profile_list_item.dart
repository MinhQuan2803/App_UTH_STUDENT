import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class ProfileListItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const ProfileListItem({
    super.key,
    required this.iconPath,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 22,
              colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
            ),
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
