import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// HTTP Client wrapper tự động xử lý refresh token cho mọi API calls
class ApiClient {
  final AuthService _authService = AuthService();

  /// GET request với auto refresh token
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequestWithRetry(
      () async {
        final token = await _authService.getValidToken();
        final requestHeaders = {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        };

        return await http
            .get(
              Uri.parse(url),
              headers: requestHeaders,
            )
            .timeout(timeout);
      },
    );
  }

  /// POST request với auto refresh token
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequestWithRetry(
      () async {
        final token = await _authService.getValidToken();
        final requestHeaders = {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        };

        return await http
            .post(
              Uri.parse(url),
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
      },
    );
  }

  /// PUT request với auto refresh token
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequestWithRetry(
      () async {
        final token = await _authService.getValidToken();
        final requestHeaders = {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        };

        return await http
            .put(
              Uri.parse(url),
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
      },
    );
  }

  /// DELETE request với auto refresh token
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequestWithRetry(
      () async {
        final token = await _authService.getValidToken();
        final requestHeaders = {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        };

        return await http
            .delete(
              Uri.parse(url),
              headers: requestHeaders,
            )
            .timeout(timeout);
      },
    );
  }

  /// Core logic: Thực hiện request, tự động retry nếu 401
  Future<http.Response> _makeRequestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    // Lần thử đầu tiên
    http.Response response = await request();

    // Nếu 401 (Unauthorized) → Token hết hạn
    if (response.statusCode == 401) {
      if (kDebugMode) {
        print('⚠️ Got 401, attempting to refresh token...');
      }

      // Thử refresh token
      final refreshed = await _authService.refreshAccessToken();

      if (refreshed) {
        if (kDebugMode) {
          print('✅ Token refreshed, retrying request...');
        }

        // Retry request với token mới
        response = await request();

        if (kDebugMode) {
          print('✅ Retry response: ${response.statusCode}');
        }
      } else {
        if (kDebugMode) {
          print('❌ Refresh token failed, user needs to re-login');
        }

        // Refresh thất bại → Xóa token và throw để force logout
        await _authService.signOut();
        throw Exception(
            '401: Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return response;
  }

  /// Multipart request (dùng cho upload file)
  Future<http.StreamedResponse> multipartRequest(
    String method,
    String url, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final token = await _authService.getValidToken();

    var request = http.MultipartRequest(method, Uri.parse(url));

    // Add headers
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add files
    if (files != null) {
      request.files.addAll(files);
    }

    try {
      final streamedResponse = await request.send().timeout(timeout);

      // Nếu 401 → cần refresh và retry
      if (streamedResponse.statusCode == 401) {
        if (kDebugMode) print('⚠️ Multipart got 401, refreshing...');

        final refreshed = await _authService.refreshAccessToken();

        if (refreshed) {
          // Tạo request mới với token mới
          final newToken = await _authService.getToken();
          var retryRequest = http.MultipartRequest(method, Uri.parse(url));

          if (newToken != null) {
            retryRequest.headers['Authorization'] = 'Bearer $newToken';
          }

          if (fields != null) {
            retryRequest.fields.addAll(fields);
          }

          if (files != null) {
            retryRequest.files.addAll(files);
          }

          return await retryRequest.send().timeout(timeout);
        } else {
          await _authService.signOut();
          throw Exception(
              '401: Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
        }
      }

      return streamedResponse;
    } catch (e) {
      if (kDebugMode) print('❌ Multipart request error: $e');
      rethrow;
    }
  }
}
