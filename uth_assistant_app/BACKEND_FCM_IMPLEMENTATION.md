# Backend Implementation Guide - Firebase Cloud Messaging

## 1. Cài đặt Firebase Admin SDK

```bash
npm install firebase-admin
```

## 2. Khởi tạo Firebase Admin

**File: `config/firebase.js`**
```javascript
const admin = require('firebase-admin');

// Download service account key từ Firebase Console:
// Project Settings → Service Accounts → Generate New Private Key
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const messaging = admin.messaging();

module.exports = { admin, messaging };
```

## 3. Update User Model

**File: `models/User.js`**
```javascript
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // ... existing fields (username, email, password, etc.)
  
  // FCM Token (single device)
  fcmToken: {
    type: String,
    default: null
  },
  
  // Hoặc hỗ trợ nhiều thiết bị:
  fcmTokens: [{
    token: { type: String, required: true },
    deviceInfo: String,
    lastUpdated: { type: Date, default: Date.now }
  }],
  
  // Notification preferences
  notificationSettings: {
    likes: { type: Boolean, default: true },
    comments: { type: Boolean, default: true },
    follows: { type: Boolean, default: true },
    mentions: { type: Boolean, default: true }
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
```

## 4. API Route - Lưu FCM Token

**File: `routes/userRoutes.js`**
```javascript
const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const User = require('../models/User');

// PATCH /api/users/me/fcm-token
router.patch('/me/fcm-token', authenticateToken, async (req, res) => {
  try {
    const { fcmToken, deviceInfo } = req.body;
    
    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    const userId = req.user._id; // Từ middleware authenticateToken

    // Option 1: Lưu 1 token (ghi đè)
    await User.findByIdAndUpdate(userId, { 
      fcmToken: fcmToken 
    });

    // Option 2: Lưu nhiều tokens (multi-device)
    // await User.findByIdAndUpdate(userId, {
    //   $addToSet: {
    //     fcmTokens: {
    //       token: fcmToken,
    //       deviceInfo: deviceInfo || 'Unknown',
    //       lastUpdated: new Date()
    //     }
    //   }
    // });

    res.json({ 
      success: true,
      message: 'FCM token saved successfully' 
    });
  } catch (error) {
    console.error('Error saving FCM token:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
```

## 5. Service - Gửi Push Notification

**File: `services/notificationService.js`**
```javascript
const { messaging } = require('../config/firebase');
const User = require('../models/User');

class NotificationService {
  
  /**
   * Gửi notification cho 1 user
   */
  async sendToUser(userId, notification, data = {}) {
    try {
      const user = await User.findById(userId);
      
      if (!user || !user.fcmToken) {
        console.log(`User ${userId} has no FCM token`);
        return null;
      }

      const message = {
        token: user.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl || undefined
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await messaging.send(message);
      console.log('✓ Notification sent:', response);
      return response;
      
    } catch (error) {
      console.error('Error sending notification:', error);
      
      // Nếu token không hợp lệ, xóa khỏi database
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        await User.findByIdAndUpdate(userId, { fcmToken: null });
      }
      
      throw error;
    }
  }

  /**
   * Gửi notification khi có like
   */
  async sendLikeNotification(postOwnerId, likerUsername, postId) {
    return this.sendToUser(postOwnerId, {
      title: '❤️ Lượt thích mới',
      body: `${likerUsername} đã thích bài viết của bạn`
    }, {
      type: 'like',
      postId: postId.toString(),
      screen: 'post_detail'
    });
  }

  /**
   * Gửi notification khi có comment
   */
  async sendCommentNotification(postOwnerId, commenterUsername, postId, commentText) {
    const truncatedComment = commentText.length > 50 
      ? commentText.substring(0, 50) + '...' 
      : commentText;
      
    return this.sendToUser(postOwnerId, {
      title: '💬 Bình luận mới',
      body: `${commenterUsername}: ${truncatedComment}`
    }, {
      type: 'comment',
      postId: postId.toString(),
      screen: 'post_detail'
    });
  }

  /**
   * Gửi notification khi có follow
   */
  async sendFollowNotification(followedUserId, followerUsername, followerId) {
    return this.sendToUser(followedUserId, {
      title: '👤 Người theo dõi mới',
      body: `${followerUsername} đã bắt đầu theo dõi bạn`
    }, {
      type: 'follow',
      userId: followerId.toString(),
      screen: 'profile'
    });
  }

  /**
   * Gửi notification khi được mention
   */
  async sendMentionNotification(mentionedUserId, mentionerUsername, postId, content) {
    return this.sendToUser(mentionedUserId, {
      title: '📢 Bạn được nhắc đến',
      body: `${mentionerUsername} đã nhắc đến bạn trong một bài viết`
    }, {
      type: 'mention',
      postId: postId.toString(),
      screen: 'post_detail'
    });
  }

  /**
   * Gửi notification cho nhiều users (broadcast)
   */
  async sendToMultipleUsers(userIds, notification, data = {}) {
    const promises = userIds.map(userId => 
      this.sendToUser(userId, notification, data)
    );
    return Promise.allSettled(promises);
  }

  /**
   * Gửi notification theo topic
   */
  async sendToTopic(topic, notification, data = {}) {
    const message = {
      topic: topic,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: data
    };

    return messaging.send(message);
  }
}

module.exports = new NotificationService();
```

