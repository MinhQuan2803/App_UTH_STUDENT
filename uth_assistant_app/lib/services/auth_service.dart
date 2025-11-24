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

class AuthService {
  static final String _baseUrl = AppAssets.authApiBaseUrl;
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _usernameKey = 'username';

  static const _timeoutDuration = Duration(seconds: 30);

  // ... (Các hàm signUp, signIn giữ nguyên) ...
  
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
      if (statusCode == 201 || statusCode == 204) {
        return {'statusCode': 201, 'message': message};
      } else {
        return {'statusCode': statusCode, 'message': message};
      }
    } on TimeoutException {
      return {'statusCode': 504, 'message': 'Máy chủ phản hồi quá chậm.'};
    } on SocketException {
      return {'statusCode': 503, 'message': 'Lỗi kết nối mạng.'};
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Lỗi không xác định: ${e.toString()}'
      };
    }
  }

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

        if (kDebugMode) {
          print('=== LOGIN RESPONSE ===');
          print('Has accessToken: ${accessToken != null}');
          print('Has refreshToken: ${refreshToken != null}');
        }

        if (accessToken != null && accessToken is String) {
          Map<String, dynamic> decodedToken;
          try {
            decodedToken = JwtDecoder.decode(accessToken);
          } catch (decodeError) {
            if (kDebugMode) print('✗ Token decode error: $decodeError');
            return {
              'success': false,
              'message': 'Lỗi giải mã token: ${decodeError.toString()}'
            };
          }

          if (kDebugMode) {
            print('=== DECODED TOKEN ===');
            print(decodedToken);
          }

          final String? userId = decodedToken['userId'];
          final String? username = decodedToken['username'];

          try {
            await _storage.write(key: _tokenKey, value: accessToken);

            if (refreshToken != null && refreshToken is String) {
              await _storage.write(key: _refreshTokenKey, value: refreshToken);
              if (kDebugMode) print('✓ Saved refresh token');
            } else {
              await _storage.write(key: _refreshTokenKey, value: accessToken);
              if (kDebugMode)
                print(
                    '⚠ No separate refreshToken, using accessToken as fallback');
            }

            if (userId != null && userId.isNotEmpty) {
              await _storage.write(key: 'userId', value: userId);
              if (kDebugMode) print('✓ Saved userId: $userId');
            }

            if (username != null && username.isNotEmpty) {
              await _storage.write(key: _usernameKey, value: username);
              if (kDebugMode) print('✓ Saved username from TOKEN: $username');
            } else {
              if (kDebugMode)
                print('⚠ Token không chứa username, thử parse từ message...');
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
                      if (kDebugMode)
                        print('✓ Saved username from MESSAGE: $parsedUsername');
                    }
                  } else {
                    if (kDebugMode)
                      print('✗ KHÔNG THỂ PARSE USERNAME từ message: $message');
                  }
                } catch (e) {
                  if (kDebugMode) print('✗ LỖI khi parse username: $e');
                }
              } else {
                if (kDebugMode)
                  print(
                      '✗ KHÔNG THỂ LẤY USERNAME (Token và Message đều không có)');
              }
            }
          } catch (storageError) {
            if (kDebugMode) print('✗ Storage error: $storageError');
            return {
              'success': false,
              'message':
                  'Lỗi lưu thông tin đăng nhập: ${storageError.toString()}'
            };
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
      if (kDebugMode) print('Signin Timeout');
      return {
        'success': false,
        'message': 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.'
      };
    } on SocketException {
      if (kDebugMode) print('Signin Socket Error');
      return {
        'success': false,
        'message': 'Lỗi kết nối mạng. Kiểm tra Internet của bạn.'
      };
    } on FormatException catch (e) {
      if (kDebugMode) print('Signin Format Error: $e');
      return {
        'success': false,
        'message': 'Lỗi dữ liệu từ server. Vui lòng thử lại sau.'
      };
    } catch (e) {
      if (kDebugMode) print('Signin Error: $e');
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

      if (kDebugMode) print('✓ All caches and tokens cleared');
      
      // Điều hướng về màn hình Login bằng Global Key
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login', 
        (route) => false,
      );
      
    } catch (e) {
      if (kDebugMode) print('✗ Signout Error: $e');
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
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        if (kDebugMode) print('✗ No refresh token available');
        return false;
      }

      if (kDebugMode) {
        print('=== REFRESHING ACCESS TOKEN ===');
        print('Refresh token exists: ${refreshToken.substring(0, 20)}...');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/refresh'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken, 
            }),
          )
          .timeout(_timeoutDuration);

      if (kDebugMode) {
        print('Refresh response status: ${response.statusCode}');
        print('Refresh response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccessToken = body['accessToken'];

        if (newAccessToken != null) {
          await _storage.write(key: _tokenKey, value: newAccessToken);

          final newRefreshToken = body['refreshToken'];
          if (newRefreshToken != null) {
            await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
            if (kDebugMode) print('✓ New refresh token also saved');
          }

          if (kDebugMode) print('✓ Access token refreshed successfully');
          return true;
        } else {
          if (kDebugMode) print('✗ Response 200 but no accessToken in body');
          return false;
        }
      } else {
        if (kDebugMode) {
          print('✗ Refresh failed with status: ${response.statusCode}');
          print('✗ Error message: ${response.body}');
        }
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _refreshTokenKey);
        return false;
      }
    } on TimeoutException {
      if (kDebugMode) print('✗ Refresh timeout - network issue');
      return false;
    } on SocketException {
      if (kDebugMode) print('✗ Refresh failed - no internet');
      return false;
    } catch (e) {
      if (kDebugMode) print('✗ Refresh token error: $e');
      return false;
    }
  }

  // --- HÀM ISLOGGEDIN (Giữ nguyên) ---
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      bool isExpired = JwtDecoder.isExpired(token);

      if (isExpired) {
        if (kDebugMode) print('⚠ Token expired, trying to refresh...');

        final hasRefreshToken = await getRefreshToken();
        if (hasRefreshToken != null) {
          final refreshed = await refreshAccessToken();

          if (refreshed) {
            if (kDebugMode) print('✓ Token refreshed, user still logged in');
            return true;
          } else {
            if (kDebugMode) print('✗ Refresh failed, user logged out');
            // Tự động đăng xuất nếu refresh thất bại
            await signOut(); 
            return false;
          }
        } else {
          if (kDebugMode)
            print('✗ No refresh token, backend not support refresh mechanism');
          await signOut();
          return false;
        }
      }

      if (kDebugMode) {
        final remainingTime = JwtDecoder.getRemainingTime(token);
        print(
            '✓ Token valid, expires in: ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('✗ Invalid token: $e');
      await signOut();
      return false;
    }
  }

  // --- HÀM LẤY TOKEN HỢP LỆ (Đã thêm logic điều hướng) ---
  Future<String?> getValidToken({bool autoRedirect = true}) async {
    final token = await getToken();

    // 1. Nếu không có token -> Đăng xuất ngay (nếu autoRedirect = true)
    if (token == null) {
      if (autoRedirect) {
        if (kDebugMode) print('🛑 No token found. Redirecting to Login...');
        await signOut();
      }
      return null;
    }

    bool isExpired = JwtDecoder.isExpired(token);
    Duration remainingTime = Duration.zero;
    try {
      remainingTime = JwtDecoder.getRemainingTime(token);
    } catch (e) {
      if (kDebugMode) print('✗ Cannot get remaining time: $e');
      isExpired = true;
    }

    // Refresh trước 2 phút
    bool aboutToExpire = !isExpired && remainingTime.inMinutes < 2; 
    
    if (isExpired || aboutToExpire) {
      if (kDebugMode) {
        if (isExpired) {
          print('⚠ Token expired, refreshing...');
        } else {
          print(
              '⚠ Token about to expire (${remainingTime.inMinutes}m left), refreshing...');
        }
      }

      final refreshed = await refreshAccessToken();
      if (refreshed) {
        return await getToken();
      } else {
        if (kDebugMode) print('✗ Cannot refresh token. Redirecting to Login...');
        // 2. Nếu refresh thất bại -> Đăng xuất ngay
        if (autoRedirect) {
          await signOut();
        }
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