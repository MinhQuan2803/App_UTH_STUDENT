import 'package:flutter/material.dart';
import 'config/app_theme.dart';

// Imports các màn hình
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/add_post_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/search_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/profile_screen.dart'; // Import profile screen
import 'models/post_model.dart';
import 'screens/user_posts_screen.dart';
import 'screens/wallet_screen.dart'; // 1. Import màn hình mới
import 'screens/upload_ducument_screen.dart'; // Import màn hình upload document

// Import service
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra token hợp lệ (bao gồm cả kiểm tra expiration)
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
      title: 'UTH Student',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),

      // Logic route:
      // - Token hợp lệ → Vào /home
      // - Token không hợp lệ/hết hạn → Vào /splash → /login
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
        // Xử lý route cho Chi tiết Bài viết
        if (settings.name == '/post_detail') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          if (arguments != null && arguments['post'] is Post) {
            final post = arguments['post'] as Post;
            return MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            );
          }
        }

        // Xử lý route cho Profile
        if (settings.name == '/profile') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          final username = arguments?['username'] as String?;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(username: username),
          );
        }

        // Xử lý route cho Bài viết của Người dùng
        if (settings.name == '/user_posts') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          if (arguments != null && arguments['username'] is String) {
            final username = arguments['username'] as String;
            return MaterialPageRoute(
              builder: (context) => UserPostsScreen(username: username),
            );
          }
        }

        // Quay về trang chủ nếu có lỗi route
        print("Error: Invalid arguments or route name");
        return MaterialPageRoute(builder: (context) => const MainScreen());
      },
    );
  }
}
