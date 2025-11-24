import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget loading screen tái sử dụng với spinner và nền tùy chỉnh
class LoadingScreen extends StatelessWidget {
  final String? message;
  final bool showAppBar;
  final String appBarTitle;
  final bool automaticallyImplyLeading;

  const LoadingScreen({
    super.key,
    this.message,
    this.showAppBar = true,
    this.appBarTitle = 'Đang tải...',
    this.automaticallyImplyLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              title: Text(
                appBarTitle,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              automaticallyImplyLeading: automaticallyImplyLeading,
              iconTheme: const IconThemeData(color: AppColors.text),
            )
          : null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.subtitle,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget loading nhỏ gọn để nhúng vào body
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
