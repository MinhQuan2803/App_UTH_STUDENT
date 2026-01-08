import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'auth_service.dart';
import 'api_client.dart';
import '../config/app_theme.dart';

class ProfileService {
  static final String _baseUrl = AppAssets.userApiBaseUrl;
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  // Cache cho profile của mình
  static Map<String, dynamic>? _cachedMyProfile;
  static DateTime? _myProfileLastFetchTime;

  // Cache cho profile người khác (key: username)
  static Map<String, Map<String, dynamic>> _cachedUserProfiles = {};
  static Map<String, DateTime> _userProfilesFetchTime = {};

  static const Duration _cacheDuration = Duration(minutes: 10); // Cache 10 phút

  /// Lấy thông tin user hiện tại (chính mình) qua API /me
  Future<Map<String, dynamic>> getMyProfile({bool forceRefresh = false}) async {
    // Kiểm tra cache
    if (!forceRefresh &&
        _cachedMyProfile != null &&
        _myProfileLastFetchTime != null) {
      final timeSinceLastFetch =
          DateTime.now().difference(_myProfileLastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        if (kDebugMode) {
          print(
              '✓ Using cached my profile (${timeSinceLastFetch.inMinutes} min old)');
        }
        return _cachedMyProfile!;
      }
    }

    if (kDebugMode) print('=== GET MY PROFILE (from /me) ===');

    // ApiClient tự động thêm token và xử lý 401
    final response = await _apiClient.get('$_baseUrl/me',
        timeout: const Duration(seconds: 20));

    if (kDebugMode) print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body)['user'];

      // Thêm field isOwner = true (vì đây là profile của mình)
      userData['isOwner'] = true;
      userData['isFollowing'] = false;

      // Lưu vào cache
      _cachedMyProfile = userData;
      _myProfileLastFetchTime = DateTime.now();

