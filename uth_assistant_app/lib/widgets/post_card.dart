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
  final Color? backgroundColor; // Màu nền tùy chỉnh (nullable)

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
    this.backgroundColor, // Người dùng có thể truyền màu vào
  });

  // Danh sách màu nền pastel tươi sáng (dự phòng nếu không chọn màu)
  static final List<Color> _backgroundColors = [
    const Color(0xFFFFF0F5), // Hồng pastel
    const Color(0xFFF0F4FF), // Xanh dương pastel
    const Color(0xFFFFFAF0), // Cam nhạt
    const Color(0xFFF0FFF4), // Xanh lá pastel
    const Color(0xFFFFF5F7), // Hồng nhạt
    const Color(0xFFF3F0FF), // Tím pastel
  ];

  Color _getBackgroundColor() {
    // Nếu người dùng đã chọn màu thì dùng màu đó
    if (backgroundColor != null) {
      return backgroundColor!;
    }
    // Nếu không, random màu dựa trên hash của name
    final hash = name.hashCode.abs();
    return _backgroundColors[hash % _backgroundColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header của bài viết
          Row(
            children: [
              // Avatar với border gradient
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.6),
                      AppColors.accent.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.white,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.postName),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(time, style: AppTextStyles.postMeta),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 10,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            major,
                            style: AppTextStyles.postMeta.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    AppAssets.iconMore,
                    width: 18,
                    colorFilter: ColorFilter.mode(
                      AppColors.subtitle,
                      BlendMode.srcIn,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nội dung bài viết
          Text(content, style: AppTextStyles.postContent),
          const SizedBox(height: 14),
          // Divider mỏng với màu accent nhẹ
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.accent.withOpacity(0.3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Nút tương tác
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InteractionButton(
                iconAsset: AppAssets.iconHeart,
                label: likes > 0 ? '$likes' : 'Thích',
                isActive: isLiked,
                activeColor: AppColors.accent,
              ),
              const SizedBox(width: 20),
              _InteractionButton(
                iconAsset: AppAssets.iconComment,
                label: comments > 0 ? '$comments' : 'Bình luận',
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget riêng cho các nút tương tác (Thích, Bình luận)
class _InteractionButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isActive;
  final Color activeColor;

  const _InteractionButton({
    required this.iconAsset,
    required this.label,
    this.isActive = false,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : AppColors.subtitle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.12)
            : AppColors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 18,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.interaction.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
