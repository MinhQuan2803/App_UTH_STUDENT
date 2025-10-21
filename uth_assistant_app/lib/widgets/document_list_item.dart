import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class DocumentListItem extends StatelessWidget {
  final String fileType;
  final String title;
  final String uploader;

  const DocumentListItem({
    super.key,
    required this.fileType,
    required this.title,
    required this.uploader,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy màu sắc dựa trên loại file
    final Map<String, Color> colors = _getColorsForFileType(fileType);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors['background'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                fileType,
                style: AppTextStyles.fileTypeLabel.copyWith(color: colors['text']),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.documentTitle),
                const SizedBox(height: 4),
                Text(uploader, style: AppTextStyles.documentUploader),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: SvgPicture.asset(AppAssets.iconDownload),
            onPressed: () {
              // TODO: Logic tải tài liệu
            },
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColorsForFileType(String type) {
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
