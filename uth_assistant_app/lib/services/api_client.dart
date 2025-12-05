import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ApiClient {
  final AuthService _authService = AuthService();

  // --- GET ---
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 90), // Tăng timeout mặc định
  }) async {
    return _makeRequestWithRetry(() async {
      final token =
          await _authService.getValidToken(); // Tự động refresh nếu cần
      final requestHeaders = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };
      return await http
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(timeout);
    });
  }

  // --- POST ---
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    return _makeRequestWithRetry(() async {
      final token = await _authService.getToken();
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
    });
  }

  // --- PUT ---
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    return _makeRequestWithRetry(() async {
      final token = await _authService.getToken();
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
    });
  }

  // --- DELETE ---
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    return _makeRequestWithRetry(() async {
      final token = await _authService.getToken();
      final requestHeaders = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };
      return await http
          .delete(Uri.parse(url), headers: requestHeaders)
          .timeout(timeout);
    });
  }

  // --- CORE LOGIC RETRY (QUAN TRỌNG) ---
  Future<http.Response> _makeRequestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;

    try {
      response = await request();
    } catch (e) {
      // Nếu lỗi mạng ngay lần đầu, ném lỗi ra UI (không logout)
      rethrow;
    }

    // Nếu 401 (Unauthorized) -> Token hết hạn
    if (response.statusCode == 401) {
      if (kDebugMode) print('⚠️ Got 401, attempting to refresh token...');

      // Gọi hàm refresh mới
      final result = await _authService.refreshAccessToken();

      // Nếu thành công HOẶC lỗi mạng (server ngủ) -> Thử retry
      if (result == RefreshResult.success ||
          result == RefreshResult.networkError) {
        if (kDebugMode)
          print('✅ Token refreshed (or network wait), retrying request...');

        // Retry request với token (mới hoặc cũ)
        try {
          response = await request();
        } catch (e) {
          // Retry vẫn lỗi (do server chưa dậy hẳn) -> Ném lỗi ra, NHƯNG KHÔNG LOGOUT
          rethrow;
        }
      } else {
        // RefreshResult.failed -> Token hỏng thật -> Logout
        if (kDebugMode) print('❌ Refresh token failed, user needs to re-login');
        await _authService.signOut();
        throw Exception(
            '401: Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return response;
  }

  // --- MULTIPART REQUEST (UPLOAD FILE) ---
  Future<http.StreamedResponse> multipartRequest(
    String method,
    String url, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final token = await _authService.getValidToken();
    var request = http.MultipartRequest(method, Uri.parse(url));

    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    try {
      final streamedResponse = await request.send().timeout(timeout);

      if (streamedResponse.statusCode == 401) {
        if (kDebugMode) print('⚠️ Multipart got 401, refreshing...');

        final result = await _authService.refreshAccessToken();

        if (result == RefreshResult.success ||
            result == RefreshResult.networkError) {
          // Tạo lại request
          final newToken = await _authService.getValidToken();
          var retryRequest = http.MultipartRequest(method, Uri.parse(url));

          if (newToken != null)
            retryRequest.headers['Authorization'] = 'Bearer $newToken';
          if (fields != null) retryRequest.fields.addAll(fields);
          if (files != null) retryRequest.files.addAll(files);

          return await retryRequest.send().timeout(timeout);
        } else {
          await _authService.signOut();
          throw Exception('401: Phiên đăng nhập hết hạn.');
        }
      }
      return streamedResponse;
    } catch (e) {
      if (kDebugMode) print('❌ Multipart request error: $e');
      rethrow;
    }
  }
}
