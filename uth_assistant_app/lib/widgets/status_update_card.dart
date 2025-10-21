import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class StatusUpdateCard extends StatelessWidget {
  const StatusUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0), // giảm padding
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.0), // hơi nhỏ lại
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bạn đang nghĩ gì, Mai Phương?',
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // giảm khoảng cách
          const Divider(color: AppColors.dividerLight, height: 1, thickness: 0.5),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                iconPath: AppAssets.iconImage,
                label: 'Ảnh',
                onTap: () {},
              ),
              _buildActionButton(
                iconPath: AppAssets.iconFileCheck,
                label: 'Tệp',
                onTap: () {},
              ),
              _buildActionButton(
                iconPath: AppAssets.iconEdit,
                label: 'Ghi',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: SvgPicture.asset(iconPath, width: 16, colorFilter: const ColorFilter.mode(AppColors.subtitle, BlendMode.srcIn)),
        label: Text(label, style: AppTextStyles.interaction.copyWith(fontSize: 12)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
          foregroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}