## 6. Tích hợp vào các Controller

### Post Controller - Like Notification

**File: `controllers/postController.js`**
```javascript
const notificationService = require('../services/notificationService');

// Khi user like một post
exports.likePost = async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(postId);
    
    // ... logic like post

    // Gửi notification cho chủ bài viết (nếu không phải tự like)
    if (post.author.toString() !== userId.toString()) {
      await notificationService.sendLikeNotification(
        post.author,
        req.user.username,
        postId
      );
    }

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};
```

### Comment Controller

**File: `controllers/commentController.js`**
```javascript
const notificationService = require('../services/notificationService');

exports.createComment = async (req, res) => {
  try {
    const { postId } = req.params;
    const { content } = req.body;
    const userId = req.user._id;

    const post = await Post.findById(postId);
    
    // ... logic create comment

    // Gửi notification
    if (post.author.toString() !== userId.toString()) {
      await notificationService.sendCommentNotification(
        post.author,
        req.user.username,
        postId,
        content
      );
    }

    res.json({ success: true, comment });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};
```

### Follow Controller

**File: `controllers/followController.js`**
```javascript
const notificationService = require('../services/notificationService');

exports.followUser = async (req, res) => {
  try {
    const { userId } = req.params; // User được follow
    const followerId = req.user._id;

    // ... logic follow

    // Gửi notification
    await notificationService.sendFollowNotification(
      userId,
      req.user.username,
      followerId
    );

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};
```

## 7. Xử lý Notification trong Flutter App

**File: `lib/services/fcm_service.dart`** (Cập nhật phần TODO)

```dart
/// Xử lý khi app được mở từ notification
static void _handleMessageOpenedApp(RemoteMessage message) {
  if (kDebugMode) {
    print('=== APP OPENED FROM NOTIFICATION ===');
    print('Data: ${message.data}');
  }

  // Navigate dựa trên type
  final type = message.data['type'];
  final screen = message.data['screen'];

  if (type == 'like' || type == 'comment' || type == 'mention') {
    final postId = message.data['postId'];
    // Navigator đến PostDetailScreen
    // navigatorKey.currentState?.pushNamed('/post-detail', arguments: postId);
  } else if (type == 'follow') {
    final userId = message.data['userId'];
    // Navigator đến ProfileScreen
    // navigatorKey.currentState?.pushNamed('/profile', arguments: userId);
  }
}
```

## 8. Environment Variables (.env)

```bash
# Firebase
FIREBASE_PROJECT_ID=uth-student-a6cd5
FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
```

## 9. Lấy Service Account Key từ Firebase

1. Vào Firebase Console
2. Project Settings → Service Accounts
3. Click "Generate New Private Key"
4. Lưu file JSON vào `config/firebase-service-account.json`
5. **QUAN TRỌNG:** Thêm file này vào `.gitignore`

## 10. Testing

**Test gửi notification bằng Postman:**

```bash
POST http://localhost:5000/api/posts/:postId/like
Authorization: Bearer <your-jwt-token>
```

Kiểm tra console log:
- ✓ FCM token saved successfully
- ✓ Notification sent: projects/.../messages/...

---

## Checklist Implementation

- [ ] Cài firebase-admin
- [ ] Tạo firebase.js config
- [ ] Download service account key
- [ ] Update User model (fcmToken field)
- [ ] Tạo API route PATCH /me/fcm-token
- [ ] Tạo NotificationService
- [ ] Tích hợp vào Like controller
- [ ] Tích hợp vào Comment controller
- [ ] Tích hợp vào Follow controller
- [ ] Test với thiết bị thật
- [ ] Xử lý navigation trong Flutter app
