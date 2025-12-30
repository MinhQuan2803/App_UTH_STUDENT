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
  final String summary; // Tóm tắt tài liệu từ AI
  final bool isFullAccess; // Backend trả về true/false - Đã mua hoặc miễn phí
  final DateTime createdAt;
  final String cloudinaryPublicId;

  // ✅ CẬP NHẬT: Tách riêng URL chính và preview
  final String?
      url; // Nullable - Chỉ có khi đã mua/miễn phí (isFullAccess = true)
  final String
      previewUrl; // Required - Luôn có cho mọi tài liệu (thumbnail/trang 1)

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
    this.summary = '',
    required this.isFullAccess,
    required this.createdAt,
    required this.cloudinaryPublicId,
    this.url, // Nullable
    required this.previewUrl, // Required
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
      summary: json['summary'] ?? '',
      isFullAccess: json['isFullAccess'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      cloudinaryPublicId: json['cloudinaryPublicId'] ?? '',

      // ✅ URL chính - URL PDF gốc
      url: json['url'], // Nullable, có thể null nếu chưa mua

      // ✅ Preview URL - Tạo từ URL chính bằng Cloudinary transform
      // Backend trả previewUrl rỗng, tự động convert PDF → JPG trang 1
      previewUrl: _generatePreviewUrl(json['url'], json['previewUrl']),
    );
  }

  /// Helper: Tạo preview URL từ PDF URL (Cloudinary transform)
  static String _generatePreviewUrl(dynamic url, dynamic previewUrl) {
    // Nếu có previewUrl sẵn từ backend → dùng luôn
    if (previewUrl != null && previewUrl.toString().trim().isNotEmpty) {
      return previewUrl.toString();
    }

    // Nếu không có URL gốc → return rỗng
    if (url == null || url.toString().trim().isEmpty) {
      return '';
    }

    final urlStr = url.toString();

    // Chỉ xử lý URL Cloudinary PDF
    if (!urlStr.contains('cloudinary.com') || !urlStr.endsWith('.pdf')) {
      return urlStr; // Không phải Cloudinary PDF → trả về nguyên
    }

    // Convert PDF → JPG (trang 1) với Cloudinary transform
    // https://res.cloudinary.com/xxx/image/upload/v123/folder/file.pdf
    // → https://res.cloudinary.com/xxx/image/upload/w_400,h_500,c_fill,f_jpg,pg_1/v123/folder/file.jpg
    return urlStr
        .replaceFirst('/upload/', '/upload/w_400,h_500,c_fill,f_jpg,pg_1/')
        .replaceAll('.pdf', '.jpg');
  }

  // --- LOGIC MỚI: Lấy URL theo quyền truy cập ---
  /// Lấy URL để hiển thị trang tài liệu
  /// - Nếu `isFullAccess = true`: dùng `url` chính (full document)
  /// - Nếu `isFullAccess = false`: chỉ trả previewUrl cho các trang được phép
  String getPageUrl(int pageNumber) {
    // ⚠️ Nếu chưa mua (isFullAccess = false), chỉ cho xem preview
    if (!isFullAccess) {
      // Tính số trang được xem trước
      final allowedPages = getSafePreviewPages();

      // Kiểm tra xem trang này có được phép xem không
      if (pageNumber <= allowedPages && previewUrl.isNotEmpty) {
        // Đối với trang 1, trả về previewUrl trực tiếp
        if (pageNumber == 1) {
          return previewUrl;
        }
        // Đối với các trang khác trong preview, cố gắng generate từ URL gốc
        // (nếu backend hỗ trợ preview nhiều trang)
        if (url != null && url!.isNotEmpty) {
          try {
            return url!
                .replaceFirst(
                    '/upload/', '/upload/w_1000,f_jpg,pg_$pageNumber/')
                .replaceAll('.pdf', '.jpg');
          } catch (e) {
            return '';
          }
        }
      }
      // Trang bị khóa - không log, chỉ return rỗng
      return '';
    }

    // ✅ Đã mua/miễn phí - Sử dụng URL chính
    final fullUrl = url ?? '';

    if (fullUrl.isEmpty) {
      return '';
    }

    // Kiểm tra URL có hợp lệ không
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      return '';
    }

    // Cloudinary transform: Convert PDF page to image
    // https://res.cloudinary.com/.../upload/... -> .../upload/w_1000,f_jpg,pg_N/...
    try {
      return fullUrl
          .replaceFirst('/upload/', '/upload/w_1000,f_jpg,pg_$pageNumber/')
          .replaceAll('.pdf', '.jpg');
    } catch (e) {
      return '';
    }
  }

  /// Lấy preview URL (thumbnail) - Luôn có thể truy cập
  String getPreviewUrl() => previewUrl;

  /// Kiểm tra có quyền truy cập full document không
  bool get hasFullAccess => isFullAccess;

  /// Kiểm tra có thể download không
  bool get canDownload => isFullAccess && url != null && url!.isNotEmpty;

  /// Tính toán số trang xem trước an toàn dựa trên tổng số trang
  /// Logic:
  /// - < 3 trang: Không cho xem trước (tránh lộ toàn bộ nội dung)
  /// - 3-5 trang: Cho xem 1 trang
  /// - 6-10 trang: Cho xem 2 trang
  /// - > 10 trang: Cho xem 3 trang (theo previewPages từ backend)
  int getSafePreviewPages() {
    if (isFullAccess) {
      return totalPages; // Đã mua → xem toàn bộ
    }

    if (totalPages < 3) {
      return 0; // Quá ít trang → không cho xem trước
    } else if (totalPages <= 5) {
      return 1; // 3-5 trang → xem 1 trang
    } else if (totalPages <= 10) {
      return 2; // 6-10 trang → xem 2 trang
    } else {
      // > 10 trang → dùng previewPages từ backend (thường là 3)
      // Nhưng đảm bảo không vượt quá totalPages
      return previewPages > totalPages ? totalPages : previewPages;
    }
  }

  /// Lấy thông điệp hiển thị cho preview
  String getPreviewMessage() {
    final safe = getSafePreviewPages();
    if (safe == 0) {
      return 'Tài liệu này có ${totalPages} trang. Mua để xem toàn bộ nội dung.';
    }
    final remaining = totalPages - safe;
    return 'Xem trước $safe/${totalPages} trang. Còn $remaining trang bị khóa.';
  }
}
