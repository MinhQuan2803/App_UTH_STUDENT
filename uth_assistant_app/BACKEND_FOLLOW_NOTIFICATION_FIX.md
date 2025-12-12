# Fix Backend Follow Notification - Thiếu Username

## Vấn Đề

```
I/flutter: data={screen: profile}
I/flutter: Available keys: [screen]
```

Backend đang gửi notification với `data` chỉ có `screen` mà thiếu `username` và `userId`.

## Nguyên Nhân

Ở file gọi `createNotification()` cho follow action (có thể là `userController.js` hoặc `followController.js`), code hiện tại:

```javascript
// ❌ SAI - Thiếu username trong data
await createNotification({
  userId: targetUserId,
  type: 'follow',
  actorId: req.user._id,
  actorUsername: req.user.username,
  data: {
    screen: 'profile'  // ← CHỈ CÓ screen, THIẾU username!
  }
});
```

## Giải Pháp

### Bước 1: Tìm File Follow Controller

Tìm file xử lý follow action (thường là một trong những file sau):
- `controllers/userController.js`
- `controllers/followController.js`
- `routes/userRoutes.js`

Tìm endpoint POST `/users/:userId/follow` hoặc hàm `followUser()`

### Bước 2: Fix Code

**TRƯỚC (SAI):**
```javascript
// File: userController.js hoặc followController.js
export const followUser = async (req, res) => {
  try {
    const { userId } = req.params;  // người được follow
    const currentUserId = req.user._id;  // người đang follow
    
    // ... logic follow ...
    
    // ❌ SAI - Thiếu thông tin
    await createNotification({
      userId: userId,
      type: 'follow',
      actorId: currentUserId,
      actorUsername: req.user.username,
      data: {
        screen: 'profile'  // ← CHỈ CÓ screen
      }
    });
    
    res.status(200).json({ message: 'Followed successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
```

**SAU (ĐÚNG):**
```javascript
// File: userController.js hoặc followController.js
export const followUser = async (req, res) => {
  try {
    const { userId } = req.params;  // người được follow
    const currentUserId = req.user._id;  // người đang follow
    
    // ... logic follow ...
    
    // ✅ ĐÚNG - Có đầy đủ thông tin
    await createNotification({
      userId: userId,
      type: 'follow',
      actorId: currentUserId,
      actorUsername: req.user.username,
      data: {
        screen: 'profile',
        username: req.user.username,  // ← THÊM username
        userId: currentUserId.toString()  // ← THÊM userId
      }
    });
    
    res.status(200).json({ message: 'Followed successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
```

### Bước 3: So Sánh Với Like/Comment

Kiểm tra code like notification (đang hoạt động tốt):

```javascript
// Like notification - ĐÚNG
await createNotification({
  userId: post.user,
  type: 'like',
  actorId: req.user._id,
  actorUsername: req.user.username,
  data: {
    screen: 'post',
    postId: post._id.toString(),  // ← Có postId
    userId: req.user._id.toString()  // ← Có userId
  }
});

// Comment notification - ĐÚNG
await createNotification({
  userId: post.user,
  type: 'comment',
  actorId: req.user._id,
  actorUsername: req.user.username,
  data: {
    screen: 'post',
    postId: post._id.toString(),  // ← Có postId
    commentId: comment._id.toString(),  // ← Có commentId
    userId: req.user._id.toString()  // ← Có userId
  }
});

// Follow notification - CẦN SỬA GIỐNG VẬY
await createNotification({
  userId: targetUserId,
  type: 'follow',
  actorId: req.user._id,
  actorUsername: req.user.username,
  data: {
    screen: 'profile',
    username: req.user.username,  // ← THÊM username
    userId: req.user._id.toString()  // ← THÊM userId
  }
});
```

## Data Structure Chuẩn

### Like Notification
```javascript
{
  type: 'like',
  data: {
    screen: 'post',
    postId: '507f1f77bcf86cd799439011',
    userId: '507f191e810c19729de860ea'
  }
}
```

### Comment Notification
```javascript
{
  type: 'comment',
  data: {
    screen: 'post',
    postId: '507f1f77bcf86cd799439011',
    commentId: '507f191e810c19729de860eb',
    userId: '507f191e810c19729de860ea'
  }
}
```

### Follow Notification (CẦN FIX)
```javascript
{
  type: 'follow',
  data: {
    screen: 'profile',
    username: 'johndoe',  // ← THÊM field này
    userId: '507f191e810c19729de860ea'  // ← THÊM field này
  }
}
```

## Debug Backend

Thêm log để kiểm tra data đang gửi:

```javascript
const notificationData = {
  userId: userId,
  type: 'follow',
  actorId: currentUserId,
  actorUsername: req.user.username,
  data: {
    screen: 'profile',
    username: req.user.username,
    userId: currentUserId.toString()
  }
};

console.log('📤 Creating follow notification:');
console.log('   To user:', userId);
console.log('   From user:', req.user.username);
console.log('   Data:', JSON.stringify(notificationData.data, null, 2));

await createNotification(notificationData);
```

## Kiểm Tra Sau Khi Fix

1. **Backend log** khi follow user:
```
📤 Creating follow notification:
   To user: 507f1f77bcf86cd799439011
   From user: johndoe
   Data: {
     "screen": "profile",
     "username": "johndoe",
     "userId": "507f191e810c19729de860ea"
   }
✓ Notification created: 67891abc2def3456789012cd
✓ FCM sent successfully: projects/...
```

2. **App log** khi nhấn notification:
```
📌 Notification tap: type=follow, data={screen: profile, username: johndoe, userId: 507f191e810c19729de860ea}
🔍 Searching for username in follow notification:
   - username: johndoe
   - fromUsername: null
   - senderUsername: null
   - userId: 507f191e810c19729de860ea
   - Result: johndoe
✓ Navigating to profile: johndoe
```

## Tóm Tắt

**File cần sửa:** `userController.js` hoặc `followController.js`

**Hàm cần sửa:** `followUser()` hoặc endpoint POST follow

**Sửa gì:**
```javascript
data: {
  screen: 'profile',
  username: req.user.username,  // ← THÊM dòng này
  userId: currentUserId.toString()  // ← THÊM dòng này
}
```

**Test:**
1. Follow một user
2. Kiểm tra backend log có in ra username/userId không
3. Nhấn vào notification trên app
4. Kiểm tra app log có tìm thấy username không
5. App phải navigate đến profile thành công
