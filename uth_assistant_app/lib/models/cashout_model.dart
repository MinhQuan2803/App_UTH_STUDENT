class BankInfo {
  final String bankName;
  final String accountNumber;
  final String accountName;

  BankInfo({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
    };
  }

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
    );
  }

  BankInfo copyWith({
    String? bankName,
    String? accountNumber,
    String? accountName,
  }) {
    return BankInfo(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
    );
  }
}

class CashoutRequest {
  final int pointsAmount;
  final BankInfo bankInfo;

  CashoutRequest({
    required this.pointsAmount,
    required this.bankInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'pointsAmount': pointsAmount,
      'bankInfo': bankInfo.toJson(),
    };
  }
}

class CashoutModel {
  final String? id;
  final int pointsAmount;
  final int moneyAmount;
  final String status; // PENDING, APPROVED, REJECTED
  final BankInfo bankInfo;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? rejectionReason;

  // Tạm thời cộng 7 tiếng vì backend đang bị lỗi timezone
  DateTime get createdAtLocal => createdAt.add(const Duration(hours: 7));
  DateTime? get processedAtLocal => processedAt?.add(const Duration(hours: 7));

  CashoutModel({
    this.id,
    required this.pointsAmount,
    required this.moneyAmount,
    required this.status,
    required this.bankInfo,
    required this.createdAt,
    this.processedAt,
    this.rejectionReason,
  });

  factory CashoutModel.fromJson(Map<String, dynamic> json) {
    return CashoutModel(
      id: json['_id'],
      pointsAmount: json['pointsAmount'] ?? 0,
      moneyAmount: json['moneyAmount'] ?? 0,
      status: json['status'] ?? 'PENDING',
      bankInfo: BankInfo.fromJson(json['bankInfo'] ?? {}),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  String getStatusText() {
    switch (status) {
      case 'PENDING':
        return 'Đang chờ duyệt';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }
}
