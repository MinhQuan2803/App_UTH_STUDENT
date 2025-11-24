import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../services/post_service.dart';
import 'package:flutter/foundation.dart';

// --- (LOGIC STATEFUL VẪN GIỮ NGUYÊN) ---
class PostCard extends StatefulWidget {
  final String postId;
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
    required this.postId,
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
  late bool _isLiked;
  late int _likesCount;
  bool _isLiking = false;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likes;
  }

  // [FIX QUAN TRỌNG] Thêm didUpdateWidget để đồng bộ state
  // khi widget cha (list) refresh lại dữ liệu
  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked ||
        widget.likes != oldWidget.likes) {
      setState(() {
        _isLiked = widget.isLiked;
        _likesCount = widget.likes;
      });
    }
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    final previousLiked = _isLiked;
    final previousCount = _likesCount;

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
      final actionType = _isLiked ? 'like' : 'unlike';
      await _postService.likePost(widget.postId, type: actionType);
    } catch (e) {
      if (kDebugMode) print("Lỗi khi like: $e");
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likesCount = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: AppColors.danger),
              title: const Text('Báo cáo bài viết',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Đã gửi báo cáo (chức năng đang phát triển).')),
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
    return AppColors
        .postBackgrounds[hash % AppColors.postBackgrounds.length];
  }

  Widget _buildMediaPreview() {
    // (Giữ nguyên logic _buildMediaPreview của bạn, nó đã khá tối ưu)
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
          height: 120, // [Refactor] Giảm chiều cao ảnh
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              color: AppColors.imagePlaceholder,
              child: const Icon(Icons.broken_image,
                  size: 40, color: AppColors.subtitle),
            );
          },
        ),
      );
    }
    return SizedBox(
      height: 90, // [Refactor] Giảm chiều cao
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
                    width: 70, // [Refactor] Giảm kích thước
                    height: 90, // [Refactor] Giảm kích thước
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 90,
                        color: AppColors.imagePlaceholder,
                        child: const Icon(Icons.broken_image,
                            size: 30, color: AppColors.subtitle),
                      );
                    },
                  ),
                ),
                if (index == 2 && widget.mediaUrls!.length > 3)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.imageOverlay,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${widget.mediaUrls!.length - 3}',
                          style: AppTextStyles.imageOverlayText,
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
      // [Refactor] Giảm padding, đặc biệt là chiều ngang, để nhỏ gọn hơn
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        // [Refactor] "Điểm nhấn" shadow nhẹ nhàng, hiện đại hơn
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08), // Nhẹ hơn
            blurRadius: 12, // Mờ hơn
            offset: const Offset(0, 4), // Đổ bóng xuống dưới
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- [REFACTOR] 1. HEADER (Thông tin tác giả) ---
          Row(
            children: [
              CircleAvatar(
                radius: 16, // [Refactor] To hơn một chút (32x32)
                backgroundImage: NetworkImage(widget.avatarUrl),
                // Thêm fallback phòng khi ảnh lỗi
                onBackgroundImageError: (e, s) {},
              ),
              const SizedBox(width: 8),
              Expanded(
                // [Refactor] Gộp Tên và Meta (Time, Major)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: AppTextStyles.postMeta.copyWith(
                        fontWeight: FontWeight.w600, // In đậm tên
                        color: AppColors.text, // Màu text chính
                        fontSize: 14, // Cỡ chữ 14
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.time} • ${widget.major}', // Hiển thị cả major
                      style: AppTextStyles.postMeta.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.text.withOpacity(0.7),
                        fontSize: 12, // Cỡ chữ meta nhỏ
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // [Refactor] Nút "More" gọn gàng hơn
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: SvgPicture.asset(
                    AppAssets.iconMore,
                    colorFilter: ColorFilter.mode(
                        AppColors.subtitle.withOpacity(0.7), BlendMode.srcIn),
                  ),
                  onPressed: () => _showMoreOptions(context),
                ),
              )
            ],
          ),

          // --- 2. NỘI DUNG ---
          const SizedBox(height: 10), // [Refactor] Khoảng cách chuẩn
          Text(
            widget.content,
            style: AppTextStyles.postContent.copyWith(
              fontSize: 14.5, // [Refactor] Cỡ chữ nhỏ hơn (14.5)
              fontWeight: FontWeight.w400, // [Refactor] Dùng W400 cho dễ đọc
              height: 1.35, // [Refactor] Giảm chiều cao dòng
            ),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),

          // --- 3. MEDIA (Nếu có) ---
          if (widget.mediaUrls != null && widget.mediaUrls!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildMediaPreview(),
          ],

          // --- [REFACTOR] 4. TƯƠNG TÁC (Like/Comment) ---
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InteractionButton(
                iconAsset: AppAssets.iconHeart,
                label: _likesCount > 0 ? '$_likesCount' : '',
                isActive: _isLiked,
                activeColor: AppColors.accent,
                onTap: _handleLike,
              ),
              const SizedBox(width: 16), // [Refactor] Tăng khoảng cách
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

// --- [REFACTOR] NÚT TƯƠNG TÁC GỌN GÀNG HƠN ---
// Chỉ Icon và Text, không có background, dùng InkWell
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // Bo tròn cho hiệu ứng ripple
      child: Padding(
        // [Refactor] Padding nhỏ để tạo vùng nhấn
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 18, // [Refactor] Icon to rõ hơn (18x18)
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5), // Khoảng cách 5px
              Text(
                label,
                style: AppTextStyles.interaction.copyWith(
                  color: color,
                  fontSize: 13, // [Refactor] Cỡ chữ 13
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}