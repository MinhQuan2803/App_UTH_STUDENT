import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import '../config/app_theme.dart';
// Import các widget card cần tái sử dụng
import '../widgets/home_post_card.dart';
import '../widgets/user_list_item.dart';
import '../widgets/document_search_item.dart';

// Import Service
import '../services/search_service.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Kết quả từ Global Search API
  List<SearchUser> _userResults = [];
  List<Post> _postResults = [];
  List<SearchDocument> _documentResults = [];

  // Biến đếm kết quả
  int _userCount = 0;
  int _postCount = 0;
  int _documentCount = 0;

  // Trạng thái tải dữ liệu
  bool _isLoading = false;
  String _error = '';

  final SearchService _searchService = SearchService();
  final AuthService _authService = AuthService();
  String? _username;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsername();
    // Lắng nghe thay đổi search query
    _searchController.addListener(_onSearchChanged);
  }

  // Debounce search để tránh gọi API quá nhiều
  void _onSearchChanged() {
    // Nếu query rỗng, clear results
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _userResults = [];
        _postResults = [];
        _documentResults = [];
        _userCount = 0;
        _postCount = 0;
        _documentCount = 0;
        _error = '';
      });
      return;
    }
    // Nếu có query, gọi API
    _performGlobalSearch();
  }

  // Gọi Global Search API
  Future<void> _performGlobalSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await _searchService.globalSearch(query);
      if (!mounted) return;

      setState(() {
        _userResults = results['users'] ?? [];
        _postResults = results['posts'] ?? [];
        _documentResults = results['documents'] ?? [];
        _userCount = _userResults.length;
        _postCount = _postResults.length;
        _documentCount = _documentResults.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
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

  // Xử lý khi có callback từ HomePostCard
  void _handlePostDeleted(Post post) {
    setState(() {
      _postResults.removeWhere((p) => p.id == post.id);
      _postCount = _postResults.length;
    });
  }

  void _handlePostUpdated() {
    // Gọi lại search để refresh data
    _performGlobalSearch();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTab(String label, int count) {
    final bool isSelected = _tabController.index ==
        ['Người dùng', 'Bài viết', 'Tài liệu'].indexOf(label);
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleSpacing: 0, // Xóa khoảng cách mặc định của title
        title: Row(
          children: [
            // Icon tìm kiếm đặt bên ngoài TextField
            Padding(
              padding: const EdgeInsets.only(
                  left: 0, right: 8.0), // Giảm padding trái
              child: SvgPicture.asset(
                AppAssets.iconSearch,
                colorFilter: ColorFilter.mode(
                    AppColors.white.withOpacity(0.7), BlendMode.srcIn),
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
                  hintStyle: AppTextStyles.searchHint
                      .copyWith(color: AppColors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14), // Thêm padding dọc
                  isCollapsed:
                      true, // Thêm dòng này để loại bỏ padding mặc định
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.white, size: 20),
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
            _buildTab('Người dùng', _userCount),
            _buildTab('Bài viết', _postCount),
            _buildTab('Tài liệu', _documentCount),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(),
          _buildPostList(),
          _buildDocumentList(),
        ],
      ),
    );
  }

  // Tab 1: Danh sách người dùng
  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error,
              textAlign: TextAlign.center, style: AppTextStyles.errorText),
        ),
      );
    }
    if (_userResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Nhập từ khóa để tìm kiếm người dùng...'
              : 'Không tìm thấy người dùng nào.',
          style: AppTextStyles.bodyRegular,
        ),
      );
    }

    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return UserListItem(
          username: user.username,
          avatarUrl: user.avatarUrl,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: {'username': user.username},
            );
          },
        );
      },
    );
  }

  // Tab 2: Danh sách bài viết
  Widget _buildPostList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error,
              textAlign: TextAlign.center, style: AppTextStyles.errorText),
        ),
      );
    }
    if (_postResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Nhập từ khóa để tìm kiếm bài viết...'
              : 'Không tìm thấy bài viết nào.',
          style: AppTextStyles.bodyRegular,
        ),
      );
    }

    return ListView.builder(
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return HomePostCard(
          post: post,
          onPostDeleted: () => _handlePostDeleted(post),
          onPostUpdated: _handlePostUpdated,
          currentUsername: _username ?? '',
        );
      },
    );
  }

  // Tab 3: Danh sách tài liệu
  Widget _buildDocumentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error,
              textAlign: TextAlign.center, style: AppTextStyles.errorText),
        ),
      );
    }
    if (_documentResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Nhập từ khóa để tìm kiếm tài liệu...'
              : 'Không tìm thấy tài liệu nào.',
          style: AppTextStyles.bodyRegular,
        ),
      );
    }

    return ListView.builder(
      itemCount: _documentResults.length,
      itemBuilder: (context, index) {
        final doc = _documentResults[index];
        return DocumentSearchItem(
          title: doc.title,
          description: doc.description ?? '',
          uploaderUsername: doc.uploaderUsername ?? 'Unknown',
          uploaderAvatar: doc.uploaderAvatar,
          fileType: doc.fileType ?? 'FILE',
          price: doc.price,
          downloads: doc.downloads,
          onTap: () {
            // Navigate tới document detail screen
            Navigator.pushNamed(
              context,
              '/document_detail',
              arguments: {'documentId': doc.id},
            );
          },
        );
      },
    );
  }
}
