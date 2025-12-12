# Notification Widget Refactoring

## Thay đổi

### 1. Tạo Widget Riêng Biệt: `NotificationItem`
**File mới:** `lib/widgets/notification_item.dart`

Widget này được tách ra từ `NotificationScreen` để:
- **Tái sử dụng:** Có thể dùng ở nhiều nơi (không chỉ trong NotificationScreen)
- **Dễ bảo trì:** Logic hiển thị 1 thông báo được tập trung vào 1 file
- **Clean code:** NotificationScreen giờ đây chỉ quản lý list, không cần quan tâm cách render từng item

**Chức năng:**
- Hiển thị icon tương ứng với type (like, comment, follow, mention, system)
- Hiển thị title, message, thời gian
- Đổi màu nền khi chưa đọc (highlight)
- Hiển thị dấu chấm xanh khi chưa đọc
- Format thời gian thân thiện (vừa xong, 5 phút trước, 2 giờ trước...)

### 2. Fix Lỗi Username Khi Nhấn Follow Notification

**Vấn đề:**
```
I/flutter (16426): ⚠ Missing username in notification data
```

**Nguyên nhân:**
Backend có thể gửi username với nhiều tên field khác nhau:
- `username`
- `fromUsername`
- `senderUsername`
- `userId`

**Giải pháp:**
Kiểm tra tất cả các field có thể có:
```dart
String? username = data['username']?.toString() ??
    data['fromUsername']?.toString() ??
    data['senderUsername']?.toString() ??
    data['userId']?.toString();
```

**Debug logging:**
```dart
if (kDebugMode) {
  print('🔍 Searching for username in follow notification:');
  print('   - username: ${data['username']}');
  print('   - fromUsername: ${data['fromUsername']}');
  print('   - senderUsername: ${data['senderUsername']}');
  print('   - userId: ${data['userId']}');
  print('   - Result: $username');
}
```

**Error handling:**
- Nếu không tìm thấy username, hiển thị SnackBar thông báo lỗi
- Log chi tiết available keys để debug: `Available keys: ${data.keys.toList()}`

### 3. Cải Tiến NotificationScreen

**Loại bỏ:**
- `_buildNotificationItem()` method (đã chuyển vào NotificationItem widget)
- `_buildNotificationIcon()` method (đã chuyển vào NotificationItem widget)
- `_formatTime()` method (đã chuyển vào NotificationItem widget)
- `DateFormat _dateFormatter` field (không cần nữa)

**Kết quả:**
- NotificationScreen giảm từ 404 dòng xuống ~296 dòng
- Code sạch hơn, dễ đọc hơn
- Tập trung vào logic navigation và state management

## Cách Sử Dụng

### Sử dụng NotificationItem Widget

```dart
NotificationItem(
  notification: notificationModel,
  onTap: () {
    // Handle tap
    print('Tapped on notification: ${notificationModel.id}');
  },
)
```

### Test Follow Notification

Khi nhấn vào follow notification, app sẽ:
1. Log chi tiết data fields
2. Thử tìm username trong nhiều fields khác nhau
3. Nếu tìm thấy → Navigate đến profile
4. Nếu không tìm thấy → Hiển thị SnackBar lỗi

### Debug

Bật debug mode để xem log chi tiết:
```dart
if (kDebugMode) {
  print('📌 Notification tap: type=$type, data=$data');
}
```

## Backend Cần Làm Gì

Để tránh lỗi username, backend nên đảm bảo follow notification có structure:

```javascript
{
  type: 'follow',
  title: 'Người theo dõi mới',
  message: '@johndoe đã theo dõi bạn',
  data: {
    username: 'johndoe',  // ← Quan trọng!
    userId: '507f1f77bcf86cd799439011'
  }
}
```

**Lưu ý:**
- Field `username` là bắt buộc cho follow notification
- App hiện hỗ trợ fallback sang `fromUsername`, `senderUsername`, `userId` nếu `username` không có
- Nhưng tốt nhất backend nên luôn gửi `username` để đồng nhất

## Kiểm Tra

✅ Notification item hiển thị đúng
✅ Icon đúng theo type
✅ Thời gian format đẹp
✅ Màu nền đổi khi chưa đọc
✅ Dấu chấm xanh hiện khi chưa đọc
✅ Navigation từ like/comment → post detail
✅ Navigation từ follow → profile (với fallback username)
✅ Error handling khi thiếu username
✅ Debug logging chi tiết
