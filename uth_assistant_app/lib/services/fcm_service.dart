import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert'; // Import để encode/decode JSON
import '../main.dart'; // Import để dùng navigatorKey
import 'post_service.dart'; // Import để fetch post by ID

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Khởi tạo FCM và local notifications
  static Future<void> initialize() async {
    if (kDebugMode) print('=== INITIALIZING FCM ===');

    // 1. Request permission (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('Permission status: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('✓ User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) print('✓ User granted provisional permission');
    } else {
      if (kDebugMode) print('✗ User declined or has not accepted permission');
    }

    // 2. Lấy FCM token
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('✓ FCM Token: $token');
    }

    // 3. Khởi tạo local notifications
    await _initializeLocalNotifications();

    // 4. Lắng nghe foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Lắng nghe background messages (khi app mở từ notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Kiểm tra xem app có được mở từ notification không
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 7. Lắng nghe token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) print('✓ FCM Token refreshed: $newToken');
      // TODO: Gửi token mới lên server
    });

    if (kDebugMode) print('✓ FCM initialized successfully');
  }

  /// Khởi tạo Flutter Local Notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Tạo notification channel cho Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Xử lý khi nhận notification trong foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('=== FOREGROUND MESSAGE ===');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('Data isEmpty: ${message.data.isEmpty}');
      print('Data keys: ${message.data.keys}');
    }

    // Hiển thị local notification
    _showLocalNotification(message);
  }

  /// Hiển thị local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'UTH Student',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(message.data), // Encode data as JSON
    );
  }

  /// Xử lý khi user nhấn vào notification
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('=== NOTIFICATION TAPPED ===');
      print('Payload: ${response.payload}');
    }

    // Parse payload từ JSON string
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        if (kDebugMode) print('Parsed data: $data');

        _navigateFromNotification(data);
      } catch (e) {
        if (kDebugMode) print('Error parsing payload: $e');
      }
    }
  }

  /// Xử lý khi app được mở từ notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('=== APP OPENED FROM NOTIFICATION ===');
      print('Title: ${message.notification?.title}');
      print('Data: ${message.data}');
    }

    _navigateFromNotification(message.data);
  }

  /// Navigate đến màn hình tương ứng dựa trên notification data
  static void _navigateFromNotification(Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('=== NAVIGATE FROM NOTIFICATION ===');
      print('Data: $data');
      print('Data isEmpty: ${data.isEmpty}');
    }

    if (data.isEmpty) {
      if (kDebugMode) print('⚠️ Data is empty, cannot navigate');
      return;
    }

    final type = data['type']?.toString();
    final screen = data['screen']?.toString();

    if (kDebugMode) {
      print('Navigating: type=$type, screen=$screen');
    }

    // Sử dụng navigatorKey từ main.dart
    if (type == 'like' || type == 'comment' || type == 'mention') {
      final postId = data['postId']?.toString();
      if (kDebugMode)
        print('→ Navigate to PostDetailScreen with postId: $postId');

      if (postId != null && postId.isNotEmpty) {
        try {
          // Fetch post data từ backend
          final postService = PostService();
          final post = await postService.getPostById(postId);

          // Navigate với post object
          navigatorKey.currentState?.pushNamed(
            '/post_detail',
            arguments: {'post': post},
          );
          if (kDebugMode) print('✓ Navigated to post detail');
        } catch (e) {
          if (kDebugMode) print('❌ Failed to fetch post: $e');
        }
      }
    } else if (type == 'follow') {
      final username = data['username']?.toString();
      if (kDebugMode)
        print('→ Navigate to ProfileScreen with username: $username');

      if (username != null && username.isNotEmpty) {
        // Navigate đến profile screen với username
        navigatorKey.currentState?.pushNamed(
          '/profile',
          arguments: {'username': username},
        );
        if (kDebugMode) print('✓ Navigated to profile');
      }
    } else if (type == 'wallet' || type == 'balance') {
      // 💰 Biến động số dư: Chuyển đến màn hình ví
      if (kDebugMode) print('→ Navigate to WalletScreen (Balance change)');

      navigatorKey.currentState?.pushNamed('/wallet');

      if (kDebugMode) print('✓ Navigated to wallet');
    } else {
      if (kDebugMode) print('⚠️ Unknown notification type: $type');
    }
  }

  /// Lấy FCM token hiện tại
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe vào topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    if (kDebugMode) print('✓ Subscribed to topic: $topic');
  }

  /// Unsubscribe khỏi topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    if (kDebugMode) print('✓ Unsubscribed from topic: $topic');
  }
}

/// Background message handler (PHẢI ở top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('=== BACKGROUND MESSAGE ===');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }
}
