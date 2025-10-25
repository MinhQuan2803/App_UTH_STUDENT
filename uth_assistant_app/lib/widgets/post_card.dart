import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class PostCard extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String time;
  final String major;
  final String content;
  final int likes;
  final int comments;
  final bool isLiked;
  final Color? backgroundColor;

  const PostCard({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.time,
    required this.major,
    required this.content,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.backgroundColor,
  });

  Color _getBackgroundColor() {
    if (backgroundColor != null) {
      return backgroundColor!;
    }
    final hash = name.hashCode.abs();
    return AppColors.postBackgrounds[hash % AppColors.postBackgrounds.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nội dung chính
          Text(
            content,
            style: AppTextStyles.postContent.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10), // Tăng khoảng cách chút

          // Thông tin người đăng và nút More
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.postMeta.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.text.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Nút More (...) cho Báo cáo
              SizedBox(
                width: 24, // Giới hạn kích thước nút
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: SvgPicture.asset(
                    AppAssets.iconMore,
                    colorFilter: ColorFilter.mode(AppColors.subtitle.withOpacity(0.7), BlendMode.srcIn),
                  ),
                  onPressed: () {
                    // TODO: Hiển thị menu với tùy chọn Báo cáo
                    print('More options tapped');
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 8), // Khoảng cách trước nút tương tác

          // Nút tương tác
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InteractionButton(
                iconAsset: AppAssets.iconHeart,
                label: likes > 0 ? '$likes' : '',
                isActive: isLiked,
                activeColor: AppColors.accent,
                onTap: () {
                  // TODO: Logic Thích
                },
              ),
              const SizedBox(width: 12),
              _InteractionButton(
                iconAsset: AppAssets.iconComment,
                label: comments > 0 ? '$comments' : '',
                activeColor: AppColors.primary,
                 onTap: () {
                  // TODO: Logic Bình luận
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Khôi phục lại Widget InteractionButton
class _InteractionButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap; // Thêm callback onTap

  const _InteractionButton({
    required this.iconAsset,
    required this.label,
    this.isActive = false,
    this.activeColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : AppColors.subtitle.withOpacity(0.8);

    // Bọc trong GestureDetector để có thể nhấn vào
    return GestureDetector(
      onTap: onTap,
      // Dùng Material để có hiệu ứng ripple
      child: Material(
        color: Colors.transparent, // Nền trong suốt
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Giảm padding nhẹ
          decoration: BoxDecoration(
            // Chỉ hiển thị nền nhẹ khi active hoặc có label (số lượng)
            color: (isActive || label.isNotEmpty)
                ? color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 16,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              // Chỉ hiện label nếu có
              if (label.isNotEmpty) ...[
                 const SizedBox(width: 4), // Giảm khoảng cách
                 Text(
                  label,
                  style: AppTextStyles.interaction.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

