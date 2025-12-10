import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart';
import '../widgets/skeleton_screens.dart';
import 'package:flutter/foundation.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _error = '';  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: 'Thông báo',
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Đánh dấu đã đọc',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.background
              : AppColors.primary.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar hoặc icon
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 12),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodyRegular.copyWith(
                      fontSize: 13,
                      color: AppColors.subtitle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAtLocal),
                    style: AppTextStyles.postMeta.copyWith(
                      fontSize: 11,
                      color: AppColors.subtitle.withOpacity(0.7),
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

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'like':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        iconData = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'follow':
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      case 'mention':
        iconData = Icons.alternate_email;
        iconColor = Colors.orange;
        break;
      case 'system':
      default:
        iconData = Icons.notifications_active;
        iconColor = AppColors.primary;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.danger.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.subtitle,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.subtitle.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.subtitle,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return _dateFormatter.format(dateTime);
    }
  }

  void _onNotificationTap(NotificationModel notification) async {
    // Đánh dấu đã đọc
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
      await _notificationService.markAsRead(notification.id);
    }

    // Navigate dựa vào type và data
    if (notification.data == null || !mounted) return;

    final type = notification.type;
    final data = notification.data!;

    try {
      if (type == 'like' || type == 'comment' || type == 'mention') {
        final postId = data['postId']?.toString();
        if (postId == null || postId.isEmpty) {
          if (kDebugMode) print('⚠ Missing postId in notification data');
          return;
        }

        // Hiển thị loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Fetch post từ backend
        final post = await _postService.getPostById(postId);

        // Đóng loading
        if (mounted) Navigator.pop(context);

        // Navigate đến post detail
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/post_detail',
            arguments: {'post': post},
          );
        }
      } else if (type == 'follow') {
        final username = data['username']?.toString();
        if (username == null || username.isEmpty) {
          if (kDebugMode) print('⚠ Missing username in notification data');
          return;
        }

        // Navigate đến profile
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'username': username},
          );
        }
      } else if (type == 'system') {
        // System notification - không navigate
        if (kDebugMode) print('ℹ System notification, no navigation');
      }
    } catch (e) {
      // Đóng loading nếu có lỗi
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (kDebugMode) print('❌ Navigation error: $e');

      // Hiển thị error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải nội dung: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification.isRead = true;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }
}
