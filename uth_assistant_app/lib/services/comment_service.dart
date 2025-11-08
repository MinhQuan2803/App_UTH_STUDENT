import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/comment_model.dart';
import '../config/app_theme.dart';
import 'dart:io';
import 'dart:async';

class CommentService {
  static final String _baseUrl = AppAssets.commentApiBaseUrl;
  final AuthService _authService = AuthService();

  // --- Helper Functions (Tái sử dụng code) ---
  Future<Map<String, String>> _getAuthHeaders(
      {bool requireToken = false}) async {
    final String? token = await _authService.getToken();
    if (requireToken && token == null) {
      throw Exception('401: Chưa đăng nhập');
    }
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    if (kDebugMode) print('CommentService Status: ${response.statusCode}');
    if (response.body.startsWith('<!DOCTYPE html>')) {
      throw Exception('Lỗi Server: API endpoint không đúng (404/500).');
    }
    final dynamic decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    } else {
      final errorMessage =
          (decodedBody is Map && decodedBody.containsKey('message'))
              ? decodedBody['message']
              : 'Lỗi Server: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  Exception _handleNetworkError(dynamic e) {
    if (kDebugMode) print('CommentService Error: $e');
    if (e is TimeoutException)
      return Exception('Hết thời gian chờ kết nối server');
    if (e is SocketException) return Exception('Lỗi kết nối mạng.');
    return e is Exception ? e : Exception(e.toString());
  }

  // --- API Functions for Comments (Dựa trên api.pdf) ---

  /// Lấy comment gốc của một bài viết
  /// GET /api/comments?postId=:postId&page=0&limit=10
  Future<List<Comment>> getCommentsForPost({
    required String postId,
    int page = 0,
    int limit = 10,
  }) async {
    if (kDebugMode) print('=== GET COMMENTS FOR POST: $postId ===');

    final headers = await _getAuthHeaders(); // Auth là tùy chọn
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'postId': postId,
      'page': page.toString(),
      'limit': limit.toString(),
    });

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final List<dynamic> data = _processResponse(response);
      final comments = data.map((json) => Comment.fromJson(json)).toList();
      if (kDebugMode) print('✓ Loaded ${comments.length} comments');
      return comments;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy replies của một comment
  /// GET /api/comments?parentId=:commentId&page=0&limit=10
  Future<List<Comment>> getRepliesForComment({
    required String parentId,
    int page = 0,
    int limit = 10,
  }) async {
    if (kDebugMode) print('=== GET REPLIES FOR COMMENT: $parentId ===');
    final headers = await _getAuthHeaders();
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'parentId': parentId,
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final List<dynamic> data = _processResponse(response);
      final comments = data.map((json) => Comment.fromJson(json)).toList();
      if (kDebugMode) print('✓ Loaded ${comments.length} replies');
      return comments;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Tạo một comment (gốc hoặc reply)
  /// POST /api/comments
  Future<Comment> createComment({
    required String text,
    required String postId,
    String? parentId,
  }) async {
    if (kDebugMode) print('=== CREATE COMMENT ===');

    final headers = await _getAuthHeaders(requireToken: true);
    final body = {
      'text': text,
      'postId': postId, // API (theo api.pdf) yêu cầu postId cho cả reply
      if (parentId != null) 'parentId': parentId,
    };

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final data = _processResponse(response);
      // API trả về { "comment": CommentObject }
      final comment = Comment.fromJson(data['comment']);

      if (kDebugMode) print('✓ Comment created successfully');
      return comment;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}
