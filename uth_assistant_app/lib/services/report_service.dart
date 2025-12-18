import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../config/app_theme.dart';
import 'auth_service.dart';

class ReportService {
  // Sử dụng base API URL chứ không phải userApiBaseUrl
  // Vì endpoint là /api/reports, không phải /api/users/reports
  static String get _baseUrl {
    // Lấy base URL từ AppAssets và loại bỏ '/users' nếu có
    final url = AppAssets.userApiBaseUrl;
    if (url.endsWith('/users')) {
      return url.substring(0, url.length - 6); // Bỏ '/users'
    }
    return url;
  }
  
  final AuthService _authService = AuthService();

  /// Gửi báo cáo
  /// [targetId] - ID của Post/Comment/User bị báo cáo
  /// [targetType] - Loại: 'Post', 'Comment', hoặc 'User'
  /// [reason] - Lý do: spam, harassment, hate_speech, nudity, false_info, other
  /// [description] - Mô tả chi tiết (optional)
  Future<String> sendReport({
    required String targetId,
    required String targetType,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập hết hạn');
      }

      if (kDebugMode) {
        print('=== SEND REPORT ===');
        print('Target ID: $targetId');
        print('Target Type: $targetType');
        print('Reason: $reason');
      }

      final body = {
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final message = data['message'] ?? 'Đã gửi báo cáo';
        
        if (kDebugMode) print('✓ Report sent successfully');
        return message;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Lỗi gửi báo cáo');
      }
    } on SocketException {
      throw Exception('Không có kết nối mạng');
    } on TimeoutException {
      throw Exception('Yêu cầu quá thời gian');
    } catch (e) {
      if (kDebugMode) print('Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
