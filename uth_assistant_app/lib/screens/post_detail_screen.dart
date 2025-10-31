import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/home_post_card.dart';
import '../widgets/comment_item.dart'; // Import CommentInput và CommentItem
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart'; // Import ProfileService
import 'package:flutter/foundation.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  late Post _currentPost;
  late String _avatarPlaceholder;
  String? _username;
  String? _currentUserAvatar; // Avatar thật từ API

  late Future<List<Comment>> _commentsFuture;
  List<Comment> _comments = [];
  Map<String, List<Comment>> _repliesMap = {}; // Map commentId -> replies
  Map<String, bool> _loadingRepliesMap = {}; // Track loading state
  bool _isPostingComment = false;
  Comment? _replyingToComment;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _commentsFuture = _loadComments();
    _loadUsername();
    _loadUserProfile(); // Load avatar thật
    _avatarPlaceholder =
        'https://placehold.co/80x80/${AppColors.secondary.value.toRadixString(16).substring(2)}/${AppColors.avatarPlaceholderText.value.toRadixString(16).substring(2)}?text=${_currentPost.author.username.isNotEmpty ? _currentPost.author.username[0].toUpperCase() : '?'}';
  }

  Future<void> _loadUsername() async {
    final username = await _authService.getUsername();
    if (mounted) setState(() => _username = username);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getMyProfile();
      if (mounted) {
        setState(() {
          _currentUserAvatar = profile['avatarUrl'];
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user profile: $e');
    }
  }

  // Tải bình luận từ API
  Future<List<Comment>> _loadComments() async {
    try {
      final comments =
          await _commentService.getCommentsForPost(postId: _currentPost.id);
      if (mounted) setState(() => _comments = comments);
      return comments;
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
      return [];
    }
  }

  // Tải lại bình luận (cho RefreshIndicator)
  Future<void> _refreshComments() async {
    setState(() {
      _commentsFuture = _loadComments();
      _repliesMap.clear(); // Clear replies khi refresh
    });
    await _commentsFuture;
  }

  // Load replies cho một comment
  Future<void> _loadReplies(String commentId) async {
    if (_loadingRepliesMap[commentId] == true) return;

    setState(() => _loadingRepliesMap[commentId] = true);

    try {
      final replies = await _commentService.getRepliesForComment(
        parentId: commentId,
      );
      if (mounted) {
        setState(() {
          _repliesMap[commentId] = replies;
          _loadingRepliesMap[commentId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRepliesMap[commentId] = false);
        _showErrorSnackBar(e.toString());
      }
    }
  }

  // Toggle hiển thị replies
  void _toggleReplies(String commentId) {
    if (_repliesMap.containsKey(commentId)) {
      // Đã load rồi, ẩn đi
      setState(() => _repliesMap.remove(commentId));
    } else {
      // Chưa load, load ngay
      _loadReplies(commentId);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _startReply(Comment comment) {
    setState(() => _replyingToComment = comment);
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  void _cancelReply() {
    setState(() => _replyingToComment = null);
    _commentFocusNode.unfocus();
  }

  // Gửi bình luận hoặc trả lời
  Future<void> _sendComment(String text) async {
    if (text.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);

    try {
      final parentId = _replyingToComment?.id;

      await _commentService.createComment(
        text: text,
        postId: _currentPost.id,
        parentId: parentId,
      );

      // Nếu là reply, reload replies của comment cha
      if (parentId != null) {
        // Clear replies để force reload
        setState(() => _repliesMap.remove(parentId));
        // Load lại replies
        await _loadReplies(parentId);
      } else {
        // Nếu là comment gốc, refresh toàn bộ
        _refreshComments();
      }

      _cancelReply();
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_currentPost.author.username}\'s Post',
            style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.text),
        elevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshComments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Tái sử dụng HomePostCard
                    HomePostCard(
                      key: ValueKey(_currentPost.id),
                      post: _currentPost,
                      avatarPlaceholder: _avatarPlaceholder,
                      username: _username,
                      isDetailView: true,
                      onPostDeleted: () {
                        Navigator.pop(context, true);
                      },
                      onPostUpdated: () {
                        _showErrorSnackBar('Cập nhật thành công (cần reload)');
                      },
                    ),
                    const Divider(color: AppColors.dividerLight, thickness: 6),
                    _buildCommentSection(),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  // Sử dụng FutureBuilder để tải bình luận
  Widget _buildCommentSection() {
    return FutureBuilder<List<Comment>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                snapshot.error.toString(),
                style: AppTextStyles.errorText,
              ),
            ),
          );
        }

        if (_comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 48,
                    color: AppColors.subtitle.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Chưa có bình luận nào.",
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hãy là người đầu tiên bình luận!",
                    style: AppTextStyles.postMeta,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  'Bình luận (${_comments.length})',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final isOwner =
                      _username != null && comment.author.username == _username;
                  final hasReplies = comment.repliesCount > 0;
                  final isShowingReplies = _repliesMap.containsKey(comment.id);
                  final replies = _repliesMap[comment.id] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comment chính
                      CommentItem(
                        comment: comment,
                        onLike: () {
                          // TODO: Implement like comment
                          _showErrorSnackBar('Tính năng đang phát triển');
                        },
                        onReply: () => _startReply(comment),
                        onEdit: isOwner
                            ? () {
                                // TODO: Implement edit comment
                                _showErrorSnackBar('Tính năng đang phát triển');
                              }
                            : null,
                        onDelete: isOwner
                            ? () => _confirmDeleteComment(comment)
                            : null,
                      ),

                      // Nút "Xem câu trả lời" nếu có replies
                      if (hasReplies)
                        Padding(
                          padding: const EdgeInsets.only(left: 58.0, bottom: 8),
                          child: InkWell(
                            onTap: () => _toggleReplies(comment.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_loadingRepliesMap[comment.id] == true)
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  else
                                    Icon(
                                      isShowingReplies
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isShowingReplies
                                        ? 'Ẩn câu trả lời'
                                        : '${comment.repliesCount} câu trả lời',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Hiển thị replies nếu đã load
                      if (isShowingReplies && replies.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 48.0),
                          child: Column(
                            children: replies.map((reply) {
                              final isReplyOwner = _username != null &&
                                  reply.author.username == _username;
                              return CommentItem(
                                comment: reply,
                                onLike: () {
                                  _showErrorSnackBar(
                                      'Tính năng đang phát triển');
                                },
                                onReply: () => _startReply(comment),
                                onEdit: isReplyOwner
                                    ? () {
                                        _showErrorSnackBar(
                                            'Tính năng đang phát triển');
                                      }
                                    : null,
                                onDelete: isReplyOwner
                                    ? () => _confirmDeleteComment(reply)
                                    : null,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Xác nhận xóa comment
  void _confirmDeleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement delete comment API
              _showErrorSnackBar('Tính năng xóa bình luận đang phát triển');
              // try {
              //   await _commentService.deleteComment(commentId: comment.id);
              //   _refreshComments();
              //   if (mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //         content: Text('✓ Đã xóa bình luận'),
              //         backgroundColor: AppColors.success,
              //       ),
              //     );
              //   }
              // } catch (e) {
              //   if (mounted) _showErrorSnackBar(e.toString());
              // }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return CommentInput(
      avatarUrl: _currentUserAvatar,
      onSubmit: _sendComment,
      hintText: 'Viết bình luận...',
      replyingTo: _replyingToComment?.author.username,
    );
  }
}
