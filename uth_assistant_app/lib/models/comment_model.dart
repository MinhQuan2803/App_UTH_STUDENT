import 'post_model.dart'; // Sử dụng lại Author model

class Comment {
  final String id;
  final Author author;
  final String text;
  final String targetId; // ID của Post hoặc Comment cha
  final String targetType; // "Post" hoặc "Comment"
  final int likesCount;
  final int repliesCount;
  final DateTime createdAt;
  final String? myReactionType;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.targetId,
    required this.targetType,
    this.likesCount = 0,
    this.repliesCount = 0,
    required this.createdAt,
    this.myReactionType,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    DateTime createdAtDate;
    try {
      createdAtDate = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      print("Error parsing comment createdAt: ${json['createdAt']}");
      createdAtDate = DateTime.now();
    }

    return Comment(
      id: json['_id'] ?? '',
      author: Author.fromJson(json['author'] ?? {}),
      text: json['text'] ?? '',
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? 'Post',
      likesCount: json['likesCount'] ?? 0,
      repliesCount: json['repliesCount'] ?? 0,
      createdAt: createdAtDate,
      myReactionType: json['myReactionType'],
    );
  }
}

