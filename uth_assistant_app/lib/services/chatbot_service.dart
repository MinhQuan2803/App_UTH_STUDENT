import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chatbot_model.dart';
import 'auth_service.dart';

class ChatbotService {
  static const String baseUrl = 'https://uth-assistant-app.onrender.com/api';
  final AuthService _authService = AuthService();

  /// Gửi câu hỏi đến chatbot
  Future<ChatMessage> sendMessage(String question) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập để sử dụng chatbot');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chatbot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'question': question}),
      );

      if (kDebugMode) {
        print('📤 Chatbot Request: $question');
        print('📥 Chatbot Response: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API trả về array, lấy phần tử đầu tiên
        if (data is List && data.isNotEmpty) {
          return ChatMessage.fromBot(data[0]);
        }

        throw Exception('Dữ liệu trả về không hợp lệ');
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Chatbot Error: $e');
      rethrow;
    }
  }

  /// Lấy lịch sử chat (nếu backend hỗ trợ)
  Future<List<ChatMessage>> getChatHistory() async {
    final token = await _authService.getToken();

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chatbot/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((msg) => ChatMessage.fromBot(msg)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('❌ Get History Error: $e');
      return [];
    }
  }
}
