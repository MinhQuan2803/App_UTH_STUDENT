import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final String imageUrl; // Đây sẽ là đường dẫn asset (vd: 'assets/...')
  final String title;
  final String date;

  const NotificationCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            
            // --- THAY ĐỔI QUAN TRỌNG TẠI ĐÂY ---
            // Đổi từ Image.network thành Image.asset
            child: Image.asset( 
              imageUrl, // Bây giờ nó đọc từ thư mục assets
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Xử lý nếu đường dẫn asset bị sai
                return Container(
                  height: 90,
                  color: AppColors.divider,
                  child: const Icon(Icons.broken_image, color: AppColors.hintText),
                );
              },
            ),
            // ------------------------------------
          ),
          Padding(
            padding: const EdgeInsets.all(6.00),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.notificationTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTextStyles.notificationDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}