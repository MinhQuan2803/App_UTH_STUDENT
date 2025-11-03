import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// AppBar hiện đại với gradient và thiết kế đồng nhất
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem có thể pop được không
    final canPop = Navigator.canPop(context);
    
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.white),
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading && canPop,
      leading: leading ??
          (automaticallyImplyLeading && canPop
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// Icon button với background hiện đại cho actions
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const ModernIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.white, size: size),
      ),
      onPressed: onPressed,
    );
  }
}
