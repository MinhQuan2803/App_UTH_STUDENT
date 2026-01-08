import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart'; // Import PostService để fetch post
import '../widgets/notification_item.dart';
import 'transaction_history_screen.dart'; // Import màn hình lịch sử giao dịch

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 15;

  // Filter state
  String _selectedFilter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications(refresh: true);

    // Listener cho Infinite Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _currentPage < _totalPages) {
        _loadMoreNotifications();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  // Detect khi app quay lại foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Reload notifications khi quay lại app
      _loadNotifications(refresh: true);
    }
  }

  // Load danh sách (Lần đầu hoặc Pull to Refresh)
  Future<void> _loadNotifications({bool refresh = false}) async {
    if (kDebugMode) {
      print('🔄 === LOADING NOTIFICATIONS ===');
      print('   Refresh: $refresh');
      print('   Current page: $_currentPage');
      print('   Filter: $_selectedFilter');
    }

    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = '';
        _currentPage = 1;
        _notifications = [];
      });
    }

    try {
      final result = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _limit,
        isRead: _selectedFilter == 'all' ? null : (_selectedFilter == 'read'),
      );

      if (kDebugMode) {
        print('   ✅ Loaded ${result['notifications'].length} notifications');
        print('   Total pages: ${result['totalPages']}');
        if (result['notifications'].isNotEmpty) {
          final firstNotif = result['notifications'][0];
          print('   First notification:');
          print('      - ID: ${firstNotif.id}');
          print('      - isRead: ${firstNotif.isRead}');
          print('      - Message: ${firstNotif.message}');
        }
      }

      if (mounted) {
        setState(() {
          _notifications = result['notifications'];
          _totalPages = result['totalPages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('   ❌ Error loading notifications: $e');

      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // Load trang tiếp theo
  Future<void> _loadMoreNotifications() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _notificationService.getNotifications(
        page: nextPage,
        limit: _limit,
        isRead: _selectedFilter == 'all' ? null : (_selectedFilter == 'read'),
      );

      if (mounted) {
        setState(() {
          _notifications.addAll(result['notifications']);
          _totalPages = result['totalPages'];
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đếm số chưa đọc client-side tạm thời
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
                'Đọc tất cả',
                style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),

          // Notification List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? _buildErrorState()
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _loadNotifications(refresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _notifications.length +
                                  (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _notifications.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                final notification = _notifications[index];
                                return NotificationItem(
                                  notification: notification,
                                  onTap: () => _onNotificationTap(notification),
                                  onLongPress: () =>
                                      _showDeleteDialog(notification),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: AppColors.white,
      child: Row(
        children: [
          _buildFilterTab('Tất cả', 'all'),
          _buildFilterTab('Chưa đọc', 'unread'),
          _buildFilterTab('Đã đọc', 'read'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectedFilter != value) {
            setState(() {
              _selectedFilter = value;
            });
            _loadNotifications(refresh: true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyRegular.copyWith(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.subtitle,
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC NAVIGATION ĐÃ TỐI ƯU ---
  void _onNotificationTap(NotificationModel notification) async {
    if (kDebugMode) {
      print('🔔 === NOTIFICATION TAPPED ===');
      print('   ID: ${notification.id}');
      print('   Type: ${notification.type}');
      print('   isRead: ${notification.isRead}');
      print('   Message: ${notification.message}');
    }

    // 1. UI Update ngay lập tức (Optimistic UI)
    final wasUnread = !notification.isRead;
    if (wasUnread) {
      setState(() {
        notification.isRead = true;
      });

      if (kDebugMode) print('   ✓ UI updated (optimistic)');

      // Gọi API ngầm để đánh dấu đã đọc
      try {
        if (kDebugMode) print('   📤 Calling markAsRead API...');
        await _notificationService.markAsRead(notification.id);
        if (kDebugMode) print('   ✅ markAsRead API success');
      } catch (e) {
        if (kDebugMode) {
          print('   ❌ markAsRead API failed: $e');
          print('   ⚠️ Reverting UI state');
        }
        // Nếu API fail, revert lại UI
        if (mounted) {
          setState(() {
            notification.isRead = false;
          });
        }
      }
    } else {
      if (kDebugMode) print('   ℹ️ Already read, skipping markAsRead');
    }

    final data = notification.data;
    if (data == null) {
      if (kDebugMode) print('   ⚠️ No data, cannot navigate');
      return;
    }

    // 2. Kiểm tra notification type trước
    final String type = notification.type ?? '';

    // 💰 XỬ LÝ THÔNG BÁO BIẾN ĐỘNG SỐ DƯ - Chuyển đến lịch sử giao dịch
    if (type == 'wallet' || type == 'balance') {
      try {
        if (kDebugMode) print('   💰 Navigating to transaction history...');

        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionHistoryScreen(),
          ),
        );

        if (kDebugMode) print('   ✓ Navigated to transaction history screen');
      } catch (e) {
        if (kDebugMode)
          print('   ❌ Navigation error to transaction history: $e');
      }
      return; // Dừng xử lý, không cần check screen
    }

    // 3. Điều hướng dựa trên 'screen' key từ backend (cho các loại khác)
    final String screen = data['screen']?.toString() ?? '';

    try {
      if (screen == 'post_detail') {
        final postId = data['postId']?.toString();
        if (postId == null) return;

        if (kDebugMode) print('   📝 Navigating to post detail...');
        _navigateToPost(postId);
      } else if (screen == 'profile') {
        final username = data['username']?.toString();
        final userId = data['userId']?.toString();

        if (username != null) {
          if (kDebugMode) print('   👤 Navigating to profile: $username');
          Navigator.pushNamed(context, '/profile',
              arguments: {'username': username});
        } else if (userId != null) {
          if (kDebugMode)
            print('   ⚠️ Navigating by ID not fully implemented yet');
        }
      }
    } catch (e) {
      if (kDebugMode) print('   ❌ Navigation error: $e');
    }
  }

  Future<void> _navigateToPost(String postId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final post = await _postService.getPostById(postId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.pushNamed(context, '/post_detail', arguments: {'post': post});
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bài viết không còn tồn tại')),
      );
    }
  }

  // ... Các hàm _buildErrorState, _buildEmptyState, _markAllAsRead giữ nguyên style cũ

  Widget _buildErrorState() {
    // (Copy từ code cũ của bạn)
    return Center(child: Text(_error));
  }

  Widget _buildEmptyState() {
    // (Copy từ code cũ của bạn)
    return const Center(child: Text('Chưa có thông báo nào'));
  }

  void _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        for (var n in _notifications) n.isRead = true;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _showDeleteDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa thông báo'),
          content: const Text('Bạn có chắc muốn xóa thông báo này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(color: AppColors.subtitle),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteNotification(notification);
              },
              child: Text(
                'Xóa',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    // Optimistic UI: xóa ngay trên UI
    setState(() {
      _notifications.remove(notification);
    });

    try {
      await _notificationService.deleteNotification(notification.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thông báo'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Nếu lỗi, thêm lại vào list
      setState(() {
        _notifications.insert(0, notification);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Lỗi xóa: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
