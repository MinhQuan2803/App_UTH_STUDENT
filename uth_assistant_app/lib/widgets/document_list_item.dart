import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class DocumentListItem extends StatelessWidget {
  final String fileType;
  final String title;
  final String uploader;
  final int price;

  const DocumentListItem({
    super.key,
    required this.fileType,
    required this.title,
    required this.uploader,
    this.price = 0,
  });

  @override
  Widget build(BuildContext context) {
    // --- CẬP NHẬT LOGIC MÀU SẮC ---
    final bool isPaid = price > 0;
    
    // Quyết định màu sắc dựa trên việc có trả phí hay không
    final Color cardColor = isPaid ? AppColors.primary : AppColors.white;
    final Color mainTextColor = isPaid ? AppColors.white : AppColors.text;
    final Color subTextColor = isPaid ? AppColors.white.withOpacity(0.9) : AppColors.subtitle;
    
    final Map<String, Color> fileTypeColors = _getColorsForFileType(fileType, isPaid);
    // --- KẾT THÚC CẬP NHẬT ---

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor, // Sử dụng màu thẻ
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fileTypeColors['background'], // Màu nền loại file
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                fileType,
                style: AppTextStyles.fileTypeLabel.copyWith(color: fileTypeColors['text']), // Màu chữ loại file
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: AppTextStyles.documentTitle.copyWith(color: mainTextColor), // Dùng màu chữ chính
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                Text(
                  uploader, 
                  style: AppTextStyles.documentUploader.copyWith(color: subTextColor) // Dùng màu chữ phụ
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildPriceTag(price, isPaid), // Truyền isPaid vào
        ],
      ),
    );
  }
  
  // CẬP NHẬT: Thẻ giá giờ cũng đổi màu
  Widget _buildPriceTag(int price, bool isPaid) {
    if (!isPaid) {
      // Miễn phí: Nền xanh nhạt, chữ Primary
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1), // Nền xanh nhạt
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Miễn phí',
          style: AppTextStyles.priceTag, // Chữ màu Primary
        ),
      );
    }
    
    // Có phí: Nền trắng, chữ Primary
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white, // Nền trắng
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.iconCoin, 
            width: 14, 
            height: 14,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn) // Icon màu Primary
          ),
          const SizedBox(width: 4),
          Text(
            '$price',
            style: AppTextStyles.priceTag.copyWith(color: AppColors.primary), // Chữ màu Primary
          ),
        ],
      ),
    );
  }

  // CẬP NHẬT: Logic màu cho loại file
  Map<String, Color> _getColorsForFileType(String type, bool isPaid) {
    if (isPaid) {
      // Nếu thẻ có phí (nền xanh), icon file sẽ có nền trắng mờ và chữ trắng
      return {
        'background': AppColors.white.withOpacity(0.2), 
        'text': AppColors.white
      };
    }
    
    // Nếu thẻ miễn phí, dùng logic màu cũ
    switch (type.toUpperCase()) {
      case 'PDF':
        return {'background': AppColors.pdfBackground, 'text': AppColors.pdfText};
      case 'DOCX':
        return {'background': AppColors.docxBackground, 'text': AppColors.docxText};
      case 'XLSX':
        return {'background': AppColors.xlsxBackground, 'text': AppColors.xlsxText};
      default:
        return {'background': AppColors.secondary, 'text': AppColors.primary};
    }
  }
}