      if (kDebugMode) print('✓ My username: ${userData['username']}');
      return userData;
    } else {
      throw Exception('Lỗi Server: ${response.statusCode}');
    }
  }

  /// Lấy profile của BẤT KỲ user nào bằng username
  Future<Map<String, dynamic>> getUserProfile(String username,
      {bool forceRefresh = false}) async {
    // Kiểm tra cache cho user này
    if (!forceRefresh && _cachedUserProfiles.containsKey(username)) {
      final lastFetchTime = _userProfilesFetchTime[username];
      if (lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(lastFetchTime);
        if (timeSinceLastFetch < _cacheDuration) {
          if (kDebugMode) {
            print(
                '✓ Using cached profile for $username (${timeSinceLastFetch.inMinutes} min old)');
          }
          return _cachedUserProfiles[username]!;
        }
      }
    }

    final String? token = await _authService.getValidToken();

    if (kDebugMode) {
      print('=== GET USER PROFILE ===');
      print('Fetching username: $username');
      print('Token: ${token != null ? "✓ Có token" : "✗ Không có token"}');
    }

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(Uri.parse('$_baseUrl/profile/$username'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final userRes = jsonDecode(response.body)['userRes'];

      // FIX: Server có lỗi chính tả "isOwer" thay vì "isOwner"
      if (userRes.containsKey('isOwer') && !userRes.containsKey('isOwner')) {
        userRes['isOwner'] = userRes['isOwer'];
        if (kDebugMode) print('⚠ Fixed typo: isOwer -> isOwner');
      }

      if (kDebugMode) {
        print('isOwner: ${userRes['isOwner']}');
        print('isFollowing: ${userRes['isFollowing']}');
      }

      // Lưu vào cache
      _cachedUserProfiles[username] = userRes;
      _userProfilesFetchTime[username] = DateTime.now();

      return userRes;
    } else if (response.statusCode == 404) {
      throw Exception('404: Không tìm thấy người dùng');
    } else if (response.statusCode == 401) {
      throw Exception('401: Phiên đăng nhập không hợp lệ');
    } else {
      throw Exception('Lỗi Server: ${response.statusCode}');
    }
  }

  /// Cập nhật thông tin profile (username, realname, bio)
  /// PATCH /api/users/me/update
  Future<Map<String, dynamic>> updateProfileDetails({
    required String username,
    String? realname,
    String? bio,
  }) async {
    if (kDebugMode) {
      print('=== UPDATE PROFILE DETAILS ===');
      print('Username: $username');
      print('Realname: ${realname ?? "(unchanged)"}');
      print('Bio: ${bio ?? "(unchanged)"}');
    }

    final body = {
      'username': username,
      if (realname != null) 'realname': realname,
      if (bio != null) 'bio': bio,
    };

    if (kDebugMode) {
      print('Request body: $body');
      print('API URL: $_baseUrl/me/update');
    }

    final response = await _apiClient.patch(
      '$_baseUrl/me/update',
      body: body,
      timeout: const Duration(seconds: 20),
    );

    if (kDebugMode) print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final updatedUser = responseData['user'];

      // Cập nhật cache với user object
      _cachedMyProfile = Map<String, dynamic>.from(updatedUser);
      _cachedMyProfile!['isOwner'] = true;
      _cachedMyProfile!['isFollowing'] = false;
      _myProfileLastFetchTime = DateTime.now();

      if (kDebugMode) {
        print('✓ Profile updated successfully');
        print('Message: ${responseData['message']}');
        print('Updated username: ${updatedUser['username']}');
      }

      return responseData;
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Dữ liệu không hợp lệ');
    } else if (response.statusCode == 409) {
      throw Exception('Username này đã được sử dụng');
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy người dùng');
    } else {
      throw Exception('Lỗi Server: ${response.statusCode}');
    }
  }

  /// Cập nhật avatar
  /// PATCH /api/users/me/avatar
  Future<Map<String, dynamic>> updateAvatar(
    String imagePath, // Đổi từ imageBytes sang imagePath (giống upload_service)
  ) async {
    final String? token = await _authService.getValidToken();

    if (token == null) {
      throw Exception('401: Chưa đăng nhập');
    }

    if (kDebugMode) {
      print('=== UPDATE AVATAR ===');
      print('Base URL: $_baseUrl');
      print('Full URL: $_baseUrl/me/avatar');
      print('Image path: $imagePath');
    }

    final uri = Uri.parse('$_baseUrl/me/avatar');
    final request = http.MultipartRequest('PATCH', uri);

    // Thêm header Authorization
    request.headers['Authorization'] = 'Bearer $token';

    if (kDebugMode) {
      print('Request headers: ${request.headers}');
      print('Request method: ${request.method}');
    }

    // Thêm file avatar - SỬ DỤNG fromPath GIỐNG UPLOAD_SERVICE
    final fileName = imagePath.split('/').last;

    // Detect MIME type từ file extension (giống upload_service)
    final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
    final mimeTypeParts = mimeType.split('/');

    final file = await http.MultipartFile.fromPath(
      'avatar', // Field name phải khớp với backend (multer.single('avatar'))
      imagePath,
      filename: fileName,
      contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]), // image/jpeg
    );

    request.files.add(file);

    if (kDebugMode) {
      print('Request files: ${request.files.length} file(s)');
      print('File field name: avatar');
      print('Filename: $fileName');
      print('Content-Type: ${file.contentType}');
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        final newAvatarUrl = responseData['avatarUrl'];

        // Cập nhật cache
        if (_cachedMyProfile != null) {
          _cachedMyProfile!['avatarUrl'] = newAvatarUrl;
          _myProfileLastFetchTime = DateTime.now();
        }

        if (kDebugMode) {
          print('✓ Avatar updated successfully');
          print('Message: ${responseData['message']}');
          print('New avatar URL: $newAvatarUrl');
        }

        return responseData;
      } catch (e) {
        if (kDebugMode) print('Error parsing JSON: $e');
        throw Exception('Server trả về dữ liệu không hợp lệ');
      }
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'File không hợp lệ');
    } else if (response.statusCode == 401) {
      throw Exception('401: Phiên đăng nhập không hợp lệ');
    } else {
      // Server error (500, 502, etc.) hoặc HTML response
      if (kDebugMode) {
        print('❌ Server error ${response.statusCode}');
        print('Response might be HTML or invalid JSON');
      }

      // Thử parse JSON, nếu không được thì dùng message mặc định
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Lỗi máy chủ khi upload avatar.');
      } catch (e) {
        // Response không phải JSON (có thể là HTML error page)
        throw Exception(
            'Lỗi server (${response.statusCode}): Không thể upload avatar. Vui lòng kiểm tra backend.');
      }
    }
  }

  // Hàm xóa cache
  static void clearCache() {
    _cachedMyProfile = null;
    _myProfileLastFetchTime = null;
    _cachedUserProfiles.clear();
    _userProfilesFetchTime.clear();
    if (kDebugMode) print('✓ Profile cache cleared');
  }

  /// Complete profile - Cập nhật realname và avatar cho user mới
  /// POST /api/users/complete-profile
  Future<Map<String, dynamic>> completeProfile({
    required String realname,
    dynamic avatarFile,
  }) async {
    if (kDebugMode) {
      print('=== COMPLETE PROFILE ===');
      print('Realname: $realname');
      print('Has avatar: ${avatarFile != null}');
    }

    final fields = {'realname': realname};
    final files = <http.MultipartFile>[];

    // Avatar file (optional)
    if (avatarFile != null) {
      String? imagePath;
      String? fileName;

      // Xử lý File hoặc XFile
      if (avatarFile.runtimeType.toString() == 'File' ||
          avatarFile.runtimeType.toString() == '_File') {
        imagePath = avatarFile.path;
        fileName = imagePath?.split('/').last;
      } else if (avatarFile.runtimeType.toString().contains('XFile')) {
        imagePath = avatarFile.path;
        fileName = avatarFile.name;
      }

      if (imagePath != null && fileName != null) {
        final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
        final mimeTypeParts = mimeType.split('/');

        final file = await http.MultipartFile.fromPath(
          'file',
          imagePath,
          filename: fileName,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );

        files.add(file);

        if (kDebugMode) {
          print('✓ Avatar file added: $fileName');
          print('  Content-Type: ${file.contentType}');
        }
      }
    }

    // Sử dụng ApiClient cho multipart request
    final streamedResponse = await _apiClient.multipartRequest(
      'POST',
      '$_baseUrl/complete-profile',
      fields: fields,
      files: files,
      timeout: const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Lưu isProfileCompleted vào storage
      await _authService.saveProfileCompletedStatus(true);

      // Xóa cache để reload profile mới
      clearCache();

      if (kDebugMode) {
        print('✓ Profile completed successfully');
        print('Message: ${responseData['message']}');
      }

      return responseData;
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi không xác định');
      } catch (e) {
        throw Exception(
            'Lỗi server (${response.statusCode}): Không thể hoàn thành hồ sơ');
      }
    }
  }
}
