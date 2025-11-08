class PaymentOrder {
  final String id;
  final String userId;
  final String vnpTxnRef;
  final int amount;
  final String orderInfo;
  final String status; // SUCCESS, PENDING, FAILED, CANCELLED
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? vnpResponseCode;
  final String? paymentMethod; // VNPAY, MOMO, BANK_TRANSFER, ZALOPAY

  PaymentOrder({
    required this.id,
    required this.userId,
    required this.vnpTxnRef,
    required this.amount,
    required this.orderInfo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vnpResponseCode,
    this.paymentMethod,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      vnpTxnRef: json['vnp_TxnRef'] ?? '',
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      status: json['status'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      vnpResponseCode: json['vnp_ResponseCode'],
      paymentMethod: json['paymentMethod'],
    );
  }
}

class PaymentOrderResponse {
  final bool success;
  final List<PaymentOrder> orders;
  final int currentPage;
  final int totalPages;
  final int totalOrders;
  final int limit;

  PaymentOrderResponse({
    required this.success,
    required this.orders,
    required this.currentPage,
    required this.totalPages,
    required this.totalOrders,
    required this.limit,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final ordersList = (data['orders'] as List?)
            ?.map((item) => PaymentOrder.fromJson(item))
            .toList() ??
        [];
    final pagination = data['pagination'] ?? {};

    return PaymentOrderResponse(
      success: json['success'] ?? false,
      orders: ordersList,
      currentPage: pagination['currentPage'] ?? 1,
      totalPages: pagination['totalPages'] ?? 1,
      totalOrders: pagination['totalOrders'] ?? 0,
      limit: pagination['limit'] ?? 10,
    );
  }
}
