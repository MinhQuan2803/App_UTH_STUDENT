class DocumentModel {
  final String id;
  final String title;
  final String ownerId;
  final String ownerName; // Cần backend populate hoặc lấy từ ownerId
  final String ownerAvatar;
  final int price;
  final String privacy; // 'public', 'private'
  final int totalPages;
  final int previewPages;
  final String description;
  final bool isFullAccess; // QUAN TRỌNG: Backend trả về true/false
  final DateTime createdAt;
  final String cloudinaryPublicId;
  final String originalUrl;
  

  DocumentModel({
    required this.id,
    required this.title,
    required this.ownerId,
    this.ownerName = 'Người dùng ẩn danh',
    this.ownerAvatar = '',
    required this.price,
    required this.privacy,
    required this.totalPages,
    required this.previewPages,
    this.description = '',
    required this.isFullAccess,
    required this.createdAt,
    required this.cloudinaryPublicId,
    required this.originalUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final ownerData = json['ownerId'];
    String oName = 'Unknown';
    String oAvatar = '';
    String oId = '';

    if (ownerData is Map) {
      oName = ownerData['username'] ?? 'Unknown';
      oAvatar = ownerData['avatarUrl'] ?? '';
      oId = ownerData['_id'] ?? '';
    } else if (ownerData is String) {
      oId = ownerData;
    }

    return DocumentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Không có tiêu đề',
      ownerId: oId,
      ownerName: oName,
      ownerAvatar: oAvatar,
      price: json['price'] ?? 0,
      privacy: json['privacy'] ?? 'private',
      totalPages: json['totalPages'] ?? 0,
      previewPages: json['previewPages'] ?? 2,
      description: json['description'] ?? 'Chưa có mô tả cho tài liệu này.',
      isFullAccess: json['isFullAccess'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      cloudinaryPublicId: json['cloudinaryPublicId'] ?? '',
      originalUrl: json['url'] ?? '',
    );
  }

  // --- HÀM THẦN THÁNH: Tự tạo URL ảnh cho từng trang ---
  // Cloudinary hỗ trợ convert PDF -> Image bằng cách thêm /pg_x/ vào URL
  String getPageUrl(int pageNumber) {
    // Base URL mẫu: https://res.cloudinary.com/demo/image/upload/v12345/doc.pdf
    // Target URL:   https://res.cloudinary.com/demo/image/upload/w_1000,f_auto,q_auto/pg_1/v12345/doc.jpg
    
    if (originalUrl.isEmpty) return '';

    // 1. Tách base url và phần đuôi
    // Trick: Thay thế '/upload/' bằng '/upload/w_1000,f_jpg,pg_$pageNumber/'
    // w_1000: Giới hạn chiều rộng để load nhanh
    // f_jpg: Ép về định dạng ảnh
    // pg_x: Lấy trang số x
    
    return originalUrl.replaceFirst(
      '/upload/', 
      '/upload/w_1000,f_jpg,pg_$pageNumber/'
    ).replaceAll('.pdf', '.jpg'); 
  }
}