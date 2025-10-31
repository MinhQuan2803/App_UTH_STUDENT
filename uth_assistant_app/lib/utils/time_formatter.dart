String formatPostTime(DateTime postDate) {
  final now = DateTime.now();
  final difference = now.difference(postDate);

  if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else {
      // Format: dd/MM/yyyy
      return '${postDate.day.toString().padLeft(2, '0')}/${postDate.month.toString().padLeft(2, '0')}/${postDate.year}';
    }
}
