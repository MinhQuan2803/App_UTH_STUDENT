// Model cho tác giả bài viết
class Author {
  final String id;
  final String username;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;

  Author({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Người dùng ẩn',
      avatarUrl: json['avatarUrl'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
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

    // Parse createdAt thành DateTime, xử lý lỗi nếu có
    DateTime createdAtDate;
    try {
      createdAtDate =
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      print("Error parsing post createdAt: ${json['createdAt']}");
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
    );
  }
}
