# 🔴 BÁO CÁO VẤN ĐỀ AUTHENTICATION & TOKEN

## Ngày phát hiện: 6/1/2026

---

## 🚨 VẤN ĐỀ 1: CÁC SERVICE KHÔNG SỬ DỤNG ApiClient

### Danh sách service gọi HTTP trực tiếp (BỎ QUA logic retry & auto-logout):

| Service | File | Vấn đề |
|---------|------|--------|
| ProfileService | `profile_service.dart` | Gọi `http.get` trực tiếp tại line 50 |
| FollowService | `follow_service.dart` | Gọi `http.get/post` trực tiếp tại line 35, 68 |
| DocumentService | `document_service.dart` | Gọi `http.get/post` trực tiếp tại line 189, 209, 225 |
| NotificationService | `notification_service.dart` | Gọi `http.get` trực tiếp tại line 29, 159 |
| SearchService | `search_service.dart` | Gọi `http.get` trực tiếp tại line 30 |
| InteractionService | `interaction_service.dart` | Gọi `http.get/post` trực tiếp tại line 38, 117, 155, 275 |
| RelationshipService | `relationship_service.dart` | Gọi `http.get` trực tiếp tại line 36, 79 |
| ChatbotService | `chatbot_service.dart` | Gọi `http.post` trực tiếp tại line 16 |

### Hậu quả:
- ❌ Khi token hết hạn (401), service này trả về exception nhưng **KHÔNG tự động logout**
- ❌ Người dùng thấy dialog báo lỗi thay vì quay về màn hình login
- ❌ Không có retry khi refresh token thành công
- ❌ Không xử lý đồng nhất lỗi network timeout

### Giải pháp:
**Thay thế TẤT CẢ các lời gọi `http.get/post/put/delete` bằng `ApiClient`:**

```dart
// ❌ SAI - Gọi trực tiếp
final response = await http.get(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);

// ✅ ĐÚNG - Dùng ApiClient
final ApiClient _apiClient = ApiClient();

final response = await _apiClient.get(url);
// ApiClient tự động thêm token, retry khi 401, và logout khi cần
```

---

## 🚨 VẤN ĐỀ 2: LOGIC getValidToken() KHÔNG LOGOUT KHI CẦN

### Vị trí: `auth_service.dart` - line 264-287

```dart
Future<String?> getValidToken({bool autoRedirect = true}) async {
  final token = await getToken();
  if (token == null) {
    if (autoRedirect) await signOut();
    return null;
  }

  bool isExpired = JwtDecoder.isExpired(token);
  Duration remainingTime = Duration.zero;
  
  try {
    remainingTime = JwtDecoder.getRemainingTime(token);
  } catch (e) {
    isExpired = true;
  }

  bool aboutToExpire = !isExpired && remainingTime.inSeconds < 120;

  if (isExpired || aboutToExpire) {
    final result = await refreshAccessToken();

    if (result == RefreshResult.success) {
      return await getToken();
    } else if (result == RefreshResult.networkError) {
      // ⚠️ VẤN ĐỀ: Khi lỗi mạng + token hết hạn → trả null NHƯNG không logout
      if (!isExpired) {
        return token; // OK: Token cũ vẫn dùng được
      }
      return null; // ❌ LỖI: Không gọi signOut()
    } else {
      if (autoRedirect) await signOut();
      return null;
    }
  }
  return token;
}
```

### Vấn đề:
Khi:
1. Token đã hết hạn (`isExpired = true`)
2. Refresh token gặp lỗi mạng (`RefreshResult.networkError`)
3. Hàm trả về `null` nhưng **KHÔNG gọi `signOut()`**

→ Người dùng vẫn ở màn hình hiện tại, không được đẩy về login

### Giải pháp:
**Thêm logic logout khi networkError + expired:**

```dart
} else if (result == RefreshResult.networkError) {
  if (!isExpired) {
    // Token cũ vẫn dùng được, giữ người dùng đăng nhập
    if (kDebugMode) print('⚠ Network error, using old token');
    return token;
  }
  // Token hết hạn + không refresh được → Logout
  if (autoRedirect) await signOut();
  return null;
} else {
```

---

## 🚨 VẤN ĐỀ 3: API_CLIENT KHÔNG LOGOUT SAU KHI REFRESH LỖI NETWORK

### Vị trí: `api_client.dart` - line 101-120

