import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/comment_model.dart'; // Sử dụng Comment model đúng
import '../utils/time_formatter.dart';

/// Widget hiển thị một comment với style giống Facebook
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  const CommentItem({
    super.key,
    required this.comment,
    this.onDelete,
    this.onEdit,
    this.onLike,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final avatarPlaceholder =
        'https://placehold.co/80x80/${AppColors.secondary.value.toRadixString(16).substring(2)}/${AppColors.avatarPlaceholderText.value.toRadixString(16).substring(2)}?text=${comment.author.username.isNotEmpty ? comment.author.username[0].toUpperCase() : '?'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar - có thể tap để xem profile
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: {'username': comment.author.username},
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                    NetworkImage(comment.author.avatarUrl ?? avatarPlaceholder),
                onBackgroundImageError: (_, __) {},
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content với background (giống Facebook)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment bubble với background
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username (có thể tap)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: {'username': comment.author.username},
                          );
                        },
                        child: Text(
                          comment.author.username,
                          style: AppTextStyles.postName.copyWith(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Comment content
                      Text(
                        comment.text,
                        style: AppTextStyles.postContent.copyWith(
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Actions bar bên dưới bubble
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Row(
                    children: [
                      // Time
                      Text(
                        formatPostTime(comment.createdAt),
                        style: AppTextStyles.postMeta.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 16),

                      // Like button
                      InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            comment.myReactionType == 'like'
                                ? 'Đã thích'
                                : 'Thích',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: comment.myReactionType == 'like'
                                  ? AppColors.primary
                                  : AppColors.subtitle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Reply button
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Trả lời',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ),
                      ),

                      // Like count nếu có
                      if (comment.likesCount > 0) ...[
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: AppColors.primary.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likesCount}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Spacer(),

                      // Menu button cho owner
                      if (onEdit != null || onDelete != null)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: AppColors.subtitle,
                          ),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.text),
                                    SizedBox(width: 12),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.danger),
                                    SizedBox(width: 12),
                                    Text('Xóa',
                                        style:
                                            TextStyle(color: AppColors.danger)),
                                  ],
                                ),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit?.call();
                            } else if (value == 'delete') {
                              onDelete?.call();
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget để nhập comment mới với UX được cải thiện
class CommentInput extends StatefulWidget {
  final String? avatarUrl;
  final Function(String) onSubmit;
  final String hintText;
  final String? replyingTo; // Username đang reply

  const CommentInput({
    super.key,
    this.avatarUrl,
    required this.onSubmit,
    this.hintText = 'Viết bình luận...',
    this.replyingTo,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _hasText = false;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_controller.text.trim().isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_controller.text.trim());
      _controller.clear();
      _focusNode.unfocus(); // Ẩn bàn phím sau khi gửi
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarPlaceholder =
        'https://placehold.co/80x80/${AppColors.secondary.value.toRadixString(16).substring(2)}/${AppColors.avatarPlaceholderText.value.toRadixString(16).substring(2)}?text=U';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator nếu đang reply
            if (widget.replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.divider.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang trả lời ${widget.replyingTo}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Input area
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        widget.avatarUrl ?? avatarPlaceholder,
                      ),
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Input field với animation
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 120, // Giới hạn chiều cao tối đa
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppColors.primary.withOpacity(0.4)
                              : AppColors.divider.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.subtitle.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.text,
                          height: 1.4,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSubmit(),
                        enabled: !_isSubmitting,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button với animation
                  _isSubmitting
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : ScaleTransition(
                          scale: _sendButtonAnimation,
                          child: Material(
                            color: _hasText
                                ? AppColors.primary
                                : AppColors.background,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _hasText ? _handleSubmit : null,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.send_rounded,
                                  color: _hasText
                                      ? AppColors.white
                                      : AppColors.subtitle.withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
