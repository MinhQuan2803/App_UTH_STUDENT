import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Cần import để dùng NavigatorState
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/app_theme.dart';
import '../main.dart'; // IMPORT main.dart để lấy navigatorKey
import 'profile_service.dart';
import 'post_service.dart';
import 'news_service.dart';

enum RefreshResult { success, failed, networkError }

class AuthService {
  static final String _baseUrl = AppAssets.authApiBaseUrl;
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _usernameKey = 'username';

  // ... (Các hàm signUp, signIn giữ nguyên) ...

  static const _timeoutDuration = Duration(seconds: 90);

  // --- SIGN UP ---
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeoutDuration);

      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Không có thông báo từ server';
      final int statusCode = response.statusCode;

      if (kDebugMode) {
        print('=== SIGNUP RESPONSE ===');
        print('Status Code: $statusCode');
        print('Message: $message');
        print('Full Body: $body');
      }

      if (statusCode == 201 || statusCode == 204) {
        return {'statusCode': 201, 'message': message};
      } else {
        // Backend trả lỗi (400, 409, 500...) → Hiển thị message từ server
        return {'statusCode': statusCode, 'message': message};
      }
    } on TimeoutException {
      return {'statusCode': 504, 'message': 'Máy chủ phản hồi quá chậm.'};
    } on SocketException {
      return {'statusCode': 503, 'message': 'Lỗi kết nối mạng.'};
    } catch (e) {
      if (kDebugMode) print('SignUp Exception: $e');
      return {
        'statusCode': 500,
        'message': 'Lỗi không xác định: ${e.toString()}'
      };
    }
  }

  // --- SIGN IN ---
  // --- SIGN IN ---
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeoutDuration);

      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Không có thông báo';

      if (response.statusCode == 200) {
        final accessToken = body['accessToken'];
        final refreshToken = body['refreshToken'];

        if (accessToken != null && accessToken is String) {
          Map<String, dynamic> decodedToken;
          try {
            decodedToken = JwtDecoder.decode(accessToken);
          } catch (decodeError) {
            return {'success': false, 'message': 'Lỗi giải mã token'};
          }

          final String? userId = decodedToken['userId'];
          // Giữ nguyên logic lấy username cũ của bạn
          final String? username = decodedToken['username'];

          try {
            await _storage.write(key: _tokenKey, value: accessToken);

            if (refreshToken != null && refreshToken is String) {
              await _storage.write(key: _refreshTokenKey, value: refreshToken);
            } else {
              await _storage.write(key: _refreshTokenKey, value: accessToken);
            }

            if (userId != null && userId.isNotEmpty) {
              await _storage.write(key: 'userId', value: userId);
            }

            // Logic fallback username cũ của bạn (giữ nguyên để app hiển thị đúng)
            if (username != null && username.isNotEmpty) {
              await _storage.write(key: _usernameKey, value: username);
            } else {
              if (message != null && message.contains('đăng nhập thành công')) {
                try {
                  final RegExp regex =
                      RegExp(r'Bạn\s+(\S+)\s+đăng nhập thành công');
                  final match = regex.firstMatch(message);
                  if (match != null) {
                    final parsedUsername = match.group(1);
                    if (parsedUsername != null) {
                      await _storage.write(
                          key: _usernameKey, value: parsedUsername);
                    }
                  }
                } catch (e) {
                  if (kDebugMode) print('Parse username error: $e');
                }
              }
            }
          } catch (storageError) {
            // Ignore storage error
          }
          return {'success': true, 'message': message};
        } else {
          return {
            'success': false,
            'message': 'Lỗi: Server không trả về token.'
          };
        }
      } else {
        return {'success': false, 'message': message};
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Máy chủ đang khởi động, vui lòng thử lại.'
      };
    } on SocketException {
      return {'success': false, 'message': 'Lỗi kết nối mạng.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Đăng nhập thất bại: ${e.toString()}'
      };
    }
  }

  // --- HÀM SIGNOUT (Cập nhật để dùng navigatorKey) ---
  Future<void> signOut() async {
    try {
      ProfileService.clearCache();
      PostService.clearCache();
      NewsService.clearCache();

      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _usernameKey);
      await _storage.delete(key: 'userId');

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (kDebugMode) print('Signout Error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'code': code,
            }),
          )
          .timeout(_timeoutDuration);

      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Không có phản hồi';
      final bool success = body['success'] ?? false;

      if (kDebugMode) {
        print('=== VERIFY CODE RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Success: $success');
        print('Message: $message');
      }

      // Backend trả về status 200 khi thành công, 400 khi lỗi
      if (response.statusCode == 200 && success) {
        return {'success': true, 'message': message};
      } else {
        return {'success': false, 'message': message};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Máy chủ phản hồi quá chậm.'};
    } on SocketException {
      return {'success': false, 'message': 'Lỗi kết nối mạng.'};
    } catch (e) {
      if (kDebugMode) print('Verify Error: $e');
      return {'success': false, 'message': 'Lỗi xác thực: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/resend-verification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
            }),
          )
          .timeout(_timeoutDuration);

      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Không có phản hồi';
      final bool success = body['success'] ?? false;

      if (kDebugMode) {
        print('=== RESEND VERIFICATION RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Success: $success');
        print('Message: $message');
      }

      // Backend trả về status 200 cho cả thành công và một số trường hợp đặc biệt
      if (response.statusCode == 200 && success) {
        return {'success': true, 'message': message};
      } else {
        return {'success': false, 'message': message};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Máy chủ phản hồi quá chậm.'};
    } on SocketException {
      return {'success': false, 'message': 'Lỗi kết nối mạng.'};
    } catch (e) {
      if (kDebugMode) print('Resend Error: $e');
      return {'success': false, 'message': 'Lỗi gửi mã: ${e.toString()}'};
    }
  }

  // ... (Các hàm getToken, getRefreshToken, getUsername, getUserId giữ nguyên) ...
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  // ... (Hàm refreshAccessToken giữ nguyên) ...

  Future<RefreshResult> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return RefreshResult.failed;
      }

      if (kDebugMode) print('=== REFRESHING TOKEN (Wait 90s) ===');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeoutDuration); // 90s timeout

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccessToken = body['accessToken'];

        if (newAccessToken != null) {
          await _storage.write(key: _tokenKey, value: newAccessToken);
          final newRefreshToken = body['refreshToken'];
          if (newRefreshToken != null) {
            await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
          }
          if (kDebugMode) print('✓ Refresh Success');
          return RefreshResult.success;
        } else {
          return RefreshResult.failed;
        }
      } else {
        // 401, 403 -> Token hết hạn thật sự -> Logout
        if (kDebugMode) print('✗ Refresh Failed (Server rejected)');
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _refreshTokenKey);
        return RefreshResult.failed;
      }
    } catch (e) {
      // Timeout, Mất mạng -> QUAN TRỌNG: TRẢ VỀ NETWORK ERROR ĐỂ KHÔNG LOGOUT
      if (kDebugMode) print('⚠ Network/Server Sleep Error: $e');
      return RefreshResult.networkError;
    }
  }

  // --- HÀM ISLOGGEDIN (Giữ nguyên) ---
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      bool isExpired = JwtDecoder.isExpired(token);

      if (isExpired) {
        if (kDebugMode) print('⚠ Token expired, trying to refresh...');

        // Gọi hàm refresh mới
        final result = await refreshAccessToken();

        switch (result) {
          case RefreshResult.success:
            return true; // Có token mới -> OK

          case RefreshResult.networkError:
            // QUAN TRỌNG: Server ngủ hoặc mạng lag -> VẪN GIỮ ĐĂNG NHẬP
            if (kDebugMode) print('⚠ Network error, keeping session active');
            return true;

          case RefreshResult.failed:
            // Server từ chối -> Logout
            await signOut();
            return false;
        }
      }
      return true;
    } catch (e) {
      await signOut();
      return false;
    }
  }

  // --- HÀM LẤY TOKEN HỢP LỆ (Đã thêm logic điều hướng) ---
  Future<String?> getValidToken({bool autoRedirect = true}) async {
    final token = await getToken();
    if (token == null) {
      if (autoRedirect) await signOut();
      return null;
    }

    bool isExpired = JwtDecoder.isExpired(token);

    // 🔥 SỬA: Kiểm tra thời gian còn lại
    Duration remainingTime = Duration.zero;
    try {
      remainingTime = JwtDecoder.getRemainingTime(token);
    } catch (e) {
      if (kDebugMode) print('✗ Cannot get remaining time: $e');
      isExpired = true; // Nếu lỗi parse → Coi như hết hạn
    }

    // 🔥 QUAN TRỌNG: Refresh trước 2 phút (120s) để tránh 401
    bool aboutToExpire = !isExpired && remainingTime.inSeconds < 120;

    if (kDebugMode && aboutToExpire) {
      print(
          '⚠ Token sắp hết hạn (còn ${remainingTime.inSeconds}s), refreshing...');
    }

    // Nếu hết hạn HOẶC sắp hết hạn → Refresh
    if (isExpired || aboutToExpire) {
      final result = await refreshAccessToken();

      if (result == RefreshResult.success) {
        return await getToken();
      } else if (result == RefreshResult.networkError) {
        // Nếu lỗi mạng, vẫn trả về token cũ (nếu chưa hết hạn)
        if (!isExpired) {
          if (kDebugMode) print('⚠ Network error, using old token');
          return token;
        }
        return null;
      } else {
        if (autoRedirect) await signOut();
        return null;
      }
    }
    return token;
  }

  // --- HÀM GỬI FCM TOKEN LÊN SERVER ---
  Future<bool> saveFcmToken(String fcmToken) async {
    try {
      // Không cần autoRedirect ở đây vì hàm này thường chạy ngầm
      final token = await getValidToken(autoRedirect: false);
      if (token == null) {
        if (kDebugMode) print('✗ No access token, cannot save FCM token');
        return false;
      }

      final userApiBaseUrl = AppAssets.userApiBaseUrl;
      final response = await http
          .patch(
            Uri.parse('$userApiBaseUrl/me/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'fcmToken': fcmToken}),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        if (kDebugMode) print('✓ FCM token saved to server');
        return true;
      } else {
        if (kDebugMode) {
          print('✗ Failed to save FCM token: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return false;
      }
    } on TimeoutException {
      if (kDebugMode) print('✗ Timeout saving FCM token');
      return false;
    } on SocketException {
      if (kDebugMode) print('✗ Network error saving FCM token');
      return false;
    } catch (e) {
      if (kDebugMode) print('✗ Error saving FCM token: $e');
      return false;
    }
  }
}
