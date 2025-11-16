# Test Push Notification Script

## Cách 1: Sử dụng Firebase Console (KHUYẾN NGHỊ)

### Bước 1: Lấy FCM Token
1. Mở app và login
2. Xem terminal logs, tìm dòng:
   ```
   ✓ FCM Token: eTnUE09wRpOg9tWvKq4Jc3:APA91b...
   ```
3. Copy toàn bộ token này

### Bước 2: Gửi Test Notification
1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project: **uth-student-a6cd5**
3. Engage → **Cloud Messaging**
4. Click **Send your first message**
5. Điền thông tin:
   - **Notification title:** ❤️ Test Like
   - **Notification text:** Someone liked your post!
6. Click **Send test message**
7. Paste FCM token → Click **Test**

### Kết quả:
- ✅ App nhận notification ngay lập tức
- ✅ Test được foreground/background/terminated
- ✅ Không cần 2 thiết bị

---

## Cách 2: Test với 2 Tài Khoản (1 Thiết bị)

### Setup:
1. Tạo 2 tài khoản: `user1@test.com` và `user2@test.com`
2. Login User 1 → FCM token được lưu vào database
3. **QUAN TRỌNG:** Logout User 1 (nhưng FCM token vẫn còn trong DB)
4. Login User 2 trên cùng thiết bị

### Test Flow:
1. **User 2** (đang login trên app) like post của User 1
2. **Backend** gửi notification cho User 1 (dùng token đã lưu)
3. **Thiết bị** nhận notification (mặc dù đang login User 2)
4. **Tap notification** → Navigate đến post detail

**Lưu ý:** Notification sẽ hiện trên cùng thiết bị vì FCM token vẫn còn trong DB

---

## Cách 3: Dùng Postman Test Backend

### Endpoint: Gửi notification thủ công

**Tạo test endpoint trong backend:**

```javascript
// routes/testRoutes.js
import express from 'express';
import notificationService from '../services/notificationService.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// POST /api/test/send-notification
router.post('/send-notification', authenticateToken, async (req, res) => {
  const { userId, type, message } = req.body;
  
  try {
    let result;
    
    if (type === 'like') {
      result = await notificationService.sendLikeNotification(
        userId,
        req.user.username,
        'test-post-id'
      );
    } else if (type === 'comment') {
      result = await notificationService.sendCommentNotification(
        userId,
        req.user.username,
        'test-post-id',
        message || 'Test comment'
      );
    } else if (type === 'follow') {
      result = await notificationService.sendFollowNotification(
        userId,
        req.user.username,
        req.user._id
      );
    }
    
    res.json({ 
      success: true, 
      message: 'Test notification sent',
      result 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
```

### Gọi API từ Postman:

```bash
POST http://192.168.2.4:5000/api/test/send-notification
Authorization: Bearer <your-jwt-token>
Content-Type: application/json

Body:
{
  "userId": "673581f49e1b0002ea64dd71",  // User ID nhận notification
  "type": "like",                          // like | comment | follow
  "message": "Test notification!"
}
```

---

## Cách 4: Test Navigation từ Notification

### Khi nhận notification:

**Foreground (App đang mở):**
```
=== FOREGROUND MESSAGE ===
Title: ❤️ Lượt thích mới
→ Local notification hiện lên
→ Tap → _onNotificationTapped() → Navigate
```

**Background (App ở background):**
```
→ Notification hiện ở status bar
→ Tap → _handleMessageOpenedApp() → Navigate
```

**Terminated (App đã tắt):**
```
→ Notification hiện ở status bar
→ Tap → App khởi động → getInitialMessage() → Navigate
```

---

## Debug Logs Cần Kiểm Tra

### Flutter App:
```dart
✓ FCM Token: xxx
=== FOREGROUND MESSAGE ===
=== NOTIFICATION TAPPED ===
Navigating: type=like, screen=post_detail
→ Navigate to PostDetailScreen with postId: xxx
```

### Backend:
```javascript
✓ FCM token saved successfully
✓ Notification sent: projects/uth-student-a6cd5/messages/xxx
```

---

## Checklist Test

- [ ] Login → Xem FCM token trong logs
- [ ] Gửi test notification từ Firebase Console
- [ ] App nhận notification (foreground)
- [ ] Tap notification → Xem logs navigation
- [ ] Đưa app ra background → Gửi lại → Tap notification
- [ ] Tắt app hoàn toàn → Gửi lại → Tap notification
- [ ] Test với 2 tài khoản: User A login → Logout → User B login → User B like post User A
- [ ] Kiểm tra backend logs xem có "✓ Notification sent"

---

## Troubleshooting

### Không nhận được notification?
1. Kiểm tra FCM token đã lưu vào database chưa
2. Kiểm tra backend có Firebase service account key chưa
3. Xem logs backend có lỗi gì không
4. Thử gửi từ Firebase Console trước

### Nhận được nhưng không navigate?
1. Kiểm tra navigatorKey đã được set trong MaterialApp chưa
2. Xem logs có "=== NOTIFICATION TAPPED ===" không
3. Kiểm tra route đã định nghĩa trong MaterialApp chưa

### Backend không gửi notification?
1. Kiểm tra `firebase-service-account.json` có đúng không
2. Xem console logs: "Firebase messaging not available"
3. Kiểm tra user có `fcmToken` trong database không
