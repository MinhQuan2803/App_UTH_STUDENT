# 🎓 UTH Student App

Ứng dụng Mạng Xã Hội Sinh Viên - Kết nối, Chia sẻ & Học tập

![Flutter](https://img.shields.io/badge/Flutter-3.4.0-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase)
![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)

---

## 📱 Giới Thiệu

**UTH Student App** là nền tảng mạng xã hội dành riêng cho sinh viên UTH, được phát triển bởi chính sinh viên UTH, giúp kết nối cộng đồng học tập, chia sẻ tài liệu, trao đổi kiến thức và quản lý hoạt động học tập hiệu quả.

![App Screenshot](assets/images/app_icon.png)

---

## ✨ Tính Năng Chính

### 📰 **Mạng Xã Hội**
- ✍️ Đăng bài viết với văn bản, hình ảnh, video
- 💬 Bình luận và tương tác với bài viết
- ❤️ Thích, lưu bài viết yêu thích
- 👥 Theo dõi người dùng khác
- 🔍 Tìm kiếm toàn cục (bài viết, người dùng, tài liệu)
- 📸 Xem ảnh phóng to với Photo Viewer

### 📚 **Thư Viện Tài Liệu**
- 📄 Tải lên tài liệu 
- 💰 Mua/Bán tài liệu với hệ thống điểm
- 📖 Đọc tài liệu trực tiếp trong ứng dụng
- 🔎 Tìm kiếm tài liệu theo từ khóa
- 💾 Lưu tài liệu yêu thích

### 💳 **Hệ Thống Thanh Toán**
- 💵 Nạp điểm qua **VNPay** và **MoMo**
- 💸 Rút tiền về tài khoản ngân hàng
- 📊 Lịch sử giao dịch chi tiết
- 💰 Ví điểm tích hợp
- 🧾 Theo dõi thu nhập từ bán tài liệu

### 🤖 **Trợ Lý AI Chatbot**
- 💬 Hỗ trợ trả lời câu hỏi 24/7
- 🎓 Tư vấn học tập và tra cứu thông tin
### 👤 **Quản Lý Tài Khoản**
- 🔐 Đăng ký/Đăng nhập an toàn
- 📧 Xác thực email
- 🖼️ Chỉnh sửa thông tin cá nhân và avatar
- 🔔 Quản lý thông báo theo dõi, bình luận, thích
- 🏦 Liên kết tài khoản ngân hàng
### 🔔 **Thông Báo Thời Gian Thực**
- 📲 Push notification qua **Firebase Cloud Messaging**
- 🔕 Thông báo khi có người theo dõi
- 💬 Thông báo bình luận mới
- ❤️ Thông báo lượt thích
- 📄 Thông báo mua tài liệu

### 🛡️ **Bảo Mật & An Toàn**
- 🔒 Mã hóa dữ liệu nhạy cảm với **Flutter Secure Storage**
- 🚫 Chống chụp màn hình với **Screen Protector**
- 🔑 Xác thực JWT Token
- 🌐 HTTPS cho tất cả API

---

## 🛠️ Công Nghệ Sử Dụng

### **Frontend: Flutter**
```yaml
Flutter SDK: 3.4.0+
Dart: 3.4.0+
```

**Thư viện chính:**
- `firebase_core` & `firebase_messaging` - Push notifications
- `flutter_local_notifications` - Thông báo nội bộ
- `cached_network_image` - Cache hình ảnh
- `photo_view` - Xem ảnh phóng to
- `image_picker` - Chọn ảnh từ thư viện/camera
- `file_picker` - Chọn file tài liệu
- `webview_flutter` - Hiển thị thanh toán WebView
- `flutter_secure_storage` - Lưu trữ token an toàn
- `screen_protector` - Chống chụp màn hình
- `http` - API calls
- `jwt_decoder` - Giải mã JWT
- `shared_preferences` - Lưu trữ cài đặt
- `url_launcher` - Mở link ngoài
- `intl` - Định dạng ngày tháng

---

## ⚡ Cài Đặt & Chạy Dự Án

### 1️⃣ **Yêu Cầu Hệ Thống**
- Flutter SDK: `>=3.4.0 <4.0.0`
- Dart: `>=3.4.0`
- Android Studio / Xcode
- Thiết bị Android hoặc iOS (hoặc Emulator)

### 2️⃣ **Clone Repository & Cài Dependencies**
```bash
git clone <repository-url>
cd uth_assistant_app

# Cài đặt Flutter dependencies
flutter pub get

# Tạo launcher icons
flutter pub run flutter_launcher_icons
```

### 3️⃣ **Cấu Hình Firebase**

#### **Bước 1: Tạo Firebase Project**
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới hoặc sử dụng project có sẵn
3. Thêm Android & iOS app vào project

#### **Bước 2: Download File Cấu Hình**
- **Android:** Download `google-services.json` → đặt vào `android/app/`
- **iOS:** Download `GoogleService-Info.plist` → đặt vào `ios/Runner/`

#### **Bước 3: Cấu Hình Firebase CLI**
```bash
# Cài Firebase CLI
npm install -g firebase-tools

# Đăng nhập
firebase login

# Khởi tạo Firebase trong project
firebase init

# Tạo file firebase_options.dart
flutterfire configure
```

#### **Bước 4: Enable Firebase Cloud Messaging**
1. Vào Firebase Console → **Cloud Messaging**
2. Lấy **Server Key** cho backend
3. Enable **Firebase Cloud Messaging API**

📖 **Chi tiết:** [FCM_DEBUG_GUIDE.md](FCM_DEBUG_GUIDE.md)

### 4️⃣ **Chạy Ứng Dụng**

#### **Chế Độ Development:**
```bash
# Xem danh sách devices
flutter devices

# Chạy app
flutter run

# Chạy trên device cụ thể
flutter run -d <device-id>

# Hot reload: Nhấn 'r' trong terminal
# Hot restart: Nhấn 'R'
```

#### **Chế Độ Release:**
```bash
# Android
flutter run --release

# iOS
flutter run --release -d <ios-device-id>
```

---

## 📁 Cấu Trúc Dự Án (Kiến trúc 3 tầng)

```
uth_assistant_app/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── firebase_options.dart              # Firebase config
│   │
│   ├── config/                            # 🔧 Configuration Layer
│   │   └── app_theme.dart                 # Theme, colors, constants
│   │
│   ├── 📱 PRESENTATION LAYER (UI)
│   │   │
│   │   ├── screens/                       # Các màn hình chính
│   │   │   ├── auth/                      # Authentication screens
│   │   │   │   ├── splash_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── signup_screen.dart
│   │   │   │   └── verification_screen.dart
│   │   │   │
│   │   │   ├── home/                      # Home & Social screens
│   │   │   │   ├── main_screen.dart       # Bottom Navigation
│   │   │   │   ├── home_screen.dart       # Feed bài viết
│   │   │   │   ├── search_screen.dart     # Tìm kiếm
│   │   │   │   └── notification_screen.dart
│   │   │   │
│   │   │   ├── post/                      # Post management
│   │   │   │   ├── add_post_screen.dart
│   │   │   │   ├── post_detail_screen.dart
│   │   │   │   ├── comments_screen.dart
│   │   │   │   └── user_posts_screen.dart
│   │   │   │
│   │   │   ├── profile/                   # User profile
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   ├── complete_profile_screen.dart
│   │   │   │   └── followers_list_screen.dart
│   │   │   │
│   │   │   ├── document/                  # Document management
│   │   │   │   ├── document_screen.dart
│   │   │   │   ├── document_detail_screen.dart
│   │   │   │   ├── document_reader_screen.dart
│   │   │   │   └── upload_document_screen.dart
│   │   │   │
│   │   │   ├── wallet/                    # Payment & Wallet
│   │   │   │   ├── wallet_screen.dart
│   │   │   │   ├── transaction_history_screen.dart
│   │   │   │   ├── withdraw_screen.dart
│   │   │   │   ├── bank_account_screen.dart
│   │   │   │   └── cashout_history_screen.dart
│   │   │   │
│   │   │   ├── chatbot/                   # AI Assistant
│   │   │   │   └── chatbot_screen.dart
│   │   │   │
│   │   │   └── common/                    # Common screens
│   │   │       ├── webview_screen.dart
│   │   │       └── image_viewer_screen.dart
│   │   │
│   │   └── widgets/                       # Reusable UI components
│   │       ├── post_card.dart             # Card hiển thị bài viết
│   │       ├── comment_card.dart          # Card bình luận
│   │       ├── user_avatar.dart           # Avatar người dùng
│   │       ├── document_card.dart         # Card tài liệu
│   │       ├── loading_indicator.dart     # Loading widget
│   │       ├── custom_button.dart         # Button tùy chỉnh
│   │       └── ...
│   │
│   ├── 🧠 BUSINESS LOGIC LAYER
│   │   │
│   │   └── providers/                     # State management (nếu dùng Provider)
│   │       ├── auth_provider.dart         # Quản lý state authentication
│   │       ├── post_provider.dart         # Quản lý state bài viết
│   │       ├── user_provider.dart         # Quản lý state user
│   │       ├── document_provider.dart     # Quản lý state tài liệu
│   │       └── wallet_provider.dart       # Quản lý state ví
│   │
│   └── 💾 DATA LAYER
│       │
│       ├── models/                        # Data models (Entities)
│       │   ├── user_model.dart            # User entity
│       │   ├── post_model.dart            # Post entity
│       │   ├── comment_model.dart         # Comment entity
│       │   ├── document_model.dart        # Document entity
│       │   ├── notification_model.dart    # Notification entity
│       │   ├── transaction_model.dart     # Transaction entity
│       │   └── ...
│       │
│       ├── services/                      # API Services (Data source)
│       │   ├── api_client.dart            # HTTP client base
│       │   ├── auth_service.dart          # Authentication API
│       │   ├── post_service.dart          # Post API calls
│       │   ├── comment_service.dart       # Comment API calls
│       │   ├── document_service.dart      # Document API calls
│       │   ├── payment_service.dart       # Payment API calls
│       │   ├── notification_service.dart  # Notification API
│       │   ├── follow_service.dart        # Follow/Unfollow API
│       │   ├── search_service.dart        # Search API
│       │   ├── chatbot_service.dart       # Chatbot API
│       │   ├── fcm_service.dart           # Firebase Cloud Messaging
│       │   ├── profile_service.dart       # Profile API
│       │   ├── transaction_service.dart   # Transaction API
│       │   ├── cashout_service.dart       # Cashout API
│       │   └── upload_service.dart        # File upload service
│       │
│       └── utils/                         # Utilities & Helpers
│           ├── validators.dart            # Form validation
│           ├── constants.dart             # App constants
│           ├── helpers.dart               # Helper functions
│           ├── date_formatter.dart        # Date formatting
│           └── string_extensions.dart     # String extensions
│
├── assets/                                # 🎨 Static assets
│   ├── images/                            # App images
│   │   ├── app_icon.png
│   │   └── ic_foreground.png
│   ├── images_pic/                        # Other images
│   └── screenshots/                       # App screenshots
│       ├── splashscreen.png
│       ├── homescreen.png
│       ├── documentscreen.png
│       ├── chatbotscreen.png
│       └── walletscreen.png
│
├── fonts/                                 # 🔤 Custom fonts
│   ├── LazyDog-Regular.ttf
│   ├── Pacifico-Regular.ttf
│   ├── BeVietnamPro-Medium.ttf
│   ├── Montserrat-BoldItalic.ttf
│   └── Poppins-BoldItalic.ttf
│
├── android/                               # 🤖 Android configuration
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json           # Firebase config (gitignore)
│   │   └── src/
│   └── gradle/
│
├── ios/                                   # 🍎 iOS configuration
│   ├── Runner/
│   │   ├── GoogleService-Info.plist       # Firebase config (gitignore)
│   │   └── Info.plist
│   └── Runner.xcodeproj/
│
├── pubspec.yaml                           # 📦 Dependencies & Assets
├── analysis_options.yaml                  # 📏 Lint rules
└── README.md                              # 📖 Documentation
```

### 🏗️ Giải thích Kiến trúc 3 tầng

#### 1. **📱 Presentation Layer (UI)**
- **Trách nhiệm:** Hiển thị giao diện, nhận input từ user
- **Bao gồm:** `screens/` và `widgets/`
- **Nguyên tắc:** Chỉ chứa code UI, không có business logic hay API calls trực tiếp

#### 2. **🧠 Business Logic Layer**
- **Trách nhiệm:** Xử lý logic nghiệp vụ, quản lý state
- **Bao gồm:** `providers/` (hoặc `controllers/`, `blocs/`)
- **Nguyên tắc:** Là cầu nối giữa UI và Data, xử lý các quy tắc nghiệp vụ

#### 3. **💾 Data Layer**
- **Trách nhiệm:** Truy xuất và lưu trữ dữ liệu
- **Bao gồm:** `models/`, `services/`, `utils/`
- **Nguyên tắc:** Giao tiếp với API, database, xử lý dữ liệu thô

### 📊 Luồng dữ liệu (Data Flow)
```
User Input → Screen (UI) → Provider (Logic) → Service (API) → Backend
                ↓                ↓                 ↓
           Widgets ←─────── State ←────────── Response
```

---

## 🔧 Build Production

### **Android**

#### **Build APK:**
```bash
flutter build apk --release
```
📦 **File output:** `build/app/outputs/flutter-apk/app-release.apk`

#### **Build App Bundle (Google Play):**
```bash
flutter build appbundle --release
```
📦 **File output:** `build/app/outputs/bundle/release/app-release.aab`

### **iOS**
```bash
flutter build ios --release
```

⚠️ **Lưu ý:** Cần MacOS và Xcode để build iOS

---

## 📖 Tài Liệu

| Tài liệu | Mô tả |
|----------|-------|
| [FCM_DEBUG_GUIDE.md](FCM_DEBUG_GUIDE.md) | Hướng dẫn cấu hình & debug Firebase Cloud Messaging |
| [PAYMENT_TESTING_GUIDE.md](PAYMENT_TESTING_GUIDE.md) | Test thanh toán VNPay & MoMo |
| [CUSTOM_NOTIFICATION_GUIDE.md](CUSTOM_NOTIFICATION_GUIDE.md) | Custom notification UI |
| [EDIT_PROFILE_DOCS.md](EDIT_PROFILE_DOCS.md) | Chức năng chỉnh sửa profile |
| [TOKEN_REFRESH_TEST_GUIDE.md](TOKEN_REFRESH_TEST_GUIDE.md) | Test refresh FCM token |

---

## 🎯 Hướng Dẫn Sử Dụng

### **1. Đăng Ký Tài Khoản**
1. Mở app → Chọn **"Đăng ký"**
2. Nhập: Họ tên, Email, Username, Mật khẩu
3. Xác thực email qua link được gửi
4. Đăng nhập với tài khoản vừa tạo

### **2. Tạo & Tương Tác Bài Viết**
1. Tab **"Trang chủ"** → Nhấn nút **"+"**
2. Viết nội dung, thêm hình ảnh/video
3. Nhấn **"Đăng bài"**
4. Thích, bình luận, chia sẻ bài viết của người khác
5. Theo dõi người dùng để xem bài viết của họ

### **3. Tìm Kiếm Toàn Cục**
1. Nhấn icon **🔍 Tìm kiếm**
2. Nhập từ khóa
3. Xem kết quả: **Người dùng**, **Bài viết**, **Tài liệu**
4. Nhấn vào kết quả để xem chi tiết

### **4. Upload & Mua Tài Liệu**

#### **Upload tài liệu:**
1. Tab **"Tài liệu"** → Nhấn **"+"**
2. Chọn file (PDF/DOC/PPT)
3. Nhập: Tiêu đề, Mô tả, Giá (điểm)
4. Upload → Tài liệu sẽ hiển thị trên thư viện

#### **Mua tài liệu:**
1. Tìm tài liệu cần tải
2. Nhấn **"Mua với X điểm"**
3. Xác nhận → Điểm sẽ bị trừ
4. Tải về hoặc đọc trực tiếp

### **5. Nạp Điểm & Rút Tiền**

#### **Nạp điểm:**
1. Tab **"Ví"** → Nhấn **"Nạp điểm"**
2. Nhập số tiền (VND)
3. Chọn **VNPay** hoặc **MoMo**
4. Thanh toán qua WebView
5. Điểm sẽ được cộng tự động (100 VND = 1 điểm)

#### **Rút tiền:**
1. Liên kết tài khoản ngân hàng
2. Tab **"Ví"** → **"Rút tiền"**
3. Nhập số điểm muốn rút
4. Chờ duyệt (1-3 ngày)

### **6. Sử Dụng Chatbot AI**
1. Tab **"Chatbot"**
2. Nhập câu hỏi về học tập, thông tin trường
3. Chatbot sẽ trả lời tự động

### **7. Quản Lý Thông Báo**
1. Nhấn icon **🔔 Thông báo**
2. Xem: Lượt theo dõi, bình luận, thích, mua tài liệu
3. Nhấn vào thông báo để xem chi tiết

---

## 🐛 Xử Lý Lỗi Thường Gặp

### ❌ **Lỗi Firebase**
**Triệu chứng:** `[firebase_core/no-app] No Firebase App '[DEFAULT]' has been created`

**Giải pháp:**
1. Đảm bảo đã download `google-services.json` & `GoogleService-Info.plist`
2. Chạy lại `flutterfire configure`:
   ```bash
   flutterfire configure
   ```
3. Clean & rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### ❌ **Push Notification không hoạt động**
**Triệu chứng:** Không nhận được thông báo khi follow/comment/like

**Giải pháp:**
1. Kiểm tra FCM token:
   ```dart
   // Trong main.dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

2. Kiểm tra permission:
   ```bash
   # Android: Vào Settings → Apps → UTH Student → Notifications → Bật
   # iOS: Settings → Notifications → UTH Student → Allow Notifications
   ```

3. Test thủ công qua Firebase Console:
   - Firebase Console → **Cloud Messaging** → **Send test message**
   - Dán FCM token vào

📖 **Chi tiết:** [FCM_DEBUG_GUIDE.md](FCM_DEBUG_GUIDE.md)

---

### ❌ **Lỗi Build Android**
**Triệu chứng:** `Execution failed for task ':app:processDebugGoogleServices'`

**Giải pháp:**
1. Đảm bảo `google-services.json` đặt đúng vị trí: `android/app/`
2. Kiểm tra `package name` trong `google-services.json` khớp với `android/app/build.gradle.kts`
3. Clean project:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

---

### ❌ **Lỗi Thanh Toán**
**Triệu chứng:** WebView mở nhưng không thanh toán được

**Giải pháp:**
1. Kiểm tra kết nối internet ổn định
2. Đảm bảo đã cấp quyền truy cập internet cho app
3. Thử lại với số tiền khác
4. Kiểm tra tài khoản thanh toán có đủ số dư

📖 **Chi tiết:** [PAYMENT_TESTING_GUIDE.md](PAYMENT_TESTING_GUIDE.md)

---

### ❌ **Lỗi Upload File**
**Triệu chứng:** `File upload failed` hoặc timeout

**Giải pháp:**
1. Kiểm tra kích thước file (max 50MB)
2. Kiểm tra định dạng file được hỗ trợ:
   - Hình ảnh: JPG, PNG, GIF
   - Tài liệu: PDF, DOC, DOCX, PPT, PPTX
3. Kiểm tra kết nối internet ổn định
4. Test upload file nhỏ trước (< 5MB)
5. Đảm bảo đã cấp quyền truy cập file cho app

---



## 📊 Screenshots

<div align="center">

### 🏠 Màn hình chính
<img src="assets/screenshots/splashscreen.png" width="200" alt="Splash Screen"/> &nbsp;&nbsp;&nbsp;
<img src="assets/screenshots/homescreen.png" width="200" alt="Home Screen"/> &nbsp;&nbsp;&nbsp;
<img src="assets/screenshots/documentscreen.png" width="200" alt="Document Screen"/>

**Màn hình khởi động** → **Trang chủ bài viết** → **Thư viện tài liệu**

---

### 🤖 Chatbot AI & 💰 Ví điểm
<img src="assets/screenshots/chatbotscreen.png" width="200" alt="Chatbot Screen"/> &nbsp;&nbsp;&nbsp;
<img src="assets/screenshots/walletscreen.png" width="200" alt="Wallet Screen"/>

**Trợ lý ảo UTH Assistant** hỗ trợ 24/7 | **Ví điểm** với thanh toán VNPay/MoMo

</div>

---

## 🤝 Đóng Góp

Chúng tôi rất hoan nghênh mọi đóng góp! Để contribute:

1. Fork repository
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit thay đổi: `git commit -m 'Thêm tính năng ABC'`
4. Push lên branch: `git push origin feature/ten-tinh-nang`
5. Tạo Pull Request

---

## 📝 License

Dự án này thuộc quyền sở hữu của **UTH Student Team**. Mọi quyền được bảo lưu.

---

## 📞 Liên Hệ & Hỗ Trợ

- 📧 **Email:** support@uthstudent.edu.vn
- 🌐 **Website:** https://uthstudent.onrender.com
- 💬 **Discord:** [UTH Student Community](https://discord.gg/uthstudent)
- 📱 **Facebook:** [UTH Student Official](https://facebook.com/uthstudent)

---

## 🌟 Credits

Phát triển bởi **UTH Student Development Team** 🎓

**Core Contributors:**
- Backend Developer: [@backend-dev](https://github.com/backend-dev)
- Mobile Developer: [@mobile-dev](https://github.com/mobile-dev)
- UI/UX Designer: [@designer](https://github.com/designer)

---

<div align="center">

**⭐ Star repository này nếu bạn thấy hữu ích! ⭐**

Made with ❤️ by UTH Students, for UTH Students

</div>
