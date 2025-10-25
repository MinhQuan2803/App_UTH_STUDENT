import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // CẬP NHẬT: Đổi tên FocusNode và Controller cho rõ ràng
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hideIllustration = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hideIllustration = _usernameFocus.hasFocus || _passwordFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _usernameFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final success = await _authService.signIn(
      // CẬP NHẬT: Gửi username thay vì email
      email: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng kiểm tra lại tên đăng nhập và mật khẩu.'), backgroundColor: AppColors.danger),
      );
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                            AppAssets.loginIllustration,
                            placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
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

                // CẬP NHẬT: Đổi thành ô nhập Tên đăng nhập
                CustomTextField(
                  hintText: 'Tên đăng nhập', // <- Đổi hint text
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  keyboardType: TextInputType.text, // <- Đổi keyboard type
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
                
                CustomButton(
                  text: 'Đăng ký',
                  onPressed: () {
                     if(!_isLoading) Navigator.pushNamed(context, '/signup');
                  },
                ),
                const SizedBox(height: 24.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: AppTextStyles.bodyRegular,
                    ),
                    GestureDetector(
                      onTap: () {
                        if(!_isLoading) Navigator.pushNamed(context, '/signup');
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

