import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Animation cho 3 chấm loading
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Hiển thị splash 2 giây rồi check token và chuyển màn hình
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // BƯỚC 1: Kiểm tra token offline trước (không gọi API)
      final storedToken = await _authService.getToken();

      if (storedToken == null || storedToken.isEmpty) {
        // Không có token -> Chuyển về login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // BƯỚC 2: Có token -> Cố gắng lấy valid token (có thể refresh)
      // Tắt autoRedirect để không bị logout tự động khi lỗi mạng
      final token = await _authService.getValidToken(autoRedirect: false);

      if (!mounted) return;

      if (token != null) {
        // Token OK -> Check profile completion
        final isProfileCompleted = await _authService.isProfileCompleted();

        if (isProfileCompleted) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/complete_profile');
        }
      } else {
        // Token không valid và không refresh được
        // (có thể là hết hạn thật sự hoặc server từ chối)
        // Kiểm tra lại xem còn token trong storage không
        final stillHasToken = await _authService.getToken();

        if (stillHasToken != null) {
          // Vẫn còn token nhưng không validate được -> Vào app thôi
          // (Có thể là lỗi mạng, để user dùng chức năng offline)
          final isProfileCompleted = await _authService.isProfileCompleted();

          if (isProfileCompleted) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/complete_profile');
          }
        } else {
          // Token đã bị xóa (signOut) -> Login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // Lỗi bất ngờ -> Kiểm tra xem có token không
      if (mounted) {
        final hasToken = await _authService.getToken();
        if (hasToken != null) {
          // Có token -> Vào app (offline mode)
          final isProfileCompleted = await _authService.isProfileCompleted();

          if (isProfileCompleted) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/complete_profile');
          }
        } else {
          // Không có token -> Login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              AppAssets.splashLogo,
              width: MediaQuery.of(context).size.width * 1,
            ),

            const SizedBox(height: 40),

            // 3 chấm loading
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.33;
                    final value = (_animationController.value - delay) % 1.0;
                    final opacity =
                        (value < 0.5) ? value * 2 : (1.0 - value) * 2;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Opacity(
                        opacity: opacity.clamp(0.2, 1.0),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 16),

            // Text "Đang kết nối..."
            Text(
              'Đang kết nối...',
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
