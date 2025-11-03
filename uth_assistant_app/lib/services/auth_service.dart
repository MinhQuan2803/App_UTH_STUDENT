import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String _baseUrl = 'https://uthstudent.onrender.com/api/auth';
  final _storage = const FlutterSecureStorage();

  // THÊM KEY MỚI
  static const String _tokenKey = 'accessToken';
  static const String _refreshTokenKey =
      'refreshToken'; // KEY MỚI cho refresh token
  static const String _usernameKey = 'username'; // Key để lưu username

  static const _timeoutDuration = Duration(seconds: 30);

  // --- HÀM SIGNUP (Giữ nguyên) ---
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

      // Chấp nhận 201 (Created) hoặc 204 (No Content)
      final int statusCode = response.statusCode;
      if (statusCode == 201 || statusCode == 204) {
        return {'statusCode': 201, 'message': message}; // Chuẩn hóa về 201
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

  // --- HÀM SIGNIN (CẬP NHẬT) ---
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
        final refreshToken =
            body['refreshToken']; // Lấy refresh token từ response

        // DEBUG: Kiểm tra xem server có trả về refresh token không
        if (kDebugMode) {
          print('=== LOGIN RESPONSE ===');
          print('Has accessToken: ${accessToken != null}');
          print('Has refreshToken: ${refreshToken != null}');
          if (refreshToken == null) {
            print('⚠️ WARNING: Server không trả về refreshToken!');
            print('Response body: $body');
          }
        }

        if (accessToken != null) {
          // Decode token để lấy thông tin
          Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);

          // Debug logs (chỉ hiển thị trong debug mode)
          if (kDebugMode) {
            print('=== DECODED TOKEN ===');
            print(decodedToken);
          }

          // Lấy userId và username từ token
          final String? userId = decodedToken['userId'];
          final String? username = decodedToken['username'];

          // Lưu access token
          await _storage.write(key: _tokenKey, value: accessToken);

          // Lưu refresh token nếu có
          if (refreshToken != null) {
            await _storage.write(key: _refreshTokenKey, value: refreshToken);
            if (kDebugMode) print('✓ Saved refresh token');
          } else {
            // Fallback: Nếu server không trả refreshToken riêng, dùng accessToken
            // (Một số backend dùng cùng token cho refresh)
            await _storage.write(key: _refreshTokenKey, value: accessToken);
            if (kDebugMode)
              print(
                  '⚠ No separate refreshToken, using accessToken as fallback');
          }

          // Lưu userId nếu có
          if (userId != null) {
            await _storage.write(key: 'userId', value: userId);
            if (kDebugMode) print('✓ Saved userId: $userId');
          }

          // Lưu username
          if (username != null && username.isNotEmpty) {
            // Trường hợp 1: Lấy được username từ token (BEST)
            await _storage.write(key: _usernameKey, value: username);
            if (kDebugMode) print('✓ Saved username from TOKEN: $username');
          } else {
            // Trường hợp 2: Fallback - Parse từ message (nếu token không có username)
            if (kDebugMode)
              print('⚠ Token không chứa username, thử parse từ message...');
            if (message != null && message.contains('đăng nhập thành công')) {
              try {
                // Parse: "Bạn john_doe đăng nhập thành công" -> "john_doe"
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
    } catch (e) {
      if (kDebugMode) print('Signin Error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối hoặc giải mã token: ${e.toString()}'
      };
    }
  }

  // --- HÀM SIGNOUT (CẬP NHẬT) ---
  Future<void> signOut() async {
    try {
      // Xóa tất cả dữ liệu đã lưu
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey); // Xóa refresh token
      await _storage.delete(key: _usernameKey);
      await _storage.delete(key: 'userId');
      if (kDebugMode) print('✓ Local tokens and user info deleted');
    } catch (e) {
      if (kDebugMode) print('✗ Signout Error (local delete): $e');
    }
  }

  // --- HÀM GETTOKEN (Giữ nguyên) ---
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // --- HÀM LẤY REFRESH TOKEN ---
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // --- THÊM HÀM MỚI ---
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // --- HÀM LẤY USER ID ---
  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  // --- HÀM REFRESH TOKEN ---
  /// Dùng refresh token để lấy access token mới
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

      // Gửi refresh token theo format backend yêu cầu
      final response = await http
          .post(
            Uri.parse('$_baseUrl/refresh'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken, // Gửi trong body
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
          // Lưu access token mới
          await _storage.write(key: _tokenKey, value: newAccessToken);

          // Cập nhật refresh token nếu server trả về mới
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
        // Refresh token hết hạn/không hợp lệ → Xóa tokens
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

  // --- HÀM ISLOGGEDIN (CẬP NHẬT: Tự động refresh khi hết hạn) ---
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();

      // Không có token
      if (token == null || token.isEmpty) {
        return false;
      }

      // Kiểm tra token có hết hạn chưa
      bool isExpired = JwtDecoder.isExpired(token);

      if (isExpired) {
        // Token hết hạn, thử refresh (nếu có refresh token)
        if (kDebugMode) print('⚠ Token expired, trying to refresh...');

        final hasRefreshToken = await getRefreshToken();
        if (hasRefreshToken != null) {
          // Có refresh token → thử refresh
          final refreshed = await refreshAccessToken();

          if (refreshed) {
            if (kDebugMode) print('✓ Token refreshed, user still logged in');
            return true;
          } else {
            if (kDebugMode) print('✗ Refresh failed, user logged out');
            return false;
          }
        } else {
          // Không có refresh token → đăng xuất (backend chưa hỗ trợ)
          if (kDebugMode)
            print('✗ No refresh token, backend not support refresh mechanism');
          await signOut();
          return false;
        }
      }

      // Token còn hợp lệ
      if (kDebugMode) {
        final remainingTime = JwtDecoder.getRemainingTime(token);
        print(
            '✓ Token valid, expires in: ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m');
      }
      return true;
    } catch (e) {
      // Lỗi khi decode token (token không hợp lệ)
      if (kDebugMode) print('✗ Invalid token: $e');
      await signOut();
      return false;
    }
  }

  // --- HÀM LẤY TOKEN HỢP LỆ (Tự động refresh nếu cần) ---
  /// Lấy access token hợp lệ, tự động refresh nếu hết hạn hoặc sắp hết hạn
  /// Refresh khi còn < 5 phút để tránh lỗi giữa chừng request
  Future<String?> getValidToken() async {
    final token = await getToken();

    if (token == null) return null;

    // Kiểm tra token còn hạn không
    bool isExpired = JwtDecoder.isExpired(token);

    // Kiểm tra token sắp hết hạn (còn < 5 phút)
    Duration remainingTime = Duration.zero;
    try {
      remainingTime = JwtDecoder.getRemainingTime(token);
    } catch (e) {
      if (kDebugMode) print('✗ Cannot get remaining time: $e');
      isExpired = true;
    }

    bool aboutToExpire = remainingTime.inMinutes < 5;

    if (isExpired || aboutToExpire) {
      if (kDebugMode) {
        if (isExpired) {
          print('⚠ Token expired, refreshing...');
        } else {
          print(
              '⚠ Token about to expire (${remainingTime.inMinutes}m left), refreshing...');
        }
      }

      // Tự động refresh
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        // Lấy token mới sau khi refresh
        return await getToken();
      } else {
        if (kDebugMode) print('✗ Cannot refresh token');
        return null;
      }
    }

    return token;
  }
}
