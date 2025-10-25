import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/notification_card.dart';
import '../widgets/animated_wave_header.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/news_service.dart';
import '../utils/launcher_util.dart';

class HomeScreen extends StatefulWidget {
  final PageController pageController;
  const HomeScreen({super.key, required this.pageController});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String _error = '';

  final NewsService _newsService = NewsService();
  final String defaultImageUrl = AppAssets.defaultNotificationImage;

  @override
  void initState() {
    super.initState();
    _fetchNewsData();
  }

  Future<void> _fetchNewsData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final fetchedArticles = await _newsService.fetchNews();
      if (!mounted) return;
      setState(() {
        _articles = fetchedArticles;
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

  // Hàm điều hướng đến màn hình tìm kiếm
  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          _buildHeader(context),
          _buildNotificationSection(),
          // BỎ SearchBarWidget ở đây
          // const SliverToBoxAdapter(child: SearchBarWidget()),
          _buildFeedTitle(),
          _buildPostList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 50.0,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedWaveHeader(
          // Truyền hàm điều hướng vào header
          onSearchPressed: _navigateToSearch,
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
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thông báo Đào tạo', style: AppTextStyles.sectionTitle),
                TextButton(
                  onPressed: () {
                    // Gọi hàm mở link với URL mới và tiêu đề
                    launchUrlHelper(
                      context,
                      'https://portal.ut.edu.vn/newfeeds/368', // URL mới
                      title: 'Thông báo', // Tiêu đề cho WebView
                    );
                  },
                  child: const Text('Xem tất cả', style: AppTextStyles.linkText),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 175,
            child: _buildNewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(child: Text("Không có thông báo nào."));
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
              launchUrlHelper(context, article.url);
            },
            child: NotificationCard(
              imageUrl: defaultImageUrl,
              title: article.title,
              date: article.date,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 4), // Tăng padding top
        child: Text('Cộng đồng sinh viên', style: AppTextStyles.sectionTitle),
      ),
    );
  }

