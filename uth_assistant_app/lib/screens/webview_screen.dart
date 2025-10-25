import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import package
import '../config/app_theme.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String? title; // Tiêu đề tùy chọn cho AppBar

  const WebViewScreen({
    super.key,
    required this.initialUrl,
    this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white) // Màu nền khi tải
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Có thể dùng progress để hiển thị thanh loading nếu muốn
            // print('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
             setState(() {
               _isLoading = true;
             });
          },
          onPageFinished: (String url) {
             setState(() {
               _isLoading = false;
             });
          },
          onWebResourceError: (WebResourceError error) {
             print('WebView error: ${error.description}');
             // Có thể hiển thị thông báo lỗi
              setState(() {
               _isLoading = false; // Dừng loading khi có lỗi
             });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Ngăn chặn điều hướng đến các link không mong muốn nếu cần
            // if (request.url.startsWith('https://www.youtube.com/')) {
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl)); // Tải URL ban đầu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Chi tiết', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.text),
        elevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Hiển thị vòng tròn loading khi đang tải trang
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
