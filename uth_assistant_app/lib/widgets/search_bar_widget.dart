import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

// Đổi tên widget thành public
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Nội dung widget được giữ nguyên từ _buildSearchBar
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài viết, tài liệu...',
          hintStyle: AppTextStyles.searchHint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              AppAssets.iconSearch,
              colorFilter: const ColorFilter.mode(AppColors.subtitle, BlendMode.srcIn),
            ),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
