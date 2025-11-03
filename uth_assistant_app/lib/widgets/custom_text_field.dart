import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // THÊM IMPORT NÀY
import '../config/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  // --- BỔ SUNG CÁC THAM SỐ MỚI ---
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.maxLines, // Thêm vào constructor
    this.inputFormatters, // Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      // --- SỬ DỤNG CÁC THAM SỐ MỚI ---
      maxLines: maxLines ?? 1, // Mặc định là 1 dòng nếu không truyền
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.hintText.copyWith(fontSize: 16),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(16),
           borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}

