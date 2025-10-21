import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SuggestionChip({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label, style: AppTextStyles.suggestionChip),
      ),
    );
  }
}
