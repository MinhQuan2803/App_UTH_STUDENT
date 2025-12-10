# 🔍 FCM DEBUG GUIDE - Flutter

## Vấn đề: FCM không gửi khi follow/comment/like

### ✅ CHECKLIST KIỂM TRA (5 phút)

#### 1️⃣ **FCM Token có được tạo không?**
Thêm vào `main.dart` sau khi khởi tạo FCM:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // DEBUG: In FCM token
  final token = await FirebaseMessaging.instance.getToken();
  print('🔑 FCM TOKEN: $token');
  
  if (token == null) {
    print('❌ FCM TOKEN NULL - Kiểm tra Firebase setup!');
  } else {
    print('✅ FCM Token OK (${token.length} chars)');
  }
  
  await FCMService.initialize();
  runApp(const MyApp());
}
```

#### 2️⃣ **Token có được gửi lên backend không?**
Kiểm tra `login_screen.dart`:
```dart
if (success) {
  final fcmToken = await FCMService.getToken();
  print('📤 Sending FCM token to backend: ${fcmToken?.substring(0, 20)}...');
  
  if (fcmToken != null) {
    final result = await _authService.saveFcmToken(fcmToken);
    print(result ? '✅ Token saved to backend' : '❌ Failed to save token');
  }
}
```

#### 3️⃣ **Permission đã được cấp chưa?**
Thêm vào `FCMService.initialize()`:
```dart
NotificationSettings settings = await _firebaseMessaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

print('🔔 Permission status: ${settings.authorizationStatus}');

if (settings.authorizationStatus == AuthorizationStatus.denied) {
  print('❌ USER DENIED NOTIFICATION PERMISSION!');
  // Hiển thị dialog yêu cầu user bật permission trong Settings
}
```

#### 4️⃣ **Foreground listener có hoạt động không?**
Thêm log chi tiết vào `_handleForegroundMessage`:
```dart
static void _handleForegroundMessage(RemoteMessage message) {
  print('🔔 FOREGROUND MESSAGE RECEIVED');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  print('   Type: ${message.data['type']}');
  
  _showLocalNotification(message);
  print('✅ Local notification shown');
}
```

#### 5️⃣ **Background handler đã được đăng ký chưa?**
Kiểm tra `main.dart`:
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 BACKGROUND MESSAGE: ${message.notification?.title}');
}

void main() async {
  // QUAN TRỌNG: Đăng ký background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // ... rest of code
}
```

---

## 🧪 TEST NHANH

### Test 1: Gửi test notification từ Firebase Console
1. Vào Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Nhập title/body → Click "Send test message"
4. Paste FCM token → Send
5. **Kết quả mong đợi:** Nhận được notification trong 5s

### Test 2: Kiểm tra backend có gửi FCM không
```bash
# Trong backend log, tìm dòng:
✓ Notification created: [ID]
✓ FCM sent successfully: [MESSAGE_ID]

# Nếu thấy:
⚠ Firebase messaging not initialized, skip FCM push
→ Backend thiếu firebase-service-account.json
```

### Test 3: Kiểm tra token trong MongoDB
```javascript
// Trong MongoDB, kiểm tra user collection:
db.users.findOne({ _id: ObjectId("YOUR_USER_ID") }, { fcmToken: 1 })

// Phải trả về:
{ fcmToken: "e1a2b3c4d5..." }

// Nếu null/undefined → Token không được lưu
```

---

## 🐛 CÁC LỖI THƯỜNG GẶP

### ❌ Lỗi 1: "Permission denied"
**Nguyên nhân:** User từ chối permission
**Giải pháp:**
```dart
// Hiển thị dialog giải thích tại sao cần permission
await showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Bật thông báo'),
    content: Text('Để nhận thông báo khi có like/comment/follow, vui lòng bật quyền thông báo trong Cài đặt'),
    actions: [
      TextButton(
        onPressed: () => openAppSettings(),
        child: Text('Mở Cài đặt'),
      ),
    ],
  ),
);
```

### ❌ Lỗi 2: "FCM token null"
**Nguyên nhân:** Firebase chưa được khởi tạo đúng
**Giải pháp:**
1. Kiểm tra `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS)
2. Chạy `flutter clean && flutter pub get`
3. Rebuild app

### ❌ Lỗi 3: "Token không được gửi lên backend"
**Nguyên nhân:** API call failed hoặc timing issue
**Giải pháp:**
```dart
// Thêm retry logic
Future<void> _saveFcmTokenWithRetry() async {
  for (int i = 0; i < 3; i++) {
    try {
      final token = await FCMService.getToken();
      if (token != null) {
        final success = await _authService.saveFcmToken(token);
        if (success) {
          print('✅ Token saved on attempt ${i + 1}');
          return;
        }
      }
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      print('⚠ Retry ${i + 1}/3 failed: $e');
    }
  }
  print('❌ Failed to save FCM token after 3 attempts');
}
```

### ❌ Lỗi 4: "Notification không hiển thị"
**Nguyên nhân:** Android notification channel chưa được tạo
**Giải pháp:**
```dart
// Trong FCMService._initializeLocalNotifications()
if (Platform.isAndroid) {
  const channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max, // ← Đổi từ high thành max
    playSound: true,
    enableVibration: true,
  );
  
  await _localNotifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
    
  print('✅ Android notification channel created');
}
```

---

## 📱 TEST TRÊN THIẾT BỊ THẬT

**LƯU Ý:** FCM không hoạt động trên Emulator/Simulator cũ!

### Android:
- ✅ Hoạt động trên Emulator có Google Play Services
- ✅ Hoạt động trên thiết bị thật
- ❌ KHÔNG hoạt động trên Emulator không có Google Play

### iOS:
- ❌ KHÔNG hoạt động trên Simulator
- ✅ CHỈ hoạt động trên thiết bị thật (iPhone/iPad)

---

## 🎯 NEXT STEPS

Sau khi FCM hoạt động:

1. **Reload unread count khi nhận notification:**
```dart
FirebaseMessaging.onMessage.listen((message) {
  _handleForegroundMessage(message);
  
  // Reload badge count
  if (message.data['type'] == 'like' || 
      message.data['type'] == 'comment' || 
      message.data['type'] == 'follow') {
    // Trigger reload unread count in home screen
    eventBus.fire(ReloadNotificationCountEvent());
  }
});
```

2. **Xóa notification khi đã xem:**
```dart
void _onNotificationTap(NotificationModel notification) async {
  if (!notification.isRead) {
    await _notificationService.markAsRead(notification.id);
    // Reload count
    eventBus.fire(ReloadNotificationCountEvent());
  }
  _navigateToPost(notification);
}
```

---

## 📞 SUPPORT

Nếu vẫn không hoạt động sau khi làm theo hướng dẫn:

1. Copy toàn bộ log từ Flutter console
2. Copy log từ backend console
3. Screenshot Firebase Console → Cloud Messaging settings
4. Gửi thông tin về để debug chi tiết hơn
