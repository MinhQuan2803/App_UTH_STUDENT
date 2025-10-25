import 'dart:convert';
import 'dart:io'; // Import để bắt SocketException
import 'dart:async'; // THÊM DÒNG NÀY để sử dụng TimeoutException
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://uthstudent.onrender.com/api/auth';
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'accessToken';

   // Trả về int (status code) thay vì bool
   Future<int> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10)); // Thêm timeout

      print('Signup Response Status: ${response.statusCode}');
      print('Signup Response Body: ${response.body}');
      return response.statusCode; // Trả về mã trạng thái thực tế
    
    } on TimeoutException catch (e) { // Giờ đây TimeoutException đã được nhận dạng
      print('Signup Error: Timeout - $e');
      return 504; // Gateway Timeout
    } on SocketException catch (e) {
      print('Signup Error: Network/Socket Error - $e');
      return 503; // Service Unavailable (thường do lỗi mạng)
    } catch (e) {
      print('Signup Error: $e');
      return 500; // Internal Server Error (hoặc lỗi chung)
    }
  }

  // --- Hàm signIn ---
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Signin Response Status: ${response.statusCode}');
      print('Signin Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final accessToken = body['accessToken'];
        if (accessToken != null) {
          await _storage.write(key: _tokenKey, value: accessToken);
          print('Token saved: $accessToken');
          return true;
        } else {
           print('Access token is null in response');
        }
      }
      return false;
    } on TimeoutException catch (e) { // Giờ đây TimeoutException đã được nhận dạng
       print('Signin Error: Timeout - $e');
       return false;
    } on SocketException catch (e) {
      print('Signin Error: Network/Socket Error - $e');
      return false;
    } catch (e) {
      print('Signin Error: $e');
      return false;
    }
  }

   // --- Các hàm còn lại ---
   Future<void> signOut() async {
     try {
       await _storage.delete(key: _tokenKey);
       print('Token deleted');
     } catch (e) {
       print('Signout Error: $e');
     }
   }
   Future<String?> getToken() async {
     final token = await _storage.read(key: _tokenKey);
     return token;
   }
   Future<bool> isLoggedIn() async {
     final token = await getToken();
     return token != null;
   }
}

