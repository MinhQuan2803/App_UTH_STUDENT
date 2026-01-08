import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_client.dart';
import '../config/app_theme.dart';

/// Service xử lý Follow/Unfollow users
/// Dựa trên tài liệu API: follow-api-documentation.md
class FollowService {
  static final String baseUrl = AppAssets.followApiBaseUrl;
  final ApiClient _apiClient = ApiClient();

  /// Lấy thông tin profile của một user theo username
  /// GET /api/users/profile/:username
  Future<UserProfile> getUserProfile(String username) async {
    try {
      final response = await _apiClient.get('$baseUrl/profile/$username');

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
      print('=== FOLLOW USER DEBUG ===');
      print('User ID: $userId');
      print('Full URL: $baseUrl/$userId/follow');

      final response = await _apiClient.post(
        '$baseUrl/$userId/follow',
        body: {},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Theo dõi thành công.';

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
  /// DELETE /api/users/:userId/unfollow
  Future<FollowResult> unfollowUser(String userId) async {
    try {
      print('=== UNFOLLOW USER DEBUG ===');
      print('User ID: $userId');

      final response = await _apiClient.delete('$baseUrl/$userId/unfollow');

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Bỏ theo dõi thành công.';

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

  /// Lấy danh sách người theo dõi (Followers)
  /// GET /api/follow/:userId/followers?page=1&limit=20
  Future<FollowListResponse> getFollowers(String userId,
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '$baseUrl/$userId/followers?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FollowListResponse.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy người dùng');
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Không thể tải danh sách followers');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải followers: $e');
    }
  }

  /// Lấy danh sách người đang theo dõi (Following)
  /// GET /api/follow/:userId/following?page=1&limit=20
  Future<FollowListResponse> getFollowing(String userId,
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '$baseUrl/$userId/following?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FollowListResponse.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy người dùng');
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Không thể tải danh sách following');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải following: $e');
    }
  }
}

/// Model cho danh sách follow
class FollowListResponse {
  final List<FollowUser> users;
  final FollowPagination pagination;

  FollowListResponse({
    required this.users,
    required this.pagination,
  });

  factory FollowListResponse.fromJson(Map<String, dynamic> json) {
    // Backend trả về 'followers' hoặc 'following' tùy endpoint
    final usersJson = json['followers'] ?? json['following'] ?? [];
    return FollowListResponse(
      users:
          (usersJson as List).map((user) => FollowUser.fromJson(user)).toList(),
      pagination: FollowPagination.fromJson(json['pagination']),
    );
  }
}

/// Model cho pagination
class FollowPagination {
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;

  FollowPagination({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMore,
  });

  factory FollowPagination.fromJson(Map<String, dynamic> json) {
    return FollowPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      total: json['totalFollowers'] ?? json['totalFollowing'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Model cho user trong danh sách follow
class FollowUser {
  final String id;
  final String username;
  final String? realname;
  final String? avatarUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final String? followedAt;
  bool isFollowing; // Trạng thái có đang follow user này không

  FollowUser({
    required this.id,
    required this.username,
    this.realname,
    this.avatarUrl,
    this.bio,
    required this.followerCount,
    required this.followingCount,
    this.followedAt,
    this.isFollowing = false, // Mặc định là chưa follow
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      realname: json['realname'],
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      followedAt: json['followedAt'],
      isFollowing:
          json['isFollowing'] ?? false, // Backend có thể trả về field này
    );
  }
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
