import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_notification.dart';
import '../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Auto focus vào ô đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Lấy mã xác thực từ 6 ô input
  String get _verificationCode {
    return _controllers.map((c) => c.text).join();
  }

  // Xóa tất cả các ô
  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // --- HÀM XỬ LÝ XÁC THỰC MÃ ---
  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();

    final code = _verificationCode;

    if (code.length != 6) {
      CustomNotification.error(
        context,
        "Vui lòng nhập đầy đủ 6 số mã xác thực.",
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> responseData;
    try {
      responseData = await _authService.verifyCode(
        email: widget.email,
        code: code,
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
      // Đợi animation xong rồi chuyển về màn hình đăng nhập
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      });
    } else {
      CustomNotification.error(context, message);
      _clearAllFields();
    }
  }

  // --- HÀM GỬI LẠI MÃ ---
  Future<void> _handleResendCode() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    Map<String, dynamic> responseData;
    try {
      responseData = await _authService.resendVerification(
        email: widget.email,
      );
    } catch (e) {
      responseData = {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }

    if (!mounted) return;

    final bool success = responseData['success'] ?? false;
    final String message = responseData['message'] ?? 'Lỗi không xác định';

    if (success) {
      CustomNotification.success(context, message);
      _clearAllFields();
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
                // Illustration
                SizedBox(
                  height: screenHeight * 0.25,
                  child: SvgPicture.asset(
                    AppAssets.loginIllustration,
                    placeholderBuilder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // Tiêu đề
                const Text(
                  'Xác thực email',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 8.0),

                // Mô tả
                Text(
                  'Nhập mã gồm 6 số đã được gửi đến\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyRegular,
                ),
                const SizedBox(height: 32.0),

                // 6 ô nhập mã
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return _buildCodeInputBox(index);
                  }),
                ),
                const SizedBox(height: 32.0),

                // Nút xác thực
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: 'Xác thực',
                        onPressed: _handleVerify,
                        isPrimary: true,
                      ),
                const SizedBox(height: 16.0),

                // Gửi lại mã
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Không nhận được mã? ',
                      style: AppTextStyles.bodyRegular,
                    ),
                    _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : GestureDetector(
                            onTap: _handleResendCode,
                            child: const Text(
                              'Gửi lại',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Quay lại đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: AppTextStyles.bodyRegular,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_isLoading && !_isResending) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
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

  // Widget ô nhập mã
  Widget _buildCodeInputBox(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppAssets.borderRadiusMedium),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? AppColors.primary
              : AppColors.divider,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Chuyển sang ô tiếp theo
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Ô cuối cùng -> Ẩn bàn phím
              _focusNodes[index].unfocus();
            }
          } else {
            // Xóa ký tự -> Quay lại ô trước
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {}); // Cập nhật border color
        },
      ),
    );
  }
}
