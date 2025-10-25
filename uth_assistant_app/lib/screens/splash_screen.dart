import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Hẹn giờ rồi chuyển sang màn hình đăng nhập
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CẬP NHẬT: Sử dụng Image.asset thay cho Text
            Image.asset(
              AppAssets.splashLogo,
              width: MediaQuery.of(context).size.width * 1, // Điều chỉnh kích thước nếu cần
            ),
          ],
        ),
      ),
    );
  }
}

