import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/interaction_service.dart';
import '../utils/time_formatter.dart';
import '../screens/add_post_screen.dart';
import '../screens/image_viewer_screen.dart';
import 'custom_notification.dart';
import 'report_dialog.dart';
import 'package:flutter/foundation.dart'; // Cho kDebugMode

class HomePostCard extends StatefulWidget {
  final Post post;
  final String? username; // Username của người dùng đang đăng nhập
  final VoidCallback onPostDeleted; // Callback khi xóa thành công
  final VoidCallback onPostUpdated; // Callback khi sửa thành công
  final bool isDetailView; // True nếu đang hiển thị trong màn hình chi tiết
  final String?
      currentUsername; // Username của profile đang xem (để tránh vòng lặp)

  const HomePostCard({
    super.key,
    required this.post,
    this.username,
    required this.onPostDeleted,
    required this.onPostUpdated,
    this.isDetailView = false, // Mặc định là false
    this.currentUsername, // Tùy chọn
  });

  @override
  State<HomePostCard> createState() => _HomePostCardState();
}

class _HomePostCardState extends State<HomePostCard> {
  late bool _isLiked;
  late bool _isDisliked;
  late int _likesCount;
  late int _dislikesCount;
  bool _isLiking = false;
  bool _isDisliking = false;
  final PostService _postService = PostService();
  final InteractionService _interactionService = InteractionService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.myReactionType == 'like';
    _isDisliked = widget.post.myReactionType == 'dislike';
    _likesCount = widget.post.likesCount;
    _dislikesCount = widget.post.dislikesCount;
  }

  // Xử lý khi nhấn nút Thích
  Future<void> _handleLikePost() async {
    if (_isLiking) return;

    // Optimistic update
    final wasLiked = _isLiked;
    final oldLikesCount = _likesCount;

    setState(() {
      _isLiking = true;
      if (_isLiked) {
        _likesCount--;
        _isLiked = false;
      } else {
        _likesCount++;
        _isLiked = true;
        // Nếu đang dislike, chuyển sang like
        if (_isDisliked) {
          _dislikesCount--;
          _isDisliked = false;
        }
      }
    });

    try {
      // Gọi API toggle like
      final result = await _interactionService.toggleLike(widget.post.id);

      // Cập nhật với data thật từ server
      if (mounted) {
        setState(() {
          _isLiked = result['isLiked'] ?? false;
          _likesCount = result['likesCount'] ?? _likesCount;
        });
      }
    } catch (e) {
      if (kDebugMode) print("Lỗi khi like: $e");
      // Rollback optimistic update
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likesCount = oldLikesCount;
        });
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  // Xử lý khi nhấn nút Không thích
  Future<void> _handleDislikePost() async {
    if (_isDisliking) return;

    // Optimistic update
    final wasDisliked = _isDisliked;
    final oldDislikesCount = _dislikesCount;

    setState(() {
      _isDisliking = true;
      if (_isDisliked) {
        _dislikesCount--;
        _isDisliked = false;
      } else {
        _dislikesCount++;
        _isDisliked = true;
        // Nếu đang like, chuyển sang dislike
        if (_isLiked) {
          _likesCount--;
          _isLiked = false;
        }
      }
    });

    try {
      // Gọi API với type='dislike'
      await _postService.likePost(widget.post.id, type: 'dislike');

      if (kDebugMode) print('✓ Dislike thành công');
    } catch (e) {
      if (kDebugMode) print("Lỗi khi dislike: $e");
      // Rollback optimistic update
      if (mounted) {
        setState(() {
          _isDisliked = wasDisliked;
          _dislikesCount = oldDislikesCount;
        });
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDisliking = false);
      }
    }
  }

  // Xử lý khi nhấn nút Chia sẻ
  Future<void> _handleSharePost() async {
    if (mounted) {
      CustomNotification.info(
          context, 'Tính năng chia sẻ đang được phát triển');
    }
  }

  // Xử lý khi nhấn nút Xóa
  void _deletePost() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Đóng dialog xác nhận

              // Hiển thị thông báo đang xóa
              if (!mounted) return;
              CustomNotification.info(context, 'Đang xóa bài viết...');

              try {
                await _postService.deletePost(widget.post.id);

                // Kiểm tra mounted chuẩn Flutter
                if (!mounted) return;

                CustomNotification.success(context, 'Đã xóa bài viết');

                // Đợi notification render
                await Future.delayed(const Duration(milliseconds: 200));

                // Sau đó mới xóa widget
                if (mounted) {
                  widget.onPostDeleted();
                }
              } catch (e) {
                if (!mounted) return;
                CustomNotification.error(
                  context,
                  e.toString().replaceFirst('Exception: ', ''),
                );
              }
            },
            child: const Text('Xóa', style: AppTextStyles.deleteDialogText),
          ),
        ],
      ),
    );
  }

  // Xử lý khi nhấn báo cáo
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetId: widget.post.id,
        targetType: 'Post',
        targetName: 'Bài viết của ${widget.post.author.username}',
      ),
    );
  }

  // Xử lý khi nhấn nút Sửa
  void _editPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPostScreen(post: widget.post)),
    );
    // Nếu màn hình Sửa trả về true (nghĩa là đã lưu thành công)
    if (result == true) {
      if (mounted) {
        CustomNotification.success(context, 'Đã cập nhật bài viết');
      }
      widget.onPostUpdated(); // Báo cho HomeScreen tải lại
    }
  }

  // Điều hướng đến trang chi tiết
  void _navigateToDetail() {
    // Nếu đang ở màn hình chi tiết rồi thì không làm gì
    if (widget.isDetailView) return;

    // Nếu là bài post từ tài liệu → Mở Document Detail
    if (widget.post.isDocumentPost && widget.post.docId != null) {
      Navigator.pushNamed(
        context,
        '/document_detail',
        arguments: {'documentId': widget.post.docId},
      );
      return;
    }

    // Bài post thông thường → Mở Post Detail
    Navigator.pushNamed(
      context,
      '/post_detail',
      arguments: {'post': widget.post},
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDetailView
          ? null
          : _navigateToDetail, // Tắt tap khi ở detail view
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: const BoxDecoration(
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Quan trọng: Tránh unbounded height
          children: [
            _buildPostHeader(context),
            if (widget.post.text.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Text(widget.post.text,
                    style: AppTextStyles.postContent
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w400)),
              ),
            // Hiển thị badge nếu là bài post từ tài liệu
            if (widget.post.isDocumentPost)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bài viết về tài liệu - Nhấn để xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              _buildMediaGallery(context, widget.post.mediaUrls),
            ],
            _buildActionButtons(context),
            // Divider giữa các posts
            const Divider(
                height: 1, thickness: 10, color: AppColors.background),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET HELPER ---

  // Tạo avatar URL từ post.author
  String _getAvatarUrl() {
    // Nếu có avatarUrl từ server, dùng nó
    if (widget.post.author.avatarUrl != null &&
        widget.post.author.avatarUrl!.isNotEmpty) {
      return widget.post.author.avatarUrl!;
    }

    // Nếu không có, tạo placeholder đẹp với chữ cái đầu
    final firstLetter = widget.post.author.username.isNotEmpty
        ? widget.post.author.username[0].toUpperCase()
        : '?';

    // Tạo URL placeholder với màu từ theme
    return 'https://ui-avatars.com/api/?name=$firstLetter&background=${AppColors.primary.value.toRadixString(16).substring(2)}&color=fff&size=80&bold=true';
  }

  // Helper: Lấy icon dựa vào privacy
  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.people;
      case 'private':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  Widget _buildPostHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          GestureDetector(
            // Nhấn vào avatar → Xem ảnh full screen
            onTap: () => _openImageViewer(
              context,
              [_getAvatarUrl()],
              0,
              widget.post.author.username,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(_getAvatarUrl()),
                onBackgroundImageError: (_, __) {},
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // KHÓA VÒNG LẶP: Kiểm tra nếu đang ở profile của chính user này thì không điều hướng
                // TH1: Đang ở ProfileScreen của user này (currentUsername khớp)
                if (widget.currentUsername != null &&
                    widget.post.author.username == widget.currentUsername) {
                  return; // Đang xem profile của user A, click vào post của user A → Không làm gì
                }

                // TH2: Click vào chính mình từ bất kỳ đâu
                if (widget.username != null &&
                    widget.post.author.username == widget.username) {
                  // Nếu đang ở ProfileScreen (có currentUsername) thì không làm gì
                  if (widget.currentUsername != null) {
                    return;
                  }
                  // Nếu không ở ProfileScreen (ở Home chẳng hạn), cho phép navigate đến profile của mình
                }

                Navigator.pushNamed(context, '/profile',
                    arguments: {'username': widget.post.author.username});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.author.displayName,
                      style: AppTextStyles.postName.copyWith(fontSize: 14)),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(formatPostTime(widget.post.createdAt),
                          style: AppTextStyles.postMeta.copyWith(fontSize: 11)),
                      const SizedBox(width: 3),
                      Icon(
                        _getPrivacyIcon(widget.post.privacy),
                        size: 11,
                        color: AppColors.primary.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.more_horiz,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            elevation: 8,
            offset: const Offset(0, 8),
            color: AppColors.white,
            onSelected: (value) {
              if (value == 'edit')
                _editPost();
              else if (value == 'delete')
                _deletePost();
              else if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (context) {
              final isMyPost = widget.username != null &&
                  widget.post.author.username == widget.username;
              return [
                if (isMyPost) ...[
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Chỉnh sửa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.subtitle.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: AppColors.subtitle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Báo cáo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
    );
  }

  // Mở ImageViewerScreen để xem ảnh full screen
  void _openImageViewer(
      BuildContext context, List<String> urls, int index, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrls: urls,
          initialIndex: index,
          title: title,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 8.0, 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  count: _likesCount,
                  color: _isLiked ? AppColors.primary : AppColors.subtitle,
                  onTap: _handleLikePost,
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                _ActionButton(
                  icon: _isDisliked
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  count: _dislikesCount,
                  color: _isDisliked ? AppColors.danger : AppColors.subtitle,
                  onTap: _handleDislikePost,
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                _ActionButton(
                  icon: Icons.comment_outlined,
                  count: widget.post.commentsCount,
                  color: AppColors.subtitle,
                  onTap: widget.isDetailView ? null : _navigateToDetail,
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  count: null,
                  color: AppColors.subtitle,
                  onTap: _handleSharePost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery(BuildContext context, List<String> mediaUrls) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    // Helper để build cached image với giới hạn chiều cao và hỗ trợ click
    Widget buildCachedImage(String url, {double? height, int? index}) {
      return GestureDetector(
        onTap: () {
          // Click vào ảnh → Mở ImageViewerScreen
          _openImageViewer(
            context,
            mediaUrls,
            index ?? mediaUrls.indexOf(url),
            widget.post.author.username,
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 400, // Giới hạn chiều cao tối đa
          ),
          child: CachedNetworkImage(
            imageUrl: url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: height ?? 200,
              color: AppColors.imagePlaceholder,
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: height ?? 200,
              color: AppColors.imagePlaceholder,
              child: const Icon(Icons.broken_image,
                  size: 40, color: AppColors.subtitle),
            ),
          ),
        ),
      );
    }

    // 1 ảnh: Full width
    if (mediaUrls.length == 1) {
      return buildCachedImage(mediaUrls[0], index: 0);
    }

    // 2 ảnh: 2 cột
    if (mediaUrls.length == 2) {
      return Row(
        children: mediaUrls
            .asMap()
            .entries
            .map((entry) => Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: buildCachedImage(entry.value,
                        height: 200, index: entry.key),
                  ),
                ))
            .toList(),
      );
    }

    // 3 ảnh: 1 lớn + 2 nhỏ
    if (mediaUrls.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1,
              child: buildCachedImage(mediaUrls[0], height: 300, index: 0),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: buildCachedImage(mediaUrls[1], height: 150, index: 1),
                ),
                const SizedBox(height: 2),
                AspectRatio(
                  aspectRatio: 1,
                  child: buildCachedImage(mediaUrls[2], height: 150, index: 2),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 4+ ảnh: Grid 2x2
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: mediaUrls.length > 4 ? 4 : mediaUrls.length,
      itemBuilder: (context, index) {
        final isLast = index == 3 && mediaUrls.length > 4;
        return Stack(
          fit: StackFit.expand,
          children: [
            buildCachedImage(mediaUrls[index], index: index),
            if (isLast)
              GestureDetector(
                onTap: () => _openImageViewer(
                  context,
                  mediaUrls,
                  index,
                  widget.post.author.username,
                ),
                child: Container(
                  color: AppColors.imageOverlay,
                  child: Center(
                    child: Text(
                      '+${mediaUrls.length - 4}',
                      style: AppTextStyles.imageOverlayText,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Widget helper cho action buttons - Hiện icon + số
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count; // Số lượng (like/comment), null nếu không hiện
  final Color color;
  final VoidCallback? onTap; // Nullable để có thể disable

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.color,
    this.onTap, // Có thể null
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
