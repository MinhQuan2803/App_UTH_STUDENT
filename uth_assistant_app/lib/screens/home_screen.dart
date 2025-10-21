import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/notification_card.dart';
import '../widgets/status_update_card.dart';

class HomeScreen extends StatelessWidget {
  final PageController pageController;

  const HomeScreen({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          _buildHeader(context),
          _buildNotificationSection(),
          _buildStatusUpdateCard(),
          _buildFeedTitle(),
          _buildPostList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 50.0,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: _AnimatedWaveHeader(),
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
                  onPressed: () {},
                  child: const Text('Xem tất cả', style: AppTextStyles.linkText),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 165,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: const [
                NotificationCard(
                  imageUrl: 'https://daotao.ut.edu.vn/wp-content/uploads/2023/10/Hinh-truong-DHGTVT-TPHCM-768x481.jpg',
                  title: 'UTH thăm và làm việc với Viện kỹ thuật đường sắt...',
                  date: '20/10/2025',
                ),
                SizedBox(width: 10),
                NotificationCard(
                  imageUrl: 'https://daotao.ut.edu.vn/wp-content/uploads/2023/10/1_1677313062_324244885_660178202558079_4009191385075749836_n.jpg',
                  title: 'UTH và CRRC viện thực tập sinh viên khóa mới',
                  date: '18/10/2025',
                ),
                SizedBox(width: 10),
                NotificationCard(
                  imageUrl: 'https://daotao.ut.edu.vn/wp-content/uploads/2023/10/1_1677313062_324244885_660178202558079_4009191385075749836_n.jpg',
                  title: 'Thông báo về lịch nghỉ lễ Quốc Khánh 2-9',
                  date: '15/10/2025',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateCard() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: StatusUpdateCard(),
      ),
    );
  }

  Widget _buildFeedTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
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
        'backgroundColor': const Color(0xFFFFF0F5), // Màu tùy chọn
      },
      {
        'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
        'name': 'Mai Phương',
        'time': '2 giờ trước',
        'major': 'Công nghệ thông tin',
        'content': 'Có bạn nào biết cách đăng ký học phần online không? Chỉ giúp mình với!',
        'backgroundColor': const Color(0xFFFFFAF0), // Hoặc bỏ qua thuộc tính này
      },
      {
        'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
        'name': 'Trần Anh',
        'time': '3 giờ trước',
        'major': 'Quản trị kinh doanh',
      'backgroundColor': const Color(0xFFF0FFF4), // Hoặc bỏ qua thuộc tính này
        'content': 'Nhóm mình đang tuyển thêm thành viên cho dự án khởi nghiệp, ai quan tâm inbox nhé!',
      },
      {
        'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
        'name': 'Ngọc Hân',
        'time': '4 giờ trước',
        'major': 'Kỹ thuật xây dựng',
        'content': 'Có ai có tài liệu môn Vật liệu xây dựng không? Xin cảm ơn!',
      },
      {
        'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
        'name': 'Minh Quân',
        'time': '5 giờ trước',
        'major': 'Logistics',
        'content': 'Chia sẻ kinh nghiệm thực tập tại cảng Cát Lái, ai cần thì hỏi nhé!',
      },
      {
        'avatarUrl': 'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
        'name': 'Bảo Trâm',
        'time': '6 giờ trước',
        'major': 'Tài chính',
        'content': 'Có ai biết deadline nộp học phí kỳ này không ạ?',
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: PostCard(
              avatarUrl: post['avatarUrl'] ?? '',
              name: post['name'] ?? 'Người dùng ẩn',
              time: post['time'] ?? 'Vừa xong',
              major: post['major'] ?? 'Chuyên ngành chung',
              content: post['content'] ?? 'Nội dung không có sẵn.',
              backgroundColor: post['backgroundColor'], // Sử dụng màu nền tùy chọn
            ),
          );
        },
        childCount: posts.length,
      ),
    );
  }
}

// WIDGET MỚI: TẠO HEADER VỚI HIỆU ỨNG SÓNG ĐỘNG
class _AnimatedWaveHeader extends StatefulWidget {
  const _AnimatedWaveHeader();

  @override
  State<_AnimatedWaveHeader> createState() => _AnimatedWaveHeaderState();
}

class _AnimatedWaveHeaderState extends State<_AnimatedWaveHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // SỬ DỤNG BIẾN TỪ APP THEME
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Lớp sóng động
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _WavePainter(animation: _controller),
                size: Size.infinite,
              );
            },
          ),
          // Lớp nội dung (avatar, tên,...)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    // SỬ DỤNG BIẾN TỪ APP THEME
                    backgroundColor: AppColors.avatarBorder,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage('https://daotao.ut.edu.vn/wp-content/uploads/2023/10/1_1677313062_324244885_660178202558079_4009191385075749836_n.jpg'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Chào bạn,', style: AppTextStyles.headerGreeting),
                      Text('Mai Phương', style: AppTextStyles.headerName),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: SvgPicture.asset(AppAssets.iconBell, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CUSTOM PAINTER MỚI ĐỂ VẼ SÓNG
class _WavePainter extends CustomPainter {
  final Animation<double> animation;

  _WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (phía sau)
    final paint1 = Paint()
      // SỬ DỤNG BIẾN TỪ APP THEME
      ..color = AppColors.headerWave1
      ..style = PaintingStyle.fill;
      
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.7 + math.sin((i / size.width * 2 * math.pi) + (animation.value * 2 * math.pi)) * 10,
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Sóng 2 (phía trước)
    final paint2 = Paint()
      // SỬ DỤNG BIẾN TỪ APP THEME
      ..color = AppColors.headerWave2
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.75 + math.sin((i / size.width * 2 * math.pi) - (animation.value * 2 * math.pi) + 1) * 15,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

