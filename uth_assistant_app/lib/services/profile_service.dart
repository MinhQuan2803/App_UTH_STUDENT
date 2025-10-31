import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProfileService {
  static const String _baseUrl = 'https://uthstudent.onrender.com/api/users';
  final AuthService _authService = AuthService();

  // Cache cho profile của mình
  static Map<String, dynamic>? _cachedMyProfile;
  static DateTime? _myProfileLastFetchTime;

  // Cache cho profile người khác (key: username)
  static Map<String, Map<String, dynamic>> _cachedUserProfiles = {};
  static Map<String, DateTime> _userProfilesFetchTime = {};

  static const Duration _cacheDuration = Duration(minutes: 10); // Cache 10 phút

  /// Lấy thông tin user hiện tại (chính mình) qua API /me
  Future<Map<String, dynamic>> getMyProfile({bool forceRefresh = false}) async {
    // Kiểm tra cache
    if (!forceRefresh &&
        _cachedMyProfile != null &&
        _myProfileLastFetchTime != null) {
      final timeSinceLastFetch =
          DateTime.now().difference(_myProfileLastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        if (kDebugMode) {
          print(
              '✓ Using cached my profile (${timeSinceLastFetch.inMinutes} min old)');
        }
        return _cachedMyProfile!;
      }
    }

    final String? token = await _authService.getToken();

    if (token == null) {
      throw Exception('401: Chưa đăng nhập');
    }

    if (kDebugMode) print('=== GET MY PROFILE (from /me) ===');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http
        .get(Uri.parse('$_baseUrl/me'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body)['user'];

      // Thêm field isOwner = true (vì đây là profile của mình)
      userData['isOwner'] = true;
      userData['isFollowing'] = false;

      // Lưu vào cache
      _cachedMyProfile = userData;
      _myProfileLastFetchTime = DateTime.now();

      if (kDebugMode) print('✓ My username: ${userData['username']}');
      return userData;
    } else if (response.statusCode == 401) {
      throw Exception('401: Phiên đăng nhập không hợp lệ');
    } else {
      throw Exception('Lỗi Server: ${response.statusCode}');
    }
  }

  /// Lấy profile của BẤT KỲ user nào bằng username
  Future<Map<String, dynamic>> getUserProfile(String username,
      {bool forceRefresh = false}) async {
    // Kiểm tra cache cho user này
    if (!forceRefresh && _cachedUserProfiles.containsKey(username)) {
      final lastFetchTime = _userProfilesFetchTime[username];
      if (lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(lastFetchTime);
        if (timeSinceLastFetch < _cacheDuration) {
          if (kDebugMode) {
            print(
                '✓ Using cached profile for $username (${timeSinceLastFetch.inMinutes} min old)');
          }
          return _cachedUserProfiles[username]!;
        }
      }
    }

    final String? token = await _authService.getToken();

    if (kDebugMode) {
      print('=== GET USER PROFILE ===');
      print('Fetching username: $username');
      print('Token: ${token != null ? "✓ Có token" : "✗ Không có token"}');
    }

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(Uri.parse('$_baseUrl/profile/$username'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final userRes = jsonDecode(response.body)['userRes'];

      // FIX: Server có lỗi chính tả "isOwer" thay vì "isOwner"
      if (userRes.containsKey('isOwer') && !userRes.containsKey('isOwner')) {
        userRes['isOwner'] = userRes['isOwer'];
        if (kDebugMode) print('⚠ Fixed typo: isOwer -> isOwner');
      }

      if (kDebugMode) {
        print('isOwner: ${userRes['isOwner']}');
        print('isFollowing: ${userRes['isFollowing']}');
      }

      // Lưu vào cache
      _cachedUserProfiles[username] = userRes;
      _userProfilesFetchTime[username] = DateTime.now();

      return userRes;
    } else if (response.statusCode == 404) {
      throw Exception('404: Không tìm thấy người dùng');
    } else if (response.statusCode == 401) {
      throw Exception('401: Phiên đăng nhập không hợp lệ');
    } else {
      throw Exception('Lỗi Server: ${response.statusCode}');
    }
  }

  // Hàm xóa cache
  static void clearCache() {
    _cachedMyProfile = null;
    _myProfileLastFetchTime = null;
    _cachedUserProfiles.clear();
    _userProfilesFetchTime.clear();
    if (kDebugMode) print('✓ Profile cache cleared');
  }
}
