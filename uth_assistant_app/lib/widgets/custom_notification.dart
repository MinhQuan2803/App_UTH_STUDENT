import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Enum để định nghĩa các loại thông báo
enum NotificationType {
  success,
  error,
  warning,
  info,
}

/// Widget thông báo tùy chỉnh hiện đại
class CustomNotification {
  /// Hiển thị thông báo với kiểu và nội dung tùy chỉnh
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        title: title,
        onDismiss: () => overlayEntry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động xóa sau duration
    Future.delayed(duration + const Duration(milliseconds: 300), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Phương thức shortcut cho thông báo thành công
  static void success(BuildContext context, String message, {String? title}) {
    show(context,
        message: message, type: NotificationType.success, title: title);
  }

  /// Phương thức shortcut cho thông báo lỗi
  static void error(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: NotificationType.error, title: title);
  }

  /// Phương thức shortcut cho thông báo cảnh báo
  static void warning(BuildContext context, String message, {String? title}) {
    show(context,
        message: message, type: NotificationType.warning, title: title);
  }

  /// Phương thức shortcut cho thông báo thông tin
  static void info(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: NotificationType.info, title: title);
  }
}

/// Widget nội bộ để hiển thị thông báo
class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? title;
  final VoidCallback onDismiss;
  final Duration duration;

  const _NotificationWidget({
    required this.message,
    required this.type,
    this.title,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Tự động dismiss trước khi hết duration
    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Lấy cấu hình màu sắc và icon theo loại thông báo
  _NotificationConfig _getConfig() {
    switch (widget.type) {
      case NotificationType.success:
        return _NotificationConfig(
          backgroundColor: AppColors.success,
          icon: Icons.check_circle,
          title: widget.title ?? 'Thành công',
        );
      case NotificationType.error:
        return _NotificationConfig(
          backgroundColor: AppColors.danger,
          icon: Icons.error,
          title: widget.title ?? 'Lỗi',
        );
      case NotificationType.warning:
        return _NotificationConfig(
          backgroundColor: AppColors.warning,
          icon: Icons.warning_amber,
          title: widget.title ?? 'Cảnh báo',
        );
      case NotificationType.info:
        return _NotificationConfig(
          backgroundColor: AppColors.primary,
          icon: Icons.info,
          title: widget.title ?? 'Thông báo',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth - 32,
                minHeight: 70,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Thanh màu bên trái
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: config.backgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Nội dung
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: config.backgroundColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              config.icon,
                              color: config.backgroundColor,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                Text(
                                  config.title,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: config.backgroundColor,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Message
                                Text(
                                  widget.message,
                                  style: AppTextStyles.bodyRegular.copyWith(
                                    color: AppColors.text,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Close button
                          InkWell(
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                color: AppColors.subtitle.withOpacity(0.6),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Class để lưu cấu hình thông báo
class _NotificationConfig {
  final Color backgroundColor;
  final IconData icon;
  final String title;

  _NotificationConfig({
    required this.backgroundColor,
    required this.icon,
    required this.title,
  });
}
