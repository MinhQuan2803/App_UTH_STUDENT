class PaymentOrder {
  final String id;
  final int amountVND;
  final int pointsToGrant;
  final String status; // COMPLETED, PENDING, FAILED, CANCELLED
  final String paymentProvider; // VNPAY, MOMO
  final DateTime createdAt;

  PaymentOrder({
    required this.id,
    required this.amountVND,
    required this.pointsToGrant,
    required this.status,
    required this.paymentProvider,
    required this.createdAt,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['_id'] ?? '',
      amountVND: json['amountVND'] ?? 0,
      pointsToGrant: json['pointsToGrant'] ?? 0,
      status: json['status'] ?? '',
      paymentProvider: json['paymentProvider'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PaymentOrderResponse {
  final String message;
  final List<PaymentOrder> orders;
  final int currentPage;
  final int totalPages;
  final int totalOrders;

  PaymentOrderResponse({
    required this.message,
    required this.orders,
    required this.currentPage,
    required this.totalPages,
    required this.totalOrders,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    // API trả về: { "message": "...", "data": { "orders": [...], "currentPage": 1, ... } }
    final data = json['data'] ?? {};
    final ordersList = (data['orders'] as List?)
            ?.map((item) => PaymentOrder.fromJson(item))
            .toList() ??
        [];

    return PaymentOrderResponse(
      message: json['message'] ?? '',
      orders: ordersList,
      currentPage: data['currentPage'] ?? 1,
      totalPages: data['totalPages'] ?? 1,
      totalOrders: data['totalOrders'] ?? 0,
    );
  }
}
