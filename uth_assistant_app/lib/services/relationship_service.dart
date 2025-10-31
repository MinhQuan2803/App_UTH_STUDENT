import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service xử lý followers/following relationships
class RelationshipService {
  static const String baseUrl =
      'https://uthstudent.onrender.com/api/relationships';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Lấy token từ secure storage
  Future<String?> _getToken() async {
    return await _storage.read(key: 'accessToken');
  }

  /// Lấy danh sách Followers (người theo dõi user)
  /// GET /api/relationships/followers/:username
  Future<List<UserRelationship>> getFollowers(String username) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/followers/$username');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Thêm token nếu có (optional)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        headers['Cookie'] = 'token=$token';
      }

      if (kDebugMode) print('=== GET FOLLOWERS: $username ===');

      final response = await http.get(url, headers: headers);

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final followers =
            data.map((json) => UserRelationship.fromJson(json)).toList();

        if (kDebugMode) print('✓ Loaded ${followers.length} followers');
        return followers;
      } else if (response.statusCode == 404) {
        // User không có followers
        if (kDebugMode) print('✓ User has no followers yet');
        return [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể tải danh sách followers');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải followers: $e');
    }
  }

  /// Lấy danh sách Following (người mà user đang theo dõi)
  /// GET /api/relationships/following/:username
  Future<List<UserRelationship>> getFollowing(String username) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/following/$username');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Thêm token nếu có (optional)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        headers['Cookie'] = 'token=$token';
      }

      if (kDebugMode) print('=== GET FOLLOWING: $username ===');

      final response = await http.get(url, headers: headers);

      if (kDebugMode) print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final following =
            data.map((json) => UserRelationship.fromJson(json)).toList();

        if (kDebugMode) print('✓ Loaded ${following.length} following');
        return following;
      } else if (response.statusCode == 404) {
        // User không follow ai
        if (kDebugMode) print('✓ User is not following anyone yet');
        return [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Không thể tải danh sách following');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải following: $e');
    }
  }
}

/// Model cho User trong relationships
class UserRelationship {
  final String id;
  final String username;
  final String? fullName;
  final String? profileImg;
  final bool isFollowing; // True nếu current user đang follow user này

  UserRelationship({
    required this.id,
    required this.username,
    this.fullName,
    this.profileImg,
    this.isFollowing = false,
  });

  factory UserRelationship.fromJson(Map<String, dynamic> json) {
    return UserRelationship(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'],
      profileImg: json['profileImg'],
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullName': fullName,
      'profileImg': profileImg,
      'isFollowing': isFollowing,
    };
  }
}
