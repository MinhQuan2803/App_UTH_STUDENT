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
      },

 onGenerateRoute: (settings) {
          if (settings.name == '/post_detail') {
            // Lấy Post object từ arguments
            final arguments = settings.arguments as Map<String, dynamic>?; // Nhận Map từ HomeScreen
            // Bỏ 'backgroundColor' vì nó không còn cần thiết
            if (arguments != null && arguments['post'] is Post) {
              final post = arguments['post'] as Post;
              return MaterialPageRoute(
                builder: (context) {
                  return PostDetailScreen(post: post);
                },
              );
            }
            print("Error: Invalid arguments passed to /post_detail");
            return MaterialPageRoute(builder: (context) => const MainScreen()); // Quay về Home
          }
          
          // Xử lý route /profile với username
          if (settings.name == '/profile') {
            final arguments = settings.arguments as Map<String, dynamic>?;
            if (arguments != null && arguments['username'] != null) {
              final username = arguments['username'] as String;
              return MaterialPageRoute(
                builder: (context) {
                  return ProfileScreen(username: username);
                },
              );
            }
            print("Error: Invalid arguments passed to /profile");
            return MaterialPageRoute(builder: (context) => const MainScreen());
          }
          
          // Xử lý các route khác
          return null;
        },
    );
  }
}
