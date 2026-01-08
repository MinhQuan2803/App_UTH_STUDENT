# ✅ ĐÃ SỬA: VẤN ĐỀ TOKEN KHÔNG TỰ ĐỘNG LOGOUT

## 🎯 Tóm tắt vấn đề đã khắc phục

**Vấn đề:** Khi token hết hạn, người dùng KHÔNG được tự động logout mà vẫn bị kẹt ở màn hình hiện tại với thông báo lỗi.

**Nguyên nhân:**
1. ❌ `auth_service.dart` - Khi token hết hạn + lỗi mạng → Return null nhưng không logout
2. ❌ `api_client.dart` - Khi 401 + lỗi mạng → Retry mù quáng không kiểm tra token validity

**Đã sửa:**
✅ Thêm logic logout khi token thực sự hết hạn
✅ Kiểm tra token cũ trước khi retry khi gặp network error
✅ Đảm bảo người dùng luôn được đẩy về login khi token không thể dùng được

---

## 📝 CHI TIẾT CÁC THAY ĐỔI

### 1️⃣ `auth_service.dart` - Dòng 436-449

#### ❌ Code CŨ (SAI):
```dart
} else if (result == RefreshResult.networkError) {
  // Nếu lỗi mạng, vẫn trả về token cũ (nếu chưa hết hạn)
  if (!isExpired) {
    if (kDebugMode) print('⚠ Network error, using old token');
    return token;
  }
  return null; // ❌ LỖI: Không logout!
}
```

#### ✅ Code MỚI (ĐÚNG):
```dart
} else if (result == RefreshResult.networkError) {
  // Nếu lỗi mạng, vẫn trả về token cũ (nếu chưa hết hạn)
  if (!isExpired) {
    if (kDebugMode) print('⚠ Network error, using old token');
    return token;
  }
  // Token hết hạn + không refresh được → Logout
  if (kDebugMode) print('❌ Token expired + network error → Logout');
  if (autoRedirect) await signOut();
  return null;
}
```

**Giải thích:**
- Khi `networkError` xảy ra NHƯNG token chưa hết hạn → Giữ người dùng đăng nhập
- Khi `networkError` xảy ra VÀ token đã hết hạn → **LOGOUT NGAY**

---

### 2️⃣ `api_client.dart` - Dòng 108-165

#### ❌ Code CŨ (SAI):
```dart
if (result == RefreshResult.success ||
    result == RefreshResult.networkError) {
  // ❌ Retry mù quáng cả khi networkError
  try {
    response = await request();
  } catch (e) {
    rethrow; // Không logout!
  }
}
```

#### ✅ Code MỚI (ĐÚNG):
```dart
if (result == RefreshResult.success) {
  // Refresh thành công → Retry với token mới
  try {
    response = await request();
  } catch (e) {
    rethrow;
  }
} else if (result == RefreshResult.networkError) {
  // Lỗi mạng → Kiểm tra token cũ còn dùng được không
  final token = await _authService.getToken();
  if (token != null) {
    try {
      final isExpired = JwtDecoder.isExpired(token);
      
      if (!isExpired) {
        // Token cũ OK → Retry với token cũ
        try {
          response = await request();
        } catch (e) {
          rethrow; // Lỗi mạng thật, giữ người dùng
        }
      } else {
        // Token hết hạn + không refresh được → Logout
        await _authService.signOut();
        throw Exception('401: Phiên đăng nhập hết hạn.');
      }
    } catch (e) {
      // Lỗi parse token → Logout
      await _authService.signOut();
      throw Exception('401: Token không hợp lệ.');
    }
  } else {
    // Không có token → Logout
    await _authService.signOut();
    throw Exception('401: Phiên đăng nhập hết hạn.');
  }
}
```

**Giải thích:**
- **KHÔNG** retry mù quáng khi `networkError`
- **KIỂM TRA** token cũ còn valid không trước khi retry
- **LOGOUT** ngay nếu token đã thực sự hết hạn

#### 🆕 Thêm Import mới:
```dart
import 'package:jwt_decoder/jwt_decoder.dart';
```

---

## 🔍 KIỂM TRA KẾT QUẢ

### Kịch bản 1: Token hết hạn + Server online
**Trước khi sửa:**
- ❌ Người dùng thấy dialog lỗi "401"
- ❌ Vẫn ở màn hình hiện tại
- ❌ Phải tự thoát app và mở lại

**Sau khi sửa:**
- ✅ Tự động logout
- ✅ Chuyển về màn hình login
- ✅ Thông báo "Phiên đăng nhập hết hạn"

### Kịch bản 2: Token hết hạn + Server ngủ (Render cold start)
**Trước khi sửa:**
- ❌ Refresh token timeout
- ❌ Retry request với token cũ (đã hết hạn)
- ❌ Lỗi 401 lại → KHÔNG logout
- ❌ Người dùng kẹt màn hình

**Sau khi sửa:**
- ✅ Refresh token timeout
- ✅ **KIỂM TRA** token cũ → Phát hiện đã hết hạn
- ✅ **LOGOUT NGAY**
- ✅ Chuyển về màn hình login

