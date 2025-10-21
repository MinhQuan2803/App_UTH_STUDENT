import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import 'dart:math' as math;

class FabWithPrompt extends StatefulWidget {
  final VoidCallback onTap;

  const FabWithPrompt({super.key, required this.onTap});

  @override
  State<FabWithPrompt> createState() => _FabWithPromptState();
}

class _FabWithPromptState extends State<FabWithPrompt> {
  final String _fullText = 'Bạn có thắc mắc ???\nHỏi UTH ASSISTANT ngay!!!';
  String _displayedText = '';
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
    _startCursorAnimation();
  }

  void _startTypingAnimation() {
    // Hủy timer cũ nếu nó đang chạy
    _typingTimer?.cancel();
    // Bắt đầu một timer mới
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_displayedText.length < _fullText.length) {
        setState(() {
          _displayedText = _fullText.substring(0, _displayedText.length + 1);
        });
      } else {
        // Khi gõ xong, hủy timer hiện tại
        timer.cancel();
        // Đợi 3 giây rồi bắt đầu lại animation
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _displayedText = '';
            });
            _startTypingAnimation(); // Gọi lại chính nó để tạo vòng lặp
          }
        });
      }
    });
  }

  void _startCursorAnimation() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
       if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      clipBehavior: Clip.none,
      children: [
        // Bong bóng chat
        Positioned(
          right: 65,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _displayedText,
                    // Sử dụng style từ theme để nhất quán
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      height: 1.4
                    ),
                  ),
                  // Hiệu ứng con trỏ chỉ nhấp nháy khi đang gõ
                  if (_displayedText.length < _fullText.length && _showCursor)
                    TextSpan(
                      text: '|',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // "Đuôi" cho bong bóng chat
        Positioned(
          right: 58,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 10,
              height: 10,
              color: AppColors.white,
            ),
          ),
        ),

        // Nút FAB
        FloatingActionButton(
          onPressed: widget.onTap,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: SvgPicture.asset(
            AppAssets.fabBot,
            // SỬA LỖI: Thêm lại colorFilter để icon có màu trắng
            colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            width: 32,
          ),
        ),
      ],
    );
  }
}

