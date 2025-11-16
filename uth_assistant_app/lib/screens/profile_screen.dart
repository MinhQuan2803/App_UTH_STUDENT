import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/profile_list_item.dart';
import '../widgets/profile_stat_item.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_notification.dart';
import '../widgets/modern_app_bar.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../services/relationship_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? username;
  const ProfileScreen({super.key, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();
  final RelationshipService _relationshipService = RelationshipService();

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;
  bool _isFollowLoading = false;

  String? _myUsername; // Username của người đang đăng nhập
  String _appBarTitle = 'Hồ sơ';
  int _actualPostsCount = 0; // Số bài viết thực tế từ API
  int _actualFollowersCount = 0; // Số followers thực tế từ API
  int _actualFollowingCount = 0; // Số following thực tế từ API

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    await _loadProfile(forceRefresh: forceRefresh);
    await Future.wait([
      _loadPostsCount(forceRefresh: forceRefresh),
      _loadFollowersCount(forceRefresh: forceRefresh),
      _loadFollowingCount(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> user;
      _myUsername = await _authService.getUsername();

      if (widget.username != null && widget.username != _myUsername) {
        // TRƯỜNG HỢP 1: Xem profile người khác
        user = await _profileService.getUserProfile(widget.username!,
            forceRefresh: forceRefresh);
      } else {
        // TRƯỜNG HỢP 2: Xem profile của MÌNH
        user = await _profileService.getMyProfile(forceRefresh: forceRefresh);
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
        // Kiểm tra xem có phải profile của mình không
        final bool isMyProfile =
            widget.username == null || widget.username == _myUsername;
        _appBarTitle = isMyProfile
            ? 'Hồ sơ của bạn'
            : 'Hồ sơ của ${user['username'] ?? '...'}';
      });

      // Tải số bài viết sau khi có username
      await Future.wait([
        _loadPostsCount(),
        _loadFollowersCount(),
        _loadFollowingCount(),
      ]);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.startsWith('401')) {
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

  Future<void> _loadPostsCount({bool forceRefresh = false}) async {
    if (_user == null) return;
    final username = _user!['username'];
    if (username == null) return;

    try {
      // Lấy tất cả bài viết với limit cao để đếm
      final posts = await _postService.getProfilePosts(
        username: username,
        page: 0,
        limit: 1000, // Lấy tối đa 1000 bài để đếm
      );
      if (!mounted) return;
      setState(() {
        _actualPostsCount = posts.length;
      });
    } catch (e) {
      // Không hiển thị lỗi, giữ giá trị mặc định 0
      if (!mounted) return;
      setState(() {
        _actualPostsCount = 0;
      });
    }
  }

  Future<void> _loadFollowersCount({bool forceRefresh = false}) async {
    if (_user == null) return;
    final username = _user!['username'];
    if (username == null) return;

    try {
      final followers = await _relationshipService.getFollowers(username);
      if (!mounted) return;
      setState(() {
        _actualFollowersCount = followers.length;
      });
    } catch (e) {
      // Không hiển thị lỗi, giữ giá trị mặc định 0
      if (!mounted) return;
      setState(() {
        _actualFollowersCount = 0;
      });
    }
  }

  Future<void> _loadFollowingCount({bool forceRefresh = false}) async {
    if (_user == null) return;
    final username = _user!['username'];
    if (username == null) return;

    try {
      final following = await _relationshipService.getFollowing(username);
      if (!mounted) return;
      setState(() {
        _actualFollowingCount = following.length;
      });
    } catch (e) {
      // Không hiển thị lỗi, giữ giá trị mặc định 0
      if (!mounted) return;
      setState(() {
        _actualFollowingCount = 0;
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context,
      {bool isTokenError = false}) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/login', (route) => false);
      if (isTokenError) {
        CustomNotification.error(
          context,
          'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
        );
      }
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_user == null || _isFollowLoading) return;
    final userId = _user!['_id'] ?? _user!['id'];
    if (userId == null) {
      CustomNotification.error(context, 'Không tìm thấy ID người dùng');
      return;
    }
    final bool currentlyFollowing = _user!['isFollowing'] ?? false;
    setState(() => _isFollowLoading = true);
    try {
      if (currentlyFollowing) {
        final result = await _followService.unfollowUser(userId);
        if (mounted) {
          setState(() {
            _user!['isFollowing'] = false;
            _user!['followerCount'] = (_user!['followerCount'] ?? 1) - 1;
          });
          CustomNotification.success(context, result.message);
        }
      } else {
        final result = await _followService.followUser(userId);
        if (mounted) {
          setState(() {
            _user!['isFollowing'] = true;
            _user!['followerCount'] = (_user!['followerCount'] ?? 0) + 1;
          });
          CustomNotification.success(context, result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem màn hình này có phải là tab hay được push
    // true = được push (xem profile người khác)
    // false = là 1 tab (xem profile của mình)
    final bool isPushed = widget.username != null;
    Widget body = _buildBody();

    if (isPushed) {
      // 1. Nếu được push -> TẠO Scaffold
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModernAppBar(
          title: _appBarTitle,
        ),
        body: body,
      );
    } else {
      // 2. Nếu là 1 tab -> Dùng Column với AppBar hiện đại
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false, // Không có nút back
              title: Text(
                _appBarTitle,
                style: AppTextStyles.appBarTitle.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: AppColors.white),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!,
            textAlign: TextAlign.center, style: AppTextStyles.errorText),
      ));
    }
    if (_user == null) {
      return const Center(
          child: Text('Không có dữ liệu người dùng.',
              style: AppTextStyles.bodyRegular));
    }

    // Giao diện đơn giản chỉ hiển thị thông tin
    return RefreshIndicator(
      onRefresh: () => _loadAllData(forceRefresh: true),
      child: ListView(
        children: [
          // Thẻ thông tin người dùng
          _buildSimpleUserInfoCard(context, _user!),
          const SizedBox(height: 8),
          // Các hành động
          _buildInfoTab(context, _user!),
        ],
      ),
    );
  }

  Widget _buildSimpleUserInfoCard(
      BuildContext context, Map<String, dynamic> user) {
    final String username = user['username'] ?? '...';
    final String avatarPlaceholder =
        'https://placehold.co/80x80/${AppColors.secondary.value.toRadixString(16).substring(2)}/${AppColors.avatarPlaceholderText.value.toRadixString(16).substring(2)}?text=${username.isNotEmpty ? username[0].toUpperCase() : '?'}';
    final String avatarUrl = user['avatarUrl'] ?? avatarPlaceholder;
    final bool isOwner = user['isOwner'] ?? false;
    final bool isFollowing = user['isFollowing'] ?? false;

    // Ưu tiên số liệu thực tế từ API, fallback về user profile
    final int followerCount = _actualFollowersCount > 0
        ? _actualFollowersCount
        : (user['followerCount'] ?? 0);
    final int followingCount = _actualFollowingCount > 0
        ? _actualFollowingCount
        : (user['followingCount'] ?? 0);
    final int postsCount =
        _actualPostsCount > 0 ? _actualPostsCount : (user['postsCount'] ?? 0);

    String joinDate = 'Tham gia từ 2024';
    if (user['createdAt'] != null) {
      try {
        final date = DateTime.parse(user['createdAt']);
        joinDate = 'Tham gia ngày ${date.day}/${date.month}/${date.year}';
      } catch (e) {}
    }

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(height: 12),
          Text(username,
              style: AppTextStyles.profileName.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(joinDate,
              style: AppTextStyles.profileMeta
                  .copyWith(color: AppColors.subtitle)),
          const SizedBox(height: 16),
          // Thống kê
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ProfileStatItem(
                label: 'Bài viết',
                count: postsCount,
                onTap: () {
                  Navigator.pushNamed(context, '/user_posts',
                      arguments: {'username': username});
                },
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              ProfileStatItem(
                label: 'Người theo dõi',
                count: followerCount,
                onTap: () {
                  Navigator.pushNamed(context, '/user_list',
                      arguments: {'username': username, 'type': 'followers'});
                },
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              ProfileStatItem(
                label: 'Đang theo dõi',
                count: followingCount,
                onTap: () {
                  Navigator.pushNamed(context, '/user_list',
                      arguments: {'username': username, 'type': 'following'});
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nút hành động
          SizedBox(
            width: double.infinity,
            child: isOwner
                ? CustomButton(
                    text: 'Chỉnh sửa hồ sơ',
                    onPressed: () async {
                      // Điều hướng đến màn hình chỉnh sửa
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentUser: user,
                          ),
                        ),
                      );
                      
                      // Nếu có thay đổi, reload profile
                      if (result == true) {
                        await _loadAllData(forceRefresh: true);
                      }
                    },
                    isPrimary: false,
                  )
                : CustomButton(
                    text: isFollowing ? 'Đang Follow' : 'Follow',
                    onPressed: _isFollowLoading
                        ? () {}
                        : () {
                            _handleFollowToggle();
                          },
                    isPrimary: !isFollowing,
                  ),
          ),
        ],
      ),
    );
  }

  // Phần hiển thị thông tin & actions
  Widget _buildInfoTab(BuildContext context, Map<String, dynamic> user) {
    final bool isOwner = user['isOwner'] ?? false;
    final String username = user['username'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
        ),
        child: Column(
          children: [
            if (isOwner) ...[
              ProfileListItem(
                iconPath: AppAssets.iconEdit,
                title: 'Bài viết của tôi',
                onTap: () => Navigator.pushNamed(context, '/user_posts',
                    arguments: {'username': username}),
              ),
              ProfileListItem(
                iconPath: AppAssets.iconWallet,
                title: 'Ví UTH',
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
              ProfileListItem(
                iconPath: AppAssets.iconFileCheck,
                title: 'Tài liệu của tôi',
                onTap: () => CustomNotification.info(
                    context, 'Tính năng đang phát triển'),
              ),
              ProfileListItem(
                iconPath: AppAssets.iconSettings,
                title: 'Cài đặt',
                onTap: () => CustomNotification.info(
                    context, 'Tính năng đang phát triển'),
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
                onTap: () => Navigator.pushNamed(context, '/user_posts',
                    arguments: {'username': username}),
              ),
              ProfileListItem(
                iconData: Icons.flag_outlined,
                title: 'Báo cáo người dùng',
                color: AppColors.danger,
                onTap: () => CustomNotification.info(
                    context, 'Tính năng đang phát triển'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
