import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chatbot_model.dart';

class ChatbotService {
  // Endpoint Webhook mới từ ngrok
  static const String apiUrl = 'https://hardbound-wilhemina-breechloading.ngrok-free.dev/webhooks/rest/webhook';

  /// Gửi câu hỏi đến chatbot
  Future<ChatMessage> sendMessage(String message) async {
    // Hardcode ID người dùng (hoặc lấy từ device ID / local storage nếu cần)
    const String senderId = "huynguyen"; 

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // Không cần Authorization header nữa
        },
        body: jsonEncode({
          'sender': senderId,
          'message': message,
        }),
      );

      if (kDebugMode) {
        print('📤 Chatbot Request: $message (sender: $senderId)');
        print('📥 Chatbot Response: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Parse dữ liệu từ mảng custom (logic cũ vẫn áp dụng tốt cho Rasa Webhook)
          return _parseRasaResponse(data[0]);
        }

        // Trường hợp Rasa trả về 200 nhưng mảng rỗng (thường do bot không hiểu hoặc không có response text)
        // Ta tạo một tin nhắn mặc định để app không bị crash
        return ChatMessage(
          text: "Xin lỗi, hiện tại tôi chưa hiểu ý của bạn hoặc chưa có dữ liệu phản hồi.",
          isFromUser: false,
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Chatbot Error: $e');
      rethrow;
    }
  }

  /// Hàm xử lý response (giữ nguyên logic tách chuỗi Link và Suggestion)
  ChatMessage _parseRasaResponse(Map<String, dynamic> botData) {
    String answerText = "";
    List<ChatLink> links = [];
    List<String> suggestions = [];

    // Kiểm tra custom payload
    if (botData.containsKey('custom') && botData['custom'] is List) {
      final List<dynamic> customList = botData['custom'];

      for (var item in customList) {
        if (item is Map<String, dynamic>) {
          // 1. Lấy câu trả lời
          if (item.containsKey('answer')) {
            answerText += "${item['answer']}\n";
          }
          // 2. Xử lý Links
          if (item.containsKey('links')) {
            links.addAll(_parseLinkString(item['links']));
          }
          // 3. Xử lý Suggestions
          if (item.containsKey('questions_suggestions')) {
            suggestions.addAll(_parseSuggestionString(item['questions_suggestions']));
          }
        }
      }
    } 
    // Fallback: Nếu không có 'custom' (ví dụ bot trả lời câu text đơn giản mặc định của Rasa)
    else if (botData.containsKey('text')) {
       answerText = botData['text'];
    }
    else {
      answerText = "Định dạng phản hồi không hỗ trợ.";
    }

    return ChatMessage(
      text: answerText.trim(),
      isFromUser: false,
      links: links.isNotEmpty ? links : null,
      suggestions: suggestions.isNotEmpty ? suggestions : null,
    );
  }

  List<ChatLink> _parseLinkString(String raw) {
    List<ChatLink> results = [];
    List<String> lines = raw.split('\n');
    for (var line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.startsWith('-')) cleanLine = cleanLine.substring(1).trim();
      
      int urlIndex = cleanLine.indexOf('http');
      if (urlIndex != -1) {
        String title = cleanLine.substring(0, urlIndex).trim();
        if (title.endsWith(':')) title = title.substring(0, title.length - 1).trim();
        String url = cleanLine.substring(urlIndex).trim();
        results.add(ChatLink(title: title, url: url));
      }
    }
    return results;
  }

  List<String> _parseSuggestionString(String raw) {
    List<String> results = [];
    List<String> lines = raw.split('\n');
    for (var line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.startsWith('-')) cleanLine = cleanLine.substring(1).trim();
      if (cleanLine.isNotEmpty) results.add(cleanLine);
    }
    return results;
  }
}