import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_theme.dart';
import 'dart:io';
import 'dart:async';
import '../models/cashout_model.dart';

class CashoutService {
  static final String _baseUrl =
      '${AppAssets.paymentApiBaseUrl.replaceAll('/payment', '/finance')}';
  final AuthService _authService = AuthService();

  // --- Helper Functions ---
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getValidToken();
    if (token == null) {
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _processResponse(http.Response response) {
    if (kDebugMode) {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Có lỗi xảy ra');
    }
  }

  Exception _handleNetworkError(dynamic e) {
    if (e is SocketException) return Exception('Không có kết nối mạng');
    if (e is TimeoutException) return Exception('Yêu cầu quá thời gian');
    return Exception(e.toString());
  }

  /// Tạo yêu cầu rút tiền
  /// POST /api/payment/cashout
  Future<Map<String, dynamic>> createCashout({
    required int pointsAmount,
    required BankInfo bankInfo,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = CashoutRequest(
        pointsAmount: pointsAmount,
        bankInfo: bankInfo,
      ).toJson();

      if (kDebugMode) {
        print('=== CREATE CASHOUT REQUEST ===');
        print('URL: $_baseUrl/cashout');
        print('Body: ${json.encode(body)}');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/cashout'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = _processResponse(response);

      if (kDebugMode) {
        print('=== CREATE CASHOUT SUCCESS ===');
        print('Data: $data');
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('=== CREATE CASHOUT ERROR ===');
        print('Error: $e');
      }
      throw _handleNetworkError(e);
    }
  }

  /// Lấy lịch sử rút tiền
  /// GET /api/payment/cashout
  Future<List<CashoutModel>> getCashoutHistory() async {
    try {
      final headers = await _getAuthHeaders();

      if (kDebugMode) {
        print('=== GET CASHOUT HISTORY ===');
        print('URL: $_baseUrl/cashout');
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/cashout'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      final data = _processResponse(response);

      if (kDebugMode) {
        print('=== GET CASHOUT HISTORY SUCCESS ===');
        print('Count: ${(data as List).length}');
      }

      return (data as List).map((item) => CashoutModel.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('=== GET CASHOUT HISTORY ERROR ===');
        print('Error: $e');
      }
      throw _handleNetworkError(e);
    }
  }
}
