import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import 'auth_service.dart';

class SearchService {
  static final String _baseUrl = AppAssets.userApiBaseUrl;
  final AuthService _authService = AuthService();

  /// Global search - Tìm kiếm users, posts, documents
  Future<Map<String, dynamic>> globalSearch(String query) async {
    try {
      final token = await _authService.getValidToken();

      // Remove '/users' từ base URL vì endpoint là /api/search/global
      final searchBaseUrl = _baseUrl.replaceAll('/users', '');
      final url =
          '$searchBaseUrl/search/global?q=${Uri.encodeComponent(query)}';

      if (kDebugMode) {
        print('=== GLOBAL SEARCH ===');
        print('Query: $query');
        print('URL: $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Parse users
        final users = (data['users'] as List?)
                ?.map((item) => SearchUser.fromJson(item))
                .toList() ??
            [];

        // Parse documents
        final documents = (data['documents'] as List?)
                ?.map((item) => SearchDocument.fromJson(item))
                .toList() ??
            [];

        // Parse posts
        final posts = (data['posts'] as List?)
                ?.map((item) => Post.fromJson(item))
                .toList() ??
            [];

        if (kDebugMode) {
          print(
              '✓ Found: ${users.length} users, ${posts.length} posts, ${documents.length} documents');
        }

        return {
          'totalResults': data['totalResults'] ?? 0,
          'users': users,
          'documents': documents,
          'posts': posts,
        };
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Lỗi tìm kiếm');
      }
    } on SocketException {
      throw Exception('Không có kết nối mạng');
    } on TimeoutException {
      throw Exception('Yêu cầu quá thời gian');
    } catch (e) {
      if (kDebugMode) print('Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

/// Model cho User trong search results
class SearchUser {
  final String id;
  final String username;
  final String? avatarUrl;

  SearchUser({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }
}

/// Model cho Document trong search results
class SearchDocument {
  final String id;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? fileType;
  final int price;
  final String? uploaderUsername;
  final String? uploaderAvatar;
  final int downloads;

  SearchDocument({
    required this.id,
    required this.title,
    this.description,
    this.fileUrl,
    this.fileType,
    required this.price,
    this.uploaderUsername,
    this.uploaderAvatar,
    required this.downloads,
  });

  factory SearchDocument.fromJson(Map<String, dynamic> json) {
    return SearchDocument(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      price: json['price'] ?? 0,
      uploaderUsername: json['uploader']?['username'],
      uploaderAvatar: json['uploader']?['avatarUrl'],
      downloads: json['downloads'] ?? 0,
    );
  }
}
