// Model cho tác giả bài viết
class Author {
  final String id;
  final String username;
  final String? realname;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;

  Author({
    required this.id,
    required this.username,
    this.realname,
    this.avatarUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Người dùng ẩn',
      realname: json['realname'],
      avatarUrl: json['avatarUrl'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(_ensureUtcFormat(json['createdAt'])).toLocal()
          : DateTime.now(),
    );
  }

  // Helper method để đảm bảo format UTC
  static String _ensureUtcFormat(String dateStr) {
    final trimmed = dateStr.trim();
    return trimmed.endsWith('Z') ? trimmed : '${trimmed}Z';
  }

  // Getter để lấy tên hiển thị (ưu tiên realname, fallback username)
  String get displayName => realname ?? username;
}

// Model cho bài viết
class Post {
  final String id;
  final Author author;
  final String text;
  final List<String> mediaUrls;
  final String privacy;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final String? myReactionType;
  final bool isDocumentPost; // Đánh dấu bài post từ tài liệu
  final String? docId; // ID của tài liệu nếu có

  Post({
    required this.id,
    required this.author,
    required this.text,
    required this.mediaUrls,
    this.privacy = 'public',
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    this.myReactionType,
    this.isDocumentPost = false,
    this.docId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Xử lý mediaUrls (có thể là String hoặc List)
    List<String> urls = [];
    if (json['mediaUrls'] != null) {
      if (json['mediaUrls'] is String) {
        urls.add(json['mediaUrls']);
      } else if (json['mediaUrls'] is List) {
        urls = List<String>.from(json['mediaUrls']);
      }
    }

    // Parse createdAt thành DateTime và convert sang local time, xử lý lỗi nếu có
    DateTime createdAtDate;
    try {
      final dateStr = (json['createdAt'] ?? DateTime.now().toIso8601String()).toString().trim();
      // Thêm 'Z' nếu chưa có để parse như UTC
      final utcDateStr = dateStr.endsWith('Z') ? dateStr : '${dateStr}Z';
      createdAtDate = DateTime.parse(utcDateStr).toLocal();
    } catch (e) {
      print("Error parsing post createdAt: ${json['createdAt']}");
      print("Stack trace: $e");
      createdAtDate = DateTime.now();
    }

    return Post(
      id: json['_id'] ?? '',
      author: Author.fromJson(json['author'] ?? {}),
      text: json['text'] ?? '',
      mediaUrls: urls,
      privacy: json['privacy'] ?? 'public',
      likesCount: json['likesCount'] ?? 0,
      dislikesCount: json['dislikesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      createdAt: createdAtDate,
      myReactionType: json['myReactionType'],
      isDocumentPost: json['isDocumentPost'] ?? false,
      docId: json['docId'],
    );
  }
}
