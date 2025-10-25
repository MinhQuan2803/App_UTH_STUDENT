import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/add_post_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/search_screen.dart'; 
import 'services/auth_service.dart'; // Import service
import 'screens/post_detail_screen.dart';

// Sử dụng async main và WidgetsFlutterBinding để đảm bảo kiểm tra token xong trước khi build UI
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Cần thiết khi dùng async main
  final authService = AuthService();
  final bool isLoggedIn = await authService.isLoggedIn(); // Kiểm tra trạng thái đăng nhập

  runApp(MyApp(isLoggedIn: isLoggedIn)); // Truyền trạng thái vào MyApp
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; // Nhận trạng thái đăng nhập

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
      
      // Quyết định màn hình đầu tiên dựa trên trạng thái đăng nhập
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
          // Lấy dữ liệu bài viết từ arguments
          final postData = settings.arguments as Map<String, dynamic>?;
          if (postData != null) {
            return MaterialPageRoute(
              builder: (context) {
                return PostDetailScreen(postData: postData);
              },
            );
          }
          // Xử lý trường hợp không có arguments (ví dụ: quay về home)
          return MaterialPageRoute(builder: (context) => const MainScreen());
        }
        // Xử lý các route khác nếu cần
        return null;
      }
    );
  }
}

