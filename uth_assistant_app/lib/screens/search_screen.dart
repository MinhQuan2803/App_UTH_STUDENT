import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
// Import các widget card cần tái sử dụng
import '../widgets/notification_card.dart';
import '../widgets/post_card.dart';
import '../widgets/document_list_item.dart';
// Import Service và Utility
import '../services/news_service.dart';
import '../utils/launcher_util.dart'; // Import launcher_util

// --- Dữ liệu mẫu (Giữ nguyên cho Bài viết và Tài liệu) ---
final List<Map<String, dynamic>> _mockPosts = [
  {'type': 'Bài viết', 'title': 'Đề cương môn Kinh tế Vận tải biển', 'name': 'Lê Nguyễn', 'time': '1 giờ trước', 'major': 'Kinh tế Vận tải','content': 'Nội dung bài viết...', 'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg', 'backgroundColor': AppColors.postBackgrounds[0]},
  {'type': 'Bài viết', 'title': 'Cách đăng ký học phần online?', 'name': 'Mai Phương', 'time': '3 giờ trước', 'major': 'Công nghệ thông tin', 'content': 'Nội dung bài viết khác...', 'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg', 'backgroundColor': AppColors.postBackgrounds[1]},
];
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
  List<NewsArticle> _allNotifications = []; // Lưu trữ dữ liệu gốc từ API
  final List<Map<String, dynamic>> _allPosts = List.from(_mockPosts);
  final List<Map<String, dynamic>> _allDocuments = List.from(_mockDocuments);

  // Danh sách kết quả đã lọc
  List<NewsArticle> _notificationResults = []; // Dùng NewsArticle
  List<Map<String, dynamic>> _postResults = [];
  List<Map<String, dynamic>> _documentResults = [];

  // Biến đếm kết quả
  int _notificationCount = 0;
  int _postCount = 0;
  int _documentCount = 0;

  // Trạng thái tải dữ liệu tin tức
  bool _isLoadingNews = true;
  String _newsError = '';
  final NewsService _newsService = NewsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNewsData(); // Gọi API để lấy tin tức
    _filterResults(); // Lọc ban đầu (chủ yếu cho mock data)
    _searchController.addListener(_filterResults);
  }

  // Hàm gọi API lấy tin tức
  Future<void> _fetchNewsData() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = '';
    });
    try {
      final fetchedArticles = await _newsService.fetchNews();
      if (!mounted) return;
      setState(() {
        _allNotifications = fetchedArticles; // Lưu dữ liệu gốc
        _isLoadingNews = false;
        _filterResults(); // Lọc lại sau khi có dữ liệu mới
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _newsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingNews = false;
        _filterResults(); // Vẫn lọc lại (dù có lỗi)
      });
    }
  }

  void _filterResults() {
    final query = _searchController.text.toLowerCase().trim();

    // Lọc tin tức từ dữ liệu API gốc
    List<NewsArticle> tempNotifications;
    if (query.isEmpty) {
      tempNotifications = List.from(_allNotifications);
    } else {
      tempNotifications = _allNotifications.where((item) =>
        item.title.toLowerCase().contains(query) // Lọc theo title của NewsArticle
      ).toList();
    }

    // Lọc bài viết và tài liệu từ dữ liệu mẫu gốc
    List<Map<String, dynamic>> tempPosts;
    List<Map<String, dynamic>> tempDocuments;
    if (query.isEmpty) {
      tempPosts = List.from(_allPosts);
      tempDocuments = List.from(_allDocuments);
    } else {
      tempPosts = _allPosts.where((item) =>
        (item['title']?.toLowerCase().contains(query) ?? false) ||
        (item['content']?.toLowerCase().contains(query) ?? false) ||
        (item['name']?.toLowerCase().contains(query) ?? false)
      ).toList();
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
          // Truyền các danh sách kết quả đã lọc vào _buildResultList
          _buildResultList(_notificationResults, 'Thông báo', isLoading: _isLoadingNews, error: _newsError),
          _buildResultList(_postResults, 'Bài viết'),
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
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger))));
    }
    if (results.isEmpty) {
      return Center(child: Text('Không tìm thấy $type nào.', style: AppTextStyles.bodyRegular));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        // Sử dụng widget tương ứng dựa trên loại
        switch (type) {
          case 'Thông báo':
            // Đảm bảo item là NewsArticle
            if (item is NewsArticle) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell( // Thêm InkWell để mở link
                   onTap: () => launchUrlHelper(context, item.url),
                   child: NotificationCard(
                    // Lấy dữ liệu từ NewsArticle object
                    imageUrl: AppAssets.defaultNotificationImage, // Vẫn dùng ảnh mặc định
                    title: item.title,
                    date: item.date,
                  ),
                )
              );
            }
            return const SizedBox.shrink(); // Bỏ qua nếu kiểu dữ liệu không đúng

          case 'Bài viết':
             if (item is Map<String, dynamic>) { // Kiểm tra kiểu dữ liệu
               return Padding(
                 padding: const EdgeInsets.only(bottom: 10),
                 child: PostCard(
                   avatarUrl: item['avatarUrl'] ?? '',
                   name: item['name'] ?? 'N/A',
                   time: item['time'] ?? '',
                   major: item['major'] ?? '',
                   content: item['content'] ?? '',
                   backgroundColor: item['backgroundColor'],
                 ),
               );
             }
             return const SizedBox.shrink();

          case 'Tài liệu':
             if (item is Map<String, dynamic>) { // Kiểm tra kiểu dữ liệu
               return Padding(
                 padding: const EdgeInsets.only(bottom: 10),
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
    );
  }
}

