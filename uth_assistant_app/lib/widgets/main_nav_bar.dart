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
    
    // Tính toán vị trí Indicator
    final double indicatorOffset = (itemWidth * selectedIndex) + (itemWidth / 2) - (indicatorWidth / 2);

    return Container(
      // BƯỚC 1: Trang trí nền và bóng đổ
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
      
      // BƯỚC 2: SafeArea tự động xử lý phần đệm của phím điều hướng
      child: SafeArea(
        top: false, 
        child: Container(
          // THÊM PADDING TẠI ĐÂY:
          // Thêm khoảng cách trên/dưới để giao diện thoáng hơn (8px mỗi chiều)
          padding: const EdgeInsets.symmetric(vertical: 8.0), 
          
          // QUAN TRỌNG: Đặt chiều cao tối thiểu để tránh lỗi "RenderBox was not laid out"
          constraints: const BoxConstraints(minHeight: kBottomNavigationBarHeight),
          
          child: Stack(
            clipBehavior: Clip.none, 
            alignment: Alignment.bottomCenter, // Căn đáy để BottomNav quyết định chiều cao
            children: [
              // Lớp dưới: BottomNavigationBar
              MediaQuery.removePadding(
                context: context,
                removeBottom: true, 
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: onTap,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent, 
                  elevation: 0, 
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.hintText,
                  
                  // --- PHẦN CHỈNH SỬA CỠ CHỮ ---
                  // 1. Cập nhật trong Style (để render chính xác font weight/family nếu có)
                  selectedLabelStyle: AppTextStyles.navLabel.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 10, // <--- Thay đổi cỡ chữ khi ĐƯỢC CHỌN tại đây
                  ),
                  unselectedLabelStyle: AppTextStyles.navLabel.copyWith(
                    color: AppColors.hintText,
                    fontSize: 10, // <--- Thay đổi cỡ chữ khi KHÔNG CHỌN tại đây
                  ),
                  
                  // 2. Cập nhật thuộc tính của Widget (quan trọng cho việc tính toán khoảng cách layout)
                  selectedFontSize: 12,   // <--- Thay đổi số này (VD: 10, 13, 14)
                  unselectedFontSize: 12, // <--- Thay đổi số này (thường để bằng selectedFontSize)
                  // ---------------------------

                  items: [
                    _buildNavItem(AppAssets.navHome, 'Trang chủ', 0),
                    _buildNavItem(AppAssets.navBot, 'UTH Assistant', 1),
                    _buildNavItem(AppAssets.navPlus, 'Đăng bài', 2),
                    _buildNavItem(AppAssets.navFolder, 'Tài liệu', 3),
                    _buildNavItem(AppAssets.navUser, 'Hồ sơ', 4),
                  ],
                ),
              ),
              
              // Lớp trên: Indicator chạy
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                top: 0, 
                left: indicatorOffset,
                child: Container(
                  width: indicatorWidth,
                  height: 3, 
                  margin: const EdgeInsets.only(top: 0), 
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String iconPath, String label, int index) {
    final color = selectedIndex == index ? AppColors.primary : AppColors.hintText;

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
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