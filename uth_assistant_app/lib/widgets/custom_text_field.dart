import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  // Thêm Controller và FocusNode
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType; // Thêm keyboardType

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.focusNode,
    this.keyboardType, // Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Gán controller
      focusNode: focusNode, // Gán focusNode
      obscureText: obscureText,
      keyboardType: keyboardType, // Gán keyboardType
      style: AppTextStyles.bodyBold.copyWith(fontSize: 16), // Kiểu chữ khi nhập
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.hintText.copyWith(fontSize: 14), // Sử dụng theme
        filled: true,
        fillColor: AppColors.inputBackground, // Sử dụng theme
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Giữ bo góc
          borderSide: BorderSide.none, // Bỏ viền mặc định
        ),
        enabledBorder: OutlineInputBorder( // Viền khi không focus
           borderRadius: BorderRadius.circular(16),
           borderSide: const BorderSide(color: AppColors.divider), // Thêm viền nhẹ
        ),
        focusedBorder: OutlineInputBorder( // Viền khi focus
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0), // Viền màu chính
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}

