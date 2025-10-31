import 'package:flutter/material.dart';

/// Màn hình hiển thị comments của bài viết
/// UI hoàn chỉnh với mock data, sẵn sàng kết nối API
class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postAuthor;
  final String postContent;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postAuthor,
    required this.postContent,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isLoading = true;
  List<CommentItem> _comments = [];
  String? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  /// Load comments (mock data)
  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    setState(() {
      _comments = [
        CommentItem(
          id: '1',
          author: 'Nguyễn Văn A',
          username: 'nguyenvana',
          avatarUrl: 'https://i.pravatar.cc/150?u=a',
          text: 'Bài viết rất hay! 👍',
          likesCount: 12,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        CommentItem(
          id: '2',
          author: 'Trần Thị B',
          username: 'tranthib',
          avatarUrl: 'https://i.pravatar.cc/150?u=b',
          text: 'Cảm ơn bạn đã chia sẻ 😊',
          likesCount: 5,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        CommentItem(
          id: '3',
          author: 'Lê Minh C',
          username: 'leminhc',
          avatarUrl: 'https://i.pravatar.cc/150?u=c',
          text: 'Mình cũng nghĩ vậy! Nội dung rất bổ ích.',
          likesCount: 8,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ];
      _isLoading = false;
    });
  }

  /// Gửi comment mới
  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Mock: Thêm comment vào danh sách
    final newComment = CommentItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'Bạn',
      username: 'current_user',
      avatarUrl: 'https://i.pravatar.cc/150?u=you',
      text: text,
      likesCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.insert(0, newComment);
      _commentController.clear();
      _replyingTo = null;
    });

    // TODO: Call API khi có
    // await _interactionService.addComment(widget.postId, text);
  }

  /// Toggle like comment
  void _toggleLikeComment(int index) {
    setState(() {
      final comment = _comments[index];
      _comments[index] = CommentItem(
        id: comment.id,
        author: comment.author,
        username: comment.username,
        avatarUrl: comment.avatarUrl,
        text: comment.text,
        likesCount:
            comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
        isLiked: !comment.isLiked,
        createdAt: comment.createdAt,
      );
    });

    // TODO: Call API khi có
    // await _interactionService.toggleCommentLike(comment.id);
  }

  /// Xóa comment
  void _deleteComment(int index) {
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
          TextButton(
            onPressed: () {
              setState(() => _comments.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa bình luận')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Format thời gian
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';

    // Format dd/MM/yyyy manually
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bình luận'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Post info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.postAuthor,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.postContent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.comment_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có bình luận nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy là người đầu tiên bình luận!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadComments,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _comments.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentItem(comment, index);
                          },
                        ),
                      ),
          ),

          // Input box
          _buildCommentInput(),
        ],
      ),
    );
  }

  /// Build comment item
  Widget _buildCommentItem(CommentItem comment, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(comment.avatarUrl),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author & time
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Comment text
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: () => _toggleLikeComment(index),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: comment.isLiked ? Colors.red : Colors.grey,
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likesCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Reply button
                    InkWell(
                      onTap: () {
                        setState(() => _replyingTo = comment.author);
                        _commentFocus.requestFocus();
                      },
                      child: Text(
                        'Trả lời',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // More options
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz,
                          size: 18, color: Colors.grey[600]),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteComment(index);
                        } else if (value == 'edit') {
                          // TODO: Edit comment
                        } else if (value == 'report') {
                          // TODO: Report comment
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('Báo cáo'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build comment input
  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Đang trả lời $_replyingTo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _replyingTo = null),
                    child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Input row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=you',
                ),
              ),
              const SizedBox(width: 12),

              // Text field
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  decoration: InputDecoration(
                    hintText: 'Viết bình luận...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              IconButton(
                onPressed: _postComment,
                icon: const Icon(Icons.send, color: Colors.blue),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Model cho Comment Item
class CommentItem {
  final String id;
  final String author;
  final String username;
  final String avatarUrl;
  final String text;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;

  CommentItem({
    required this.id,
    required this.author,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.likesCount,
    required this.isLiked,
    required this.createdAt,
  });
}
