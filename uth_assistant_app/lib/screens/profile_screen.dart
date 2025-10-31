import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/profile_list_item.dart';
import '../widgets/profile_stat_item.dart';
import '../widgets/home_post_card.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  // THÊM: Một username TÙY CHỌN.
  // Nếu là null: xem profile của MÌNH
  // Nếu có giá trị: xem profile của NGƯỜI KHÁC
  final String? username;

  const ProfileScreen({super.key, this.username}); // Cập nhật constructor

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;
  bool _isFollowLoading = false; // Loading state cho button Follow

  // State cho bài viết
  List<Post> _posts = [];
  bool _isLoadingPosts = false;
  String? _postsError;
  String? _currentUsername; // Username hiện tại đang xem

  // Biến để lưu AppBar title
  String _appBarTitle = 'Hồ sơ';

  @override
  void initState() {
    super.initState();
    // Bỏ logic ở didChangeDependencies và chuyển về initState
    _loadProfile();
  }

  // Hàm load profile với option force refresh
  Future<void> _loadProfile({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> user;

      if (widget.username != null) {
        // TRƯỜNG HỢP 1: Được truyền username (xem profile người khác)
        _appBarTitle = 'Hồ sơ của ${widget.username}';
        user = await _profileService.getUserProfile(
          widget.username!,
          forceRefresh: forceRefresh,
        );
        _currentUsername = widget.username;
      } else {
        // TRƯỜNG HỢP 2: KHÔNG được truyền (xem profile của MÌNH)
        _appBarTitle = 'Hồ sơ của tôi';
        user = await _profileService.getMyProfile(forceRefresh: forceRefresh);
        _currentUsername = user['username'];
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
        if (widget.username == null) {
          _appBarTitle = 'Hồ sơ của tôi';
        } else {
          _appBarTitle = 'Hồ sơ của ${user['username'] ?? widget.username}';
        }
      });

      // Load bài viết sau khi load profile thành công
      _loadPosts();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (errorMessage.startsWith('401')) {
        // Lỗi 401 (chưa đăng nhập, token hết hạn, ...)
        _handleSignOut(context, isTokenError: true);
      } else {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
          _appBarTitle = 'Lỗi';
        });
      }
    }
  }

  // Hàm load bài viết của user
  Future<void> _loadPosts({bool forceRefresh = false}) async {
    if (_currentUsername == null) return;

    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final posts = await _postService.getProfilePosts(
        username: _currentUsername!,
        page: 0,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPosts = false;
      });
    }
  }

  // Hàm đăng xuất (thêm tham số isTokenError)
  Future<void> _handleSignOut(BuildContext context,
      {bool isTokenError = false}) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

      if (isTokenError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Xử lý Follow/Unfollow user
  Future<void> _handleFollowToggle() async {
    if (_user == null || _isFollowLoading) return;

    final userId = _user!['_id'] ?? _user!['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID người dùng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool currentlyFollowing = _user!['isFollowing'] ?? false;

    setState(() => _isFollowLoading = true);

    try {
      if (currentlyFollowing) {
        // Unfollow
        final result = await _followService.unfollowUser(userId);

        if (mounted) {
          // Update UI
          setState(() {
            _user!['isFollowing'] = false;
            _user!['followerCount'] = (_user!['followerCount'] ?? 0) - 1;
            _isFollowLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Follow
        final result = await _followService.followUser(userId);

        if (mounted) {
          // Update UI
          setState(() {
            _user!['isFollowing'] = true;
            _user!['followerCount'] = (_user!['followerCount'] ?? 0) + 1;
            _isFollowLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thêm Scaffold nếu ProfileScreen này được PUSH
    // Nếu nó là MỘT TAB trong MainScreen, thì KHÔNG cần Scaffold
    // Giả sử MainScreen của bạn đã có AppBar cho tab, chúng ta bỏ AppBar ở đây

    // Nếu file này vừa là 1 tab, vừa được push, chúng ta cần biết:
    final bool isPushed = ModalRoute.of(context)?.canPop ?? false;

    Widget body = _buildBody(); // Tạo body

    if (isPushed) {
      // Nếu được push (xem profile người khác), TẠO Scaffold
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 1,
          shadowColor: AppColors.divider,
          title: Text(_appBarTitle, style: AppTextStyles.appBarTitle),
          centerTitle: true,
        ),
        body: body,
      );
    } else {
      // Nếu là 1 tab (xem profile của mình), KHÔNG TẠO Scaffold
      // (Giả sử MainScreen sẽ cung cấp AppBar)
      // Nhưng nếu MainScreen không cung cấp AppBar, bạn cần 1 AppBar riêng

      // GIẢI PHÁP AN TOÀN: Dùng AppBar riêng cho tab
      return Column(
        children: [
          AppBar(
            backgroundColor: AppColors.white,
            elevation: 1,
            shadowColor: AppColors.divider,
            automaticallyImplyLeading: false, // Không có nút back
            title: Text(_appBarTitle, style: AppTextStyles.appBarTitle),
            centerTitle: true,
          ),
          Expanded(
            child: body,
          ),
        ],
      );
    }
  }

  // Widget Body (Xử lý Loading/Error)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger)),
      ));
    }
    if (_user == null) {
      return const Center(child: Text('Không có dữ liệu người dùng.'));
    }

    // Nếu tải thành công - Wrap trong DefaultTabController
    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile(forceRefresh: true);
          await _loadPosts();
        },
        child: CustomScrollView(
          slivers: [
            // Header với thông tin user
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildUserInfoCard(context, _user!),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Tab Bar cho các section
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.subtitle,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.grid_on, size: 20),
                      text: 'Bài viết',
                    ),
                    Tab(
                      icon: Icon(Icons.menu, size: 20),
                      text: 'Thông tin',
                    ),
                  ],
                ),
              ),
            ),
            // Tab View Content
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  _buildPostsTab(),
                  _buildInfoTab(context, _user!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cập nhật UserInfoCard với cover image và UI đẹp hơn
  Widget _buildUserInfoCard(BuildContext context, Map<String, dynamic> user) {
    final String username = user['username'] ?? '...';
    final String avatarUrl = user['avatarUrl'] ??
        'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg';
    final bool isOwner = user['isOwner'] ?? false;
    final bool isFollowing = user['isFollowing'] ?? false;

    // Lấy số liệu thống kê từ server
    final int followerCount = user['followerCount'] ?? 0;
    final int followingCount = user['followingCount'] ?? 0;

    String joinDate = 'Thông tin trường...';
    if (user['createdAt'] != null) {
      try {
        final date = DateTime.parse(user['createdAt']);
        joinDate = 'Tham gia ngày ${date.day}/${date.month}/${date.year}';
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Cover Image với gradient overlay
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Cover Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.accent.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              // Avatar
              Positioned(
                bottom: -40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          spreadRadius: 2)
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          // Username và Join Date
          Text(username,
              style: AppTextStyles.profileName.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(joinDate,
              style:
                  AppTextStyles.profileMeta.copyWith(color: AppColors.subtitle)),
          const SizedBox(height: 20),

          // Thống kê: bài viết, followers, following (3 cột)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileStatItem(
                  label: 'Bài viết',
                  count: _posts.length,
                  onTap: () {
                    // Switch to posts tab
                    DefaultTabController.of(context).animateTo(0);
                  },
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                ),
                ProfileStatItem(
                  label: 'Người theo dõi',
                  count: followerCount,
                  onTap: () {
                    final usernameToShow =
                        widget.username ?? _user?['username'];
                    if (usernameToShow != null) {
                      Navigator.pushNamed(
                        context,
                        '/followers',
                        arguments: {
                          'username': usernameToShow,
                        },
                      );
                    }
                  },
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                ),
                ProfileStatItem(
                  label: 'Đang theo dõi',
                  count: followingCount,
                  onTap: () {
                    final usernameToShow =
                        widget.username ?? _user?['username'];
                    if (usernameToShow != null) {
                      Navigator.pushNamed(
                        context,
                        '/following',
                        arguments: {
                          'username': usernameToShow,
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: isOwner
                ? ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Tính năng đang phát triển')),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Chỉnh sửa hồ sơ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isFollowLoading ? null : _handleFollowToggle,
                    icon: Icon(
                        isFollowing ? Icons.check : Icons.person_add, size: 18),
                    label: Text(isFollowing ? 'Đang Follow' : 'Follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFollowing ? AppColors.subtitle : AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Tab hiển thị danh sách bài viết
  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_postsError!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyRegular
                      .copyWith(color: AppColors.danger)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      final bool isOwner = _user?['isOwner'] ?? false;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.post_add,
                  size: 80, color: AppColors.subtitle.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                isOwner
                    ? 'Bạn chưa có bài viết nào\nHãy chia sẻ điều gì đó!'
                    : 'Người dùng này chưa có bài viết nào',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyRegular
                    .copyWith(color: AppColors.subtitle),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final avatarPlaceholder =
            'https://placehold.co/80x80/${AppColors.secondary.value.toRadixString(16).substring(2)}/${AppColors.avatarPlaceholderText.value.toRadixString(16).substring(2)}?text=${post.author.username.isNotEmpty ? post.author.username[0].toUpperCase() : '?'}';

        return HomePostCard(
          key: ValueKey(post.id),
          post: post,
          avatarPlaceholder: avatarPlaceholder,
          username: _user?['username'],
          onPostDeleted: () {
            setState(() {
              _posts.removeAt(index);
            });
          },
          onPostUpdated: () {
            _loadPosts();
          },
        );
      },
    );
  }

  // Tab hiển thị thông tin & actions
  Widget _buildInfoTab(BuildContext context, Map<String, dynamic> user) {
    final bool isOwner = user['isOwner'] ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              if (isOwner) ...[
                ProfileListItem(
                  iconPath: AppAssets.iconFileCheck,
                  title: 'Tài liệu của tôi',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
                ProfileListItem(
                  iconPath: AppAssets.iconSettings,
                  title: 'Cài đặt',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
                ProfileListItem(
                  iconPath: AppAssets.iconLogout,
                  title: 'Đăng xuất',
                  color: AppColors.danger,
                  onTap: () => _handleSignOut(context),
                ),
              ] else ...[
                ProfileListItem(
                  iconPath: AppAssets.iconEdit,
                  title: 'Xem tất cả bài viết',
                  onTap: () {
                    // Switch to posts tab
                    DefaultTabController.of(context).animateTo(0);
                  },
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

// Custom SliverPersistentHeaderDelegate để hiển thị TabBar sticky
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
