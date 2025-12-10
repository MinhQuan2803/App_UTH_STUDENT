import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../config/app_theme.dart'; // Import AppTheme
import '../screens/image_viewer_screen.dart'; // Import ImageViewer

class AnimatedWaveHeader extends StatefulWidget {
  final VoidCallback? onSearchPressed;
  final VoidCallback? onNotificationPressed;
  final String username;
  final String? avatarUrl; // Avatar từ server
  final VoidCallback? onProfileTap; // Callback khi nhấn vào profile
  final int unreadCount; // Số thông báo chưa đọc

  const AnimatedWaveHeader({
    super.key,
    this.onSearchPressed,
    this.onNotificationPressed,
    required this.username,
    this.avatarUrl,
    this.onProfileTap,
    this.unreadCount = 0,
  });

  @override
  State<AnimatedWaveHeader> createState() => _AnimatedWaveHeaderState();
}

class _AnimatedWaveHeaderState extends State<AnimatedWaveHeader>
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
    // Tạo avatar URL: ưu tiên từ server, nếu null thì dùng placeholder
    final String displayAvatarUrl = widget.avatarUrl ??
        'https://ui-avatars.com/api/?name=${widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?'}&background=${AppColors.primary.value.toRadixString(16).substring(2)}&color=fff&size=80&bold=true';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
                  // Avatar: Nhấn để xem ảnh full screen
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            imageUrls: [displayAvatarUrl],
                            initialIndex: 0,
                            title: widget.username,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.avatarBorder,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(displayAvatarUrl),
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Username: Nhấn để đến profile
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Chào bạn,',
                              style: AppTextStyles.headerGreeting),
                          const SizedBox(height: 0),
                          Text(widget.username,
                              style: AppTextStyles.usernamePacifico.copyWith(
                                  color: AppColors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  // Nút Tìm kiếm
                  IconButton(
                    icon: SvgPicture.asset(AppAssets.iconSearch,
                        width: 22,
                        colorFilter: const ColorFilter.mode(
                            AppColors.white, BlendMode.srcIn)),
                    onPressed: widget.onSearchPressed,
                  ),
                  // Nút Thông báo với badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(AppAssets.iconBell,
                            width: 22,
                            colorFilter: const ColorFilter.mode(
                                AppColors.white, BlendMode.srcIn)),
                        onPressed: widget.onNotificationPressed,
                      ),
                      if (widget.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              widget.unreadCount > 99
                                  ? '99+'
                                  : '${widget.unreadCount}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
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
