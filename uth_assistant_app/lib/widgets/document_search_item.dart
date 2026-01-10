import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class DocumentSearchItem extends StatelessWidget {
  final String title;
  final String description;
  final String fileType;
  final int price;
  final VoidCallback onTap;

  const DocumentSearchItem({
    super.key,
    required this.title,
    required this.description,
    required this.fileType,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File type badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileTypeColor(fileType),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  fileType.toUpperCase(),
                  style: AppTextStyles.fileTypeLabel.copyWith(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: AppTextStyles.documentTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Price badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: price > 0 ? AppColors.primary : AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: price > 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$price',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          AppAssets.iconCoin,
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            AppColors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Miễn phí',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return const Color(0xFFE74C3C);
      case 'DOCX':
      case 'DOC':
        return const Color(0xFF2980B9);
      case 'XLSX':
      case 'XLS':
        return const Color(0xFF27AE60);
      case 'PPTX':
      case 'PPT':
        return const Color(0xFFE67E22);
      case 'ZIP':
      case 'RAR':
        return const Color(0xFF8E44AD);
      default:
        return AppColors.primary;
    }
  }
}
