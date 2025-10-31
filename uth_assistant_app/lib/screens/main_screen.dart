import 'package:flutter/material.dart';
import '../widgets/main_nav_bar.dart';
import '../widgets/fab_with_prompt.dart';
import 'home_screen.dart';
import 'chatbot_screen.dart';
import 'document_screen.dart';
import 'profile_screen.dart';

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

  late final List<Widget> _screens = [
    HomeScreen(key: _homeScreenKey, pageController: _pageController),
    const ChatbotScreen(),
    const DocumentScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedNavIndex) return;

    // CẬP NHẬT: Xử lý sự kiện cho nút "Thêm"
    if (index == 2) {
      // Mở màn hình tạo bài viết dưới dạng một trang mới
      Navigator.pushNamed(context, '/add_post').then((result) {
        // Nếu đăng bài thành công, refresh home screen
        if (result == true) {
          // Gọi refresh method của HomeScreen thông qua GlobalKey
          final homeScreenState = _homeScreenKey.currentState;
          if (homeScreenState != null) {
            (homeScreenState as dynamic).refreshPosts();
          }
        }
      });
      return; // Không chuyển tab trong PageView
    }

    // Các logic còn lại không đổi
    _handleNavChange(index);

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
    final wasFabHidden = _selectedNavIndex == 1;
    final isFabHidden = newNavIndex == 1;

    setState(() {
      _selectedNavIndex = newNavIndex;
      if (wasFabHidden && !isFabHidden) {
        _fabKeyCounter++;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Tắt vuốt để chuyển trang
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: MainNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedNavIndex == 1
          ? null
          : FabWithPrompt(
              key: ValueKey<int>(_fabKeyCounter),
              onTap: () {
                _onItemTapped(1);
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
