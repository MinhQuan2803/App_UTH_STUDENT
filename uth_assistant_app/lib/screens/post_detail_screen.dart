import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/post_card.dart'; // Tái sử dụng PostCard

// CHUYỂN THÀNH StatefulWidget để quản lý trạng thái trả lời
class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostDetailScreen({super.key, required this.postData});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyingToUser; // Lưu tên người đang được trả lời

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // Hàm để bắt đầu trả lời bình luận
  void _startReply(String username) {
    setState(() {
      _replyingToUser = username;
    });
    // Tự động focus vào ô nhập liệu khi nhấn trả lời
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  // Hàm để hủy trả lời
  void _cancelReply() {
    setState(() {
      _replyingToUser = null;
    });
    // Bỏ focus khỏi ô nhập liệu
     _commentFocusNode.unfocus();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bài viết', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.text),
        elevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // THÊM Padding ở dưới để nâng nội dung lên
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: PostCard(
                      avatarUrl: widget.postData['avatarUrl'] ?? '',
                      name: widget.postData['name'] ?? 'N/A',
                      time: widget.postData['time'] ?? '',
                      major: widget.postData['major'] ?? '',
                      content: widget.postData['content'] ?? '',
                      likes: widget.postData['likes'] ?? 0,
                      comments: widget.postData['comments'] ?? 0,
                      isLiked: widget.postData['isLiked'] ?? false,
                      backgroundColor: widget.postData['backgroundColor'],
                    ),
                  ),
                  const Divider(color: AppColors.dividerLight, thickness: 6),
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    final List<Map<String, String>> comments = [
      {'user': 'Trần An', 'comment': 'Bài viết rất hữu ích, cảm ơn bạn!'},
      {'user': 'Ngọc Mai', 'comment': 'Mình cũng đang tìm tài liệu này.'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bình luận', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14), // Tăng khoảng cách
            itemBuilder: (context, index) {
              final commentUser = comments[index]['user']!;
              final commentText = comments[index]['comment']!;
              return Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage('https://placehold.co/32x32/E0E7FF/4338CA?text=${commentUser[0]}'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(commentUser, style: AppTextStyles.postName.copyWith(fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(commentText, style: AppTextStyles.postContent.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // THÊM Nút trả lời
                  Padding(
                    padding: const EdgeInsets.only(left: 42.0, top: 4.0), // Căn lề với nội dung bình luận
                    child: GestureDetector(
                       onTap: () => _startReply(commentUser),
                       child: Text(
                         'Trả lời',
                         style: AppTextStyles.postMeta.copyWith(fontWeight: FontWeight.w600, color: AppColors.subtitle),
                       ),
                    ),
                  )
                 ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column( // Bọc trong Column để thêm dòng "Replying to"
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị thông báo đang trả lời ai (nếu có)
          if (_replyingToUser != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 6.0),
               child: Row(
                 children: [
                   Expanded(
                     child: Text(
                       'Đang trả lời @$_replyingToUser',
                       style: AppTextStyles.postMeta.copyWith(color: AppColors.subtitle),
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   GestureDetector(
                     onTap: _cancelReply,
                     child: const Icon(Icons.close, size: 16, color: AppColors.subtitle),
                   )
                 ],
               ),
             ),
          // Hàng nhập liệu chính
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode, // Gán FocusNode
                  decoration: InputDecoration(
                    hintText: _replyingToUser == null ? 'Thêm bình luận...' : 'Viết câu trả lời...',
                    hintStyle: AppTextStyles.hintText.copyWith(fontSize: 14),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                  onSubmitted: (_) => _sendComment(), // Gửi khi nhấn Enter
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: _sendComment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendComment() {
     // TODO: Logic gửi bình luận (kiểm tra có đang reply không)
     print('Sending comment: ${_commentController.text}');
     if (_replyingToUser != null) {
       print('Replying to: $_replyingToUser');
     }
     _commentController.clear();
     _cancelReply(); // Xóa trạng thái reply sau khi gửi
     FocusScope.of(context).unfocus(); // Ẩn bàn phím
  }
}

