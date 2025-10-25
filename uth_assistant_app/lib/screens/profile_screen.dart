import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/profile_list_item.dart';
import '../services/auth_service.dart'; // Import service

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Hàm xử lý đăng xuất
  Future<void> _handleSignOut(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();
    // Chuyển về màn hình đăng nhập và xóa hết stack cũ
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.white,
          elevation: 1,
          shadowColor: AppColors.divider,
          automaticallyImplyLeading: false,
          title: const Text('Hồ sơ của tôi', style: AppTextStyles.appBarTitle),
          centerTitle: true,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildUserInfoCard(context),
              const SizedBox(height: 24),
              _buildActionList(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    // ... (Giữ nguyên nội dung)
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -50,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 4),
                boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, spreadRadius: 2)],
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg'),
              ),
            ),
          ),
          Column(
            children: [
              const Text('Mai Phương', style: AppTextStyles.profileName),
              const SizedBox(height: 4),
              const Text('MSV: 2251012345 | CNTT', style: AppTextStyles.profileMeta),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Chỉnh sửa hồ sơ', style: AppTextStyles.profileButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionList(BuildContext context) {
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Column(
        children: [
          ProfileListItem(
            iconPath: AppAssets.iconEdit,
            title: 'Bài viết của tôi',
            onTap: () {},
          ),
          ProfileListItem(
            iconPath: AppAssets.iconFileCheck,
            title: 'Tài liệu của tôi',
            onTap: () {},
          ),
          ProfileListItem(
            iconPath: AppAssets.iconSettings,
            title: 'Cài đặt',
            onTap: () {},
          ),
          // Cập nhật nút Đăng xuất
          ProfileListItem(
            iconPath: AppAssets.iconLogout,
            title: 'Đăng xuất',
            color: AppColors.danger,
            onTap: () => _handleSignOut(context), // Gọi hàm đăng xuất
          ),
        ],
      ),
    );
  }
}

