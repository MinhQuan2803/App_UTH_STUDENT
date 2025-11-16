class PointHistory {
  final String id;
  final String userId;
  final String type; // EARNED, SPENT
  final int amount;
  final String source; // PAYMENT, POST, etc.
  final String description;
  final String? referenceId;
  final int balanceBefore;
  final int balanceAfter;
  final String? eventId;
  final DateTime createdAt;

  PointHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.source,
    required this.description,
    this.referenceId,
    required this.balanceBefore,
    required this.balanceAfter,
    this.eventId,
    required this.createdAt,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] ?? 0,
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      referenceId: json['referenceId'],
      balanceBefore: json['balanceBefore'] ?? 0,
      balanceAfter: json['balanceAfter'] ?? 0,
      eventId: json['eventId'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PointHistoryResponse {
  final bool success;
  final List<PointHistory> history;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int limit;

  PointHistoryResponse({
    required this.success,
    required this.history,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.limit,
  });

  factory PointHistoryResponse.fromJson(Map<String, dynamic> json) {
    // API trả về: { "data": [...], "pagination": {...} }
    final historyList = (json['data'] as List?)
            ?.map((item) => PointHistory.fromJson(item))
            .toList() ??
        [];
    final pagination = json['pagination'] ?? {};

    return PointHistoryResponse(
      success: true, // API không trả success field, mặc định true
      history: historyList,
      currentPage: pagination['currentPage'] ?? 1,
      totalPages: pagination['totalPages'] ?? 1,
      totalRecords: pagination['totalItems'] ?? 0, // API dùng totalItems
      limit: pagination['limit'] ?? 20,
    );
  }
}
