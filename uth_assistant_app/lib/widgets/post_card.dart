import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../services/post_service.dart'; // Import service để gọi API Like
import 'package:flutter/foundation.dart'; // Import kDebugMode

// --- CHUYỂN THÀNH STATEFULWIDGET ---
class PostCard extends StatefulWidget {
  final String postId; // THÊM: ID bài viết
  final String avatarUrl;
  final String name;
  final String time;
  final String major;
  final String content;
  final int likes;
  final int comments;
  final bool isLiked;
  final Color? backgroundColor;
  final List<String>? mediaUrls;

  const PostCard({
    super.key,
    required this.postId, // Yêu cầu ID
    required this.avatarUrl,
    required this.name,
    required this.time,
    required this.major,
    required this.content,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.backgroundColor,
    this.mediaUrls,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Trạng thái cục bộ để cập nhật UI ngay lập tức
  late bool _isLiked;
  late int _likesCount;
  bool _isLiking = false; // Ngăn spam click
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likes;
  }

  // --- HÀM XỬ LÝ LIKE ---
  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
      if (_isLiked) {
        _likesCount--;
        _isLiked = false;
      } else {
        _likesCount++;
        _isLiked = true;
      }
    });

    try {
      // Gọi API (sử dụng PostService từ Canvas)
      await _postService.likePost(widget.postId, type: 'like');
    } catch (e) {
      if (kDebugMode) print("Lỗi khi like: $e");
      // Nếu API lỗi, đảo ngược lại trạng thái UI
      setState(() {
        if (_isLiked) {
          _likesCount--;
          _isLiked = false;
        } else {
          _likesCount++;
          _isLiked = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
         setState(() => _isLiking = false);
      }
    }
  }

  // --- HÀM HIỂN THỊ MENU BÁO CÁO ---
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: AppColors.danger),
              title: const Text('Báo cáo bài viết', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.of(ctx).pop();
                // TODO: Gọi API báo cáo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi báo cáo (chức năng đang phát triển).')),
                );
              },
            ),
             ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppColors.subtitle),
              title: const Text('Hủy'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }
    final hash = widget.name.hashCode.abs();
    return AppColors.postBackgrounds[hash % AppColors.postBackgrounds.length];
  }

  Widget _buildMediaPreview() {
    if (widget.mediaUrls == null || widget.mediaUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.mediaUrls!.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.mediaUrls![0],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              color: AppColors.imagePlaceholder, // Sử dụng theme
              child: const Icon(Icons.broken_image, size: 40, color: AppColors.subtitle), // Sử dụng theme
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.mediaUrls!.length > 3 ? 3 : widget.mediaUrls!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.mediaUrls![index],
                    fit: BoxFit.cover,
                    width: 80,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 100,
                        color: AppColors.imagePlaceholder, // Sử dụng theme
                        child: const Icon(Icons.broken_image, size: 30, color: AppColors.subtitle), // Sử dụng theme
                      );
                    },
                  ),
                ),
                if (index == 2 && widget.mediaUrls!.length > 3)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.imageOverlay, // Sử dụng theme
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${widget.mediaUrls!.length - 3}',
                          style: AppTextStyles.imageOverlayText, // Sử dụng theme
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
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
          Text(
            widget.content,
            style: AppTextStyles.postContent.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.mediaUrls != null && widget.mediaUrls!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMediaPreview(),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(widget.avatarUrl),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.name,
                  style: AppTextStyles.postMeta.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.text.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: SvgPicture.asset(
                    AppAssets.iconMore,
                    colorFilter: ColorFilter.mode(
                        AppColors.subtitle.withOpacity(0.7), BlendMode.srcIn),
                  ),
                  onPressed: () => _showMoreOptions(context), // Kích hoạt menu
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InteractionButton(
                iconAsset: AppAssets.iconHeart,
                label: _likesCount > 0 ? '$_likesCount' : '',
                isActive: _isLiked, // Sử dụng state cục bộ
                activeColor: AppColors.accent,
                onTap: _handleLike, // Kích hoạt logic Like
              ),
              const SizedBox(width: 12),
              _InteractionButton(
                iconAsset: AppAssets.iconComment,
                label: widget.comments > 0 ? '${widget.comments}' : '',
                activeColor: AppColors.primary,
                onTap: () {
                  // TODO: Logic Bình luận (sẽ được xử lý bằng cách nhấn vào thẻ)
                  print('Comment tapped for post ${widget.postId}');
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
  final VoidCallback? onTap;

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

    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: AppColors.transparent, // Sử dụng theme
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isActive || label.isNotEmpty)
                ? color.withOpacity(0.1)
                : AppColors.transparent, // Sử dụng theme
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
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
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