 Widget _buildPostList() {
   final List<Map<String, dynamic>> posts = [
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Lê Nguyễn',
    'time': '1 giờ trước',
    'major': 'Kinh tế Vận tải',
    'content': 'Mọi người có ai có đề cương môn Kinh tế Vận tải biển không ạ? Cho mình xin với...',
    'backgroundColor': const Color(0xFFFFF0F5),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Mai Phương',
    'time': '2 giờ trước',
    'major': 'Công nghệ thông tin',
    'content': 'Có bạn nào biết cách đăng ký học phần online không? Chỉ giúp mình với! Các bước thực hiện như thế nào nhỉ?',
    'backgroundColor': const Color(0xFFFFFAF0),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Trần Anh',
    'time': '5 giờ trước',
    'major': 'Logistics',
    'content': 'Review công ty thực tập ABC nè mọi người.',
    'backgroundColor': const Color(0xFFF0F4FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Ngọc Hà',
    'time': '1 ngày trước',
    'major': 'Xây dựng',
    'content': 'Tìm bạn học chung môn Sức bền vật liệu :D',
    'backgroundColor': const Color(0xFFF0FFF4),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Hoàng Việt',
    'time': '3 giờ trước',
    'major': 'Điện tử Viễn thông',
    'content': 'Có ai làm đồ án môn Vi xử lý chưa? Mình cần tham khảo một số ý tưởng về đề tài.',
    'backgroundColor': const Color(0xFFF3F0FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Phương Anh',
    'time': '4 giờ trước',
    'major': 'Quản trị kinh doanh',
    'content': 'Share tài liệu Marketing căn bản cho các bạn mới học nè!',
    'backgroundColor': const Color(0xFFFFF5F7),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Minh Quân',
    'time': '6 giờ trước',
    'major': 'Kỹ thuật Cơ khí',
    'content': 'Hôm nay vừa đi thực tập tại nhà máy sản xuất ô tô. Trải nghiệm thật tuyệt vời, học được nhiều kiến thức thực tế!',
    'backgroundColor': const Color(0xFFF0F4FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Thanh Tú',
    'time': '8 giờ trước',
    'major': 'Ngôn ngữ Anh',
    'content': 'Có group học IELTS không ạ? Mình đang tìm bạn luyện speaking cùng.',
    'backgroundColor': const Color(0xFFFFFAF0),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Bảo Trâm',
    'time': '10 giờ trước',
    'major': 'Tài chính - Ngân hàng',
    'content': 'Deadline nộp bài tập lớn môn Phân tích tài chính là khi nào nhỉ?',
    'backgroundColor': const Color(0xFFF0FFF4),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Đức Anh',
    'time': '12 giờ trước',
    'major': 'Kinh tế Vận tải',
    'content': 'Mình vừa tìm được internship tại công ty Logistics lớn. Ai cần CV mẫu inbox nhé!',
    'backgroundColor': const Color(0xFFFFF0F5),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Khánh Linh',
    'time': '1 ngày trước',
    'major': 'Công nghệ thông tin',
    'content': 'Có ai biết cách fix lỗi "Null pointer exception" trong Java không? Mình đang bí quá 😭',
    'backgroundColor': const Color(0xFFF3F0FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Tuấn Kiệt',
    'time': '1 ngày trước',
    'major': 'Xây dựng',
    'content': 'Team mình đang thiếu người làm đồ án Kết cấu bê tông. Ai có hứng thú join không?',
    'backgroundColor': const Color(0xFFFFF5F7),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Mỹ Duyên',
    'time': '1 ngày trước',
    'major': 'Logistics',
    'content': 'Chia sẻ bí kíp đạt điểm cao môn Quản trị chuỗi cung ứng cho các bạn nè!',
    'backgroundColor': const Color(0xFFF0F4FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Hải Đăng',
    'time': '2 ngày trước',
    'major': 'Điện tử Viễn thông',
    'content': 'Lịch thi cuối kỳ đã ra chưa các bạn? Mình chưa thấy thông báo gì cả.',
    'backgroundColor': const Color(0xFFFFFAF0),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Thu Hằng',
    'time': '2 ngày trước',
    'major': 'Quản trị kinh doanh',
    'content': 'Hội thảo Khởi nghiệp tại trường vào T7 tuần này. Ai có ý tưởng startup thú vị thì tham gia nha!',
    'backgroundColor': const Color(0xFFF0FFF4),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Quốc Bảo',
    'time': '2 ngày trước',
    'major': 'Kỹ thuật Cơ khí',
    'content': 'Mình vừa pass môn CAD/CAM với điểm 9.5. Có bạn nào cần ôn tập không?',
    'backgroundColor': const Color(0xFFF3F0FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Lan Anh',
    'time': '3 ngày trước',
    'major': 'Ngôn ngữ Anh',
    'content': 'Chia sẻ một số mẹo học từ vựng TOEIC hiệu quả mà mình đang áp dụng.',
    'backgroundColor': const Color(0xFFFFF0F5),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Thành Đạt',
    'time': '3 ngày trước',
    'major': 'Tài chính - Ngân hàng',
    'content': 'Có ai biết thầy nào dạy môn Đầu tư chứng khoán dễ hiểu không? Mình đang băn khoăn chọn lớp.',
    'backgroundColor': const Color(0xFFFFF5F7),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Gia Hân',
    'time': '3 ngày trước',
    'major': 'Kinh tế Vận tải',
    'content': 'Cần tìm tài liệu về Quản lý cảng biển. Ai có thể share cho mình với!',
    'backgroundColor': const Color(0xFFF0F4FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Minh Tuấn',
    'time': '4 ngày trước',
    'major': 'Công nghệ thông tin',
    'content': 'Hôm nay mình vừa hoàn thành project React Native đầu tiên. Cảm giác thật tuyệt! 🎉',
    'backgroundColor': const Color(0xFFFFFAF0),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Huyền Trang',
    'time': '4 ngày trước',
    'major': 'Xây dựng',
    'content': 'Tuyển thêm 2 bạn vào nhóm làm đồ án Thiết kế kiến trúc. Liên hệ mình nhé!',
    'backgroundColor': const Color(0xFFF0FFF4),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Phúc An',
    'time': '5 ngày trước',
    'major': 'Logistics',
    'content': 'Ngày mai có ai đi thư viện học nhóm không? Mình book phòng rồi, thiếu 2 người.',
    'backgroundColor': const Color(0xFFF3F0FF),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Thu Thảo',
    'time': '5 ngày trước',
    'major': 'Điện tử Viễn thông',
    'content': 'Có ai tham gia cuộc thi Robotics sắp tới không? Cùng nhau chia sẻ kinh nghiệm nào!',
    'backgroundColor': const Color(0xFFFFF0F5),
  },
  {
    'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
    'name': 'Công Minh',
    'time': '1 tuần trước',
    'major': 'Quản trị kinh doanh',
    'content': 'Share case study về chiến lược Marketing của Apple. Rất hay và bổ ích!',
    'backgroundColor': const Color(0xFFFFF5F7),
  },
];

    // Sử dụng SliverMasonryGrid thay cho SliverList
    return SliverPadding( // Thêm Padding bao quanh lưới
       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
       sliver: SliverMasonryGrid.count(
        crossAxisCount: 2, // Số cột
        mainAxisSpacing: 8, // Khoảng cách dọc
        crossAxisSpacing: 8, // Khoảng cách ngang
        childCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          // BỌC PostCard BẰNG GestureDetector VÀ THÊM onTap
          return GestureDetector(
            onTap: () {
              // Điều hướng đến màn hình chi tiết, truyền dữ liệu post đi
              Navigator.pushNamed(context, '/post_detail', arguments: post);
            },
            child: PostCard(
              avatarUrl: post['avatarUrl'] ?? '',
              name: post['name'] ?? 'Người dùng ẩn',
              time: post['time'] ?? 'Vừa xong',
              major: post['major'] ?? 'Chuyên ngành chung',
              content: post['content'] ?? 'Nội dung không có sẵn.',
              likes: post['likes'] ?? 0,
              comments: post['comments'] ?? 0,
              isLiked: post['isLiked'] ?? false,
              backgroundColor: post['backgroundColor'],
            ),
          );
        },
      ),
    );
  }
}

