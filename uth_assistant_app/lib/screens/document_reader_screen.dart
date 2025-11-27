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
      backgroundColor: Colors.black, // Nền đen để tiệp màu nếu bị chụp màn hình đen
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
            ),
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
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
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
          itemCount: widget.document.totalPages,
          separatorBuilder: (context, index) => const Divider(color: Colors.grey, height: 4),
          itemBuilder: (context, index) {
            final imageUrl = widget.document.getPageUrl(index + 1);
            
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
                      Text('Không thể tải trang này', style: TextStyle(color: Colors.white54))
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