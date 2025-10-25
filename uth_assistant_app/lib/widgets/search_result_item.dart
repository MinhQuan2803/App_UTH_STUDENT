import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class SearchResultItem extends StatelessWidget {
  // Thay đổi: Nhận dynamic để xử lý cả IconData và String (SVG path)
  final dynamic iconData; 
  final String type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.iconData,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                // Kiểm tra loại icon để hiển thị đúng cách
                child: (iconData is IconData)
                    ? Icon(iconData as IconData, color: AppColors.primary, size: 20)
                    : (iconData is String && iconData.endsWith('.svg')) 
                      ? SvgPicture.asset(
                          iconData as String, 
                          width: 20,
                          colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                        )
                      : const Icon(Icons.help_outline, color: AppColors.primary, size: 20), // Icon mặc định nếu không khớp
              ),
            ),
            const SizedBox(width: 12),
            // Nội dung text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: AppTextStyles.postMeta.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTextStyles.postName.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.postMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.subtitle),
          ],
        ),
      ),
    );
  }
}
