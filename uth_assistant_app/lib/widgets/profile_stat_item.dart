import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget tái sử dụng để hiển thị thống kê profile (followers, following, posts, etc.)
class ProfileStatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const ProfileStatItem({
    super.key,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
