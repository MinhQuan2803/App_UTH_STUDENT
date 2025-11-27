import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import '../config/app_theme.dart';
// Import các widget card cần tái sử dụng
import '../widgets/notification_card.dart';
import '../widgets/home_post_card.dart'; // SỬ DỤNG WIDGET MỚI

// Import Service và Utility
import '../services/news_service.dart';
import '../services/post_service.dart' hide Post; // SỬA LỖI: Thêm 'hide Post'
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../utils/launcher_util.dart';
import '../utils/time_formatter.dart'; // Import hàm format

// --- Dữ liệu mẫu (Giữ nguyên cho Tài liệu) ---
// Bỏ _mockPosts vì sẽ tải từ API
final List<Map<String, dynamic>> _mockDocuments = [
  {
    'type': 'Tài liệu',
    'title': 'Bài tập lớn Cấu trúc dữ liệu',
    'uploader': 'Trần Anh',
    'fileType': 'DOCX',
    'price': 50,
  },
  {
    'type': 'Tài liệu',
    'title': 'Tổng hợp công thức Excel',
    'uploader': 'Mai Phương',
    'fileType': 'XLSX',
    'price': 0,
  },
   {
    'type': 'Tài liệu',
    'title': 'Đề cương Kinh tế Vận tải (có phí)',
    'uploader': 'Lê Nguyễn',
    'fileType': 'PDF',
    'price': 100,
  },
];
// --- Kết thúc dữ liệu mẫu ---

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Danh sách gốc từ API và dữ liệu mẫu
  List<NewsArticle> _allNotifications = [];
  List<Post> _allPosts = []; // Sửa thành List<Post>
  final List<Map<String, dynamic>> _allDocuments = List.from(_mockDocuments);

  // Danh sách kết quả đã lọc
  List<NewsArticle> _notificationResults = [];
  List<Post> _postResults = []; // Sửa thành List<Post>
  List<Map<String, dynamic>> _documentResults = [];

  // Biến đếm kết quả
  int _notificationCount = 0;
  int _postCount = 0;
  int _documentCount = 0;

  // Trạng thái tải dữ liệu
  bool _isLoadingNews = true;
  bool _isLoadingPosts = true; // Thêm trạng thái tải cho posts
  String _newsError = '';
  String _postsError = ''; // Thêm trạng thái lỗi cho posts
  
  final NewsService _newsService = NewsService();
  final PostService _postService = PostService(); // Thêm PostService
  final AuthService _authService = AuthService(); // Thêm AuthService
  String? _username; // Thêm username

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNewsData();
    _fetchPostsData(); // Tải dữ liệu posts
    _loadUsername(); // Tải username
    _filterResults(); // Lọc ban đầu
    _searchController.addListener(_filterResults);
  }

  // Hàm gọi API lấy tin tức
  Future<void> _fetchNewsData() async {
    setState(() => _isLoadingNews = true);
    try {
      final fetchedArticles = await _newsService.fetchNews(forceRefresh: false);
      if (!mounted) return;
      setState(() {
        _allNotifications = fetchedArticles;
        _isLoadingNews = false;
        _filterResults();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _newsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingNews = false;
        _filterResults();
      });
    }
  }

  // Hàm gọi API lấy bài viết
  Future<void> _fetchPostsData() async {
    setState(() => _isLoadingPosts = true);
    try {
      // Hàm getHomeFeed trả về List<dynamic>, cần ép kiểu
      final List<dynamic> fetchedPostsDynamic = await _postService.getHomeFeed(page: 0, limit: 100, feed: 'public', forceRefresh: false); // Tải 100 posts
      if (!mounted) return;
      setState(() {
        // Ép kiểu List<dynamic> (chứa Maps) thành List<Post> (từ model)
        _allPosts = fetchedPostsDynamic.map((json) => Post.fromJson(json)).toList();
        _isLoadingPosts = false;
        _filterResults();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPosts = false;
        _filterResults();
      });
    }
  }
  
  // Hàm lấy username
  Future<void> _loadUsername() async {
    final username = await _authService.getUsername();
    if (mounted) {
      setState(() => _username = username);
    }
  }

  void _filterResults() {
    final query = _searchController.text.toLowerCase().trim();

    // Lọc tin tức
    List<NewsArticle> tempNotifications;
    if (query.isEmpty) {
      tempNotifications = List.from(_allNotifications);
    } else {
      tempNotifications = _allNotifications.where((item) => 
        item.title.toLowerCase().contains(query)
      ).toList();
    }

    // Lọc bài viết
    List<Post> tempPosts;
    if (query.isEmpty) {
      tempPosts = List.from(_allPosts);
    } else {
      tempPosts = _allPosts.where((post) =>
        (post.text.toLowerCase().contains(query)) ||
        (post.author.username.toLowerCase().contains(query))
      ).toList();
    }

    // Lọc tài liệu
    List<Map<String, dynamic>> tempDocuments;
    if (query.isEmpty) {
      tempDocuments = List.from(_allDocuments);
    } else {
      tempDocuments = _allDocuments.where((item) =>
        (item['title']?.toLowerCase().contains(query) ?? false) ||
        (item['uploader']?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Cập nhật state
    setState(() {
      _notificationResults = tempNotifications;
      _postResults = tempPosts;
      _documentResults = tempDocuments;
      _notificationCount = tempNotifications.length;
      _postCount = tempPosts.length;
      _documentCount = tempDocuments.length;
    });
  }
  
  // Xử lý khi có callback từ HomePostCard
  void _handlePostDeleted(Post post) {
    setState(() {
      _allPosts.removeWhere((p) => p.id == post.id);
      _filterResults(); // Lọc lại danh sách và cập nhật count
    });
  }

  void _handlePostUpdated() {
    // Tải lại toàn bộ posts để lấy dữ liệu mới nhất
    _fetchPostsData().then((_) => _filterResults());
  }


  @override
  void dispose() {
    _searchController.removeListener(_filterResults);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTab(String label, int count) {
    final bool isSelected = _tabController.index == ['Thông báo', 'Bài viết', 'Tài liệu'].indexOf(label);
    final Color textColor = isSelected ? AppColors.white : AppColors.white.withOpacity(0.7);

    return Tab(
      child: Stack(
        clipBehavior: Clip.none, // Cho phép hiển thị số bên ngoài Stack
        children: [
          // Tiêu đề chính của tab
          Padding(
            padding: const EdgeInsets.only(right: 12), // Tạo khoảng trống cho số
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Số lượng kết quả (superscript)
          if (count > 0) // Chỉ hiển thị nếu có kết quả
            Positioned(
              top: -4, // Nâng số lên trên
              right: 0, // Đặt số ở góc phải
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10, // Kích thước chữ nhỏ
                  color: textColor, // Màu giống tiêu đề
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleSpacing: 0, // Xóa khoảng cách mặc định của title
        title: Row(
          children: [
            // Icon tìm kiếm đặt bên ngoài TextField
             Padding(
              padding: const EdgeInsets.only(left: 0, right: 8.0), // Giảm padding trái
              child: SvgPicture.asset(
                AppAssets.iconSearch,
                colorFilter: ColorFilter.mode(AppColors.white.withOpacity(0.7), BlendMode.srcIn),
                width: 20, // Kích thước icon
              ),
            ),
            // TextField mở rộng để chiếm không gian còn lại
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: AppTextStyles.searchHint.copyWith(color: AppColors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14), // Thêm padding dọc
                  isCollapsed: true, // Thêm dòng này để loại bỏ padding mặc định
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.white, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          labelStyle: AppTextStyles.tabLabel.copyWith(fontSize: 14),
          indicatorWeight: 3.0,
          onTap: (_) => setState(() {}),
          tabs: [
            _buildTab('Thông báo', _notificationCount),
            _buildTab('Bài viết', _postCount),
            _buildTab('Tài liệu', _documentCount),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResultList(_notificationResults, 'Thông báo', isLoading: _isLoadingNews, error: _newsError),
          _buildResultList(_postResults, 'Bài viết', isLoading: _isLoadingPosts, error: _postsError),
          _buildResultList(_documentResults, 'Tài liệu'),
        ],
      ),
    );
  }

  Widget _buildResultList(List results, String type, {bool isLoading = false, String error = ''}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error.isNotEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error, textAlign: TextAlign.center, style: AppTextStyles.errorText)));
    }
    if (results.isEmpty) {
      return Center(child: Text('Không tìm thấy $type nào.', style: AppTextStyles.bodyRegular));
    }

    // CẬP NHẬT: Dùng CustomScrollView + SliverList
    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            switch (type) {
              case 'Thông báo':
                if (item is NewsArticle) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: InkWell(
                      onTap: () => launchUrlHelper(context, item.url, title: item.title),
                      child: NotificationCard(
                        imageUrl: AppAssets.defaultNotificationImage,
                        title: item.title,
                        date: item.date, // API đã format
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();

              case 'Bài viết':
                if (item is Post) { // Đã sửa
                  final avatarPlaceholder = 'https://placehold.co/80x80/${AppColors.secondary.value.toRadixString(16).substring(2)}/${AppColors.avatarPlaceholderText.value.toRadixString(16).substring(2)}?text=${item.author.username.isNotEmpty ? item.author.username[0].toUpperCase() : '?'}';
                  
                  // SỬ DỤNG HomePostCard (kiểu Facebook)
                  return HomePostCard( 
                    key: ValueKey(item.id),
                    post: item,
                    // avatarPlaceholder: avatarPlaceholder, // HomePostCard tự xử lý
                    username: _username,
                    onPostDeleted: () => _handlePostDeleted(item),
                    onPostUpdated: _handlePostUpdated,
                  );
                }
                return const SizedBox.shrink();

              case 'Tài liệu':
                if (item is Map<String, dynamic>) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  
                  );
                }
                return const SizedBox.shrink();

              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }
}

