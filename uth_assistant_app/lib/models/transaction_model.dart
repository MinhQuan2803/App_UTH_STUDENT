class TransactionModel {
  final String id;
  final int amount;
  final bool isPlus; // API trả về true/false, dùng cái này tiện hơn type EARNED/SPENT
  final String type; // 'DEPOSIT', 'BUY_DOCUMENT'
  final String description;
  final String status;
  final DateTime createdAt;

  // Constructor
  TransactionModel({
    required this.id,
    required this.amount,
    required this.isPlus,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  // Factory parse JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      amount: json['amount'] ?? 0,
      isPlus: json['isPlus'] ?? false, // Đây là field quan trọng nhất backend trả về
      type: json['type'] ?? '',
      description: json['description'] ?? 'Giao dịch',
      status: json['status'] ?? 'PENDING',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// Class Response bọc ngoài (cho phân trang)
class TransactionResponse {
  final List<TransactionModel> transactions;
  final int totalPages;
  final int currentPage;

  TransactionResponse({
    required this.transactions,
    required this.totalPages,
    required this.currentPage,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List?)
            ?.map((e) => TransactionModel.fromJson(e))
            .toList() ?? [];
            
    return TransactionResponse(
      transactions: list,
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
    );
  }
}