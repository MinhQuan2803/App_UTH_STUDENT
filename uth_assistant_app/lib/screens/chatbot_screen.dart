import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/suggestion_chip.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.white,
          elevation: 1,
          shadowColor: AppColors.divider,
          // ĐÃ THÊM LẠI: Nút back để quay lại màn hình trước đó trên stack
          leading: IconButton(
            icon: SvgPicture.asset(AppAssets.iconChevronLeft),
            onPressed: () {
              // Hành động pop mặc định sẽ quay lại route trước đó (LoginScreen)
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text('Hỏi UTH Assistant', style: AppTextStyles.appBarTitle),
          centerTitle: true,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: const [
              ChatBubble(
                text: 'Chào bạn! Tôi là UTH Assistant. Tôi có thể giúp gì cho bạn hôm nay?',
                isFromUser: false,
              ),
               SizedBox(height: 12),
              ChatBubble(
                text: 'Lịch thi cuối kỳ khi nào có?',
                isFromUser: true,
              ),
               SizedBox(height: 12),
              ChatBubble(
                text: 'Theo thông báo mới nhất từ phòng đào tạo, lịch thi dự kiến sẽ được công bố vào ngày 25/10/2025 bạn nhé.',
                isFromUser: false,
              ),
               SizedBox(height: 12),
              ChatBubble(
                text: 'Cảm ơn bạn nhé!',
                isFromUser: true,
              ),
               SizedBox(height: 12),
              ChatBubble(
                isTyping: true,
                isFromUser: false,
              ),
            ],
          ),
        ),
        const _ChatInputArea(),
      ],
    );
  }
}

class _ChatInputArea extends StatelessWidget {
  const _ChatInputArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                SuggestionChip(label: 'Lịch thi'),
                SizedBox(width: 8),
                SuggestionChip(label: 'Đăng ký học phần'),
                SizedBox(width: 8),
                SuggestionChip(label: 'Mượn sách'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập câu hỏi của bạn...',
                    hintStyle: AppTextStyles.hintText.copyWith(fontSize: 15),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(AppAssets.iconMic, colorFilter: const ColorFilter.mode(AppColors.subtitle, BlendMode.srcIn)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppColors.primary,
                  ),
                  child: SvgPicture.asset(AppAssets.iconSend, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

