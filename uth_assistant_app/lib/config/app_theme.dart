import 'package:flutter/material.dart';

// Lớp quản lý màu sắc trong ứng dụng
class AppColors {
  // Bảng màu chính
  static const Color primary = Color(0xFF38B2AC);
  static const Color secondary = Color(0xFFE3F2FD);
  static const Color accent = Color(0xFFFF4081); // Hồng san hô cho điểm nhấn
  static const Color background = Color(0xFFF5F7FA); // Xám rất nhạt, sạch sẽ
  static const Color white = Colors.white;
  static const Color splashBackground =
      Color(0xFF038D8F); // Màu nền Splash Screen
  static const Color transparent = Colors.transparent;
  static const Color warning = Colors.orange; // BỔ SUNG


  static const Color coinColor = Color(0xFFFFC107); // Vàng cho điểm UTH

  // Màu chữ
  static const Color text = Color(0xFF1A1A1A); // Đen đậm, nhưng không quá gắt
  static const Color subtitle =
      Color(0xFF5A6472); // Xám đậm hơn cho độ tương phản
  static const Color hintText = Color(0xFF9AA4B2);
  static const Color textSecondary = Color(0xFF5A6472);
  static const Color avatarPlaceholderText =
      AppColors.primary; // Màu chữ cho avatar placeholder

  // Màu cho Add Post Screen
  static const Color postCardBorder = Color(0xFFE4E6EB);
  static const Color toolbarItem = Color(0xFF606770);
  static const Color toolbarItemHover = Color(0xFFF2F3F5);
  static const Color privacyButton = Color(0xFFE4E6EB);
  static const Color imageOverlayRemove = Color(0x99000000);

  // Màu giao diện
  static const Color divider = Color(0xFFEAEFF5);
  static const Color dividerLight = Color(0xFFF0F3F7);
  static const Color inputBackground =
      Color(0xFFFFFFFF); // Nền trắng cho ô nhập liệu
  static const Color shadow =
      Color.fromRGBO(90, 108, 123, 0.08); // Bóng đổ nhẹ nhàng hơn
  static const Color imagePlaceholder = Color(0xFFE0E0E0);
  static final Color imageOverlay = Colors.black.withOpacity(0.5);

  // Màu header & Gradient
  static const Color headerGradientStart = Color(0xFF38B2AC);
  static const Color headerGradientEnd = Color.fromARGB(255, 34, 141, 143);
  static const Color avatarBorder = Colors.white;
  static final Color headerWave1 = Colors.white.withOpacity(0.1);
  static final Color headerWave2 = Colors.white.withOpacity(0.15);
  static const Color appBarGradientEnd = Color(0xFF764BA2);
  static const Color postButtonGradientStart = Color(0xFFFF6B9D);
  static const Color postButtonGradientEnd = Color(0xFFFFA06B);
  static const Color avatarBorderGradientStart = Color(0xFF667EEA);
  static const Color avatarBorderGradientEnd = Color(0xFFFF6B9D);

  // Màu trạng thái
  static const Color liked = Color(0xFFFF4081); // Dùng màu accent
  static const Color notificationDot = Color(0xFFFF4081);
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Colors.green; // Thêm màu success
  // Màu cho các loại file
  static const Color pdfBackground = Color(0xFFFFF0E5);
  static const Color pdfText = Color(0xFFFB8C00);
  static const Color docxBackground = Color(0xFFE3F2FD);
  static const Color docxText = Color(0xFF1976D2);
  static const Color xlsxBackground = Color(0xFFE8F5E9);
  static const Color xlsxText = Color(0xFF388E3C);

  // Danh sách màu nền cho bài viết
  static const List<Color> postBackgrounds = [
    Color(0xFFFFF0F5), // Hồng pastel
    Color(0xFFF0F4FF), // Xanh dương pastel
    Color(0xFFFFFAF0), // Cam nhạt
    Color(0xFFF0FFF4), // Xanh lá pastel
    Color(0xFFFFF5F7), // Hồng nhạt
    Color(0xFFF3F0FF), // Tím pastel
  ];
}

// Lớp quản lý các kiểu chữ (ĐÃ ĐỒNG NHẤT VỀ FONT 'Inter')
class AppTextStyles {
  // Header & AppBar
  static const TextStyle appBarTitle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  static const TextStyle appBarTitleWhite = TextStyle(
      fontFamily: 'Inter',
      color: AppColors.white,
      fontSize: 17,
      fontWeight: FontWeight.w700);
  static const TextStyle appBarButton = TextStyle(
      fontFamily: 'Inter',
      color: AppColors.white,
      fontSize: 15,
      fontWeight: FontWeight.w500);
  static const TextStyle headerGreeting =
      TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.white);
  static const TextStyle headerName = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.white);

  // Màn hình Thêm bài viết
  static const TextStyle addPostUserName = TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  static final TextStyle addPostHintText = TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      color: AppColors.hintText,
      fontWeight: FontWeight.w400);
  static const TextStyle addPostInputText = TextStyle(
      fontFamily: 'Inter', fontSize: 15, color: AppColors.text, height: 1.4);
  static const TextStyle addPostPrivacy = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.toolbarItem);
  static const TextStyle toolbarItemText = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.toolbarItem);
  static const TextStyle bottomToolbarTitle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  // Tiêu đề
  static const TextStyle heading1 = TextStyle(
      fontFamily: 'Inter',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.text);
  static const TextStyle sectionTitle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.text);

  // Thân bài
  static const TextStyle bodyRegular =
      TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.subtitle);
  static const TextStyle bodyBold = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  static const TextStyle chatMessage =
      TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4);

  // Bài viết (Post)
  static const TextStyle postName = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  static const TextStyle postMeta =
      TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.subtitle);
  static const TextStyle postContent = TextStyle(
      fontFamily: 'Inter', fontSize: 13, color: AppColors.text, height: 1.4);
  static const TextStyle interaction = TextStyle(
      fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary);

  // Nút bấm & Nhập liệu
  static const TextStyle button =
      TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle hintText =
      TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.hintText);
  static const TextStyle suggestionChip = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.primary);
  static const TextStyle searchHint =
      TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.hintText);

  // Điều hướng & Danh sách
  static const TextStyle navLabel = TextStyle(fontFamily: 'Inter', fontSize: 9);
  static const TextStyle tabLabel =
      TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle listItem =
      TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500);

  // Lỗi
  static const TextStyle errorText =
      TextStyle(fontFamily: 'Inter', color: AppColors.danger, fontSize: 14);

