import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/notification_card.dart';
import '../widgets/animated_wave_header.dart';
import '../widgets/home_post_card.dart'; // Import widget mới
import '../widgets/custom_button.dart'; // Import CustomButton
import '../widgets/skeleton_screens.dart'; // Import Skeleton Loading
import '../services/news_service.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../models/post_model.dart';
import '../utils/launcher_util.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart'; // Cho kDebugMode

class HomeScreen extends StatefulWidget {
  final PageController pageController;
  const HomeScreen({super.key, required this.pageController});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  List<NewsArticle> _articles = [];
  bool _isLoadingNews = true;
  String _newsError = '';
  final NewsService _newsService = NewsService();
  final String defaultImageUrl = AppAssets.defaultNotificationImage;

  List<Post> _posts = []; // Kiểu dữ liệu Post từ models/post_model.dart
  bool _isLoadingPosts = true;
  String _postsError = '';
  final PostService _postService = PostService();

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  String? _username;
  String? _avatarUrl;

  // ScrollController để scroll to top
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchNewsData();
    _fetchPostsData();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    _fetchNewsData(forceRefresh: true);
    _fetchPostsData(forceRefresh: true);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getMyProfile();
      if (mounted) {
        setState(() {
          _username = profile['username'];
          _avatarUrl = profile['avatarUrl'];
        });
      }
    } catch (e) {
      // Fallback to getUsername if profile fails
      final username = await _authService.getUsername();
      if (mounted) {
        setState(() => _username = username);
      }
    }
  }

  // Public method để refresh posts từ bên ngoài (ví dụ: sau khi đăng bài mới)
  Future<void> refreshPosts() async {
    await _fetchPostsData(forceRefresh: true);
  }

  Future<void> _fetchNewsData({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingNews = true;
      _newsError = '';
    });
    try {
      final fetchedArticles =
          await _newsService.fetchNews(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _articles = fetchedArticles;
        _isLoadingNews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _newsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _fetchPostsData({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingPosts = true;
      _postsError = '';
    });
    try {
      // getHomeFeed đã trả về List<Post>, không cần parse lại
      final List<Post> fetchedPosts = await _postService.getHomeFeed(
        page: 0,
        limit: 20,
        feed: 'public',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _posts = fetchedPosts;
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) return 'Hôm nay';
      if (difference.inDays == 1) return 'Hôm qua';
      if (difference.inDays < 7) return '${difference.inDays} ngày trước';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () async {
          await _fetchNewsData(forceRefresh: true);
          await _fetchPostsData(forceRefresh: true);
          await _loadUserProfile();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildHeader(context),
            _buildNotificationSection(),
            _buildFeedTitle(),
            _buildPostList(),
            // Thêm padding bottom để không bị BottomNavBar che
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.transparent, // Sử dụng biến
      expandedHeight: 50.0,
      floating: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false, // Loại bỏ nút back
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedWaveHeader(
          onSearchPressed: _navigateToSearch,
          username: _username ?? '...',
          avatarUrl: _avatarUrl,
          onProfileTap: () {
            // Chuyển đến tab Profile (index 3)
            widget.pageController.jumpToPage(3);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thông báo Đào tạo',
                    style: AppTextStyles.beVietnam.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                TextButton(
                  onPressed: () {
                    launchUrlHelper(
                        context, 'https://portal.ut.edu.vn/newfeeds/368',
                        title: 'Thông báo');
                  },
                  child:
                      const Text('Xem tất cả', style: AppTextStyles.linkText),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: _buildNewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    if (_isLoadingNews) {
      return NewsListSkeleton();
    }
    if (_newsError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_newsError,
              textAlign: TextAlign.center, style: AppTextStyles.errorText),
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(
          child: Text("Không có thông báo nào.",
              style: AppTextStyles.bodyRegular));
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: InkWell(
            onTap: () {
              if (article.url != null && article.url!.isNotEmpty) {
                launchUrlHelper(context, article.url!, title: article.title);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Không có link chi tiết cho thông báo này.')),
                );
              }
            },
            child: NotificationCard(
              imageUrl: defaultImageUrl,
              title: article.title,
              date: _formatDate(article.date), // Sử dụng hàm format date
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        child: Text('Cộng đồng sinh viên',
            style: AppTextStyles.title.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark)),
      ),
    );
  }

  Widget _buildPostList() {
    if (_isLoadingPosts) {
      return SliverFillRemaining(
        child: PostsListSkeleton(itemCount: 4),
      );
    }
    if (_postsError.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_postsError,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.errorText),
                const SizedBox(height: 16),
                CustomButton(
                  // Sử dụng CustomButton
                  onPressed: () => _fetchPostsData(forceRefresh: true),
                  text: 'Thử lại',
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Chưa có bài viết nào.\nHãy là người đầu tiên chia sẻ!',
                textAlign: TextAlign.center, style: AppTextStyles.bodyRegular),
          ),
        ),
      );
    }

    // Hiển thị danh sách bài viết
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 16.0),
      sliver: SliverList.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];

          return HomePostCard(
            key: ValueKey(post.id), // Dùng Key để Flutter nhận diện đúng
            post: post,
            username: _username,
            onPostDeleted: () {
              setState(() {
                _posts.removeAt(index);
              });
            },
            onPostUpdated: () {
              _fetchPostsData(forceRefresh: true);
            },
          );
        },
      ),
    );
  }
}
