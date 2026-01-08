import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/follow_service.dart';
import '../services/profile_service.dart';
import '../widgets/custom_notification.dart';

class FollowListScreen extends StatefulWidget {
  final String username;
  final int initialIndex; // 0: Following, 1: Followers

  const FollowListScreen({
    super.key,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowService _followService = FollowService();
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  List<FollowUser> _followingList = [];
  List<FollowUser> _followersList = [];
  String? _userId;
  String? _error;

  // Counters cho số lượng hiển thị trong tab
  int _followingCount = 0;
  int _followersCount = 0;

  // Pagination
  int _followingPage = 1;
  int _followersPage = 1;
  bool _hasMoreFollowing = true;
  bool _hasMoreFollowers = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lấy userId từ username
      final userProfile = await _profileService.getUserProfile(widget.username);
      _userId = userProfile['_id'] ?? userProfile['id'];

      // Load cả 2 danh sách song song
      await Future.wait([
        _loadFollowing(isInitial: true),
        _loadFollowers(isInitial: true),
      ]);

      if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _loadFollowing({bool isInitial = false}) async {
    if (_userId == null || (!isInitial && !_hasMoreFollowing)) return;

    try {
      final response = await _followService.getFollowing(
        _userId!,
        page: isInitial ? 1 : _followingPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _followingList = response.users;
            _followingPage = 1;
            // Tab Following: Tất cả user trong danh sách này đều đang được follow
            for (var user in _followingList) {
              user.isFollowing = true;
            }
          } else {
            final newUsers = response.users;
            for (var user in newUsers) {
              user.isFollowing = true;
            }
            _followingList.addAll(newUsers);
          }
          _hasMoreFollowing = response.pagination.hasMore;
          _followingPage++;
          // Cập nhật count từ pagination
          _followingCount = response.pagination.total;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          'Không thể tải danh sách following',
        );
      }
    }
  }

  Future<void> _loadFollowers({bool isInitial = false}) async {
    if (_userId == null || (!isInitial && !_hasMoreFollowers)) return;

    try {
      final response = await _followService.getFollowers(
        _userId!,
        page: isInitial ? 1 : _followersPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _followersList = response.users;
            _followersPage = 1;
            // Tab Followers: Cần kiểm tra từng user xem mình có follow lại không
            // Backend có thể trả về isFollowing, nếu không thì mặc định false
          } else {
            _followersList.addAll(response.users);
          }
          _hasMoreFollowers = response.pagination.hasMore;
          _followersPage++;
          // Cập nhật count từ pagination
          _followersCount = response.pagination.total;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          'Không thể tải danh sách followers',
        );
      }
    }
  }

  Future<void> _handleFollowUser(FollowUser user, int tabIndex) async {
    try {
      await _followService.followUser(user.id);
      if (mounted) {
        // Cập nhật trạng thái local
        setState(() {
          user.isFollowing = true;
          // Tăng số lượng following
          _followingCount++;
        });
        CustomNotification.success(context, 'Đã theo dõi ${user.username}');
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _handleUnfollowUser(FollowUser user, int tabIndex) async {
    // Hiển thị dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ theo dõi'),
        content: Text('Bạn có chắc chắn muốn bỏ theo dõi ${user.username}?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.text,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Bỏ theo dõi',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _followService.unfollowUser(user.id);
      if (mounted) {
        // Nếu đang ở tab Following -> Remove khỏi danh sách
        // Nếu đang ở tab Followers -> Chỉ cập nhật trạng thái
        if (tabIndex == 0) {
          // Tab Following: Remove user khỏi danh sách
          setState(() {
            _followingList.removeWhere((u) => u.id == user.id);
            // Giảm số lượng following
            _followingCount--;
          });
        } else {
          // Tab Followers: Chỉ đổi trạng thái
          setState(() {
            user.isFollowing = false;
            // Giảm số lượng following
            _followingCount--;
          });
        }
        CustomNotification.success(
          context,
          'Đã bỏ theo dõi ${user.username}',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _navigateToProfile(String username) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'username': username},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.username,
            style: AppTextStyles.usernamePacifico.copyWith(
              fontSize: 20,
              color: AppColors.text,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.username,
            style: AppTextStyles.usernamePacifico.copyWith(
              fontSize: 20,
              color: AppColors.text,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: AppTextStyles.bodyRegular),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: AppTextStyles.usernamePacifico.copyWith(
            fontSize: 20,
            color: AppColors.text,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.transparent)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryDark,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryDark,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 15),
              unselectedLabelStyle:
                  AppTextStyles.bodyRegular.copyWith(fontSize: 15),
              tabs: [
                Tab(text: 'Đang theo dõi $_followingCount'),
                Tab(text: 'Người theo dõi $_followersCount'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(_followingList, tabIndex: 0), // Tab Following
          _buildListView(_followersList, tabIndex: 1), // Tab Followers
        ],
      ),
    );
  }

  Widget _buildListView(List<FollowUser> users, {required int tabIndex}) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    final isFollowingTab = tabIndex == 0;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoadingMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          if (isFollowingTab && _hasMoreFollowing) {
            setState(() => _isLoadingMore = true);
            _loadFollowing().then((_) {
              if (mounted) setState(() => _isLoadingMore = false);
            });
          } else if (!isFollowingTab && _hasMoreFollowers) {
            setState(() => _isLoadingMore = true);
            _loadFollowers().then((_) {
              if (mounted) setState(() => _isLoadingMore = false);
            });
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          if (isFollowingTab) {
            await _loadFollowing(isInitial: true);
          } else {
            await _loadFollowers(isInitial: true);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == users.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _buildUserItem(users[index], tabIndex: tabIndex);
          },
        ),
      ),
    );
  }

  Widget _buildUserItem(FollowUser user, {required int tabIndex}) {
    // Dựa vào user.isFollowing thực tế thay vì chỉ dựa vào tab
    // Tab Following (0): Luôn isFollowing = true
    // Tab Followers (1): Có thể true hoặc false tùy backend trả về

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: InkWell(
        onTap: () => _navigateToProfile(user.username),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : 'U',
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 20),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.realname != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.realname!,
                        style: AppTextStyles.bodyRegular.copyWith(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (user.bio != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.bio!,
                        style: AppTextStyles.bodyRegular.copyWith(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Follow/Unfollow Button dựa vào user.isFollowing
              SizedBox(
                height: 34,
                child: user.isFollowing
                    ? ElevatedButton(
                        onPressed: () => _handleUnfollowUser(user, tabIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: AppColors.text,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Đang theo dõi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _handleFollowUser(user, tabIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Theo dõi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Chưa có dữ liệu',
            style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