// ví
 static const TextStyle priceTag = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary);
  static const TextStyle walletBalance = TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary);
  // Tài liệu
  static const TextStyle documentTitle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  static const TextStyle documentUploader =
      TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.subtitle);
  static const TextStyle fileTypeLabel =
      TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700);

  static const TextStyle actionButton =
      TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle imageOverlayText = TextStyle(
      fontFamily: 'Inter',
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold);
  static const TextStyle bottomSheetName =
      TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle deleteDialogText = TextStyle(color: AppColors.danger);

  // Hồ sơ
  static const TextStyle profileName = TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.text);
  static const TextStyle profileMeta =
      TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.subtitle);
  static const TextStyle profileButton = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.white);

  // Thông báo
  static const TextStyle linkText = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.primary);
  static const TextStyle notificationTitle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.text);
  static const TextStyle notificationDate =
      TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.subtitle);

  // Splash Screen (Sử dụng phông chữ tùy chỉnh)
  static const TextStyle splashTitle = TextStyle(
      fontFamily:
          'LazyDog', // Bạn cần đảm bảo font này đã được thêm vào pubspec
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: AppColors.white,
      shadows: [
        Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)
      ]);

  // Kiểu chữ cho ảnh
}

// Lớp quản lý đường dẫn tài sản (assets)
class AppAssets {
  // Nhóm đường dẫn
  static const String _imagesPath = 'assets/images';
  static const String _imagesPicPath = 'assets/images_pic';

  // --- API URLS ---
  static const String newsApiUrl = 'http://192.168.1.12:3000/api/news';
  static const String uploadApiBaseUrl =
      'https://uthstudent.onrender.com/api/upload';

  // --- ẢNH LỚN ---
  static const String defaultNotificationImage =
      '$_imagesPicPath/uth_hoathinh.jpg';
  static const String splashLogo = '$_imagesPath/splash_logo.png';

  // --- ICON CHUNG ---
  static const String loginIllustration = '$_imagesPath/login_illustration.svg';
  static const String googleLogo = '$_imagesPath/google_logo.svg';
  static const String iconBell = '$_imagesPath/icon_bell.svg';
  static const String iconHeart = '$_imagesPath/icon_heart.svg';
  static const String iconComment = '$_imagesPath/icon_comment.svg';
  static const String iconMore = '$_imagesPath/icon_more.svg';
  static const String iconChevronRight = '$_imagesPath/icon_chevron_right.svg';
  static const String iconImage = '$_imagesPath/icon_image.svg';
  static const String iconSearch = '$_imagesPath/icon_search.svg';
  static const String iconChevronLeft = '$_imagesPath/icon_chevron_left.svg';
  static const String iconMic = '$_imagesPath/icon_mic.svg';
  static const String iconSend = '$_imagesPath/icon_send.svg';
  static const String iconDownload = '$_imagesPath/icon_download.svg';
  static const String iconUpload = '$_imagesPath/icon_upload.svg';
  static const String iconEdit = '$_imagesPath/icon_edit.svg';
  static const String iconFileCheck = '$_imagesPath/icon_file_check.svg';
  static const String iconSettings = '$_imagesPath/icon_settings.svg';
  static const String iconLogout = '$_imagesPath/icon_logout.svg';

  // --- ICON ĐIỀU HƯỚNG & FAB ---
  static const String fabBot = '$_imagesPath/fab_bot.svg';
  static const String navPlus = '$_imagesPath/nav_plus.svg';
  static const String navHome = '$_imagesPath/nav_home.svg';
  static const String navBot = '$_imagesPath/nav_bot.svg';
  static const String navFolder = '$_imagesPath/nav_folder.svg';
  static const String navUser = '$_imagesPath/nav_user.svg';

   static const String iconWallet = '$_imagesPath/icon_wallet.svg';
// ví
   static const String iconCoin = '$_imagesPath/icon_coin.svg';
   static const String iconmomo = '$_imagesPath/icon_momo.svg';
   static const String iconZalo = '$_imagesPath/icon_zalopay.svg';
  // Biến cũ không còn dùng (đã được thay bằng navPlus)
  // static const String iconPlus = '$_imagesPath/icon_plus.svg';
}
