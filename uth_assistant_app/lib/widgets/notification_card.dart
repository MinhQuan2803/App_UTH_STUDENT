import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final String imageUrl;
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
      width: 250,
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
            // SỬA LỖI: Thêm errorBuilder để xử lý lỗi tải ảnh
            child: Image.network(
              imageUrl,
              height: 90, // Giảm chiều cao
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 90,
                  color: AppColors.divider,
                  child: const Icon(Icons.image_not_supported, color: AppColors.hintText),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.00), // Giảm padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.notificationTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Giảm khoảng cách
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

