import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../models/document_model.dart';
import '../../config/app_theme.dart';

class DocumentReaderScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentReaderScreen({super.key, required this.document});

  @override
  State<DocumentReaderScreen> createState() => _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends State<DocumentReaderScreen> {
  @override
  void initState() {
    super.initState();
    _enableSecureMode();
  }

  @override
  void dispose() {
    _disableSecureMode();
    super.dispose();
  }

  Future<void> _enableSecureMode() async {
    try {
      // API của bản 1.4.7 vẫn hỗ trợ các hàm này
      // 1. protectDataLeakageOn:
      // - Android: Bật FLAG_SECURE (Màn hình đen khi chụp/quay)
      // - iOS: Che mờ khi vào đa nhiệm
      await ScreenProtector.protectDataLeakageOn();

      // 2. preventScreenshotOn:
      // - iOS: Hiển thị màn hình đen khi quay phim/chụp ảnh
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint("Lỗi bật bảo mật: $e");
    }
  }

  Future<void> _disableSecureMode() async {
    try {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.preventScreenshotOff();
    } catch (e) {
      debugPrint("Lỗi tắt bảo mật: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Nền đen để tiệp màu nếu bị chụp màn hình đen
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.document.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(
                  '${widget.document.totalPages} trang',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.lock, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                const Text(
                  'DRM Protected',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Chế độ bảo mật cao',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang bật chế độ chống sao chép nội dung.'),
                  backgroundColor: AppColors.primary,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          )
        ],
      ),
      body: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 40),
          // Hiển thị số trang phù hợp với quyền truy cập
          itemCount: widget.document.isFullAccess
              ? widget.document.totalPages
              : widget.document.getSafePreviewPages(),
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.grey, height: 4),
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final imageUrl = widget.document.getPageUrl(pageNumber);

            // ⚠️ Xử lý khi không có quyền truy cập (URL rỗng)
            if (imageUrl.isEmpty) {
              // Kiểm tra xem có phải do chưa mua không
              if (!widget.document.isFullAccess) {
                return Container(
                  height: 400,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline,
                            color: AppColors.primary, size: 64),
                        const SizedBox(height: 16),
                        const Text('Trang này bị khóa',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            'Mua tài liệu để xem toàn bộ ${widget.document.totalPages} trang',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Mở màn hình mua tài liệu
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: Text('Mua với ${widget.document.price} điểm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // URL rỗng do lỗi khác
              return Container(
                height: 400,
                color: Colors.grey[900],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      SizedBox(height: 12),
                      Text('Không thể tải trang này',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Vui lòng thử lại sau',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            return CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Container(
                height: 400,
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[900],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 40),
                      SizedBox(height: 8),
                      Text('Không thể tải trang này',
                          style: TextStyle(color: Colors.white54))
                    ],
                  ),
                ),
              ),
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}
