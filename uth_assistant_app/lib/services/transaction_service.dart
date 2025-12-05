import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../../config/app_theme.dart'; // Đảm bảo import đúng AppAssets
import 'dart:io';
import 'dart:async';
import '../models/transaction_model.dart'; // Import model mới

class TransactionService {
  // Base URL trỏ vào /api/documents vì các route mua/lịch sử đang nằm ở đó
  static final String _baseUrl = '${AppAssets.documentApiBaseUrl}';
  final AuthService _authService = AuthService();

  // --- Helper Functions (Giống PaymentService) ---
  Future<Map<String, String>> _getAuthHeaders(
      {bool requireToken = true}) async {
    final String? token = await _authService.getValidToken();
    if (requireToken && token == null) throw Exception('401: Chưa đăng nhập');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _processResponse(http.Response response) {
    if (kDebugMode) print('Response Status: ${response.statusCode}');

    final dynamic decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    } else {
      final errorMessage =
          (decodedBody is Map && decodedBody.containsKey('message'))
              ? decodedBody['message']
              : 'Lỗi Server: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  Exception _handleNetworkError(dynamic e) {
    if (e is TimeoutException) return Exception('Hết thời gian chờ kết nối');
    if (e is SocketException) return Exception('Lỗi kết nối mạng.');
    return e is Exception ? e : Exception(e.toString());
  }

  // =================================================================
  // 1. MUA TÀI LIỆU (Trừ điểm trong ví)
  // API: POST /api/documents/buy
  // =================================================================
  Future<Map<String, dynamic>> buyDocument(String documentId) async {
    if (kDebugMode) print('=== BUY DOCUMENT: $documentId ===');

    final headers = await _getAuthHeaders();
    final body = jsonEncode({'documentId': documentId});

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/buy'), // Route chúng ta đã test trên Postman
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      final data = _processResponse(response);

      if (kDebugMode) {
        print('✓ Mua thành công. Số dư mới: ${data['newBalance']}');
      }

      // Trả về kết quả (thường chứa newBalance để update UI)
      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // =================================================================
  // 2. LẤY LỊCH SỬ GIAO DỊCH (Nạp tiền + Mua bán)
  // API: GET /api/documents/transactions (Hoặc route bạn đã đặt cho getMyTransactions)
  // =================================================================
  Future<Map<String, dynamic>> getMyTransactions({
    int page = 1,
    int limit = 10,
  }) async {
    if (kDebugMode) print('=== GET TRANSACTIONS (Page: $page) ===');

    final headers = await _getAuthHeaders();

    try {
      // LƯU Ý: Bạn cần chắc chắn route này khớp với route bên backend
      // Nếu bên backend bạn để là router.get('/transactions', ...) trong document.routes.js
      // Thì URL sẽ là: $_baseUrl/transactions
      final response = await http
          .get(
            Uri.parse('$_baseUrl/transactions?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      if (kDebugMode) {
        print('✓ Lịch sử loaded: ${data['data']?.length ?? 0} records');
      }

      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}
