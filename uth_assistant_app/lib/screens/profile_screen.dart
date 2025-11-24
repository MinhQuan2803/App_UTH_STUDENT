import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/custom_notification.dart';
import '../widgets/profile_action_button.dart';
import '../widgets/home_post_card.dart';
import '../widgets/skeleton_screens.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? username;
  const ProfileScreen({super.key, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  // --- Services ---
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();

  // --- State ---
  Map<String, dynamic>? _user;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;
  bool _isFollowLoading = false;

  String? _myUsername;
  String _appBarTitle = 'Hồ sơ';

  // Realtime counters
  int _actualPostsCount = 0;
  int _actualFollowersCount = 0;
  int _actualFollowingCount = 0;

  // Cache flag - chỉ load data lần đầu
  bool _hasLoadedData = false;

  @override
  bool get wantKeepAlive => true; // Giữ state khi chuyển tab

  @override
  void initState() {
    super.initState();
    // Chỉ load data lần đầu, các lần sau sẽ dùng cache
    if (!_hasLoadedData) {
      _loadAllData();
    }
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Nếu đã load data và không force refresh thì không load lại
    if (_hasLoadedData && !forceRefresh) {
      if (kDebugMode) print('✅ Using cached profile data');
      return;
    }

    setState(() {
      if (!forceRefresh) _isLoading = true;
      _error = null;
    });

    try {
      _myUsername = await _authService.getUsername();
      final targetUsername = widget.username ?? _myUsername;

      // 1. Lấy thông tin Profile
      Map<String, dynamic> userProfile;
      if (widget.username != null && widget.username != _myUsername) {
        userProfile = await _profileService.getUserProfile(widget.username!,
            forceRefresh: forceRefresh);
      } else {
        userProfile =
            await _profileService.getMyProfile(forceRefresh: forceRefresh);
      }

      if (!mounted) return;

      setState(() {
        _user = userProfile;
        final isMyProfile = targetUsername == _myUsername;
        _appBarTitle = isMyProfile
            ? 'Hồ sơ của tôi'
            : (userProfile['username'] ?? 'Hồ sơ');

        // Lấy followers/following count từ profile luôn
        _actualFollowersCount = userProfile['followerCount'] ?? 0;
        _actualFollowingCount = userProfile['followingCount'] ?? 0;
      });

      // 2. Chỉ cần lấy posts, followers/following đã có từ profile rồi
      await _loadPosts(userProfile['username'], forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedData = true; // Đánh dấu đã load xong
        });
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('401')) {
        _handleSignOut(context, isTokenError: true);
      } else {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPosts(String? username, {bool forceRefresh = false}) async {
    if (username == null) return;
    try {
      // PostService.getProfilePosts() đã trả về List<Post> sẵn
      final posts = await _postService.getProfilePosts(
        username: username,
        page: 0,
        limit: 100,
      );
      if (kDebugMode) {
        print('📊 Posts loaded: ${posts.length} posts');
      }
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _actualPostsCount = posts.length;
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error loading posts: $e');
      if (!mounted) return;
      setState(() {
        _posts = [];
        _actualPostsCount = 0;
      });
    }
  }

  // --- User Actions ---

  Future<void> _handleFollowToggle() async {
    if (_user == null || _isFollowLoading) return;
    setState(() => _isFollowLoading = true);

    final userId = _user!['_id'] ?? _user!['id'];
    final bool currentlyFollowing = _user!['isFollowing'] ?? false;

    try {
      if (currentlyFollowing) {
        await _followService.unfollowUser(userId);
        if (mounted) {
          setState(() {
            _user!['isFollowing'] = false;
            _actualFollowersCount--;
          });
          CustomNotification.success(context, "Đã hủy theo dõi");
        }
      } else {
        await _followService.followUser(userId);
        if (mounted) {
          setState(() {
            _user!['isFollowing'] = true;
            _actualFollowersCount++;
          });
          CustomNotification.success(context, "Đã theo dõi");
        }
      }
    } catch (e) {
      if (mounted) CustomNotification.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  Future<void> _handleSignOut(BuildContext context,
      {bool isTokenError = false}) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/login', (route) => false);
      if (isTokenError) {
        CustomNotification.error(context, 'Phiên đăng nhập hết hạn.');
      }
    }
  }

  void _showMenuBottomSheet(BuildContext context, bool isOwner) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          if (isOwner) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Chỉnh sửa hồ sơ"),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditProfileScreen(currentUser: _user!)),
                );
                if (result == true) _loadAllData(forceRefresh: true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleSignOut(context);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_outlined),
              title: const Text("Báo cáo"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text("Chặn người dùng",
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildUserInfoSection(bool isOwner) {
    final String? avatarUrl = _user!['avatarUrl'];
    final String username = _user!['username'] ?? 'User';
    final String? bio = _user!['bio'];
    final bool isFollowing = _user!['isFollowing'] ?? false;

    // Hiển thị "Bạn" thay vì tên nếu là owner
    final String displayName = isOwner ? username : username;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          // Row: Avatar + Stats
          Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: AppTextStyles.heading1.copyWith(fontSize: 24),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$_actualPostsCount', 'Bài viết'),
                    _buildStatItem('$_actualFollowersCount', 'Người theo dõi'),
                    _buildStatItem('$_actualFollowingCount', 'Đang theo dõi'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Name & Bio
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.heading1.copyWith(fontSize: 18),
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: AppTextStyles.bodyRegular
                        .copyWith(color: AppColors.text),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 2),

          // Action Buttons
          if (isOwner)
            // Chỉ hiện 1 nút Ví UTH với icon khi xem profile của mình
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/wallet');
                    },
                    icon: SvgPicture.asset(
                      AppAssets.iconWallet,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: const Text('Ví UTH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Hiện 2 nút Theo dõi và Nhắn tin cho khách
            Row(
              children: [
                Expanded(
                  child: ProfileActionButton(
                    text: isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                    onPressed: _handleFollowToggle,
                    type: isFollowing
                        ? ProfileButtonType.following
                        : ProfileButtonType.follow,
                    isLoading: _isFollowLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ProfileActionButton(
                    text: 'Nhắn tin',
                    onPressed: () {
                      CustomNotification.info(
                          context, "Tính năng nhắn tin đang phát triển");
                    },
                    type: ProfileButtonType.secondary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          const Divider(thickness: 2, color: AppColors.divider),

          // Tiêu đề "Tất cả bài viết"
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tất cả bài viết',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.bodyBold
              .copyWith(fontSize: 19, color: AppColors.primary),
          selectionColor: AppColors.primary,
        ),
        Text(label, style: AppTextStyles.bodyRegular.copyWith(fontSize: 12)),
      ],
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc cho AutomaticKeepAliveClientMixin

    final bool isPushed = widget.username != null;
    final bool isOwner = _user?['isOwner'] ?? false;

    if (_isLoading) {
      return ProfileSkeletonScreen(
        appBarTitle: _appBarTitle,
        automaticallyImplyLeading: isPushed,
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: ModernAppBar(title: 'Lỗi', automaticallyImplyLeading: isPushed),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Không tìm thấy thông tin người dùng',
                  style: AppTextStyles.bodyRegular),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadAllData(forceRefresh: true),
                child: const Text('Thử lại'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: "Hồ sơ của bạn",
        automaticallyImplyLeading: isPushed,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              isOwner ? AppAssets.iconSettings : AppAssets.iconWarning,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.text,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => _showMenuBottomSheet(context, isOwner),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAllData(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Phần 1: Header Thông tin (Avatar, Bio, Stats...)
            SliverToBoxAdapter(
              child: _buildUserInfoSection(isOwner),
            ),

            // Phần 2: Danh sách bài viết (Grid hoặc List)
            if (_posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 6),
                      Text('Chưa có bài viết nào',
                          style: AppTextStyles.bodyRegular),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: HomePostCard(
                        post: _posts[index],
                        username: _myUsername,
                        onPostDeleted: () => _loadAllData(forceRefresh: true),
                        onPostUpdated: () => _loadAllData(forceRefresh: true),
                      ),
                    );
                  },
                  childCount: _posts.length,
                ),
              ),

            // Padding bottom an toàn
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }
}
