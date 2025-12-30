import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import 'auth_service.dart';
import '../models/document_model.dart';
import 'dart:io'; // Import để dùng File
import 'package:http_parser/http_parser.dart'; // Import để xử lý MediaType

class DocumentService {
  // URL gốc trỏ vào /api/documents
  static final String _baseUrl = '${AppAssets.documentApiBaseUrl}';
  final AuthService _authService = AuthService();

  /// Upload tài liệu (không tạo bài post)
  Future<bool> uploadDocument({
    required File file,
    required String title,
    required String description,
    required int price,
    String privacy = 'public',
  }) async {
    final uri = Uri.parse('$_baseUrl/upload');
    final token = await _authService.getValidToken();

    // 1. Tạo MultipartRequest (POST)
    var request = http.MultipartRequest('POST', uri);

    // 2. Thêm Headers (Auth)
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Thêm Fields (Text) - Backend req.body
    request.fields['title'] = title;
    request.fields['price'] = price.toString();
    request.fields['description'] = description;
    request.fields['privacy'] = privacy;

    // 4. Thêm File - Backend req.file
    request.files.add(await _createMultipartFile(file));

    try {
      // 5. Gửi Request
      if (kDebugMode) print('Đang upload file: ${file.path}...');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (kDebugMode) print('Upload thành công: ${response.body}');
        return true;
      } else {
        if (kDebugMode) print('Upload thất bại: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi upload tài liệu');
      }
    } catch (e) {
      if (kDebugMode) print('Error uploading doc: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Upload tài liệu VÀ tự động tạo bài post
  Future<Map<String, dynamic>> uploadDocumentWithPost({
    required File file,
    required String title,
    required String description,
    required int price,
    String privacy = 'public',
  }) async {
    final uri = Uri.parse('$_baseUrl/upload-with-post');
    final token = await _authService.getValidToken();

    // 1. Tạo MultipartRequest (POST)
    var request = http.MultipartRequest('POST', uri);

    // 2. Thêm Headers (Auth)
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Thêm Fields (Text) - Backend req.body
    request.fields['title'] = title;
    request.fields['price'] = price.toString();
    request.fields['description'] = description;
    request.fields['privacy'] = privacy;

    // 4. Thêm File - Backend req.file
    request.files.add(await _createMultipartFile(file));

    try {
      // 5. Gửi Request
      if (kDebugMode) print('Đang upload file với auto-post: ${file.path}...');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (kDebugMode) print('Upload + Post thành công: ${response.body}');
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'document': data['document'],
          'post': data['post'],
        };
      } else {
        if (kDebugMode) print('Upload + Post thất bại: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi upload tài liệu');
      }
    } catch (e) {
      if (kDebugMode) print('Error uploading doc with post: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Helper: Tạo MultipartFile từ File
  Future<http.MultipartFile> _createMultipartFile(File file) async {
    String extension = file.path.split('.').last.toLowerCase();
    MediaType mediaType;

    if (extension == 'pdf') {
      mediaType = MediaType('application', 'pdf');
    } else if (extension == 'doc') {
      mediaType = MediaType('application', 'msword');
    } else {
      mediaType = MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document'); // docx
    }

    return await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: mediaType,
    );
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getValidToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Tab Khám phá (Public Feed)
  Future<List<DocumentModel>> getPublicDocuments({int page = 1}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'page': page.toString(),
      'limit': '1000',
    });
    return _fetchDocuments(uri.toString());
  }

  // 2. Tab Đã đăng (My Uploads)
  Future<List<DocumentModel>> getMyUploadedDocuments({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/me').replace(queryParameters: {
      'page': page.toString(),
      'limit': '1000',
    });
    return _fetchDocuments(uri.toString());
  }

  // 3. Tab Tủ sách (Purchased)
  Future<List<DocumentModel>> getPurchasedDocuments({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/purchased').replace(queryParameters: {
      'page': page.toString(),
      'limit': '1000',
    });
    return _fetchDocuments(uri.toString());
  }

  // 4. Tab Yêu thích (Liked)
  Future<List<DocumentModel>> getLikedDocuments({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/liked').replace(queryParameters: {
      'page': page.toString(),
      'limit': '10',
    });
    return _fetchDocuments(uri.toString());
  }

  // Hàm helper để gọi API và parse list
// Hàm helper để gọi API và parse list
  Future<List<DocumentModel>> _fetchDocuments(String url) async {
    if (kDebugMode) print('GET DOCS: $url');

    final headers = await _getHeaders();
    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        return (data['documents'] as List)
            .map((e) => DocumentModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Lỗi tải danh sách tài liệu: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching docs: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy chi tiết tài liệu
  Future<DocumentModel> getDocumentDetail(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/public/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return DocumentModel.fromJson(data);
    } else {
      throw Exception('Lỗi tải chi tiết tài liệu');
    }
  }

  //yêu thích
  Future<bool> toggleLike(String id) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/$id/like'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isLiked'] ?? false;
    } else {
      throw Exception('Lỗi thao tác yêu thích');
    }
  }

  //sửa và xoá tài liệu
  Future<bool> deleteDocument(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Lỗi khi xóa tài liệu');
    }
  }

  // Cập nhật tài liệu (Tiêu đề & Quyền riêng tư)
  Future<bool> updateDocument(
      String id, String title, String privacy, int price) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      'title': title,
      'privacy': privacy,
      'price': price,
    });

    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Lỗi khi cập nhật tài liệu');
    }
  }

  /// Helper: Lấy URL phù hợp để mở document (full hoặc preview)
  String getDocumentUrlToOpen(DocumentModel doc) {
    // Nếu có quyền đầy đủ → dùng URL gốc
    if (doc.isFullAccess && doc.url != null && doc.url!.isNotEmpty) {
      return doc.url!;
    }

    // Nếu không có quyền → dùng previewUrl
    if (doc.previewUrl.isNotEmpty) {
      return doc.previewUrl;
    }

    throw Exception('Không có URL để mở tài liệu');
  }

  /// Kiểm tra có thể xem preview không
  bool canPreviewDocument(DocumentModel doc) {
    return doc.getSafePreviewPages() > 0 || doc.isFullAccess;
  }
}