```dart
if (response.statusCode == 401) {
  final result = await _authService.refreshAccessToken();

  if (result == RefreshResult.success ||
      result == RefreshResult.networkError) {
    // ⚠️ VẤN ĐỀ: Retry cả khi networkError
    try {
      response = await request();
    } catch (e) {
      rethrow; // ❌ Ném lỗi nhưng không logout
    }
  } else {
    await _authService.signOut();
    throw Exception('401: Phiên đăng nhập hết hạn.');
  }
}
```

### Vấn đề:
Khi:
1. Request gặp 401
2. Refresh token gặp lỗi network (`RefreshResult.networkError`)
3. Retry request vẫn lỗi → `rethrow`
4. **Không logout** → Người dùng thấy lỗi nhưng vẫn ở màn hình cũ

### Giải pháp:
**Kiểm tra token còn hợp lệ trước khi retry:**

```dart
if (result == RefreshResult.success) {
  // Refresh thành công → Retry
  try {
    response = await request();
  } catch (e) {
    rethrow;
  }
} else if (result == RefreshResult.networkError) {
  // Lỗi mạng → Kiểm tra token cũ còn dùng được không
  final token = await _authService.getToken();
  if (token != null && !JwtDecoder.isExpired(token)) {
    // Token cũ OK → Retry với token cũ
    try {
      response = await request();
    } catch (e) {
      rethrow; // Lỗi mạng, giữ người dùng đăng nhập
    }
  } else {
    // Token hết hạn + không refresh được → Logout
    await _authService.signOut();
    throw Exception('401: Phiên đăng nhập hết hạn.');
  }
} else {
  // RefreshResult.failed → Logout
  await _authService.signOut();
  throw Exception('401: Phiên đăng nhập hết hạn.');
}
```

---

## 📋 KẾ HOẠCH SỬA CHỮA (Theo thứ tự ưu tiên)

### 🔥 QUAN TRỌNG NHẤT - Sửa ngay:

1. **Sửa `auth_service.dart`** - Thêm logout khi networkError + expired
2. **Sửa `api_client.dart`** - Kiểm tra token trước khi retry

### 🔄 QUAN TRỌNG - Sửa theo từng service:

3. **Chuyển ProfileService sang ApiClient** (Đang dùng trong ProfileScreen)
4. **Chuyển FollowService sang ApiClient** (Đang dùng trong ProfileScreen)
5. **Chuyển NotificationService sang ApiClient** (Đang dùng trong MainScreen)
6. **Chuyển InteractionService sang ApiClient** (Đang dùng trong HomePostCard)
7. **Chuyển DocumentService sang ApiClient** (Đang dùng trong DocumentScreen)
8. **Chuyển SearchService sang ApiClient** (Đang dùng trong SearchScreen)
9. **Chuyển RelationshipService sang ApiClient**
10. **Chuyển ChatbotService sang ApiClient**

---

## ✅ CHUẨN MỰC KHI SỬA

### 1. Thay thế HTTP trực tiếp bằng ApiClient:

```dart
// Khai báo ApiClient trong service
class MyService {
  final ApiClient _apiClient = ApiClient();
  
  Future<void> myFunction() async {
    // Không cần lấy token thủ công
    // Không cần xử lý 401 thủ công
    // ApiClient tự động làm tất cả
    
    final response = await _apiClient.get(url);
    
    // Xử lý response như bình thường
    if (response.statusCode == 200) {
      // ...
    }
  }
}
```

### 2. Loại bỏ logic refresh token thủ công:

```dart
// ❌ XÓA các đoạn code kiểu này:
final token = await _authService.getValidToken();
if (token == null) {
  throw Exception('Chưa đăng nhập');
}

// ✅ ApiClient tự động xử lý
```

### 3. Xóa try-catch xử lý 401 thủ công:

```dart
// ❌ XÓA các đoạn code kiểu này:
if (response.statusCode == 401) {
  // Tự xử lý refresh
}

// ✅ ApiClient tự động retry và logout
```

---

## 🎯 KẾT QUẢ MONG ĐỢI SAU KHI SỬA

✅ Khi token hết hạn → Tự động logout → Chuyển về màn hình login  
✅ Khi server ngủ (network error) → Giữ người dùng đăng nhập → Hiển thị thông báo lỗi mạng  
✅ Mọi service xử lý token đồng nhất qua ApiClient  
✅ Không còn tình trạng "hết phiên nhưng vẫn ở màn hình cũ"  

---

## 📌 GHI CHÚ

- **Không xóa code cũ ngay**, test kỹ từng service sau khi sửa
- **Giữ nguyên cache logic** trong các service (không ảnh hưởng đến performance)
- **Test kịch bản:** Để token hết hạn → Reload màn hình → Kiểm tra có logout không

---

Người lập báo cáo: GitHub Copilot  
Ngày: 6/1/2026
