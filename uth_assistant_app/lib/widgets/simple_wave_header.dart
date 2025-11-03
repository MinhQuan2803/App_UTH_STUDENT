import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';

/// Header đơn giản với animation wave cho các tab screen
class SimpleWaveHeader extends StatefulWidget {
  final String title;
  final List<Widget>? actions; // Các nút action bên phải (optional)

  const SimpleWaveHeader({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  State<SimpleWaveHeader> createState() => _SimpleWaveHeaderState();
}

class _SimpleWaveHeaderState extends State<SimpleWaveHeader>
    with SingleTickerProviderStateMixin {
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
      height: 80,
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.appBarTitle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.actions != null) ...widget.actions!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
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
