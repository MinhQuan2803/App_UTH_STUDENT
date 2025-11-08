import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_theme.dart';
import 'dart:io';
import 'dart:async';

class PaymentService {
  static final String _baseUrl = AppAssets.paymentApiBaseUrl;
  static final String _userBaseUrl = AppAssets.userApiBaseUrl;
  final AuthService _authService = AuthService();

  // --- Helper Functions (Tái sử dụng) ---
  Future<Map<String, String>> _getAuthHeaders(
      {bool requireToken = false}) async {
    final String? token = await _authService.getToken();
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

  /// Tạo link thanh toán VNPAY
  /// POST /api/payment/vnpay/create-payment-link
  /// Trả về Map với paymentUrl và orderId để tracking
  Future<Map<String, dynamic>> createPaymentUrl({
    required int amount,
    required String orderInfo,
  }) async {
    if (kDebugMode) print('=== CREATE VNPAY PAYMENT LINK ===');

    final headers = await _getAuthHeaders(requireToken: true); // Yêu cầu token
    final body = jsonEncode({
      'amount': amount,
      'orderInfo': orderInfo,
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/vnpay/create-payment-link'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      final data = _processResponse(response);

      // Lấy paymentUrl và vnp_TxnRef từ JSON trả về
      final String? paymentUrl = data['paymentUrl'];
      final String? vnpTxnRef = data['vnp_TxnRef'];

      if (paymentUrl != null) {
        if (kDebugMode) {
          print('✓ Payment URL received: $paymentUrl');
          print('✓ VNP TxnRef: $vnpTxnRef');
        }
        return {
          'paymentUrl': paymentUrl,
          'vnpTxnRef': vnpTxnRef,
        };
      } else {
        throw Exception('Phản hồi không chứa paymentUrl');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Kiểm tra trạng thái đơn hàng
  /// GET /api/payment/vnpay/order-status/:orderId
  Future<Map<String, dynamic>> checkOrderStatus(String vnpTxnRef) async {
    if (kDebugMode) print('=== CHECK ORDER STATUS: $vnpTxnRef ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/vnpay/order-status/$vnpTxnRef'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final responseData = _processResponse(response);

      // Parse status từ data object
      final String status = responseData['data']?['status'] ??
          responseData['status'] ??
          'PENDING';

      if (kDebugMode) {
        print('✓ Order Status: $status');
      }

      // Trả về format chuẩn
      return {
        'success': responseData['success'] ?? true,
        'status': status,
        'data': responseData['data'],
      };
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy thông tin điểm của user hiện tại
  /// GET /api/users/me/points
  Future<Map<String, dynamic>> getUserPoints() async {
    if (kDebugMode) print('=== GET USER POINTS ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_userBaseUrl/me/points'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      if (data['success'] == true && data['data'] != null) {
        final pointsData = data['data'];
        final int balance = pointsData['balance'] ?? 0;
        final int level = pointsData['level'] ?? 0;
        final int totalEarned = pointsData['totalEarned'] ?? 0;
        final int totalSpent = pointsData['totalSpent'] ?? 0;

        if (kDebugMode) {
          print('✓ User Points loaded');
          print('Balance: $balance điểm');
          print('Level: $level');
          print('Total Earned: $totalEarned');
          print('Total Spent: $totalSpent');
        }

        return {
          'success': true,
          'balance': balance,
          'level': level,
          'totalEarned': totalEarned,
          'totalSpent': totalSpent,
          'lastUpdated': pointsData['lastUpdated'],
        };
      } else {
        throw Exception('Không thể lấy thông tin điểm');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy lịch sử điểm của user
  /// GET /api/users/me/points/history?page=1&limit=20
  Future<Map<String, dynamic>> getPointsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (kDebugMode) print('=== GET POINTS HISTORY (Page: $page) ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse(
                '$_userBaseUrl/me/points/history?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      if (kDebugMode) {
        print(
            '✓ Points History loaded: ${data['data']?['history']?.length ?? 0} records');
      }

      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// Lấy lịch sử đơn hàng thanh toán VNPAY của user
  /// GET /api/payment/vnpay/my-orders?page=1&limit=10
  Future<Map<String, dynamic>> getMyOrders({
    int page = 1,
    int limit = 10,
  }) async {
    if (kDebugMode) print('=== GET MY ORDERS (Page: $page) ===');

    final headers = await _getAuthHeaders(requireToken: true);

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/vnpay/my-orders?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _processResponse(response);

      if (kDebugMode) {
        print(
            '✓ Orders loaded: ${data['data']?['orders']?.length ?? 0} records');
      }

      return data;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }
}
