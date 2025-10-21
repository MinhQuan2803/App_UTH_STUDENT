// ...existing code...
import 'package:flutter/material.dart';

// Lớp quản lý màu sắc trong ứng dụng
class AppColors {
  // Bảng màu chính, trẻ trung và năng động hơn
  static const Color primary = Color(0xFF38B2AC); // Xanh dương rực rỡ
  static const Color secondary = Color(0xFFE3F2FD); // Xanh dương rất nhạt
  static const Color accent = Color(0xFFFF4081); // Hồng san hô cho điểm nhấn
  static const Color background = Color(0xFFF5F7FA); // Xám rất nhạt, sạch sẽ
  static const Color white = Colors.white;

  // Màu chữ
  static const Color text = Color(0xFF1A1A1A); // Đen đậm, nhưng không quá gắt
  static const Color subtitle = Color(0xFF5A6472); // Xám đậm hơn cho độ tương phản
  static const Color hintText = Color(0xFF9AA4B2);
  static const Color textSecondary = Color(0xFF5A6472);

  // Màu giao diện
  static const Color divider = Color(0xFFEAEFF5);
  static const Color dividerLight = Color(0xFFF0F3F7);
  static const Color inputBackground = Color(0xFFFFFFFF); // Nền trắng cho ô nhập liệu
  static const Color shadow = Color.fromRGBO(90, 108, 123, 0.08); // Bóng đổ nhẹ nhàng hơn
  
  // Màu header
  static const Color headerGradientStart = Color(0xFF38B2AC);
  static const Color headerGradientEnd = Color.fromARGB(255, 34, 141, 143); // Cập nhật màu gradient
  static const Color avatarBorder = Colors.white; // Màu viền avatar
  static final Color headerWave1 = Colors.white.withOpacity(0.1); // Màu sóng 1
  static final Color headerWave2 = Colors.white.withOpacity(0.15); // Màu sóng 2

  // Màu trạng thái
  static const Color liked = Color(0xFFFF4081); // Dùng màu accent
  static const Color notificationDot = Color(0xFFFF4081);
  static const Color danger = Color(0xFFD32F2F);

  // Màu cho các loại file
  static const Color pdfBackground = Color(0xFFFFF0E5);
  static const Color pdfText = Color(0xFFFB8C00);
  static const Color docxBackground = Color(0xFFE3F2FD);
  static const Color docxText = Color(0xFF1976D2);
  static const Color xlsxBackground = Color(0xFFE8F5E9);
  static const Color xlsxText = Color(0xFF388E3C);
   
    // --- BỔ SUNG: DANH SÁCH MÀU NỀN CHO BÀI VIẾT ---
  static const List<Color> postBackgrounds = [
    Color(0xFFFFF0F5), // Hồng pastel
    Color(0xFFF0F4FF), // Xanh dương pastel
    Color(0xFFFFFAF0), // Cam nhạt
    Color(0xFFF0FFF4), // Xanh lá pastel
    Color(0xFFFFF5F7), // Hồng nhạt
    Color(0xFFF3F0FF), // Tím pastel
  ];

 static const Color appBarGradientEnd = Color(0xFF764BA2);
  static const Color postButtonGradientStart = Color(0xFFFF6B9D);
  static const Color postButtonGradientEnd = Color(0xFFFFA06B);
  static const Color avatarBorderGradientStart = Color(0xFF667EEA);
  static const Color avatarBorderGradientEnd = Color(0xFFFF6B9D);

}

// Lớp quản lý các kiểu chữ (KÉM KÍCH THƯỚC)
class AppTextStyles {
  // Header & AppBar
  static const TextStyle appBarTitle = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle headerGreeting = TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.white);
  static const TextStyle headerName = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white);

  // Tiêu đề
  static const TextStyle heading1 = TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text);
  static const TextStyle sectionTitle = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text);
  
  // Thân bài
  static const TextStyle bodyRegular = TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.subtitle);
  static const TextStyle bodyBold = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle chatMessage = TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4);
  
  // Bài viết (Post)
  static const TextStyle postName = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle postMeta = TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.subtitle);
  static const TextStyle postContent = TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.text, height: 1.4);
  static const TextStyle interaction = TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary);

  // Nút bấm & Nhập liệu
  static const TextStyle button = TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle hintText = TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.hintText);
  static const TextStyle suggestionChip = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary);
  
  // Điều hướng & Danh sách
  static const TextStyle navLabel = TextStyle(fontFamily: 'Inter', fontSize: 9);
  static const TextStyle tabLabel = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle listItem = TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500);

  // Tài liệu
  static const TextStyle documentTitle = TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle documentUploader = TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.subtitle);
  static const TextStyle fileTypeLabel = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700);
  
  // Hồ sơ
  static const TextStyle profileName = TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text);
  static const TextStyle profileMeta = TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.subtitle);
  static const TextStyle profileButton = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white);

  // Thông báo
  static const TextStyle linkText = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary);
  static const TextStyle notificationTitle = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle notificationDate = TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.subtitle);

 static const TextStyle appBarButton = TextStyle(fontFamily: 'Manrope', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle appBarTitleWhite = TextStyle(fontFamily: 'Manrope', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700);
  static const TextStyle postButtonText = TextStyle(fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w700);
  static const TextStyle addPostUserName = TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text);
  static final TextStyle addPostHintText = TextStyle(fontFamily: 'Manrope', fontSize: 18, color: AppColors.subtitle.withOpacity(0.5), fontWeight: FontWeight.w400);
  static const TextStyle addPostInputText = TextStyle(fontFamily: 'Manrope', fontSize: 17, color: AppColors.text, height: 1.5);
  static const TextStyle bottomToolbarTitle = TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text);
}

// Lớp quản lý đường dẫn tài sản (assets)
class AppAssets {
  static const String _imagesPath = 'assets/images';
  
  static const String loginIllustration = '$_imagesPath/login_illustration.svg';
  static const String googleLogo = '$_imagesPath/google_logo.svg';

  static const String iconBell = '$_imagesPath/icon_bell.svg';
  static const String iconHeart = '$_imagesPath/icon_heart.svg';
  static const String iconComment = '$_imagesPath/icon_comment.svg';
  static const String iconMore = '$_imagesPath/icon_more.svg';
  static const String iconPlus = '$_imagesPath/icon_plus.svg';
  static const String iconChevronRight = '$_imagesPath/icon_chevron_right.svg';
  static const String iconImage = '$_imagesPath/icon_image.svg';

  static const String iconChevronLeft = '$_imagesPath/icon_chevron_left.svg';
  static const String iconMic = '$_imagesPath/icon_mic.svg';
  static const String iconSend = '$_imagesPath/icon_send.svg';

  static const String iconDownload = '$_imagesPath/icon_download.svg';
  static const String iconUpload = '$_imagesPath/icon_upload.svg';
  
  static const String iconEdit = '$_imagesPath/icon_edit.svg';
  static const String iconFileCheck = '$_imagesPath/icon_file_check.svg';
  static const String iconSettings = '$_imagesPath/icon_settings.svg';
  static const String iconLogout = '$_imagesPath/icon_logout.svg';

  static const String fabBot = '$_imagesPath/fab_bot.svg';

  static const String navPlus = '$_imagesPath/nav_plus.svg';
  static const String navHome = '$_imagesPath/nav_home.svg';
  static const String navBot = '$_imagesPath/nav_bot.svg';
  static const String navFolder = '$_imagesPath/nav_folder.svg';
  static const String navUser = '$_imagesPath/nav_user.svg';
}