import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_theme.dart';
import 'dart:io';
import 'dart:async';

class PaymentService {
  static final String _baseUrl = AppAssets.paymentApiBaseUrl;
  static final String _pointsBaseUrl = AppAssets.pointsApiBaseUrl;
  final AuthService _authService = AuthService();

  // --- Helper Functions (Tái sử dụng) ---
  Future<Map<String, String>> _getAuthHeaders(
      {bool requireToken = false}) async {
    final String? token = await _authService.getValidToken();
    if (requireToken && token == null) throw Exception('401: Chưa đăng nhập');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    if (kDebugMode) print('Response Status: ${response.statusCode}');
    if (response.body.startsWith('<!DOCTYPE html>')) {
      throw Exception('Lỗi Server: API endpoint không đúng (404/500).');
    }
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
    if (kDebugMode) print('API Call Error: $e');
    if (e is TimeoutException)
      return Exception('Hết thời gian chờ kết nối server');
    if (e is SocketException) return Exception('Lỗi kết nối mạng.');
    return e is Exception ? e : Exception(e.toString());
  }

  // --- API Function for Payment ---

  /// Tạo link thanh toán (VNPAY hoặc MOMO)
  /// POST /api/payment/create-payment
  /// Body: { "amountVND": 100000, "provider": "VNPAY" | "MOMO" }
  /// Trả về Map với paymentUrl và orderId để tracking
  Future<Map<String, dynamic>> createPaymentUrl({
    required int amount,
    required String provider, // "VNPAY" hoặc "MOMO"
  }) async {
    if (kDebugMode) print('=== CREATE PAYMENT LINK ($provider) ===');

    final headers = await _getAuthHeaders(requireToken: true); // Yêu cầu token
    final body = jsonEncode({
      'amountVND': amount,
      'provider': provider,
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/create-payment'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      final data = _processResponse(response);

      // Lấy paymentUrl và orderId từ JSON trả về
      final String? paymentUrl = data['paymentUrl'];
      final String? orderId = data['orderId'];

      if (paymentUrl != null && orderId != null) {
        if (kDebugMode) {
          print('✓ Payment URL received: $paymentUrl');
          print('✓ Order ID: $orderId');
        }
        return {
          'paymentUrl': paymentUrl,
          'orderId': orderId,
        };
      } else {
        throw Exception('Phản hồi không chứa paymentUrl hoặc orderId');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Kiểm tra trạng thái đơn hàng
  /// GET /api/payment/payment-history/:orderId
  Future<Map<String, dynamic>> checkOrderStatus(String orderId) async {
    if (kDebugMode) print('=== CHECK ORDER STATUS: $orderId ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/payment-history/$orderId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final responseData = _processResponse(response);

      // API trả về: { "message": "...", "data": { "orderId": "...", "status": "COMPLETED", ... } }
      final data = responseData['data'] ?? {};
      final String status = data['status'] ?? 'PENDING';

      if (kDebugMode) {
        print('✓ Order Status: $status');
      }

      // Trả về format chuẩn
      return {
        'success': true,
        'status': status,
        'data': data,
      };
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy thông tin điểm của user hiện tại
  /// GET /api/points/balance
  Future<Map<String, dynamic>> getUserPoints() async {
    if (kDebugMode) print('=== GET USER POINTS ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_pointsBaseUrl/balance'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      // API trả về trực tiếp: { "success": true, "balance": 1460, "level": 0 }
      if (data is Map && data.containsKey('balance')) {
        final int balance = data['balance'] ?? 0;
        final int level = data['level'] ?? 0;
        final int totalEarned = data['totalEarned'] ?? 0;
        final int totalSpent = data['totalSpent'] ?? 0;

        if (kDebugMode) {
          print('✓ User Points: $balance điểm (Level $level)');
        }

        return {
          'success': true,
          'balance': balance,
          'level': level,
          'totalEarned': totalEarned,
          'totalSpent': totalSpent,
          'lastUpdated': data['lastUpdated'],
        };
      } else {
        throw Exception('Không thể lấy thông tin điểm');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy lịch sử điểm của user
  /// GET /api/points/history?page=1&limit=20
  Future<Map<String, dynamic>> getPointsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (kDebugMode) print('=== GET POINTS HISTORY (Page: $page) ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_pointsBaseUrl/history?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      if (kDebugMode) {
        print('✓ Points History loaded: ${data['data']?.length ?? 0} records');
      }

      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy lịch sử đơn hàng thanh toán của user
  /// GET /api/payment/payment-history?page=1&limit=10
  Future<Map<String, dynamic>> getMyOrders({
    int page = 1,
    int limit = 10,
  }) async {
    if (kDebugMode) print('=== GET PAYMENT HISTORY (Page: $page) ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/payment-history?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      if (kDebugMode) {
        print(
            '✓ Payment History loaded: ${data['data']?['orders']?.length ?? 0} orders');
      }

      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}
