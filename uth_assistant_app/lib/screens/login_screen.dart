import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Import file cấu hình giao diện
import '../config/app_theme.dart';
// Import các widget tái sử dụng
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Phần hình minh hoạ ---
                  SizedBox(
                    height: screenHeight * 0.25,
                    child: SvgPicture.asset(
                      AppAssets.loginIllustration,
                      placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // --- Tiêu đề và mô tả ---
                  const Text(
                    'Chào mừng bạn!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Đăng nhập để tiếp tục',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyRegular,
                  ),
                  const SizedBox(height: 32.0),

                  // --- Các ô nhập liệu (ĐÃ CẬP NHẬT) ---
                  const CustomTextField(hintText: 'Email sinh viên'),
                  const SizedBox(height: 16.0),
                  const CustomTextField(hintText: 'Mật khẩu', obscureText: true),
                  const SizedBox(height: 32.0),

                  // --- Các nút bấm (ĐÃ CẬP NHẬT) ---
                  CustomButton(
                    text: 'Đăng nhập',
                    onPressed: () {},
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16.0),
                  CustomButton(
                    text: 'Đăng ký',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24.0),

                  // --- Dải phân cách "hoặc" ---
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'hoặc',
                          style: TextStyle(color: AppColors.subtitle, fontSize: 14),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // --- Nút đăng nhập với Google ---
                  OutlinedButton.icon(
                    onPressed: () {
                    // THAY ĐỔI Ở ĐÂY: Điều hướng tới màn hình home
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                    icon: SvgPicture.asset(
                      AppAssets.googleLogo,
                      width: 20,
                    ),
                    label: const Text(
                      'Tiếp tục với Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

