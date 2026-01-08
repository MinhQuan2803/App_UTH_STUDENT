import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_client.dart';
import '../config/app_theme.dart';

/// Service xử lý tương tác với bài viết (like, comment)
/// ✅ ĐÃ CẬP NHẬT THEO TÀI LIỆU API CHÍNH THỨC
class InteractionService {
  // Sử dụng production base URL (không có /posts hay /users, chỉ /api)
  static const String baseUrl = 'https://uthstudent.onrender.com/api';
  final ApiClient _apiClient = ApiClient();

  /// Toggle like cho bài viết
  /// API: POST /api/posts/:postId/react (correct endpoint)
  /// Body: { "type": "like" }
  /// Response: { "newReactionType": "like" | null }
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      if (kDebugMode) {
        print('=== TOGGLE LIKE ===');
        print('URL: $baseUrl/posts/$postId/react');
        print('PostId: $postId');
      }

      final response = await _apiClient.post(
        '$baseUrl/posts/$postId/react',
        body: {'type': 'like'},
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
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

        // BACKEND CHỈ TRẢ VỀ: { "newReactionType": "like" | "dislike" | null }
        // KHÔNG có likesCount/dislikesCount trong response
        final newReactionType = data['newReactionType'];
        final isLiked = newReactionType == 'like';
        final isDisliked = newReactionType == 'dislike';

        if (kDebugMode)
          print('✓ Toggle like thành công: newReactionType=$newReactionType');

        return {
          'success': true,
          'isLiked': isLiked,
          'isDisliked': isDisliked,
          'newReactionType': newReactionType, // null, "like", hoặc "dislike"
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
      if (kDebugMode) print('=== GET COMMENTS: $postId ===');

      final response = await _apiClient.get('$baseUrl/comments/$postId');

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
      if (kDebugMode) print('=== ADD COMMENT: $postId ===');

      final response = await _apiClient.post(
        '$baseUrl/comments/$postId',
        body: {'text': content},
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
      if (kDebugMode) print('=== DELETE COMMENT: $commentId ===');

      final response = await _apiClient.delete('$baseUrl/comments/$commentId');

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
      if (kDebugMode) print('=== UPDATE COMMENT: $commentId ===');

      final response = await _apiClient.put(
        '$baseUrl/comments/$commentId',
        body: {'text': newContent},
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
      if (kDebugMode) print('=== TOGGLE COMMENT LIKE: $commentId ===');

      final response =
          await _apiClient.post('$baseUrl/likes/comment/$commentId', body: {});

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
