import 'package:flutter/material.dart';
import '../widgets/main_nav_bar.dart';
import '../widgets/fab_with_prompt.dart';
import 'home_screen.dart';
import 'chatbot_screen.dart';
import 'document_screen.dart';
import 'profile_screen.dart';
import '../config/app_theme.dart'; // Import để lấy màu AppColors
import 'upload_document_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();
  int _selectedNavIndex = 0;
  int _fabKeyCounter = 0;
  final GlobalKey<State<HomeScreen>> _homeScreenKey = GlobalKey();
  final GlobalKey<State<ProfileScreen>> _profileScreenKey = GlobalKey();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeScreenKey, pageController: _pageController),
    const ChatbotScreen(),
    // DocumentScreen không cần lo về FAB nữa
    const DocumentScreen(),
    ProfileScreen(key: _profileScreenKey),
  ];

  void _onItemTapped(int index) {
    // Xử lý nút "Thêm" (Index 2 trên NavBar)
    if (index == 2) {
      Navigator.pushNamed(context, '/add_post').then((result) {
        if (result == true) {
          final homeScreenState = _homeScreenKey.currentState;
          if (homeScreenState != null) {
            (homeScreenState as dynamic).refreshPosts();
          }
        }
      });
      return;
    }

    // Nếu tap lại tab hiện tại → Scroll to top + reload
    if (index == _selectedNavIndex) {
      if (index == 0) {
        // Tab Trang chủ
        final homeScreenState = _homeScreenKey.currentState;
        if (homeScreenState != null) {
          (homeScreenState as dynamic).scrollToTopAndRefresh();
        }
      } else if (index == 4) {
        // Tab Hồ sơ
        final profileScreenState = _profileScreenKey.currentState;
        if (profileScreenState != null) {
          (profileScreenState as dynamic).scrollToTopAndRefresh();
        }
      }
      return;
    }

    _handleNavChange(index);

    // Map index NavBar -> PageView
    int pageIndex = index > 2 ? index - 1 : index;

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int pageIndex) {
    final newNavIndex = pageIndex >= 2 ? pageIndex + 1 : pageIndex;
    _handleNavChange(newNavIndex);
  }

  void _handleNavChange(int newNavIndex) {
    setState(() {
      _selectedNavIndex = newNavIndex;
      // Reset chatbot nếu quay lại các tab Home/Profile
      if (newNavIndex == 0 || newNavIndex == 4) {
        _fabKeyCounter++;
      }
    });
  }

  // Hàm xử lý khi bấm nút Đăng tài liệu
  void _onUploadDocumentPressed() {
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UploadDocumentScreen()))
        .then((result) {
      // Có thể cần dùng EventBus hoặc GlobalKey để báo cho DocumentScreen reload
      // Nhưng đơn giản nhất là DocumentScreen tự reload khi chuyển tab hoặc pull-to-refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: MainNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onItemTapped,
      ),

      // --- LOGIC HIỂN THỊ FAB THEO TAB ---
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFab() {
    // 1. Tab Chatbot (index 1): Ẩn tất cả
    if (_selectedNavIndex == 1) return null;

    // 2. Tab Tài liệu (index 3): Hiện nút Đăng bài
    if (_selectedNavIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: _onUploadDocumentPressed,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text("Đăng bài", style: TextStyle(color: Colors.white)),
      );
    }

    // 3. Các Tab còn lại (Home, Profile): Hiện Trợ lý ảo
    return FabWithPrompt(
      key: ValueKey<int>(_fabKeyCounter),
      onTap: () => _onItemTapped(1),
    );
  }
}
