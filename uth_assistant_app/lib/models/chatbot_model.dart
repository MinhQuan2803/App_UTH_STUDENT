class ChatMessage {
  final String text;
  final bool isFromUser;
  final bool isTyping;
  final List<ChatLink>? links;
  final List<String>? suggestions;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    this.isTyping = false,
    this.links,
    this.suggestions,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromBot(Map<String, dynamic> json) {
    String answer = '';
    List<ChatLink>? links;
    List<String>? suggestions;

    // Xử lý custom array từ API mới
    if (json['custom'] != null && json['custom'] is List) {
      for (var item in json['custom']) {
        if (item['answer'] != null) {
          answer = item['answer'];
        }
        if (item['links'] != null) {
          // Parse links từ string format "- Title: URL\n- Title: URL"
          String linksStr = item['links'];
          links = _parseLinksFromString(linksStr);
        }
        if (item['questions_suggestions'] != null) {
          // Parse suggestions từ string format "- Question?\n- Question?"
          String suggestionsStr = item['questions_suggestions'];
          suggestions = _parseSuggestionsFromString(suggestionsStr);
        }
      }
    }

    return ChatMessage(
      text: answer,
      isFromUser: false,
      links: links,
      suggestions: suggestions,
    );
  }

  // Helper để parse links từ string
  static List<ChatLink> _parseLinksFromString(String linksStr) {
    List<ChatLink> result = [];
    // Tách theo dấu xuống dòng và loại bỏ dòng trống
    var lines = linksStr.split('\n').where((line) => line.trim().isNotEmpty);

    for (var line in lines) {
      // Bỏ dấu "- " ở đầu
      line = line.trim();
      if (line.startsWith('- ')) {
        line = line.substring(2);
      }

      // Tách title và URL bằng dấu ":"
      var parts = line.split(': ');
      if (parts.length >= 2) {
        String title = parts[0].trim();
        String url =
            parts.sublist(1).join(': ').trim(); // Nối lại nếu URL có dấu ":"
        result.add(ChatLink(title: title, url: url));
      }
    }

    return result;
  }

  // Helper để parse suggestions từ string
  static List<String> _parseSuggestionsFromString(String suggestionsStr) {
    // Tách theo dấu xuống dòng và loại bỏ dòng trống
    var lines =
        suggestionsStr.split('\n').where((line) => line.trim().isNotEmpty);

    return lines.map((line) {
      // Bỏ dấu "- " ở đầu
      line = line.trim();
      if (line.startsWith('- ')) {
        return line.substring(2);
      }
      return line;
    }).toList();
  }

  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      text: text,
      isFromUser: true,
    );
  }

  factory ChatMessage.typing() {
    return ChatMessage(
      text: '',
      isFromUser: false,
      isTyping: true,
    );
  }
}

class ChatLink {
  final String title;
  final String url;

  ChatLink({
    required this.title,
    required this.url,
  });

  factory ChatLink.fromJson(Map<String, dynamic> json) {
    return ChatLink(
      title: json['tittle_link'] ??
          '', // Lưu ý: backend dùng "tittle" sai chính tả
      url: json['url'] ?? '',
    );
  }
}
