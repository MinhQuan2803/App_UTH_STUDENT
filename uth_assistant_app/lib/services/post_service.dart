import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_client.dart'; // Import ApiClient
import '../models/post_model.dart';
import '../config/app_theme.dart';
import 'dart:io'; // Import dart:io
import 'dart:async'; // Import dart:async

class PostService {
  static final String _baseUrl = AppAssets.postApiBaseUrl;
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient(); // Sử dụng ApiClient

  // Cache
  static List<Post>? _cachedPosts;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // --- Helper Functions (Tái sử dụng code) ---

  /// Lấy headers kèm token (nếu có)
  Future<Map<String, String>> _getAuthHeaders(
      {bool requireToken = false}) async {
    final String? token = await _authService.getValidToken();
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
      throw Exception(
          'Lỗi Server: API endpoint không đúng hoặc bị crash (404/500).');
    }

    final dynamic decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody; // Trả về dữ liệu đã decode
    } else {
      // Ném lỗi từ server (nếu có)
      final errorMessage =
          (decodedBody is Map && decodedBody.containsKey('error'))
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
    if (!forceRefresh &&
        page == 0 &&
        _cachedPosts != null &&
        _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        if (kDebugMode)
          print(
              '✓ Using cached posts (${timeSinceLastFetch.inMinutes} min old)');
        return _cachedPosts!;
      }
    }
    if (kDebugMode) print('=== GET HOME FEED ===');

    // 2. Chuẩn bị gọi API
    final uri = Uri.parse('$_baseUrl/home').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      'feed': feed,
    });
    if (kDebugMode) print('Requesting URL: $uri');

    // 3. Gọi API với ApiClient (auto refresh token)
    try {
      final response = await _apiClient.get(
        uri.toString(),
        timeout: const Duration(seconds: 20),
      );
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
    final uri =
        Uri.parse('$_baseUrl/profile/$username').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

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

  /// Lấy chi tiết 1 bài viết theo ID
  /// GET /api/posts/:postId
  Future<Post> getPostById(String postId) async {
    if (kDebugMode) print('=== GET POST BY ID: $postId ===');

    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/$postId');

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      final dynamic data = _processResponse(response);

      // Backend có thể trả về { post: {...} } hoặc trực tiếp post object
      final postJson =
          data is Map && data.containsKey('post') ? data['post'] : data;
      final post = Post.fromJson(postJson);

      if (kDebugMode) print('✓ Loaded post: ${post.id}');
      return post;
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
      final response = await http
          .post(
            // SỬA LỖI: Endpoint phải là /createpost
            Uri.parse('$_baseUrl/createpost'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

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
    if (kDebugMode) {
      print('=== UPDATE POST: $postId ===');
      print('📝 Text: $text');
      print('🖼️ MediaUrls: $mediaUrls');
      print('🔒 Privacy: $privacy');
    }

    final headers = await _getAuthHeaders(requireToken: true);
    final body = {
      'text': text,
      'privacy': privacy,
      // QUAN TRỌNG: Luôn gửi mediaUrls (có thể là [], không bao giờ skip)
      // Nếu null → gửi [] để xóa hết ảnh
      // Nếu có ảnh → gửi array ảnh
      'mediaUrls': mediaUrls ?? [],
      if (docId != null) 'docId': docId,
    };

    try {
      final response = await http
          .put(
            // SỬA LỖI: Endpoint phải là /updatepost/:id
            // (Lưu ý: Backend controller đang dùng :id, không phải :postId)
            Uri.parse('$_baseUrl/updatepost/$postId'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

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

    try {
      final response = await _apiClient.delete(
        '$_baseUrl/deletepost/$postId',
        timeout: const Duration(seconds: 90),
      );

      // Debug: Xem response từ server
      if (kDebugMode) {
        print('📡 DELETE Response Status: ${response.statusCode}');
        print('📡 DELETE Response Body: ${response.body}');
        print('📡 DELETE Response Headers: ${response.headers}');
      }

      _processResponse(response); // Chỉ kiểm tra lỗi

      clearCache();
      if (kDebugMode) print('✓ Post deleted successfully');
    } catch (e) {
      if (kDebugMode) print('❌ DELETE Error: $e');
      throw _handleNetworkError(e);
    }
  }

  /// Like/Unlike bài viết
  /// POST /api/posts/:postId/react
  Future<String?> likePost(String postId, {String type = 'like'}) async {
    if (kDebugMode) print('=== REACTION POST: $postId, Type: $type ===');

    try {
      final response = await _apiClient.post(
        '$_baseUrl/$postId/react',
        body: {'type': type},
        timeout: const Duration(seconds: 15),
      );

      final data = _processResponse(response);
      return data['newReactionType']; // Trả về "like", "dislike" hoặc null
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy danh sách người đã react bài viết
  /// GET /api/posts/:postId/reactions?type=all|like|dislike&page=1&limit=20
  Future<Map<String, dynamic>> getPostReactions({
    required String postId,
    String type = 'all', // 'all', 'like', 'dislike'
    int page = 1,
    int limit = 20,
  }) async {
    if (kDebugMode) {
      print('=== GET POST REACTIONS: $postId ===');
      print('Type: $type, Page: $page, Limit: $limit');
    }

    final uri = Uri.parse('$_baseUrl/$postId/reactions').replace(
      queryParameters: {
        'type': type,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    try {
      final response = await _apiClient.get(
        uri.toString(),
        timeout: const Duration(seconds: 20),
      );

      final data = _processResponse(response);
      if (kDebugMode) {
        print('✓ Loaded ${data['data']['reactions'].length} reactions');
      }
      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}
