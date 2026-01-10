class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'like', 'comment', 'follow', 'system'...
  bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final List<RelatedUser> relatedUsers;
  final int actorCount;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.relatedUsers = const [],
    this.actorCount = 1,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'],
      relatedUsers: (json['relatedUsers'] as List?)
              ?.map((e) => RelatedUser.fromJson(e))
              .toList() ??
          [],
      actorCount: json['actorCount'] ?? 1,
    );
  }

  // Getter để hiển thị thời gian local
  DateTime get createdAtLocal => createdAt.toLocal();
}

class RelatedUser {
  final String userId;
  final String username;
  final String?
      avatarURL; // Lưu ý: Bạn đang đặt tên biến là avatarURL (có URL viết hoa)

  RelatedUser({required this.userId, required this.username, this.avatarURL});

  // --- ĐOẠN CODE BẠN CẦN SỬA NẰM Ở ĐÂY ---
  factory RelatedUser.fromJson(Map<String, dynamic> json) {
    String id = '';
    String? avt;
    // Mặc định lấy tên snapshot (tên cũ lưu trong thông báo)
    String name = json['username'] ?? '';

    // Kiểm tra xem userId có được populate (là Map) hay không
    if (json['userId'] is Map) {
      final userMap = json['userId'];
      id = userMap['_id'] ?? '';

      // Lấy avatarUrl từ database (khớp với model User.js của bạn)
      avt = userMap['avatarUrl'];

      // Lấy tên mới nhất từ bảng User (nếu có)
      if (userMap['username'] != null) {
        name = userMap['username'];
      }
    } else {
      // Fallback nếu backend trả về string ID
      id = json['userId']?.toString() ?? '';
    }

    return RelatedUser(
      userId: id,
      username: name,
      avatarURL: avt, // Gán vào biến avatarURL
    );
  }
}
