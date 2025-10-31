import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Giả sử AppAssets, AppColors, AppTextStyles, CustomButton, CustomTextField
// được định nghĩa trong các file này
import '../config/app_theme.dart'; 
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

// Giả sử bạn có file này để chứa AppAssets
class AppAssets {
  static const String loginIllustration = 'assets/images/login_illustration.svg'; // Đường dẫn ví dụ
}


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
  final AuthService _authService = AuthService(); // Khởi tạo service

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
    // Luôn luôn dispose và remove listener!
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

  // --- HÀM XỬ LÝ ĐĂNG KÝ (ĐÃ CẬP NHẬT) ---
  Future<void> _handleSignUp() async {
    // 1. Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // 2. Validation phía client (trước khi gọi API)
    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập tên đăng nhập!');
      return;
    }
    // Kiểm tra email (định dạng cơ bản)
    final email = _emailController.text.trim();
    bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
    if (email.isEmpty || !emailValid) {
       _showErrorSnackBar('Vui lòng nhập email hợp lệ!');
       return;
    }
    // Kiểm tra mật khẩu (độ dài)
    if (_passwordController.text.length < 6) {
       _showErrorSnackBar('Mật khẩu phải có ít nhất 6 ký tự!');
       return;
    }
    // Kiểm tra mật khẩu nhập lại
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Mật khẩu nhập lại không khớp!');
      return;
    }
    
    // 3. Bắt đầu loading
    setState(() => _isLoading = true);

    // 4. Gọi AuthService (nhận về Map thay vì int)
    Map<String, dynamic> responseData;

    try {
      responseData = await _authService.signUp(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch(e) {
        print("Error calling signUp service: $e");
        // Lỗi không mong muốn (ví dụ: code client bị crash)
        responseData = {'statusCode': 500, 'message': 'Lỗi cục bộ tại app: ${e.toString()}'};
    } finally {
        // Luôn tắt loading sau khi gọi xong
        if (mounted) {
          setState(() => _isLoading = false);
        }
    }

    // Kiểm tra mounted trước khi truy cập context (quan trọng)
    if (!mounted) return;

    // 5. Xử lý response từ server
    final int statusCode = responseData['statusCode'];
    final String message = responseData['message'];

    // Dùng statusCode để quyết định LOGIC (chuyển màn hình, màu sắc)
    // Dùng message để HIỂN THỊ thông báo
    if (statusCode == 201) {
      // Thành công! (204 No Content là mã API của bạn)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isNotEmpty ? message : 'Đăng ký thành công!'), // Dùng message từ server
          backgroundColor: AppColors.primary, // Màu xanh
        ),
      );
      Navigator.pop(context); // Quay về màn hình đăng nhập
    } else {
      // Thất bại (400, 409, 503, 504, 500...)
      _showErrorSnackBar(message); // Hiển thị lỗi từ server
    }
  }

  // Hàm tiện ích để hiển thị lỗi
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger, // Màu đỏ
      ),
    );
  }


  // --- PHẦN BUILD UI (Không thay đổi) ---
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
                            AppAssets.loginIllustration, // Đảm bảo bạn có asset này
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
                        onPressed: _handleSignUp, // Gọi hàm đã sửa
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