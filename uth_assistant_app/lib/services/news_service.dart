import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Lớp đại diện cho một bài báo/tin tức
class NewsArticle {
  final String id;
  final String title;
  final String? imageUrl;
  final String date;
  final String? internalLink;
  final String? originalLink;
  final String content;

  NewsArticle({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.date,
    this.internalLink,
    this.originalLink,
    required this.content,
  });

  // Factory constructor để tạo đối tượng từ JSON
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['_id']?.toString() ?? '',
      title: json['tieuDe'] ?? 'Không có tiêu đề',
      imageUrl: json['hinhDaiDien'],
      date: json['ngayHienThi'] ?? '',
      internalLink: json['linkNoiBo'],
      originalLink: json['linkGoc'],
      content: json['noiDung'] ?? '',
    );
  }

  // Getter để lấy URL hiển thị (ưu tiên linkGoc)
  String? get url => originalLink ?? internalLink;
}

// Lớp Service để xử lý việc gọi API
class NewsService {
  // Sử dụng production URL cho news (vì render.com đã có endpoint này)
  static const String _baseUrl = 'https://uthstudent.onrender.com/api/uth';

  // Cache dữ liệu
  static List<NewsArticle>? _cachedNews;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 15); // Cache 15 phút

  Future<List<NewsArticle>> fetchNews({bool forceRefresh = false}) async {
    // Kiểm tra cache còn hiệu lực không
    if (!forceRefresh && _cachedNews != null && _lastFetchTime != null) {
      final now = DateTime.now();
      final timeSinceLastFetch = now.difference(_lastFetchTime!);

      if (timeSinceLastFetch < _cacheDuration) {
        if (kDebugMode) {
          print(
              '✓ Using cached news (${timeSinceLastFetch.inMinutes} minutes old)');
        }
        return _cachedNews!;
      }
    }

    // Cache hết hạn hoặc chưa có, gọi API
    if (kDebugMode) {
      print('=== FETCH NEWS FROM API ===');
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/thongbaouth'))
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('=== FETCH NEWS ===');
        print('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Kiểm tra success
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'] ?? [];

          if (kDebugMode) {
            print('✓ Loaded ${data.length} news articles');
          }

          // Chuyển đổi JSON thành danh sách các đối tượng NewsArticle
          final articles =
              data.map((jsonItem) => NewsArticle.fromJson(jsonItem)).toList();

          // Lưu vào cache
          _cachedNews = articles;
          _lastFetchTime = DateTime.now();

          return articles;
        } else {
          throw Exception('Server trả về success: false');
        }
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Hết thời gian chờ kết nối.');
    } on SocketException {
      throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra lại.');
    } catch (e) {
      if (kDebugMode) print('✗ Error fetching news: $e');
      throw Exception('Không thể tải tin tức: $e');
    }
  }

  // Hàm xóa cache (dùng khi cần force refresh)
  static void clearCache() {
    _cachedNews = null;
    _lastFetchTime = null;
    if (kDebugMode) print('✓ News cache cleared');
  }
}
