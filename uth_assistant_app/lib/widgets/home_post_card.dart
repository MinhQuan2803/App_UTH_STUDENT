import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../utils/time_formatter.dart';
import '../screens/add_post_screen.dart';
import 'custom_notification.dart';
import 'package:flutter/foundation.dart'; // Cho kDebugMode

/// Widget này hiển thị một bài viết đầy đủ theo phong cách Facebook
/// và tự quản lý các tương tác của nó (like, delete, update).
class HomePostCard extends StatefulWidget {
  final Post post;
  final String? username; // Username của người dùng đang đăng nhập
  final VoidCallback onPostDeleted; // Callback khi xóa thành công
  final VoidCallback onPostUpdated; // Callback khi sửa thành công
  final bool isDetailView; // True nếu đang hiển thị trong màn hình chi tiết

  const HomePostCard({
    super.key,
    required this.post,
    this.username,
    required this.onPostDeleted,
    required this.onPostUpdated,
    this.isDetailView = false, // Mặc định là false
  });

  @override
  State<HomePostCard> createState() => _HomePostCardState();
}

class _HomePostCardState extends State<HomePostCard> {
  late bool _isLiked;
  late int _likesCount;
  bool _isLiking = false;
  final PostService _postService = PostService();

  // GlobalKey để lấy context stable ngay cả khi widget bị dispose
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.myReactionType == 'like';
    _likesCount = widget.post.likesCount;
  }

  // Xử lý khi nhấn nút Thích
  Future<void> _handleLikePost() async {
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
      await _postService.likePost(widget.post.id, type: 'like');
    } catch (e) {
      if (kDebugMode) print("Lỗi khi like: $e");
      // Rollback
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

              // Lấy context từ GlobalKey - context này sẽ KHÔNG bị deactivate
              final keyContext = _key.currentContext;
              if (keyContext == null || !keyContext.mounted) return;

              // Hiển thị thông báo đang xóa
              CustomNotification.info(keyContext, 'Đang xóa bài viết...');

              try {
                await _postService.deletePost(widget.post.id);

                // Hiển thị thông báo thành công (dùng key context)
                if (_key.currentContext != null &&
                    _key.currentContext!.mounted) {
                  CustomNotification.success(
                      _key.currentContext!, 'Đã xóa bài viết');
                }

                // Đợi notification render
                await Future.delayed(const Duration(milliseconds: 200));

                // Sau đó mới xóa widget
                if (mounted) {
                  widget.onPostDeleted();
                }
              } catch (e) {
                // Show error nếu context vẫn còn
                if (_key.currentContext != null &&
                    _key.currentContext!.mounted) {
                  CustomNotification.error(
                    _key.currentContext!,
                    e.toString().replaceFirst('Exception: ', ''),
                  );
                }
              }
            },
            child: const Text('Xóa', style: AppTextStyles.deleteDialogText),
          ),
        ],
      ),
    );
  } // Xử lý khi nhấn nút Sửa

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

    Navigator.pushNamed(context, '/post_detail',
        // SỬA LỖI: Không cần truyền backgroundColor cho style Facebook
        arguments: {'post': widget.post});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key, // Gắn GlobalKey vào widget root
      onTap: widget.isDetailView
          ? null
          : _navigateToDetail, // Tắt tap khi ở detail view
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(
              left: BorderSide(color: AppColors.primary, width: 3)),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(context),
            if (widget.post.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(widget.post.text,
                    style: AppTextStyles.postContent.copyWith(fontSize: 15)),
              ),
            if (widget.post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMediaGallery(context, widget.post.mediaUrls),
            ],
            if (_likesCount > 0 || widget.post.commentsCount > 0)
              _buildPostStats(_likesCount, widget.post.commentsCount),
            Divider(
                height: 1,
                thickness: 1,
                color: AppColors.primary.withOpacity(0.1)),
            _buildActionButtons(context),
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

  // Helper: Lấy label hiển thị (optional)
  String _getPrivacyLabel(String privacy) {
    switch (privacy) {
      case 'public':
        return 'Công khai';
      case 'friends':
        return 'Bạn bè';
      case 'private':
        return 'Riêng tư';
      default:
        return 'Công khai';
    }
  }

  Widget _buildPostHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          GestureDetector(
            // Nhấn vào avatar → Đi đến profile
            onTap: () => Navigator.pushNamed(context, '/profile',
                arguments: {'username': widget.post.author.username}),
            // Long press avatar → Xem ảnh đại diện phóng to
            onLongPress: () => _showAvatarFullScreen(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(_getAvatarUrl()),
                onBackgroundImageError: (_, __) {},
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile',
                  arguments: {'username': widget.post.author.username}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.author.username,
                      style: AppTextStyles.postName.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(formatPostTime(widget.post.createdAt),
                          style: AppTextStyles.postMeta.copyWith(fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(
                        _getPrivacyIcon(widget.post.privacy),
                        size: 12,
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
                CustomNotification.info(context, 'Tính năng đang phát triển');
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

  // Hiển thị ảnh đại diện full screen khi long press avatar
  void _showAvatarFullScreen(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Ảnh có thể zoom và pan
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  _getAvatarUrl(),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 300,
                      color: AppColors.imagePlaceholder,
                      child: const Icon(Icons.broken_image,
                          size: 80, color: AppColors.subtitle),
                    );
                  },
                ),
              ),
            ),
            // Nút đóng
            Positioned(
              top: 40,
              right: 20,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon:
                      const Icon(Icons.close, color: AppColors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Tên người dùng ở dưới
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.post.author.username,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile', arguments: {
                          'username': widget.post.author.username
                        });
                      },
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text('Xem trang cá nhân'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStats(int likesCount, int commentsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          if (likesCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent]),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.favorite, size: 12, color: AppColors.white),
            ),
            const SizedBox(width: 6),
            Text('$likesCount',
                style: AppTextStyles.interaction.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
          const Spacer(),
          if (commentsCount > 0)
            Text('$commentsCount bình luận',
                style: AppTextStyles.interaction
                    .copyWith(color: AppColors.subtitle)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Thích',
            color: _isLiked ? AppColors.accent : AppColors.subtitle,
            onTap: _handleLikePost,
          ),
          _ActionButton(
            icon: Icons.comment_outlined,
            label: 'Bình luận',
            color: AppColors.subtitle,
            onTap: widget.isDetailView
                ? null
                : _navigateToDetail, // Tắt nếu đang ở detail view
          ),
          _ActionButton(
            icon: Icons.share_outlined,
            label: 'Chia sẻ',
            color: AppColors.subtitle,
            onTap: _handleSharePost,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery(BuildContext context, List<String> mediaUrls) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    // 1 ảnh: Full width
    if (mediaUrls.length == 1) {
      return GestureDetector(
        onTap: widget.isDetailView
            ? null
            : _navigateToDetail, // Tắt navigation nếu ở detail view
        child: Image.network(
          mediaUrls[0],
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: AppColors.imagePlaceholder,
              child: const Icon(Icons.broken_image,
                  size: 50, color: AppColors.subtitle),
            );
          },
        ),
      );
    }
    // 2 ảnh: 2 cột
    if (mediaUrls.length == 2) {
      return GestureDetector(
        onTap: widget.isDetailView ? null : _navigateToDetail,
        child: Row(
          children: mediaUrls
              .map((url) => Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        url,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                              height: 200,
                              color: AppColors.imagePlaceholder,
                              child: const Icon(Icons.broken_image,
                                  size: 40, color: AppColors.subtitle));
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      );
    }
    // 3 ảnh: 1 lớn + 2 nhỏ
    if (mediaUrls.length == 3) {
      return GestureDetector(
        onTap: widget.isDetailView ? null : _navigateToDetail,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  mediaUrls[0],
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                        height: 300,
                        color: AppColors.imagePlaceholder,
                        child: const Icon(Icons.broken_image,
                            color: AppColors.subtitle));
                  },
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      mediaUrls[1],
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                            height: 150,
                            color: AppColors.imagePlaceholder,
                            child: const Icon(Icons.broken_image,
                                color: AppColors.subtitle));
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      mediaUrls[2],
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                            height: 150,
                            color: AppColors.imagePlaceholder,
                            child: const Icon(Icons.broken_image,
                                color: AppColors.subtitle));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 4+ ảnh: Grid 2x2
    return GestureDetector(
      onTap: widget.isDetailView ? null : _navigateToDetail,
      child: GridView.builder(
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
              Image.network(
                mediaUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                      color: AppColors.imagePlaceholder,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.subtitle));
                },
              ),
              if (isLast)
                Container(
                  color: AppColors.imageOverlay,
                  child: Center(
                    child: Text(
                      '+${mediaUrls.length - 4}',
                      style: AppTextStyles.imageOverlayText,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Widget helper cho action buttons
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap; // Nullable để có thể disable

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap, // Có thể null
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap, // Nếu null thì button sẽ disabled
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1.0, // Làm mờ nếu disabled
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.actionButton.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
