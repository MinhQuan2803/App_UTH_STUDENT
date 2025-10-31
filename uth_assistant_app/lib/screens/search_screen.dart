import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import '../config/app_theme.dart';
// Import các widget card cần tái sử dụng
import '../widgets/notification_card.dart';
import '../widgets/home_post_card.dart'; // SỬ DỤNG WIDGET MỚI
import '../widgets/document_list_item.dart';
// Import Service và Utility
import '../services/news_service.dart';
import '../services/post_service.dart'; // Import service
import '../models/post_model.dart'; // Import model
import '../services/auth_service.dart'; // Import auth
import '../utils/launcher_util.dart';
import '../utils/time_formatter.dart'; // Import time formatter

// --- Dữ liệu mẫu (Giữ nguyên cho Tài liệu) ---
// Bỏ _mockPosts vì sẽ tải từ API
final List<Map<String, dynamic>> _mockDocuments = [
  {'type': 'Tài liệu', 'title': 'Bài tập lớn Cấu trúc dữ liệu', 'uploader': 'Trần Anh', 'fileType': 'DOCX'},
  {'type': 'Tài liệu', 'title': 'Tổng hợp công thức Excel', 'uploader': 'Mai Phương', 'fileType': 'XLSX'},
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
      final fetchedPosts = await _postService.getHomeFeed(page: 0, limit: 100, feed: 'public', forceRefresh: false); // Tải 100 posts
      if (!mounted) return;
      setState(() {
        _allPosts = fetchedPosts;
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

    final bool isSelected = _tabController.index ==

        ['Thông báo', 'Bài viết', 'Tài liệu'].indexOf(label);

    final Color textColor =

        isSelected ? AppColors.white : AppColors.white.withOpacity(0.7);



    return Tab(

      child: Stack(

        clipBehavior: Clip.none, // Cho phép hiển thị số bên ngoài Stack

        children: [

          // Tiêu đề chính của tab

          Padding(

            padding:

                const EdgeInsets.only(right: 12), // Tạo khoảng trống cho số

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
        // ... (Code AppBar giữ nguyên)
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

    // CẬP NHẬT: Dùng SliverList.builder bên trong CustomScrollView
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
                  
                  // SỬ DỤNG HomePostCard
                  return HomePostCard( 
                    key: ValueKey(item.id),
                    post: item,
                    avatarPlaceholder: avatarPlaceholder,
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
                    child: DocumentListItem(
                      fileType: item['fileType'] ?? 'N/A',
                      title: item['title'] ?? 'N/A',
                      uploader: item['uploader'] ?? 'N/A',
                    ),
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