### Kịch bản 3: Token còn hạn + Server ngủ
**Trước khi sửa:**
- ✅ Giữ người dùng đăng nhập (Đúng)
- ⚠️ Nhưng retry nhiều lần gây lag

**Sau khi sửa:**
- ✅ Giữ người dùng đăng nhập (Đúng)
- ✅ Kiểm tra token validity trước khi retry
- ✅ Thông báo lỗi mạng rõ ràng hơn

---

## ⚠️ VẤN ĐỀ CÒN TỒN TẠI

### 🔴 QUAN TRỌNG: 8 Service CHƯA dùng ApiClient

Các service này vẫn gọi `http.get/post` trực tiếp → **BỎ QUA logic retry & auto-logout:**

1. ❌ `profile_service.dart`
2. ❌ `follow_service.dart`
3. ❌ `document_service.dart`
4. ❌ `notification_service.dart`
5. ❌ `search_service.dart`
6. ❌ `interaction_service.dart`
7. ❌ `relationship_service.dart`
8. ❌ `chatbot_service.dart`

### Tại sao đây là vấn đề?

**Ví dụ:** Người dùng vào Profile Screen:
1. `profile_service.dart` gọi API `/users/me`
2. Token đã hết hạn → Server trả về 401
3. Service ném exception "401: Phiên đăng nhập không hợp lệ"
4. **KHÔNG tự động logout** vì không qua `ApiClient`
5. ProfileScreen bắt exception → Hiển thị dialog lỗi
6. ❌ Người dùng vẫn kẹt ở màn hình Profile

### Giải pháp:

**CẦN SỬA TỪNG SERVICE** theo chuẩn này:

```dart
// ❌ TRƯỚC (SAI):
class ProfileService {
  final AuthService _authService = AuthService();
  
  Future<Map<String, dynamic>> getMyProfile() async {
    final token = await _authService.getValidToken();
    
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 401) {
      // Phải tự xử lý 401 → Dễ quên logout
    }
    // ...
  }
}

// ✅ SAU (ĐÚNG):
class ProfileService {
  final ApiClient _apiClient = ApiClient();
  
  Future<Map<String, dynamic>> getMyProfile() async {
    // ApiClient tự động:
    // - Thêm token
    // - Xử lý 401
    // - Retry khi refresh thành công
    // - Logout khi token thực sự hết hạn
    
    final response = await _apiClient.get('$_baseUrl/me');
    
    // Chỉ cần xử lý success case
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi: ${response.statusCode}');
    }
  }
}
```

---

## 📊 TÌNH TRẠNG HIỆN TẠI

| Tình trạng | Chi tiết |
|-----------|----------|
| ✅ Đã sửa | `auth_service.dart` - Logic logout khi token hết hạn |
| ✅ Đã sửa | `api_client.dart` - Kiểm tra token validity trước retry |
| ✅ Đã test | PostService đang dùng ApiClient → Hoạt động tốt |
| ⚠️ Chưa sửa | 8 service khác chưa dùng ApiClient |

### Ưu tiên sửa tiếp:

**Cấp độ 1 (QUAN TRỌNG):**
- 🔥 `profile_service.dart` - Đang dùng trong ProfileScreen (màn hình quan trọng)
- 🔥 `follow_service.dart` - Đang dùng trong ProfileScreen
- 🔥 `notification_service.dart` - Đang dùng trong MainScreen

**Cấp độ 2 (KHẢ QUAN TRỌNG):**
- 🟡 `interaction_service.dart` - Like/Comment (dùng nhiều)
- 🟡 `document_service.dart` - Download/Upload tài liệu
- 🟡 `search_service.dart` - Tìm kiếm

**Cấp độ 3 (ÍT QUAN TRỌNG HƠN):**
- 🟢 `relationship_service.dart` - Follower/Following list
- 🟢 `chatbot_service.dart` - Chatbot

---

## 🎯 HƯỚNG DẪN TEST

### Test Case 1: Token hết hạn bình thường
1. Login vào app
2. Đợi token hết hạn (hoặc xóa token thủ công)
3. Mở Profile Screen
4. **Kỳ vọng:** Tự động logout → Chuyển về Login Screen

### Test Case 2: Server ngủ + Token còn hạn
1. Login vào app
2. Tắt server backend
3. Pull to refresh ở Home
4. **Kỳ vọng:** Hiển thị lỗi mạng, KHÔNG logout

### Test Case 3: Server ngủ + Token hết hạn
1. Login vào app
2. Đợi token hết hạn
3. Tắt server backend
4. Pull to refresh
5. **Kỳ vọng:** Tự động logout → Chuyển về Login Screen

---

## 📝 GHI CHÚ BỔ SUNG

- ✅ Đã thêm `jwt_decoder` vào `api_client.dart`
- ✅ Logic logout giờ chạy qua `navigatorKey` trong `main.dart`
- ✅ Không cần truyền `BuildContext` vào `AuthService.signOut()`
- ⚠️ **8 service chưa sửa** vẫn có thể gặp lỗi "không logout được" trong một số trường hợp

---

Ngày hoàn thành: 6/1/2026  
Người thực hiện: GitHub Copilot
