import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class UserListItem extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.username,
    this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.secondary,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.white,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Username
            Expanded(
              child: Text(
                username,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.text,
                  fontSize: 16,
                ),
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
