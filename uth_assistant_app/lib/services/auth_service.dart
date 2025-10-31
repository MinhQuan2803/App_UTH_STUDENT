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

          // Lưu token
          await _storage.write(key: _tokenKey, value: accessToken);

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

  // --- THÊM HÀM MỚI ---
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // --- THÊM HÀM LẤY USER ID ---
  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  // --- HÀM ISLOGGEDIN (CẬP NHẬT: Kiểm tra cả expiration) ---
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
        // Token hết hạn, xóa token cũ
        if (kDebugMode) print('⚠ Token expired, clearing...');
        await signOut();
        return false;
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
}
