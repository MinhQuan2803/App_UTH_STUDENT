# Backend - Kiểm tra Data Field trong Notification

## Vấn đề hiện tại:
```
I/flutter: Data: {}  ❌ RỖNG!
I/flutter: Payload: {} ❌ RỖNG!
```

## Nguyên nhân có thể:

### 1. Gửi từ Firebase Console (Không có data)
Nếu bạn test bằng **Firebase Console → Send test message**, data sẽ rỗng vì Firebase Console chỉ gửi `notification` field, không gửi `data`.

**Giải pháp:** Test bằng backend API (Like/Comment/Follow)

---

### 2. Backend NotificationService có vấn đề

Kiểm tra file `backend/src/services/notificationService.js`:

```javascript
const message = {
  token: user.fcmToken,
  notification: {
    title: notification.title,
    body: notification.body,
  },
  data: {  // ⚠️ PHẢI CÓ PHẦN NÀY
    type: 'like',
    postId: postId.toString(),
    screen: 'post_detail'
  },
  // ...
};
```

**QUAN TRỌNG:** Tất cả values trong `data` phải là **String**!

❌ **SAI:**
```javascript
data: {
  type: 'like',
  postId: postId,  // ❌ ObjectId (object)
  userId: userId   // ❌ ObjectId (object)
}
```

✅ **ĐÚNG:**
```javascript
data: {
  type: 'like',
  postId: postId.toString(),  // ✅ String
  userId: userId.toString(),  // ✅ String
  screen: 'post_detail'       // ✅ String
}
```

---

### 3. Kiểm tra Backend Logs

Khi Like/Comment/Follow, kiểm tra backend console:

```javascript
✓ Notification sent: projects/uth-student-a6cd5/messages/0:xxx
```

Nếu có lỗi:
```javascript
✗ Error sending notification: Invalid argument: all values in data must be strings
```

→ Cần chuyển tất cả values sang String

---

## Cách Test Đúng:

### Bước 1: Đừng dùng Firebase Console
Firebase Console không gửi `data` field khi test.

### Bước 2: Test bằng Backend API

**Chuẩn bị:**
1. User A đăng nhập → FCM token được lưu
2. User A logout
3. User B đăng nhập

**Test Like:**
```bash
POST http://192.168.2.4:5000/api/posts/:postId/like
Authorization: Bearer <user_b_token>
```

**Kết quả mong đợi:**
```
=== FOREGROUND MESSAGE ===
Title: ❤️ Lượt thích mới
Body: user_b đã thích bài viết của bạn
Data: {type: like, postId: xxx, screen: post_detail} ✅
Data isEmpty: false ✅
Data keys: (type, postId, screen) ✅
```

---

## Fix Backend (Nếu cần)

### File: `backend/src/services/notificationService.js`

**Cập nhật hàm `sendToUser()`:**

```javascript
async sendToUser(userId, notification, data = {}) {
  // ... existing code

  // ✅ Đảm bảo TẤT CẢ values là String
  const stringData = {};
  Object.keys(data).forEach(key => {
    stringData[key] = String(data[key]); // Convert to string
  });

  const message = {
    token: user.fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: stringData, // ✅ Sử dụng data đã convert
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        sound: 'default'
      }
    },
    // ...
  };

  const response = await messaging.send(message);
  console.log('✓ Notification sent:', response);
  console.log('  Data sent:', stringData); // Debug
}
```

---

## Checklist Debug:

- [ ] Không dùng Firebase Console để test (chỉ dùng để test token)
- [ ] Test bằng Like/Comment/Follow từ app hoặc Postman
- [ ] Kiểm tra backend logs có "✓ Notification sent"
- [ ] Kiểm tra Flutter logs có `Data keys: (type, postId, screen)`
- [ ] Verify tất cả values trong data là String (không phải ObjectId)

---

## Expected Logs:

### Backend:
```
✓ Notification sent: projects/uth-student-a6cd5/messages/0:xxx
  Data sent: { type: 'like', postId: '123abc', screen: 'post_detail' }
```

### Flutter:
```
=== FOREGROUND MESSAGE ===
Title: ❤️ Lượt thích mới
Body: user123 đã thích bài viết của bạn
Data: {type: like, postId: 123abc, screen: post_detail}
Data isEmpty: false
Data keys: (type, postId, screen)
```

### Tap Notification:
```
=== NOTIFICATION TAPPED ===
Payload: {type: like, postId: 123abc, screen: post_detail}
=== NAVIGATE FROM NOTIFICATION ===
Data: {type: like, postId: 123abc, screen: post_detail}
Data isEmpty: false
Navigating: type=like, screen=post_detail
→ Navigate to PostDetailScreen with postId: 123abc
```
