import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../config/app_theme.dart'; // Import AppTheme

class AnimatedWaveHeader extends StatefulWidget {
  final VoidCallback? onSearchPressed;
  
  // --- 1. THÊM BIẾN NÀY ĐỂ NHẬN USERNAME ---
  final String username;

  const AnimatedWaveHeader({
    super.key, 
    this.onSearchPressed,
    required this.username, // <-- 2. THÊM VÀO CONSTRUCTOR
  });

  @override
  State<AnimatedWaveHeader> createState() => _AnimatedWaveHeaderState();
}

class _AnimatedWaveHeaderState extends State<AnimatedWaveHeader> with SingleTickerProviderStateMixin {
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
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: WavePainter(animation: _controller),
                size: Size.infinite,
              );
            },
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.avatarBorder,
                    child: const CircleAvatar(
                      radius: 20,
                      // TODO: Bạn cũng nên cập nhật avatar này động
                      backgroundImage: NetworkImage(
                          'https://daotao.ut.edu.vn/wp-content/uploads/2023/10/1_1677313062_324244885_660178202558079_4009191385075749836_n.jpg'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column( // <-- Bỏ 'const' ở đây
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chào bạn,', style: AppTextStyles.headerGreeting),
                      // --- 3. SỬA DÒNG NÀY ---
                      // Bỏ 'const' và dùng 'widget.username'
                      Text(widget.username, style: AppTextStyles.headerName),
                    ],
                  ),
                  const Spacer(),
                  // Nút Tìm kiếm
                  IconButton(
                    icon: SvgPicture.asset(AppAssets.iconSearch,
                        width: 22,
                        colorFilter: const ColorFilter.mode(
                            AppColors.white, BlendMode.srcIn)),
                    onPressed: widget.onSearchPressed,
                  ),
                  // Nút Thông báo
                  IconButton(
                    icon: SvgPicture.asset(AppAssets.iconBell,
                        width: 22,
                        colorFilter: const ColorFilter.mode(
                            AppColors.white, BlendMode.srcIn)),
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

// Lớp WavePainter (Giữ nguyên, không thay đổi)
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // ... (Toàn bộ code của paint giữ nguyên) ...
    final paint1 = Paint()
      ..color = AppColors.headerWave1
      ..style = PaintingStyle.fill;
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.7 +
            math.sin((i / size.width * 2 * math.pi) +
                (animation.value * 2 * math.pi)) *
            10,
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = AppColors.headerWave2
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.75 +
            math.sin((i / size.width * 2 * math.pi) -
                (animation.value * 2 * math.pi) +
                1) *
            15,
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