import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../config/app_theme.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  static final String _baseUrl = AppAssets.userApiBaseUrl;
  final AuthService _authService = AuthService();

  // Get all notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) throw Exception('Phiên đăng nhập hết hạn');

      String url = '$_baseUrl/notifications?page=$page&limit=$limit';
      if (isRead != null) {
        url += '&isRead=$isRead';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Debug: In ra response để kiểm tra backend có gửi avatar không
        if (kDebugMode) {
          print('📥 Notification API Response:');
          if (data['notifications'] != null &&
              (data['notifications'] as List).isNotEmpty) {
            final firstNotif = data['notifications'][0];
            print('   First notification:');
            print('   - type: ${firstNotif['type']}');
            print('   - message: ${firstNotif['message']}');
            if (firstNotif['relatedUsers'] != null &&
                (firstNotif['relatedUsers'] as List).isNotEmpty) {
              final firstUser = firstNotif['relatedUsers'][0];
              print('   - relatedUsers[0]:');
              print('     • userId: ${firstUser['userId']}');
              print('     • username: ${firstUser['username']}');
              print('     • avatar: ${firstUser['avatar']}');
              print('     • userId type: ${firstUser['userId'].runtimeType}');

              // Nếu userId là object (đã populate)
              if (firstUser['userId'] is Map) {
                print('     • userId._id: ${firstUser['userId']['_id']}');
                print(
                    '     • userId.username: ${firstUser['userId']['username']}');
                print('     • userId.avatar: ${firstUser['userId']['avatar']}');
              }
            }
          }
        }

        // Parse danh sách notifications
        final notifications = (data['notifications'] as List)
            .map((item) => NotificationModel.fromJson(item))
            .toList();

        // Trả về Map bao gồm cả notifications và thông tin phân trang
        return {
          'notifications': notifications,
          'totalPages': data['pagination']?['totalPages'] ?? 1,
          'total': data['pagination']?['total'] ?? 0,
        };
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Lỗi tải thông báo');
      }
    } catch (e) {
      if (kDebugMode) print('Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập hết hạn');
      }

      if (kDebugMode) {
        print('=== MARK NOTIFICATION AS READ ===');
        print('ID: $notificationId');
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Lỗi đánh dấu đã đọc');
      }

      if (kDebugMode) print('✓ Marked as read');
    } catch (e) {
      if (kDebugMode) print('Error: $e');
      // Không throw error để không ảnh hưởng UX
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập hết hạn');
      }

      if (kDebugMode) print('=== MARK ALL AS READ ===');

      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Lỗi đánh dấu tất cả đã đọc');
      }

      if (kDebugMode) print('✓ All marked as read');
    } catch (e) {
      if (kDebugMode) print('Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) print('Error getting unread count: $e');
      return 0;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await _authService.getValidToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập hết hạn');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Lỗi xóa thông báo');
      }

      if (kDebugMode) print('✓ Notification deleted');
    } catch (e) {
      if (kDebugMode) print('Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
