import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String? text;
  final bool isFromUser;
  final bool isTyping;

  const ChatBubble({
    super.key,
    this.text,
    required this.isFromUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isFromUser ? AppColors.primary : AppColors.white;
    final textColor = isFromUser ? AppColors.white : AppColors.text;
    final borderRadius = isFromUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromUser) ...[
            const CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 20,
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
                boxShadow: [
                  if (!isFromUser)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                ],
              ),
              child: isTyping ? _TypingIndicator() : Text(
                text ?? '',
                style: AppTextStyles.chatMessage.copyWith(color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Hiệu ứng "đang gõ..."
class _TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return FadeTransition(
            opacity: DelayTween(begin: 0.2, end: 1.0, delay: index * 0.2).animate(_controller),
            child: const CircleAvatar(radius: 3, backgroundColor: AppColors.subtitle),
          );
        }),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  final double delay;
  DelayTween({super.begin, super.end, required this.delay});

  @override
  double lerp(double t) {
    return super.lerp((t - delay).clamp(0.0, 1.0));
  }
}
