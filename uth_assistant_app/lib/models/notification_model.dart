class NotificationModel {
  final String id;
  final String type; // like, comment, follow, mention, system
  final String title;
  final String message;
  bool isRead; // Changed to non-final
  final DateTime createdAt;
  final Map<String, dynamic>? data; // postId, userId, username, etc.

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  // Temporary fix for backend timezone (add 7 hours)
  DateTime get createdAtLocal => createdAt.add(const Duration(hours: 7));

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }
}
