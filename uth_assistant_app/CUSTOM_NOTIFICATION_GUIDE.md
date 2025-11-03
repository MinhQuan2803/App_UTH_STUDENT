# Custom Notification Widget - Hướng dẫn sử dụng

## 📱 Mô tả

Widget thông báo tùy chỉnh với giao diện hiện đại, sử dụng màu sắc và typography từ `app_theme.dart`. Thay thế hoàn toàn SnackBar mặc định của Flutter.

## ✨ Tính năng

- 🎨 **4 loại thông báo**: Success, Error, Warning, Info
- 💫 **Animation mượt mà**: Slide từ trên xuống với fade effect
- 🎯 **Auto-dismiss**: Tự động ẩn sau 3 giây
- 👆 **Có thể đóng thủ công**: Nút X để đóng sớm
- 📱 **Responsive**: Tự động điều chỉnh theo màn hình
- 🎨 **Sử dụng AppColors**: Đồng nhất với theme của app

## 🎨 Các loại thông báo

### 1. Success (Thành công) ✅
- **Màu**: `AppColors.success` (Xanh lá)
- **Icon**: `check_circle`
- **Khi nào dùng**: Đăng nhập thành công, đăng bài thành công, cập nhật thành công

```dart
CustomNotification.success(context, 'Đăng nhập thành công!');
```

### 2. Error (Lỗi) ❌
- **Màu**: `AppColors.danger` (Đỏ)
- **Icon**: `error`
- **Khi nào dùng**: Lỗi kết nối, validation failed, API error

```dart
CustomNotification.error(context, 'Email hoặc mật khẩu không đúng');
```

### 3. Warning (Cảnh báo) ⚠️
- **Màu**: `AppColors.warning` (Cam)
- **Icon**: `warning_amber`
- **Khi nào dùng**: Giới hạn đạt tối đa, cảnh báo người dùng

```dart
CustomNotification.warning(context, 'Chỉ được chọn tối đa 3 ảnh');
```

### 4. Info (Thông tin) ℹ️
- **Màu**: `AppColors.primary` (Xanh dương)
- **Icon**: `info`
- **Khi nào dùng**: Thông báo chung, tính năng đang phát triển

```dart
CustomNotification.info(context, 'Tính năng đang phát triển');
```

## 📖 Cách sử dụng

### Bước 1: Import widget

```dart
import '../widgets/custom_notification.dart';
```

### Bước 2: Gọi thông báo

#### Cách 1: Sử dụng method shortcut (Khuyên dùng)

```dart
// Success
CustomNotification.success(context, 'Đăng bài thành công!');

// Error
CustomNotification.error(context, 'Không thể tải dữ liệu');

// Warning
CustomNotification.warning(context, 'Bạn đã đạt giới hạn');

// Info
CustomNotification.info(context, 'Vui lòng chờ trong giây lát');
```

#### Cách 2: Sử dụng method chính với tùy chỉnh

```dart
CustomNotification.show(
  context,
  message: 'Thông báo của bạn',
  type: NotificationType.success,
  title: 'Tiêu đề tùy chỉnh', // Optional
  duration: Duration(seconds: 5), // Optional, mặc định 3 giây
);
```

## 🔄 Thay thế SnackBar cũ

