import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'auth_service.dart';
// Import AppAssets để lấy Base URL
import '../config/app_theme.dart';

class UploadService {
  // Lấy URL từ AppAssets
  static final String _baseUrl = AppAssets.uploadApiBaseUrl;
  final AuthService _authService = AuthService();

  Future<List<String>> uploadImages(List<File> imageFiles) async {
    if (kDebugMode) print('=== UPLOAD IMAGES ===');
    if (kDebugMode) print('Base URL: $_baseUrl');
    if (kDebugMode) print('Full endpoint: $_baseUrl/images');
    if (kDebugMode) print('Number of files: ${imageFiles.length}');

    if (imageFiles.isEmpty) {
      return [];
    }

    // Logic kiểm tra 3 ảnh đã có trong middleware, nhưng kiểm tra ở đây vẫn tốt
    if (imageFiles.length > 3) {
      throw Exception('Chỉ được upload tối đa 3 ảnh');
    }

    final String? token = await _authService.getValidToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    final uri = Uri.parse('$_baseUrl/images');
    final request = http.MultipartRequest('POST', uri);

    // Thêm header Authorization (không cần Content-Type, MultipartRequest tự động set)
    request.headers['Authorization'] = 'Bearer $token';

    for (var imageFile in imageFiles) {
      // Kiểm tra file tồn tại và kích thước
      if (!await imageFile.exists()) {
        throw Exception('File không tồn tại: ${imageFile.path}');
      }
      final fileSize = await imageFile.length();
      if (kDebugMode)
        print(
            'File size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception('File quá lớn (>10MB): ${imageFile.path}');
      }

      // Đọc file và tạo MultipartFile với contentType rõ ràng
      final fileName = imageFile.path.split('/').last;

      // Detect MIME type từ file extension
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');

      final file = await http.MultipartFile.fromPath(
        'images', // Key name phải khớp với backend (đúng rồi)
        imageFile.path,
        filename: fileName, // Đảm bảo có filename
        contentType:
            MediaType(mimeTypeParts[0], mimeTypeParts[1]), // image/jpeg
      );
      request.files.add(file);
      if (kDebugMode) print('Added file: $fileName (${file.contentType})');
    }

    if (kDebugMode) print('Request URL: ${uri.toString()}');
    if (kDebugMode) print('Request files count: ${request.files.length}');
    if (kDebugMode) print('Request headers: ${request.headers}');

    // Gửi request
    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) print('Upload Response Status: ${response.statusCode}');
    if (kDebugMode) print('Upload Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data != null && data['urls'] is List) {
        final List<String> urls = List<String>.from(data['urls']);
        if (kDebugMode) print('✓ Uploaded ${urls.length} images');
        return urls;
      } else {
        throw Exception(
            'Định dạng phản hồi từ server không đúng (thiếu key "urls")');
      }
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Lỗi upload ảnh');
      } catch (e) {
        // Nếu server trả về HTML (lỗi 404, 500)
        if (response.body.contains('<!DOCTYPE html>')) {
          throw Exception('Lỗi Server: Không tìm thấy API upload (404/500).');
        }
        throw Exception('Lỗi upload ảnh (Status ${response.statusCode})');
      }
    }
  }
}
