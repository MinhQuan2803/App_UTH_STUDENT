# Backend: Populate Avatar Trong Notification

## Vấn Đề

Widget notification đã được cập nhật để hiển thị avatar user, nhưng backend cần populate thông tin avatar vào `relatedUsers`.

## Backend Cần Fix

### File: `notificationController.js`

Trong hàm `getNotifications()`, cần populate `relatedUsers.userId` để lấy thông tin avatar:

**TRƯỚC (không có avatar):**
```javascript
export const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, isRead } = req.query;
    
    const query = { user: req.user._id };
    if (isRead !== undefined) query.isRead = isRead === 'true';

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
      
    // ❌ relatedUsers không có avatar
    
    res.status(200).json({
      notifications,
      pagination: { ... }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
```

**SAU (có avatar):**
```javascript
export const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, isRead } = req.query;
    
    const query = { user: req.user._id };
    if (isRead !== undefined) query.isRead = isRead === 'true';

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      // ✅ THÊM populate để lấy avatar
      .populate({
        path: 'relatedUsers.userId',
        select: 'username avatar' // Chỉ lấy username và avatar
      });
      
    res.status(200).json({
      notifications,
      pagination: { ... }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
```

### Giải Thích

**Populate làm gì:**
- Chuyển `relatedUsers.userId` từ String ID → Object User
- Object User có fields: `_id`, `username`, `avatar`

**Dữ liệu trước populate:**
```json
{
  "relatedUsers": [
    {
      "userId": "507f1f77bcf86cd799439011",
      "username": "johndoe",
      "timestamp": "2024-01-01T10:00:00.000Z"
    }
  ]
}
```

**Dữ liệu sau populate:**
```json
{
  "relatedUsers": [
    {
      "userId": {
        "_id": "507f1f77bcf86cd799439011",
        "username": "johndoe",
        "avatar": "https://example.com/avatars/johndoe.jpg"
      },
      "username": "johndoe",
      "timestamp": "2024-01-01T10:00:00.000Z"
    }
  ]
}
```

## App Frontend (Đã Fix)

`notification_item.dart` đã được cập nhật để:
1. ✅ Kiểm tra `user.avatar` có tồn tại không
2. ✅ Load ảnh từ network nếu có URL
3. ✅ Hiển thị placeholder (chữ cái đầu) nếu:
   - Không có avatar
   - Load ảnh lỗi
   - Đang loading
4. ✅ Xử lý cả 2 trường hợp:
   - `userId` là String
   - `userId` là Object (sau populate)

## Test

### 1. Kiểm Tra Backend Response

Gọi API `GET /api/users/notifications`:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:5000/api/users/notifications
```

**Response cần có:**
```json
{
  "notifications": [
    {
      "_id": "...",
      "type": "like",
      "message": "johndoe đã thích bài viết của bạn",
      "relatedUsers": [
        {
          "userId": {
            "_id": "507f1f77bcf86cd799439011",
            "username": "johndoe",
            "avatar": "https://storage.googleapis.com/..." // ← Cần có field này
          },
          "username": "johndoe",
          "timestamp": "2024-01-01T10:00:00.000Z"
        }
      ]
    }
  ]
}
```

### 2. Kiểm Tra App

1. Mở app và vào màn hình Thông báo
2. Debug log sẽ in ra:
```dart
print('Avatar URL: ${user.avatar}');
```

3. **Nếu có avatar URL:**
   - App sẽ load ảnh từ network
   - Hiển thị CircleAvatar với ảnh user

4. **Nếu không có avatar URL:**
   - App sẽ hiển thị chữ cái đầu trong vòng tròn xám

## Lưu Ý

### Avatar URL Format

Backend nên trả về **full URL** hoặc **relative path**:

```javascript
// ✅ ĐÚNG - Full URL
avatar: "https://storage.googleapis.com/uth-student/avatars/johndoe.jpg"

// ✅ ĐÚNG - Relative path (app sẽ tự thêm base URL)
avatar: "/uploads/avatars/johndoe.jpg"

// ❌ SAI - Null hoặc empty
avatar: null
avatar: ""
```

### Performance

Nếu notification list có nhiều user khác nhau, populate có thể chậm. Giải pháp:
1. **Cache avatar URL** trong relatedUsers (đã có trong schema)
2. **Lean query** để tăng tốc:
```javascript
const notifications = await Notification.find(query)
  .sort({ createdAt: -1 })
  .limit(limit * 1)
  .skip((page - 1) * limit)
  .populate({
    path: 'relatedUsers.userId',
    select: 'username avatar'
  })
  .lean(); // ← Thêm lean() để tăng tốc
```

## Checklist

- [ ] Mở `notificationController.js`
- [ ] Tìm hàm `getNotifications()`
- [ ] Thêm `.populate({ path: 'relatedUsers.userId', select: 'username avatar' })`
- [ ] Test API trả về có field `avatar` không
- [ ] Chạy app, vào màn Thông báo
- [ ] Kiểm tra avatar hiển thị đúng
- [ ] Kiểm tra placeholder hiện nếu không có avatar
