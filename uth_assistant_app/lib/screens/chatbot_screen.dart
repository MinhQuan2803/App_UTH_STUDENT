import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/bot_info_sheet.dart';
import '../services/chatbot_service.dart';
import '../models/chatbot_model.dart';
import '../widgets/custom_notification.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    // Welcome message
    _messages.add(ChatMessage(
      text:
          'Chào bạn! Tôi là UTH Assistant. Tôi có thể giúp gì cho bạn hôm nay?',
      isFromUser: false,
    ));

    // Sample user question
    _messages.add(ChatMessage(
      text: 'Thời gian đăng ký học phần là khi nào?',
      isFromUser: true,
    ));

    // Sample bot response with links and suggestions
    _messages.add(ChatMessage(
      text:
          'Ở học kì hiện tại (học kì 1 năm học 2025-2026) thì thời gian là từ ngày 30/08 đến ngày 03/09, để biết thêm chi tiết vui lòng truy cập thông báo bên dưới.',
      isFromUser: false,
      links: [
        ChatLink(
          title: 'thong_bao_thoi_gian_dangki_hoc_phan',
          url:
              'https://daotao.ut.edu.vn/ve-viec-dang-ky-hoc-phan-hoc-ky-1-nam-hoc-2025-2026',
        ),
      ],
      suggestions: [
        'Cách thức đăng kí học phần?',
        'Hạn nộp học phí?',
      ],
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage.fromUser(text);
    setState(() {
      _messages.add(userMessage);
      _textController.clear();
      _isLoading = true;
      _messages.add(ChatMessage.typing());
    });

    _scrollToBottom();

    try {
      final botResponse = await _chatbotService.sendMessage(text);

      setState(() {
        _messages.removeLast(); // Remove typing indicator
        _messages.add(botResponse);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast(); // Remove typing indicator
        _messages.add(ChatMessage(
          text:
              'Xin lỗi, đã có lỗi xảy ra: ${e.toString().replaceFirst('Exception: ', '')}',
          isFromUser: false,
        ));
        _isLoading = false;
      });

      if (mounted) {
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showBotInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BotInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent ,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary,
            child: SvgPicture.asset(
              AppAssets.iconRobot,
              width: 26,
              height: 26,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Trợ lý ảo UTH',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showBotInfo(context),
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 18),
            label: const Text(
              'Thông tin',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message bubble (text answer)
                    ChatBubble(message: message),

                    // Links - hiển thị riêng nếu có
                    if (message.links != null && message.links!.isNotEmpty)
                      ...message.links!.map((link) => ChatLinkCard(link: link)),

                    // Suggestions - hiển thị riêng nếu có
                    if (message.suggestions != null &&
                        message.suggestions!.isNotEmpty)
                      ChatSuggestions(
                        suggestions: message.suggestions!,
                        onSuggestionTap: (suggestion) {
                          _textController.text = suggestion;
                          _sendMessage(suggestion);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          _ChatInputArea(
            controller: _textController,
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}

class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;

  const _ChatInputArea({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppColors.subtitle),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            // Input field
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors
                        .primary, // hoặc AppColors.divider nếu muốn nhẹ hơn
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'Nhập câu hỏi...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.hintText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (text) => onSend(text),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Icon(Icons.send, color: AppColors.white, size: 20),
                onPressed: isLoading ? null : () => onSend(controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
