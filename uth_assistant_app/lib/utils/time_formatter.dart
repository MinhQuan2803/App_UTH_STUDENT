String formatPostTime(DateTime postDate) {
  final now = DateTime.now();
  // postDate đã được convert sang local time từ models
  final difference = now.difference(postDate);

  // ✅ Xử lý thời gian trong tương lai (do sai lệch đồng hồ máy local)
  if (difference.isNegative) {
    final absDiff = difference.abs();
    // Sai lệch nhỏ < 60s → Hiển thị "Vừa xong"
    if (absDiff.inSeconds < 60) {
      return 'Vừa xong';
    }
    // Sai lệch lớn → Hiển thị ngày tháng đầy đủ
    return '${postDate.day.toString().padLeft(2, '0')}/${postDate.month.toString().padLeft(2, '0')}/${postDate.year} ${postDate.hour.toString().padLeft(2, '0')}:${postDate.minute.toString().padLeft(2, '0')}';
  }

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
