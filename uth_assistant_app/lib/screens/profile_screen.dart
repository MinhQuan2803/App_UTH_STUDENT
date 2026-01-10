import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/custom_notification.dart';
import '../widgets/profile_action_button.dart';
import '../widgets/home_post_card.dart';
import '../widgets/skeleton_screens.dart';
import '../widgets/report_dialog.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import 'edit_profile_screen.dart';
import 'follow_list_screen.dart'; // Import màn hình mới

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

  // --- SCROLL CONTROL FOR EFFECT ---
  late ScrollController _scrollController;
  bool _isPullingDown = false; // Trạng thái đang kéo xuống (Refresh)
  bool _isScrolled = false; // Trạng thái đã cuộn xuống xem nội dung

  @override
  bool get wantKeepAlive => true; // Giữ state khi chuyển tab

  @override
  void initState() {
    super.initState();

    // 1. Khởi tạo Controller lắng nghe cuộn để tạo hiệu ứng đổi màu
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      // Logic: Kéo xuống quá giới hạn (Offset âm)
      final isPulling = offset < 0;

      // Logic: Đã cuộn nội dung lên (Offset dương)
      // Dùng > 0 để đổi màu ngay lập tức khi cuộn
      final isScrolled = offset > 0;

      // Chỉ setState khi trạng thái thay đổi để tối ưu hiệu năng
      if (isPulling != _isPullingDown || isScrolled != _isScrolled) {
        setState(() {
          _isPullingDown = isPulling;
          _isScrolled = isScrolled;
        });
      }
    });

    // Chỉ load data lần đầu, các lần sau sẽ dùng cache
    if (!_hasLoadedData) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Quan trọng: Hủy controller
    super.dispose();
  }

  // Method public để scroll to top và reload
  void scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
    _loadAllData(forceRefresh: true);
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (!mounted) return;

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
            ? (userProfile['username'] ?? 'Hồ sơ của tôi')
            : (userProfile['username'] ?? 'Hồ sơ');

        _actualFollowersCount = userProfile['followerCount'] ?? 0;
        _actualFollowingCount = userProfile['followingCount'] ?? 0;
      });

      await _loadPosts(userProfile['username'], forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedData = true;
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

  // Hiển thị dialog báo cáo user
  void _showReportDialog() {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetId: _user!['_id'] ?? _user!['id'],
        targetType: 'User',
        targetName: _user!['username'] ?? 'User',
      ),
    );
  }

  // --- UI Components ---

  // Hàm điều hướng sang màn hình Follow
  void _navigateToFollowList(int initialIndex) {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListScreen(
          username: _user!['username'] ?? 'User',
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(bool isOwner) {
    final String? avatarUrl = _user!['avatarUrl'];
    final String realname = _user!['realname'] ?? 'User';
    final String? bio = _user!['bio'];
    final bool isFollowing = _user!['isFollowing'] ?? false;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          // Row: Avatar + Stats
          Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryDark, width: 3),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          realname.isNotEmpty ? realname[0].toUpperCase() : 'U',
                          style: AppTextStyles.heading1.copyWith(fontSize: 24),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              // Stats
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          realname,
                          style: AppTextStyles.usernamePacifico
                              .copyWith(color: AppColors.text),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('$_actualPostsCount',
                              'Bài viết'), // Bài viết không cần click

                          // THAY ĐỔI: Thêm onTap cho Follower
                          _buildStatItem(
                            '$_actualFollowersCount',
                            'Người theo dõi',
                            onTap: () =>
                                _navigateToFollowList(1), // Index 1: Follower
                          ),

                          // THAY ĐỔI: Thêm onTap cho Following
                          _buildStatItem(
                            '$_actualFollowingCount',
                            'Đang theo dõi',
                            onTap: () => _navigateToFollowList(
                                0), // Index 0: Đang follow
                          ),
                        ],
                      ),
                    ]),
              )
            ],
          ),

          const SizedBox(height: 10),

          // Name & Bio
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      backgroundColor: AppColors.primaryDark,
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tất cả bài viết',
                style: AppTextStyles.title.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CẬP NHẬT: Widget Stat Item dễ nhấn hơn ---
  Widget _buildStatItem(String value, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior
          .opaque, // QUAN TRỌNG: Bắt sự kiện nhấn trên toàn bộ vùng chứa kể cả khoảng trắng
      child: Container(
        color: Colors.transparent, // Đảm bảo bắt được sự kiện nhấn
        // Padding rộng ra để dễ nhấn (12px ngang, 8px dọc)
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Căn giữa nội dung
          children: [
            Text(
              value,
              style: AppTextStyles.numberInfor.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: AppTextStyles.bodyRegular.copyWith(
                fontSize: 10, // Chữ nhỏ gọn
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc cho AutomaticKeepAliveClientMixin

    final bool isPushed = widget.username != null;
    final bool isOwner = _user?['isOwner'] ?? false;

    // QUAN TRỌNG: Kiểm tra xem có phải được push từ Navigator hay không
    // Nếu canPop = true → Có màn hình phía sau → Hiển thị nút back
    // Nếu canPop = false → Không có màn hình phía sau (từ BottomBar) → Hiển thị icon khóa
    final bool canGoBack = Navigator.canPop(context);
    final bool showBackButton =
        canGoBack && isPushed; // Chỉ show back nếu được push VÀ có thể pop

    // --- LOGIC MÀU SẮC DỰA TRÊN 3 TRẠNG THÁI ---
    // 1. Kéo xuống (_isPullingDown) hoặc Đã cuộn (_isScrolled) -> Màu ĐEN
    // 2. Ở vị trí đầu (Mặc định) -> Màu TRẮNG
    final currentColor =
        (_isPullingDown || _isScrolled) ? Colors.black : AppColors.white;

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
      body: RefreshIndicator(
        onRefresh: () => _loadAllData(forceRefresh: true),
        child: CustomScrollView(
          controller: _scrollController, // Gắn Controller
          physics: const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics()), // Bắt buộc để kéo quá giới hạn mượt mà
          slivers: [
            SliverAppBar(
              expandedHeight: 45,
              toolbarHeight: 40,
              pinned: true,
              elevation: 0,
              backgroundColor: _isScrolled ? Colors.white : Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: _isScrolled
                        ? Colors.white
                        : (_isPullingDown ? Colors.transparent : null),
                    gradient: (!_isScrolled && !_isPullingDown)
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: _isScrolled
                        ? Border(
                            bottom: BorderSide(color: Colors.grey.shade200))
                        : null,
                  ),
                ),
              ),

              // --- CHANGED: wrap title with GestureDetector to scroll to top on tap ---
              title: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Row(
                  children: [
                    // LOGIC: Hiển thị nút back nếu được push từ Navigator
                    // Hiển thị icon khóa nếu vào từ BottomBar (profile của mình)
                    showBackButton
                        ? Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.arrow_back,
                                  color: currentColor, size: 25),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: SvgPicture.asset(
                              AppAssets.iconPrivate,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                  currentColor, BlendMode.srcIn),
                            ),
                          ),
                    const SizedBox(width: 8),
                    Text(
                      _appBarTitle,
                      style: AppTextStyles.usernamePacifico
                          .copyWith(color: currentColor, fontSize: 18),
                    ),
                  ],
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                PopupMenuButton<String>(
                  icon: SvgPicture.asset(
                    AppAssets.iconSetting,
                    width: 24,
                    height: 24,
                    colorFilter:
                        ColorFilter.mode(currentColor, BlendMode.srcIn),
                  ),
                  color: AppColors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  offset: const Offset(0, 45),
                  itemBuilder: (BuildContext context) => isOwner
                      ? [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    color: AppColors.text, size: 20),
                                const SizedBox(width: 12),
                                Text('Chỉnh sửa hồ sơ',
                                    style: AppTextStyles.listItem
                                        .copyWith(fontSize: 14)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 12),
                                Text('Đăng xuất',
                                    style: AppTextStyles.listItem.copyWith(
                                        fontSize: 14, color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ]
                      : [
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.report_gmailerrorred_outlined,
                                    color: AppColors.text, size: 20),
                                const SizedBox(width: 12),
                                Text('Báo cáo',
                                    style: AppTextStyles.listItem
                                        .copyWith(fontSize: 14)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'block',
                            child: Row(
                              children: [
                                const Icon(Icons.block,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 12),
                                Text('Chặn người dùng',
                                    style: AppTextStyles.listItem.copyWith(
                                        fontSize: 14, color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ],
                  onSelected: (String value) async {
                    switch (value) {
                      case 'edit':
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(currentUser: _user!)),
                        );
                        if (result == true) _loadAllData(forceRefresh: true);
                        break;
                      case 'logout':
                        _handleSignOut(context);
                        break;
                      case 'report':
                        _showReportDialog();
                        break;
                      case 'block':
                        CustomNotification.info(
                            context, 'Tính năng đang phát triển');
                        break;
                    }
                  },
                ),
              ],
            ),

            // Phần 1: Header Thông tin
            SliverToBoxAdapter(
              child: _buildUserInfoSection(isOwner),
            ),

            // Phần 2: Danh sách bài viết
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
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: HomePostCard(
                        post: _posts[index],
                        username: _myUsername,
                        currentUsername: _user?[
                            'username'], // Truyền username của profile đang xem
                        onPostDeleted: () => _loadAllData(forceRefresh: true),
                        onPostUpdated: () => _loadAllData(forceRefresh: true),
                      ),
                    );
                  },
                  childCount: _posts.length,
                ),
              ),

            // Padding bottom để không bị BottomNavBar che
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 80),
            ),
          ],
        ),
      ),
    );
  }
}
