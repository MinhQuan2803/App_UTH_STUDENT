import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_theme.dart';

/// Service xử lý tương tác với bài viết (like, comment)
/// ✅ ĐÃ CẬP NHẬT THEO TÀI LIỆU API CHÍNH THỨC
class InteractionService {
  // Sử dụng production base URL (không có /posts hay /users, chỉ /api)
  static const String baseUrl = 'https://uthstudent.onrender.com/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Lấy token từ secure storage
  Future<String?> _getToken() async {
    return await _storage.read(key: 'accessToken');
  }

  /// Toggle like cho bài viết
  /// API: POST /api/posts/:postId/react (correct endpoint)
  /// Body: { "type": "like" }
  /// Response: { "newReactionType": "like" | null }
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/posts/$postId/react');

      if (kDebugMode) {
        print('=== TOGGLE LIKE ===');
        print('URL: $url');
        print('PostId: $postId');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
        body: json.encode({'type': 'like'}),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print(
            'Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }

      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw Exception(
            'Server trả về HTML thay vì JSON. Status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // API trả về: { "newReactionType": "like" | "dislike" | null, "likesCount": 5, "dislikesCount": 2 }
        final newReactionType = data['newReactionType'];
        final isLiked = newReactionType == 'like';

        if (kDebugMode)
          print('✓ Toggle like thành công: newReactionType=$newReactionType');

        return {
          'success': true,
          'isLiked': isLiked,
          'likesCount': data['likesCount'] ?? 0,
          'dislikesCount': data['dislikesCount'] ?? 0,
        };
      } else {
        // Try to parse error
        try {
          final error = json.decode(response.body);
          throw Exception(error['error'] ??
              error['message'] ??
              'Không thể like bài viết (${response.statusCode})');
        } catch (e) {
          throw Exception(
              'Không thể like bài viết. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error: $e');
      throw Exception('Lỗi khi like bài viết: $e');
    }
  }

  /// Lấy danh sách comments của bài viết
  /// API: GET /api/comments/:postId
  /// Response: Array of comments
  Future<List<Comment>> getComments(String postId) async {
    try {
      final token = await _getToken();

      final url = Uri.parse('$baseUrl/comments/$postId');

      if (kDebugMode) print('=== GET COMMENTS: $postId ===');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Thêm token nếu có (optional cho public posts)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        headers['Cookie'] = 'token=$token';
      }

      final response = await http.get(url, headers: headers);

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final comments = data.map((json) => Comment.fromJson(json)).toList();

        if (kDebugMode) print('✓ Loaded ${comments.length} comments');
        return comments;
      } else if (response.statusCode == 404) {
        // Bài viết chưa có comment
        if (kDebugMode) print('✓ No comments yet');
        return [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể tải bình luận');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải bình luận: $e');
    }
  }

  /// Thêm comment mới
  /// API: POST /api/comments/:postId
  /// Body: { "text": "comment content" }
  /// Response: Comment object
  Future<Comment> addComment(String postId, String content) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/comments/$postId');

      if (kDebugMode) print('=== ADD COMMENT: $postId ===');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
        body: json.encode({
          'text': content, // API expects 'text' not 'content'
        }),
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (kDebugMode) print('✓ Comment added successfully');

        return Comment.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['error'] ?? error['message'] ?? 'Không thể thêm bình luận');
      }
    } catch (e) {
      throw Exception('Lỗi khi thêm bình luận: $e');
    }
  }

  /// Xóa comment
  /// API: DELETE /api/comments/:commentId
  Future<void> deleteComment(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/comments/$commentId');

      if (kDebugMode) print('=== DELETE COMMENT: $commentId ===');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) print('✓ Comment deleted successfully');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể xóa bình luận');
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa bình luận: $e');
    }
  }

  /// Chỉnh sửa comment
  /// API: PUT /api/comments/:commentId
  /// Body: { "text": "new comment content" }
  Future<Comment> updateComment(String commentId, String newContent) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/comments/$commentId');

      if (kDebugMode) print('=== UPDATE COMMENT: $commentId ===');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
        body: json.encode({
          'text': newContent, // API expects 'text'
        }),
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) print('✓ Comment updated successfully');

        return Comment.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể cập nhật bình luận');
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật bình luận: $e');
    }
  }

  /// Like một comment
  /// API: POST /api/likes/comment/:commentId
  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/likes/comment/$commentId');

      if (kDebugMode) print('=== TOGGLE COMMENT LIKE: $commentId ===');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
      );

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        final isLiked = data['message']?.toString().contains('Liked') ?? true;

        if (kDebugMode) print('✓ Toggle comment like thành công');

        return {
          'success': true,
          'message': data['message'] ?? 'Thành công',
          'isLiked': isLiked,
          'likesCount': data['likesCount'] ?? 0,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể like bình luận');
      }
    } catch (e) {
      throw Exception('Lỗi khi like bình luận: $e');
    }
  }
}

/// Model cho Comment
class Comment {
  final String id;
  final String postId;
  final CommentAuthor author;
  final String text;
  final int likesCount;
  final bool isLiked;
  final String createdAt;
  final String? updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? json['id'] ?? '',
      postId: json['post'] ?? json['postId'] ?? '',
      author: CommentAuthor.fromJson(json['user'] ?? json['author'] ?? {}),
      text: json['text'] ?? json['content'] ?? '',
      likesCount: json['likes']?.length ?? 0, // Array of user IDs who liked
      isLiked: json['myReactionType'] == 'like' || json['isLiked'] == true,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'post': postId,
      'user': author.toJson(),
      'text': text,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Model cho Comment Author
class CommentAuthor {
  final String id;
  final String username;
  final String? profileImg;
  final String? fullName;

  CommentAuthor({
    required this.id,
    required this.username,
    this.profileImg,
    this.fullName,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? 'Unknown',
      profileImg: json['profileImg'],
      fullName: json['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'profileImg': profileImg,
      'fullName': fullName,
    };
  }
}
