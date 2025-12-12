import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.background
              : AppColors.primary.withOpacity(0.08), // Đậm hơn xíu cho dễ nhìn
          border: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar hoặc Icon
            _buildLeading(context),
            const SizedBox(width: 14),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: notification.message,
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.text,
                            height: 1.4,
                            // Nếu chưa đọc thì chữ đậm hơn chút
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.createdAtLocal),
                    style: AppTextStyles.postMeta.copyWith(
                      fontSize: 12,
                      color: notification.isRead
                          ? AppColors.subtitle.withOpacity(0.7)
                          : AppColors.primary, // Time xanh nếu chưa đọc
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Dấu chấm xanh nếu chưa đọc (Optional, vì đã đổi màu nền)
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    // Ưu tiên hiển thị Avatar của người tương tác gần nhất
    if (notification.relatedUsers.isNotEmpty) {
      final user = notification.relatedUsers.last; // Người mới nhất

      return Stack(
        children: [
          // Avatar - Hiển thị ảnh thật hoặc placeholder
          _buildUserAvatar(user),

          // Badge icon nhỏ ở góc (Like/Comment/...)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: _getIconForType(notification.type, size: 12),
            ),
          ),
        ],
      );
    }

    // Nếu là thông báo hệ thống hoặc không có người dùng liên quan
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getColorForType(notification.type).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(child: _getIconForType(notification.type, size: 24)),
    );
  }

  Widget _buildUserAvatar(dynamic user) {
    final String username = user.username ?? '';
    final String? avatarUrl = user.avatarURL;

    if (kDebugMode) {
      print('👤 Building avatar for user: $username');
      print('   Avatar URL: $avatarUrl');
    }

    // Nếu có avatar URL và không rỗng
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) print('   ⚠ Avatar load error: $error');
              // Nếu load ảnh lỗi → hiển thị chữ cái đầu
              return _buildAvatarPlaceholder(username);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                if (kDebugMode) print('   ✓ Avatar loaded successfully');
                return child;
              }
              // Hiển thị loading placeholder
              return _buildAvatarPlaceholder(username);
            },
          ),
        ),
      );
    }

    if (kDebugMode) print('   → Using placeholder (no avatar URL)');

    // Nếu không có avatar → hiển thị chữ cái đầu
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: _buildAvatarPlaceholder(username),
    );
  }

  Widget _buildAvatarPlaceholder(String username) {
    return Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColors.subtitle,
        ),
      ),
    );
  }

  Icon _getIconForType(String type, {required double size}) {
    switch (type) {
      case 'like':
        return Icon(Icons.favorite, color: Colors.red, size: size);
      case 'comment':
        return Icon(Icons.comment, color: Colors.blue, size: size);
      case 'follow':
        return Icon(Icons.person_add, color: Colors.green, size: size);
      case 'mention':
        return Icon(Icons.alternate_email, color: Colors.orange, size: size);
      case 'payment':
        return Icon(Icons.monetization_on, color: Colors.amber, size: size);
      default:
        return Icon(Icons.notifications, color: AppColors.primary, size: size);
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'payment':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    // (Logic format time giữ nguyên như code cũ của bạn)
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
