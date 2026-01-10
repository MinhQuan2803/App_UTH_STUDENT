import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../config/app_theme.dart';
// Import các widget card cần tái sử dụng
import '../widgets/home_post_card.dart';
import '../widgets/user_list_item.dart';
import '../widgets/document_search_item.dart';
import '../widgets/shimmer_loading.dart';

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
  Timer? _debounceTimer;

  // Suggestions
  final List<String> _recentSearches = [
    'Lịch thi',
    'Thông báo học phí',
    'Đề cương môn học',
    'Lịch học kỳ 1',
  ];

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
    // Cancel timer cũ nếu có
    _debounceTimer?.cancel();

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

    // Tạo timer mới với delay 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performGlobalSearch();
    });
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
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Search Bar - Background phủ lên cả status bar
          _buildModernSearchBar(),
          // Tab Bar
          _buildTabBar(),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(),
                _buildPostList(),
                _buildDocumentList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Search Bar với gradient background - phủ lên cả status bar
  Widget _buildModernSearchBar() {
    // Lấy chiều cao status bar
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        // Padding compact như Facebook
        padding: EdgeInsets.fromLTRB(8, statusBarHeight + 8, 8, 8),
        child: Row(
          children: [
            // Back Button - compact
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.text, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            // Search TextField - chiếm nhiều space
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle: AppTextStyles.searchHint.copyWith(
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.subtitle,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.cancel,
                              color: AppColors.subtitle,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab Bar với hiệu ứng hiện đại
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.subtitle,
        labelStyle: AppTextStyles.tabLabel.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.tabLabel.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        onTap: (_) => setState(() {}),
        isScrollable: false,
        tabs: [
          _buildModernTab('Người dùng', _userCount, Icons.people_rounded),
          _buildModernTab('Bài viết', _postCount, Icons.article_rounded),
          _buildModernTab(
              'Tài liệu', _documentCount, Icons.description_rounded),
        ],
      ),
    );
  }

  // Modern Tab với icon - compact layout
  Widget _buildModernTab(String label, int count, IconData icon) {
    return Tab(
      height: 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Container(
              constraints: const BoxConstraints(minWidth: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Tab 1: Danh sách người dùng
  Widget _buildUserList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }
    if (_error.isNotEmpty) {
      return _buildErrorState(_error);
    }

    // Empty state với suggestions
    if (_searchController.text.isEmpty) {
      return _buildEmptySearchState(
        subtitle: 'Nhập tên hoặc username để tìm kiếm',
      );
    }

    if (_userResults.isEmpty) {
      return _buildNoResultState('Không tìm thấy người dùng nào');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _userResults.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 72,
        color: AppColors.divider,
      ),
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
      return _buildShimmerLoading();
    }
    if (_error.isNotEmpty) {
      return _buildErrorState(_error);
    }

    // Empty state
    if (_searchController.text.isEmpty) {
      return _buildEmptySearchState(
        subtitle: 'Tìm bài viết theo nội dung hoặc hashtag',
      );
    }

    if (_postResults.isEmpty) {
      return _buildNoResultState('Không tìm thấy bài viết nào');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _postResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      return _buildShimmerLoading();
    }
    if (_error.isNotEmpty) {
      return _buildErrorState(_error);
    }

    // Empty state
    if (_searchController.text.isEmpty) {
      return _buildEmptySearchState(
        subtitle: 'Tìm tài liệu học tập, đề thi, bài giảng',
      );
    }

    if (_documentResults.isEmpty) {
      return _buildNoResultState('Không tìm thấy tài liệu nào');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _documentResults.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final doc = _documentResults[index];
        return DocumentSearchItem(
          title: doc.title,
          description: doc.summary ?? '', // Sử dụng summary từ backend
          fileType: doc.type ?? 'FILE', // Sử dụng type từ backend
          price: doc.price,
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

  // Shimmer Loading
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  // Empty Search State với suggestions
  Widget _buildEmptySearchState({
    required String subtitle,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            subtitle,
            style: AppTextStyles.bodyRegular,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Search Suggestions
          if (_recentSearches.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tìm kiếm gần đây',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((query) {
                return _buildSuggestionChip(query);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // No Result State
  Widget _buildNoResultState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.subtitle.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: AppColors.subtitle.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử từ khóa khác hoặc kiểm tra chính tả',
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Error State
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã có lỗi xảy ra',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.errorText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _performGlobalSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Suggestion Chip
  Widget _buildSuggestionChip(String label) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _performGlobalSearch();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.suggestionChip.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
