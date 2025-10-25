import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final FocusNode _usernameFocus = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _hideIllustration = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _confirmPasswordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hideIllustration = _usernameFocus.hasFocus || _emailFocus.hasFocus || _passwordFocus.hasFocus || _confirmPasswordFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _usernameFocus.removeListener(_onFocusChange);
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _confirmPasswordFocus.removeListener(_onFocusChange);
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Xử lý lỗi chi tiết hơn
  Future<void> _handleSignUp() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp!'), backgroundColor: AppColors.danger),
      );
      return;
    }
     if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập!'), backgroundColor: AppColors.danger),
      );
      return;
    }
    // TODO: Thêm validation cho email và password (độ dài, định dạng)

    setState(() => _isLoading = true);
    int statusCode = 500; // Mã lỗi mặc định

    try {
      statusCode = await _authService.signUp(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch(e) {
       print("Error calling signUp service: $e");
       statusCode = 503; // Giả định là lỗi mạng nếu catch ở đây
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }


    if (!mounted) return; // Kiểm tra lại mounted sau await

    // Hiển thị thông báo dựa trên status code
    if (statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.'), backgroundColor: AppColors.primary),
      );
      Navigator.pop(context);
    } else if (statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email hoặc tên đăng nhập đã tồn tại.'), backgroundColor: AppColors.danger),
      );
    } else if (statusCode == 400) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.'), backgroundColor: AppColors.danger),
      );
    } else if (statusCode == 503 || statusCode == 504) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Lỗi kết nối mạng. Vui lòng thử lại.'), backgroundColor: AppColors.danger),
       );
    }
    else { // Các lỗi khác (500, ...)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã có lỗi xảy ra phía máy chủ. Vui lòng thử lại sau.'), backgroundColor: AppColors.danger),
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
                          height: screenHeight * 0.20,
                          child: SvgPicture.asset(
                            AppAssets.loginIllustration,
                            placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                ),
                if (!_hideIllustration) const SizedBox(height: 24.0),

                const Text(
                  'Tạo tài khoản',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Bắt đầu trải nghiệm UTH Student',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyRegular,
                ),
                const SizedBox(height: 24.0),

                CustomTextField(
                  hintText: 'Tên đăng nhập (3-30 ký tự)',
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  hintText: 'Email sinh viên',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  hintText: 'Tạo mật khẩu (ít nhất 6 ký tự)',
                  obscureText: true,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  hintText: 'Nhập lại mật khẩu',
                  obscureText: true,
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                ),
                const SizedBox(height: 24.0),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: 'Đăng ký',
                        onPressed: _handleSignUp,
                        isPrimary: true,
                      ),
                const SizedBox(height: 16.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: AppTextStyles.bodyRegular,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_isLoading) Navigator.pop(context);
                      },
                      child: const Text(
                        'Đăng nhập ngay',
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

