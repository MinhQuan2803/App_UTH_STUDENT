import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../../config/app_theme.dart';

/// Service xử lý bảo mật tài liệu - lấy URL an toàn từ backend
class DocumentSecurityService {
  static final String _baseUrl = AppAssets.documentApiBaseUrl;
  final AuthService _authService = AuthService();

  // Cache signed URLs (hết hạn sau 8 phút, backend set 10 phút)
  final Map<String, _CachedUrl> _urlCache = {};

  Future<Map<String, String>> _getAuthHeaders() async {
    final String? token = await _authService.getValidToken();
    if (token == null) throw Exception('401: Chưa đăng nhập');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lấy thông tin quyền truy cập tài liệu
  ///
  /// Returns:
  /// ```dart
  /// {
  ///   "documentId": "674abc123",
  ///   "title": "Giáo trình Flutter",
  ///   "totalPages": 20,
  ///   "price": 5000,
  ///   "isOwner": false,
  ///   "hasPurchased": true,
  ///   "hasFullAccess": true,
  ///   "maxPreviewPage": 2,
  ///   "canPreview": true
  /// }
  /// ```
  Future<DocumentAccessInfo> getDocumentAccess(String documentId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$documentId/access'),
        headers: headers,
      );

      if (kDebugMode) {
        print(
            'GET /documents/$documentId/access - Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DocumentAccessInfo.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Tài liệu không tồn tại');
      } else {
        throw Exception('Lỗi lấy thông tin: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error getDocumentAccess: $e');
      rethrow;
    }
  }

  /// Lấy URL trang tài liệu (có kiểm tra quyền từ backend)
  ///
  /// Returns signed Cloudinary URL nếu có quyền
  /// Throws Exception với status 403 nếu bị chặn
  Future<String> getPageUrl(String documentId, int pageNumber) async {
    // Check cache trước
    final cacheKey = '${documentId}_$pageNumber';
    final cached = _urlCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      if (kDebugMode) print('📦 Cache hit: $cacheKey');
      return cached.url;
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$documentId/page/$pageNumber'),
        headers: headers,
      );

      if (kDebugMode) {
        print(
            'GET /documents/$documentId/page/$pageNumber - Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] as String;
        final expiresIn = data['expiresIn'] as int? ?? 600;

        // Cache URL (8 phút = 480 giây)
        _urlCache[cacheKey] = _CachedUrl(
          url: url,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 120)),
        );

        return url;
      } else if (response.statusCode == 403) {
        // Trang bị khóa - cần mua tài liệu
        final data = jsonDecode(response.body);
        throw DocumentAccessDeniedException(
          message: data['message'] ?? 'Bạn cần mua tài liệu để xem trang này',
          maxPreviewPage: data['maxPreviewPage'] ?? 0,
        );
      } else if (response.statusCode == 404) {
        throw Exception('Trang không tồn tại');
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Số trang không hợp lệ');
      } else {
        throw Exception('Lỗi lấy URL: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error getPageUrl: $e');
      rethrow;
    }
  }

  /// Xóa cache (dùng sau khi mua tài liệu)
  void clearCache(String documentId) {
    _urlCache.removeWhere((key, _) => key.startsWith('${documentId}_'));
    if (kDebugMode) print('🗑️ Cleared cache for document: $documentId');
  }

  /// Xóa toàn bộ cache
  void clearAllCache() {
    _urlCache.clear();
    if (kDebugMode) print('🗑️ Cleared all URL cache');
  }
}

/// Model chứa thông tin quyền truy cập
class DocumentAccessInfo {
  final String documentId;
  final String title;
  final int totalPages;
  final int price;
  final bool isOwner;
  final bool hasPurchased;
  final bool hasFullAccess;
  final int maxPreviewPage;
  final bool canPreview;

  DocumentAccessInfo({
    required this.documentId,
    required this.title,
    required this.totalPages,
    required this.price,
    required this.isOwner,
    required this.hasPurchased,
    required this.hasFullAccess,
    required this.maxPreviewPage,
    required this.canPreview,
  });

  factory DocumentAccessInfo.fromJson(Map<String, dynamic> json) {
    return DocumentAccessInfo(
      documentId: json['documentId'],
      title: json['title'],
      totalPages: json['totalPages'],
      price: json['price'],
      isOwner: json['isOwner'] ?? false,
      hasPurchased: json['hasPurchased'] ?? false,
      hasFullAccess: json['hasFullAccess'] ?? false,
      maxPreviewPage: json['maxPreviewPage'] ?? 0,
      canPreview: json['canPreview'] ?? false,
    );
  }
}

/// Exception khi không có quyền xem trang
class DocumentAccessDeniedException implements Exception {
  final String message;
  final int maxPreviewPage;

  DocumentAccessDeniedException({
    required this.message,
    required this.maxPreviewPage,
  });

  @override
  String toString() => message;
}

/// Cache entry cho signed URLs
class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl({required this.url, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
