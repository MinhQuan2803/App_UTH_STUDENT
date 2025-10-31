import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/post_model.dart';
import 'dart:io'; // Import dart:io
import 'dart:async'; // Import dart:async

class PostService {
  static const String _baseUrl = 'https://uthstudent.onrender.com/api/posts';
  final AuthService _authService = AuthService();

  // Cache
  static List<Post>? _cachedPosts;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // --- Helper Functions (Tái sử dụng code) ---

  /// Lấy headers kèm token (nếu có)
  Future<Map<String, String>> _getAuthHeaders({bool requireToken = false}) async {
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

  /// Xử lý và giải mã response (Hỗ trợ tiếng Việt)
  dynamic _processResponse(http.Response response) {
    if (kDebugMode) print('Response Status: ${response.statusCode}');
    if (kDebugMode && response.statusCode >= 300) {
       print('Response Body: ${response.body}');
    }

    // Xử lý lỗi HTML (404/500 từ Render)
    if (response.body.startsWith('<!DOCTYPE html>')) {
      throw Exception('Lỗi Server: API endpoint không đúng hoặc bị crash (404/500).');
    }

    final dynamic decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody; // Trả về dữ liệu đã decode
    } else {
      // Ném lỗi từ server (nếu có)
      final errorMessage = (decodedBody is Map && decodedBody.containsKey('error'))
          ? decodedBody['error']
          : (decodedBody is Map && decodedBody.containsKey('message'))
              ? decodedBody['message']
              : 'Lỗi Server: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  /// Xử lý lỗi mạng
  Exception _handleNetworkError(dynamic e) {
    if (kDebugMode) print('API Call Error: $e');
    if (e is TimeoutException) {
      return Exception('Hết thời gian chờ kết nối server');
    }
    if (e is SocketException) {
      return Exception('Lỗi kết nối mạng. Vui lòng kiểm tra lại.');
    }
    return e is Exception ? e : Exception(e.toString());
  }

  // --- API Functions ---

  /// Lấy danh sách bài viết trang chủ
  /// GET /api/posts/home
  Future<List<Post>> getHomeFeed({
    int page = 0,
    int limit = 10,
    String feed = 'public',
    bool forceRefresh = false,
  }) async {
    // 1. Kiểm tra cache
    if (!forceRefresh && page == 0 && _cachedPosts != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        if (kDebugMode) print('✓ Using cached posts (${timeSinceLastFetch.inMinutes} min old)');
        return _cachedPosts!;
      }
    }
    if (kDebugMode) print('=== GET HOME FEED ===');

    // 2. Chuẩn bị gọi API
    final headers = await _getAuthHeaders(); // Auth là tùy chọn
    final uri = Uri.parse('$_baseUrl/home').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      'feed': feed,
    });
    if (kDebugMode) print('Requesting URL: $uri');

    // 3. Gọi API và xử lý
    try {
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      final List<dynamic> data = _processResponse(response);

      final posts = data.map((json) => Post.fromJson(json)).toList();

      if (page == 0) {
        _cachedPosts = posts;
        _lastFetchTime = DateTime.now();
      }
      if (kDebugMode) print('✓ Loaded ${posts.length} posts');
      return posts;

    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy bài viết của một user cụ thể trong profile
  /// GET /api/posts/profile/:username
  Future<List<Post>> getProfilePosts({
    required String username,
    int page = 0,
    int limit = 10,
  }) async {
    if (kDebugMode) print('=== GET PROFILE POSTS: $username ===');
    
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/profile/$username').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    try {
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      
      // Kiểm tra 404 cho trường hợp không có bài viết
      if (response.statusCode == 404) {
         if (kDebugMode) print('✓ User has no posts yet or User not found');
         return [];
      }

      final List<dynamic> data = _processResponse(response);
      final posts = data.map((json) => Post.fromJson(json)).toList();
      
      if (kDebugMode) print('✓ Loaded ${posts.length} posts for $username');
      return posts;

    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Xóa cache
  static void clearCache() {
    _cachedPosts = null;
    _lastFetchTime = null;
    if (kDebugMode) print('Cache cleared');
  }

  /// Tạo bài viết mới
  /// POST /api/posts/createpost
  Future<Post> createPost({
    required String text,
    List<String>? mediaUrls,
    String privacy = 'public',
    String? docId,
  }) async {
    if (kDebugMode) print('=== CREATE POST ===');
    
    final headers = await _getAuthHeaders(requireToken: true);
    final body = {
      'text': text,
      'privacy': privacy,
      if (mediaUrls != null && mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
      if (docId != null) 'docId': docId,
    };

    try {
      final response = await http.post(
        // SỬA LỖI: Endpoint phải là /createpost
        Uri.parse('$_baseUrl/createpost'), 
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final data = _processResponse(response); // API trả về 201 Created
      final post = Post.fromJson(data);

      clearCache();
      if (kDebugMode) print('✓ Post created successfully');
      return post;

    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Cập nhật bài viết
  /// PUT /api/posts/updatepost/:id
  Future<Post> updatePost({
    required String postId,
    required String text,
    List<String>? mediaUrls,
    String privacy = 'public',
    String? docId,
  }) async {
    if (kDebugMode) print('=== UPDATE POST: $postId ===');

    final headers = await _getAuthHeaders(requireToken: true);
    final body = {
      'text': text,
      'privacy': privacy,
      if (mediaUrls != null) 'mediaUrls': mediaUrls,
      'docId': docId,
    };

    try {
      final response = await http.put(
        // SỬA LỖI: Endpoint phải là /updatepost/:id
        // (Lưu ý: Backend controller đang dùng :id, không phải :postId)
        Uri.parse('$_baseUrl/updatepost/$postId'), 
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final data = _processResponse(response);
      // API của bạn trả về { status, message, data: { post } }
      final post = Post.fromJson(data['data']['post']);

      clearCache();
      if (kDebugMode) print('✓ Post updated successfully');
      return post;

    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Xóa bài viết
  /// DELETE /api/posts/deletepost/:postId
  Future<void> deletePost(String postId) async {
    if (kDebugMode) print('=== DELETE POST: $postId ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http.delete(
        // SỬA LỖI: Endpoint phải là /deletepost/:postId
        Uri.parse('$_baseUrl/deletepost/$postId'), 
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      _processResponse(response); // Chỉ kiểm tra lỗi

      clearCache();
      if (kDebugMode) print('✓ Post deleted successfully');

    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Like/Unlike bài viết
  /// POST /api/posts/:postId/react
  Future<String?> likePost(String postId, {String type = 'like'}) async {
    if (kDebugMode) print('=== REACTION POST: $postId, Type: $type ===');

    final headers = await _getAuthHeaders(requireToken: true);
    final body = jsonEncode({'type': type});

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$postId/react'), // Endpoint này đã đúng
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      final data = _processResponse(response);
      return data['newReactionType']; // Trả về "like", "dislike" hoặc null

    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}

