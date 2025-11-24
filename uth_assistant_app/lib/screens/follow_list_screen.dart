import 'package:flutter/material.dart';
import '../config/app_theme.dart'; // Sử dụng lại theme của ProfileScreen
import '../services/follow_service.dart';
import '../services/auth_service.dart';

class FollowListScreen extends StatefulWidget {
  final String username;
  final int initialIndex; // 0: Đang follow, 1: Follower

  const FollowListScreen({
    super.key,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field
  final FollowService _followService = FollowService();
  // ignore: unused_field
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _followingList = [];
  List<Map<String, dynamic>> _followersList = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 2 tab: Đang follow và Follower
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // --- MÔ PHỎNG DATA ---
    await Future.delayed(const Duration(milliseconds: 500)); 

    _followingList = List.generate(12, (index) => {
      'id': 'following_$index',
      'username': index % 2 == 0 ? 'WHY.NOT STORE' : 'Thanh Phương $index',
      'avatarUrl': 'https://i.pravatar.cc/150?img=${index + 10}',
      'bio': index % 2 == 0 ? 'Ghé thăm cửa hàng >' : 'Xem phần trưng bày >',
      'isFollowing': true, // Tab Đang follow thì chắc chắn là true
    });

    _followersList = List.generate(20, (index) => {
      'id': 'follower_$index',
      'username': 'Người hâm mộ $index',
      'avatarUrl': 'https://i.pravatar.cc/150?img=${index + 30}',
      'bio': 'Đang theo dõi bạn',
      'isFollowing': index % 3 == 0, // Một số người mình đã follow lại, một số chưa
    });
    // ---------------------

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Nền trắng giống ProfileScreen
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0.5, // Đổ bóng nhẹ ngăn cách header
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: AppTextStyles.usernamePacifico.copyWith(fontSize: 20,color: AppColors.text),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.transparent)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryDark, // Màu chữ khi chọn (Đen)
              unselectedLabelColor: Colors.grey, // Màu chữ khi không chọn (Xám)
              indicatorColor: AppColors.primaryDark, // Gạch chân màu đen
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label, // Gạch chân chỉ dài bằng chữ
              labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 15),
              unselectedLabelStyle: AppTextStyles.bodyRegular.copyWith(fontSize: 15),
              tabs: [
                Tab(text: 'Người theo dõi ${_followingList.length}'),
                Tab(text: 'Đang theo dõi ${_followersList.length}'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildListContent(_followingList, isFollowingTab: true),
              _buildListContent(_followersList, isFollowingTab: false),
            ],
          ),
    );
  }

  Widget _buildListContent(List<Map<String, dynamic>> users, {required bool isFollowingTab}) {
    return Column(
      children: [
        // 1. Thanh tìm kiếm (Giống TikTok: Nằm ngay dưới Tab)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100], // Màu nền xám nhạt
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                hintStyle: AppTextStyles.bodyRegular.copyWith(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8), // Căn giữa text
              ),
              style: AppTextStyles.bodyRegular,
            ),
          ),
        ),

        // 2. Tiêu đề danh sách (Optional: "Đã follow")
        if (users.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFollowingTab ? 'Đã follow' : 'Tất cả follower', 
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: Colors.grey[800]),
                ),
                // Nút sắp xếp (như hình mẫu)
                Row(
                  children: [
                    Text(
                      'Sắp xếp theo Mặc định', 
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                  ],
                )
              ],
            ),
          ),

        // 3. Danh sách người dùng
        Expanded(
          child: users.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserItem(users[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    // Logic nút bấm:
    // - Nếu đang follow -> Hiện "Đã follow" (Nền xám, chữ đen)
    // - Nếu chưa follow -> Hiện "Follow" (Nền đỏ/primary, chữ trắng)
    bool isFollowing = user['isFollowing'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Khoảng cách giữa các item
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: CircleAvatar(
              radius: 28, // Kích thước avatar
              backgroundImage: NetworkImage(user['avatarUrl']),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 12),
          
          // Info (Tên & Bio)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user['bio'] ?? '',
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Action Button
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  user['isFollowing'] = !isFollowing;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey[200] : AppColors.primary,
                foregroundColor: isFollowing ? AppColors.text : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // Bo góc nhẹ giống hình
                ),
              ),
              child: Text(
                isFollowing ? 'Đã follow' : 'Follow',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFollowing ? AppColors.text : Colors.white,
                ),
              ),
            ),
          ),
          
          // Menu Icon (3 chấm)
          const SizedBox(width: 8),
          const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Chưa có dữ liệu', 
            style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}