### Trước đây (SnackBar mặc định):
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Đăng nhập thành công'),
    backgroundColor: AppColors.success,
  ),
);
```

### Bây giờ (Custom Notification):
```dart
CustomNotification.success(context, 'Đăng nhập thành công');
```

## 📝 Ví dụ thực tế

### 1. Xử lý đăng nhập (login_screen.dart)

```dart
Future<void> _handleSignIn() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    CustomNotification.error(context, "Vui lòng nhập đầy đủ email và mật khẩu");
    return;
  }

  try {
    final result = await _authService.signIn(email: email, password: password);
    
    if (result['success']) {
      CustomNotification.success(context, 'Đăng nhập thành công!');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      CustomNotification.error(context, result['message']);
    }
  } catch (e) {
    CustomNotification.error(context, 'Lỗi kết nối: ${e.toString()}');
  }
}
```

### 2. Đăng bài viết (add_post_screen.dart)

```dart
Future<void> _handlePost() async {
  try {
    if (_isEditMode) {
      await _postService.updatePost(...);
      CustomNotification.success(context, 'Đã cập nhật bài viết');
    } else {
      await _postService.createPost(...);
      CustomNotification.success(context, 'Đã đăng bài viết');
    }
    Navigator.pop(context);
  } catch (e) {
    CustomNotification.error(context, e.toString());
  }
}
```

### 3. Follow/Unfollow (profile_screen.dart)

```dart
Future<void> _handleFollowToggle() async {
  try {
    if (currentlyFollowing) {
      final result = await _followService.unfollowUser(userId);
      CustomNotification.success(context, result.message);
    } else {
      final result = await _followService.followUser(userId);
      CustomNotification.success(context, result.message);
    }
  } catch (e) {
    CustomNotification.error(context, e.toString());
  }
}
```

### 4. Validation (chọn ảnh)

```dart
Future<void> _pickImages() async {
  final totalImages = _selectedImages.length + images.length;
  
  if (totalImages > 3) {
    CustomNotification.warning(context, 'Chỉ được chọn tối đa 3 ảnh');
    return;
  }
  
  // Xử lý chọn ảnh...
}
```

## 🎯 Best Practices

### ✅ NÊN:
- Dùng `success` cho các action thành công (đăng nhập, đăng bài, update)
- Dùng `error` cho lỗi thực sự (API fail, validation fail)
- Dùng `warning` cho cảnh báo không phải lỗi (giới hạn, điều kiện)
- Dùng `info` cho thông báo chung (tính năng đang làm)
- Message ngắn gọn, rõ ràng (1-2 dòng)

### ❌ KHÔNG NÊN:
- Hiển thị notification liên tục (spam)
- Message quá dài (>3 dòng)
- Dùng sai loại notification (error cho info)
- Hiển thị technical error trực tiếp cho user

## 🔧 Tùy chỉnh

### Thay đổi thời gian hiển thị:
```dart
CustomNotification.show(
  context,
  message: 'Thông báo quan trọng',
  type: NotificationType.info,
  duration: Duration(seconds: 10), // Hiển thị 10 giây
);
```

### Tùy chỉnh title:
```dart
CustomNotification.show(
  context,
  message: 'Bài viết đã được lưu vào nháp',
  type: NotificationType.success,
  title: 'Lưu nháp', // Thay vì "Thành công"
);
```

## 📂 File structure

```
lib/
  widgets/
    custom_notification.dart  ← Widget mới
  screens/
    login_screen.dart         ← Đã cập nhật
    add_post_screen.dart      ← Đã cập nhật  
    profile_screen.dart       ← Đã cập nhật
  config/
    app_theme.dart            ← Sử dụng AppColors
```

## 🎨 Màu sắc được sử dụng

Tất cả màu từ `AppColors` trong `app_theme.dart`:

- `AppColors.success` - Xanh lá (Success)
- `AppColors.danger` - Đỏ (Error)
- `AppColors.warning` - Cam (Warning)
- `AppColors.primary` - Xanh dương (Info)
- `AppColors.white` - Trắng (Background)
- `AppColors.text` - Đen (Message text)
- `AppColors.subtitle` - Xám (Close button)

## 🚀 Migration Guide

Để chuyển toàn bộ app sang CustomNotification:

1. Find & Replace trong tất cả files:
   - Tìm: `ScaffoldMessenger.of(context).showSnackBar`
   - Xem xét từng trường hợp và thay bằng `CustomNotification`

2. Xác định loại notification phù hợp:
   - `backgroundColor: AppColors.success` → `CustomNotification.success`
   - `backgroundColor: AppColors.danger` → `CustomNotification.error`
   - `backgroundColor: AppColors.warning` → `CustomNotification.warning`
   - Còn lại → `CustomNotification.info`

3. Đơn giản hóa message:
   ```dart
   // Trước
   SnackBar(content: Text(message), backgroundColor: color)
   
   // Sau
   CustomNotification.success(context, message)
   ```

## 💡 Tips

- **Loading states**: Không nên dùng notification cho loading, dùng CircularProgressIndicator
- **Confirm actions**: Dùng Dialog cho confirm, không dùng notification
- **Form errors**: Validation errors nên hiển thị dưới field, không dùng notification
- **Multiple notifications**: Nếu cần hiển thị nhiều, chúng sẽ xếp chồng lên nhau (overlay system)

## 🎉 Kết quả

Bạn đã có một hệ thống thông báo hiện đại, đẹp mắt và nhất quán trong toàn bộ app!
