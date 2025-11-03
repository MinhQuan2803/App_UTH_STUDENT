import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_notification.dart';
import '../services/auth_service.dart';

class AppAssets {
  static const String loginIllustration =
      'assets/images/login_illustration.svg';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _hideIllustration = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hideIllustration = _emailFocus.hasFocus || _passwordFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ ĐĂNG NHẬP ---
  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      CustomNotification.error(
        context,
        "Vui lòng nhập đầy đủ email và mật khẩu.",
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> responseData;
    try {
      responseData = await _authService.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      responseData = {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;

    final bool success = responseData['success'] ?? false;
    final String message = responseData['message'] ?? 'Lỗi không xác định';

    if (success) {
      CustomNotification.success(context, message);
      // Đợi animation xong rồi mới chuyển trang
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      });
    } else {
      CustomNotification.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _hideIllustration
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: screenHeight * 0.25,
                          child: SvgPicture.asset(
                            AppAssets
                                .loginIllustration, // Đảm bảo bạn có asset này
                            placeholderBuilder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          ),
                        ),
                ),
                if (!_hideIllustration) const SizedBox(height: 32.0),
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
                CustomTextField(
                  hintText: 'Email',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  hintText: 'Mật khẩu',
                  obscureText: true,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                ),
                const SizedBox(height: 32.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: 'Đăng nhập',
                        onPressed: _handleSignIn,
                        isPrimary: true,
                      ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: AppTextStyles.bodyRegular,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_isLoading) {
                          Navigator.pushNamed(context, '/signup');
                        }
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
