import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';

// Imports các màn hình
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/add_post_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/search_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/profile_screen.dart'; 
import 'models/post_model.dart';
import 'screens/user_posts_screen.dart';
import 'screens/wallet_screen.dart'; 
import 'screens/upload_ducument_screen.dart'; 
import 'screens/webview_screen.dart'; 

import 'services/auth_service.dart';
import 'services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('=== BACKGROUND MESSAGE ===');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CẤU HÌNH GIAO DIỆN HỆ THỐNG ---
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, 
    // Thêm dòng này: Tắt chế độ tự động tăng tương phản của Android (gây ra lớp phủ mờ)
    systemNavigationBarContrastEnforced: false, 
    systemNavigationBarIconBrightness: Brightness.dark, 
    statusBarColor: Colors.transparent, 
    statusBarIconBrightness: Brightness.dark,
  ));
  // ------------------------------------

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FCMService.initialize();

  final authService = AuthService();
  final bool isLoggedIn = await authService.isLoggedIn(); 

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, 
      title: 'UTH Student',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),

      initialRoute: isLoggedIn ? '/home' : '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/add_post': (context) => const AddPostScreen(),
        '/signup': (context) => const SignupScreen(),
        '/search': (context) => const SearchScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/upload_document': (context) => const UploadDocumentScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/post_detail') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          if (arguments != null && arguments['post'] is Post) {
            final post = arguments['post'] as Post;
            return MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            );
          }
          debugPrint("Error: /post_detail missing valid Post argument");
          return null;
        }

        if (settings.name == '/profile') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          final username = arguments?['username'] as String?;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(username: username),
          );
        }

        if (settings.name == '/webview') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          if (arguments != null && arguments['url'] is String) {
            final url = arguments['url'] as String;
            final title = arguments['title'] as String?;
            final isPayment = arguments['isPayment'] as bool? ?? false;
            return MaterialPageRoute(
              builder: (context) => WebViewScreen(
                initialUrl: url,
                title: title,
                isPayment: isPayment,
              ),
            );
          }
          debugPrint("Error: /webview missing valid url argument");
          return null;
        }

        if (settings.name == '/user_posts') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          if (arguments != null && arguments['username'] is String) {
            final username = arguments['username'] as String;
            return MaterialPageRoute(
              builder: (context) => UserPostsScreen(username: username),
            );
          }
          debugPrint("Error: /user_posts missing valid username argument");
          return null;
        }

        return null;
      },

      onUnknownRoute: (settings) {
        debugPrint("Unknown route: ${settings.name}");
        return MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const MainScreen() : const SplashScreen(),
        );
      },
    );
  }
}