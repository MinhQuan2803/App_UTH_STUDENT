import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import package
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String? title; // Tiêu đề tùy chọn cho AppBar
  final bool isPayment; // Đánh dấu đây là màn hình thanh toán

  const WebViewScreen({
    super.key,
    required this.initialUrl,
    this.title,
    this.isPayment = false,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isClosed = false; // Flag để tránh đóng nhiều lần

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
            print('📍 WebView loading: $url');

            // Kiểm tra nếu là màn hình thanh toán và URL chứa returnUrl của VNPay
            // Sử dụng danh sách keywords từ AppAssets
            if (widget.isPayment &&
                !_isClosed &&
                AppAssets.paymentReturnUrlKeywords
                    .any((keyword) => url.contains(keyword))) {
              print('🔙 Payment return URL detected, closing WebView...');
              _isClosed = true;

              // Delay nhỏ để tránh crash - sử dụng constant từ AppAssets
              Future.delayed(
                  Duration(milliseconds: AppAssets.webViewCloseDelayMs), () {
                if (mounted) {
                  Navigator.pop(context);
                }
              });
              return; // Dừng xử lý, không set loading
            }

            if (!_isClosed) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (!_isClosed) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            // Có thể hiển thị thông báo lỗi
            if (!_isClosed) {
              setState(() {
                _isLoading = false; // Dừng loading khi có lỗi
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔍 Navigation request: ${request.url}');

            // Nếu là màn hình thanh toán và URL chứa returnUrl
            // Sử dụng danh sách keywords từ AppAssets
            if (widget.isPayment &&
                !_isClosed &&
                AppAssets.paymentReturnUrlKeywords
                    .any((keyword) => request.url.contains(keyword))) {
              print('🛑 Preventing navigation to return URL');
              _isClosed = true;

              // Đóng WebView với delay để tránh crash - sử dụng constant từ AppAssets
              Future.delayed(
                  Duration(milliseconds: AppAssets.webViewCloseDelayMs), () {
                if (mounted) {
                  Navigator.pop(context);
                }
              });

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl)); // Tải URL ban đầu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: widget.title ?? 'Chi tiết',
        actions: [
          ModernIconButton(
            icon: Icons.refresh,
            onPressed: () => _controller.reload(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Hiển thị loading đẹp hơn khi đang tải trang
          if (_isLoading)
            Container(
              color: AppColors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
