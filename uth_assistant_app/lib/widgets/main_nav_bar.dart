import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class MainNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const MainNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const itemCount = 5;
    final itemWidth = screenWidth / itemCount;
    const indicatorWidth = 24.0;
    
    // Tính toán vị trí bên trái (left offset) cho thanh ngang
    // Vị trí này sẽ được AnimatedPositioned sử dụng để tạo hiệu ứng
    final double indicatorOffset = (itemWidth * selectedIndex) + (itemWidth / 2) - (indicatorWidth / 2);

    return Container(
      height: 70, // Chiều cao của toàn bộ thanh nav
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lớp 1: Thanh ngang trượt (Indicator)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 4, // Khoảng cách từ đỉnh
            left: indicatorOffset,
            child: Container(
              width: indicatorWidth,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Lớp 2: Thanh BottomNavigationBar
          BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Nền trong suốt để thấy Container cha
            elevation: 0, // Bỏ đổ bóng mặc định
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.hintText,
            selectedLabelStyle: AppTextStyles.navLabel.copyWith(color: AppColors.primary),
            unselectedLabelStyle: AppTextStyles.navLabel.copyWith(color: AppColors.hintText),
            items: [
              _buildNavItem(AppAssets.navHome, 'Trang chủ', 0),
              _buildNavItem(AppAssets.navBot, 'UTH Assistant', 1),
              _buildNavItem(AppAssets.navPlus, 'Đăng bài', 2),
              _buildNavItem(AppAssets.navFolder, 'Tài liệu', 3),
              _buildNavItem(AppAssets.navUser, 'Hồ sơ', 4),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildNavItem giờ đã được đơn giản hóa, không còn chứa logic vẽ thanh ngang
  BottomNavigationBarItem _buildNavItem(String iconPath, String label, int index) {
    final color = selectedIndex == index ? AppColors.primary : AppColors.hintText;

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0), // Điều chỉnh padding
        child: SvgPicture.asset(
          iconPath,
          width: 22,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
      label: label,
    );
  }
}

