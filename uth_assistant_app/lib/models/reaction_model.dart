/// Model cho người dùng đã react bài viết
class ReactionUser {
  final String id;
  final String username;
  final String? realname;
  final String? avatarUrl;
  final String? bio;
  final String reactionType; // 'like' | 'dislike'
  final DateTime createdAt;

  ReactionUser({
    required this.id,
    required this.username,
    this.realname,
    this.avatarUrl,
    this.bio,
    required this.reactionType,
    required this.createdAt,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return ReactionUser(
      id: user['_id'] ?? '',
      username: user['username'] ?? 'Người dùng ẩn',
      realname: user['realname'],
      avatarUrl: user['avatarUrl'],
      bio: user['bio'],
      reactionType: json['type'] ?? 'like',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String get displayName => realname ?? username;
}

/// Model cho số lượng reactions
class ReactionCounts {
  final int likes;
  final int dislikes;
  final int total;

  ReactionCounts({
    required this.likes,
    required this.dislikes,
    required this.total,
  });

  factory ReactionCounts.fromJson(Map<String, dynamic> json) {
    return ReactionCounts(
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

/// Model cho phân trang reactions
class ReactionPagination {
  final int currentPage;
  final int totalPages;
  final int totalReactions;
  final bool hasMore;

  ReactionPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalReactions,
    required this.hasMore,
  });

  factory ReactionPagination.fromJson(Map<String, dynamic> json) {
    return ReactionPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalReactions: json['totalReactions'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Model cho response danh sách reactions
class ReactionListResponse {
  final List<ReactionUser> reactions;
  final ReactionPagination pagination;
  final ReactionCounts counts;

  ReactionListResponse({
    required this.reactions,
    required this.pagination,
    required this.counts,
  });

  factory ReactionListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final reactionsList = data['reactions'] as List? ?? [];

    return ReactionListResponse(
      reactions:
          reactionsList.map((item) => ReactionUser.fromJson(item)).toList(),
      pagination: ReactionPagination.fromJson(data['pagination'] ?? {}),
      counts: ReactionCounts.fromJson(data['counts'] ?? {}),
    );
  }
}
