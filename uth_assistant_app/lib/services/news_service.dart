import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart'; // Để lấy apiUrl

// Lớp đại diện cho một bài báo/tin tức
class NewsArticle {
  final String title;
  final String? url; // URL có thể null
  final String date;

  NewsArticle({required this.title, this.url, required this.date});

  // Factory constructor để tạo đối tượng từ JSON
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Không có tiêu đề',
      url: json['url'], // Giữ nguyên null nếu không có
      date: json['date'] ?? 'Ngày đăng',
    );
  }
}

// Lớp Service để xử lý việc gọi API
class NewsService {
  final String _apiUrl = AppAssets.newsApiUrl;

  Future<List<NewsArticle>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Chuyển đổi JSON thành danh sách các đối tượng NewsArticle
        return data.map((jsonItem) => NewsArticle.fromJson(jsonItem)).toList();
      } else {
        // Ném lỗi nếu server trả về mã lỗi
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } on TimeoutException {
       throw Exception('Hết thời gian chờ kết nối.');
    } on SocketException {
       throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra lại.');
    } catch (e) {
      // Ném lại lỗi để màn hình có thể xử lý
      throw Exception('Không thể tải tin tức: $e');
    }
  }
}
