import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_theme.dart';

/// Service xử lý Follow/Unfollow users
/// Dựa trên tài liệu API: follow-api-documentation.md
class FollowService {
  static final String baseUrl = AppAssets.userApiBaseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Lấy token từ secure storage (phải khớp với key trong auth_service.dart)
  Future<String?> _getToken() async {
    return await _storage.read(
        key: 'accessToken'); // Sửa từ 'auth_token' thành 'accessToken'
  }

  /// Lấy thông tin profile của một user theo username
  /// GET /api/users/profile/:username
  Future<UserProfile> getUserProfile(String username) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/profile/$username');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Thêm token nếu có (optional cho public info)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        headers['Cookie'] = 'token=$token';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data['userRes']);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy người dùng');
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Không thể tải thông tin người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải profile: $e');
    }
  }

  /// Theo dõi một user
  /// POST /api/users/:userId/follow
  Future<FollowResult> followUser(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/$userId/follow');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Theo dõi thành công.';

        // Kiểm tra xem đã follow trước đó chưa
        final alreadyFollowing =
            message.contains('Đã theo dõi người dùng này rồi');

        return FollowResult(
          success: true,
          message: message,
          isFollowing: true,
          alreadyFollowing: alreadyFollowing,
        );
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Yêu cầu không hợp lệ');
      } else if (response.statusCode == 404) {
        throw Exception('Người dùng bạn muốn theo dõi không tồn tại');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Không thể theo dõi người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi khi theo dõi: $e');
    }
  }

  /// Bỏ theo dõi một user
  /// DELETE /api/users/:userId/follow
  Future<FollowResult> unfollowUser(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/$userId/follow');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Bỏ theo dõi thành công.';

        // Kiểm tra xem đã unfollow trước đó chưa
        final notFollowing =
            message.contains('Bạn chưa theo dõi người dùng này');

        return FollowResult(
          success: true,
          message: message,
          isFollowing: false,
          alreadyFollowing: false,
          notFollowing: notFollowing,
        );
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Yêu cầu không hợp lệ');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Không thể bỏ theo dõi người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi khi bỏ theo dõi: $e');
    }
  }

  /// Kiểm tra trạng thái follow (KHÔNG SỬ DỤNG - API chưa hoạt động)
  /// Thay vào đó, dùng getUserProfile để lấy isFollowing
  /*
  Future<bool> checkFollowStatus(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('$baseUrl/$userId/follow-status');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Cookie': 'token=$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['isFollowing'] ?? false;
      } else if (response.statusCode == 404) {
        throw Exception('User không tồn tại');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Không thể kiểm tra trạng thái');
      }
    } catch (e) {
      throw Exception('Lỗi khi kiểm tra follow status: $e');
    }
  }
  */
}

/// Model cho User Profile
/// Dựa trên response từ GET /api/users/profile/:username
class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final bool isOwner; // true nếu là profile của chính mình
  final bool isFollowing; // true nếu đang follow user này

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.followerCount,
    required this.followingCount,
    this.isOwner = false,
    this.isFollowing = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isOwner:
          json['isOwer'] ?? json['isOwner'] ?? false, // API có typo "isOwer"
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'isOwer': isOwner,
      'isFollowing': isFollowing,
    };
  }

  /// Copy with để update một số field
  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? followerCount,
    int? followingCount,
    bool? isOwner,
    bool? isFollowing,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isOwner: isOwner ?? this.isOwner,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

/// Model cho kết quả Follow/Unfollow
class FollowResult {
  final bool success;
  final String message;
  final bool isFollowing;
  final bool alreadyFollowing; // true nếu đã follow trước đó
  final bool notFollowing; // true nếu chưa follow (khi unfollow)

  FollowResult({
    required this.success,
    required this.message,
    required this.isFollowing,
    this.alreadyFollowing = false,
    this.notFollowing = false,
  });
}
