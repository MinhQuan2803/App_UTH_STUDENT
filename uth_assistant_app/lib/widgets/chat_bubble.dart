import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../models/chatbot_model.dart';
import '../services/profile_service.dart';

/// Widget hiển thị tin nhắn chat - theo thiết kế mới
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: message.isFromUser ? 0 : 0,
        right:
            message.isFromUser ? 0 : MediaQuery.of(context).size.width * 0.13,
      ),
      child: Row(
        mainAxisAlignment: message.isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromUser) ...[
            // Bot avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.secondary,
              child: SvgPicture.asset(
                AppAssets.iconRobot,
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isFromUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Tên người gửi
                Padding(
                  padding: const EdgeInsets.only(bottom: 1, left: 1, right: 1),
                  child: Text(
                    message.isFromUser ? 'Bạn' : 'UTH Assistant',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isFromUser
                        ? AppColors.primary
                        : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: message.isFromUser
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: message.isFromUser
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isFromUser
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message.isTyping
                      ? const _TypingIndicator()
                      : Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: message.isFromUser
                                ? AppColors.white
                                : AppColors.text,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 10),
            // User avatar
            FutureBuilder<Map<String, dynamic>>(
              future: ProfileService().getMyProfile(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['avatarUrl'] != null) {
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary,
                    backgroundImage: CachedNetworkImageProvider(
                      snapshot.data!['avatarUrl'],
                    ),
                  );
                }
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 24,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget hiển thị link cards - theo thiết kế mới với gradient
class ChatLinkCard extends StatelessWidget {
  final ChatLink link;

  const ChatLinkCard({
    super.key,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.13,
        right: 0,
        top: 2,
        bottom: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openInWebView(context, link),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatLinkTitle(link.title),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLinkTitle(String title) {
    return title
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _openInWebView(BuildContext context, ChatLink link) {
    Navigator.pushNamed(
      context,
      '/webview',
      arguments: {
        'url': link.url,
        'title': _formatLinkTitle(link.title),
      },
    );
  }
}

/// Widget hiển thị suggestion chips - theo thiết kế mới
class ChatSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onSuggestionTap;

  const ChatSuggestions({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.13,
        top: 2,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn có thắc mắc về ',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((suggestion) => _buildSuggestionChip(context, suggestion))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSuggestionTap?.call(suggestion),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
            minHeight: 30,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Hiệu ứng "đang gõ..."
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
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
            opacity: DelayTween(begin: 0.2, end: 1.0, delay: index * 0.2)
                .animate(_controller),
            child: const CircleAvatar(
                radius: 3, backgroundColor: AppColors.subtitle),
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
