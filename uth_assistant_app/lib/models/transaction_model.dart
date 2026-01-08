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
    DateTime createdAtDate;
    try {
      final dateStr = (json['createdAt'] ?? '').toString().trim();
      if (dateStr.isEmpty) {
        createdAtDate = DateTime.now();
      } else {
        // Thêm 'Z' nếu chưa có để parse như UTC
        final utcDateStr = dateStr.endsWith('Z') ? dateStr : '${dateStr}Z';
        createdAtDate = DateTime.parse(utcDateStr).toLocal();
      }
    } catch (e) {
      print("Error parsing transaction createdAt: ${json['createdAt']}");
      print("Stack trace: $e");
      createdAtDate = DateTime.now();
    }
    
    return TransactionModel(
      id: json['_id'] ?? '',
      amount: json['amount'] ?? 0,
      isPlus: json['isPlus'] ?? false, // Đây là field quan trọng nhất backend trả về
      type: json['type'] ?? '',
      description: json['description'] ?? 'Giao dịch',
      status: json['status'] ?? 'PENDING',
      createdAt: createdAtDate,
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