import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // Không cần thư viện này nữa
import '../screens/webview_screen.dart'; // Import màn hình WebViewScreen mới

// CẬP NHẬT: Hàm này giờ sẽ mở WebViewScreen thay vì trình duyệt ngoài
Future<void> launchUrlHelper(BuildContext context, String? urlString, {String? title}) async {
  if (urlString == null || urlString.isEmpty) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Không có đường link hợp lệ.')),
     );
     return;
  }

  // Chuyển sang màn hình WebViewScreen bằng Navigator.push
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebViewScreen(
        initialUrl: urlString,
        title: title, // Truyền tiêu đề (nếu có) vào WebViewScreen
      ),
    ),
  );
}

