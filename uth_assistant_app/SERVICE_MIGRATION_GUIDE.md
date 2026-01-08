# ✅ HƯỚNG DẪN CẬP NHẬT CÁC SERVICE SANG ApiClient

## 📊 TIẾN ĐỘ

| Service | Trạng thái | Ghi chú |
|---------|------------|---------|
| ✅ ProfileService | **Hoàn thành** | Đã chuyển sang ApiClient |
| ✅ FollowService | **Hoàn thành** | Đã chuyển sang ApiClient |
| ⏳ NotificationService | **Cần sửa** | Đang gọi http trực tiếp |
| ⏳ InteractionService | **Cần sửa** | Đang gọi http trực tiếp |
| ⏳ DocumentService | **Cần sửa** | Đang gọi http trực tiếp |
| ⏳ SearchService | **Cần sửa** | Đang gọi http trực tiếp |
| ⏳ RelationshipService | **Cần sửa** | Đang gọi http trực tiếp |
| ⏳ ChatbotService | **Cần sửa** | Đang gọi http trực tiếp |

---

## 📝 TEMPLATE CHUYỂN ĐỔI

### Bước 1: Thêm import ApiClient

```dart
// ❌ CŨ
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MyService {
  final AuthService _authService = AuthService();
  
  Future<String?> _getToken() async {
    return await _authService.getValidToken();
  }
}

// ✅ MỚI
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_client.dart'; // THÊM IMPORT

class MyService {
  final ApiClient _apiClient = ApiClient(); // THÊM ApiClient
  // XÓA: final AuthService _authService và _getToken()
}
```

### Bước 2: Chuyển GET requests

```dart
// ❌ CŨ
Future<List<Data>> getData() async {
  final token = await _authService.getValidToken();
  
  if (token == null) {
    throw Exception('401: Chưa đăng nhập');
  }
  
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  
  final response = await http.get(
    Uri.parse('$_baseUrl/data'),
    headers: headers,
  ).timeout(const Duration(seconds: 20));
  
  if (response.statusCode == 200) {
    // Parse data
  } else if (response.statusCode == 401) {
    throw Exception('401: Phiên đăng nhập không hợp lệ');
  } else {
    throw Exception('Lỗi Server: ${response.statusCode}');
  }
}

// ✅ MỚI
Future<List<Data>> getData() async {
  // ApiClient tự động thêm token và xử lý 401
  final response = await _apiClient.get(
    '$_baseUrl/data',
    timeout: const Duration(seconds: 20),
  );
  
  if (response.statusCode == 200) {
    // Parse data
  } else {
    throw Exception('Lỗi Server: ${response.statusCode}');
  }
}
```

### Bước 3: Chuyển POST requests

```dart
// ❌ CŨ
Future<void> postData(Map<String, dynamic> data) async {
  final token = await _authService.getValidToken();
  
  if (token == null) {
    throw Exception('401: Chưa đăng nhập');
  }
  
  final response = await http.post(
    Uri.parse('$_baseUrl/data'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(data),
  );
  
  if (response.statusCode == 200) {
    // Success
  } else if (response.statusCode == 401) {
    throw Exception('401: Phiên đăng nhập không hợp lệ');
  }
}

// ✅ MỚI
Future<void> postData(Map<String, dynamic> data) async {
  final response = await _apiClient.post(
    '$_baseUrl/data',
    body: data, // ApiClient tự động jsonEncode
  );
  
  if (response.statusCode == 200) {
    // Success
  } else {
    throw Exception('Lỗi Server: ${response.statusCode}');
  }
}
```

### Bước 4: Chuyển DELETE requests

```dart
// ❌ CŨ
Future<void> deleteData(String id) async {
  final token = await _authService.getValidToken();
  
  if (token == null) {
    throw Exception('401: Chưa đăng nhập');
  }
  
  final response = await http.delete(
    Uri.parse('$_baseUrl/data/$id'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  
  // Handle response...
}

// ✅ MỚI
Future<void> deleteData(String id) async {
  final response = await _apiClient.delete('$_baseUrl/data/$id');
  // Handle response...
}
```

### Bước 5: Chuyển PUT/PATCH requests

```dart
// ❌ CŨ
Future<void> updateData(String id, Map<String, dynamic> data) async {
  final token = await _authService.getValidToken();
  
  if (token == null) {
    throw Exception('401: Chưa đăng nhập');
  }
  
  final response = await http.put(
    Uri.parse('$_baseUrl/data/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(data),
  );
}

// ✅ MỚI  
Future<void> updateData(String id, Map<String, dynamic> data) async {
  final response = await _apiClient.put(
    '$_baseUrl/data/$id',
    body: data,
  );
}
```

---

## 🎯 CHECKLIST SAU KHI SỬA

Sau khi chuyển đổi xong một service, kiểm tra:

- [ ] ✅ Đã import `api_client.dart`
- [ ] ✅ Đã khai báo `final ApiClient _apiClient = ApiClient();`
- [ ] ✅ Đã xóa `_authService` (nếu chỉ dùng để lấy token)
- [ ] ✅ Đã xóa `_getToken()` (nếu có)
- [ ] ✅ Đã xóa tất cả logic kiểm tra `if (token == null)`
- [ ] ✅ Đã xóa tất cả xử lý `if (response.statusCode == 401)`
- [ ] ✅ Đã thay `http.get/post/put/delete` bằng `_apiClient.get/post/put/delete`
- [ ] ✅ Đã xóa `Uri.parse()` (ApiClient nhận String trực tiếp)
- [ ] ✅ Đã xóa `jsonEncode()` trong body (ApiClient tự động encode)
- [ ] ✅ Test lại service sau khi sửa

---

## 📋 CHI TIẾT CÁC SERVICE CẦN SỬA

### 1. NotificationService (`notification_service.dart`)

**Các function cần sửa:**
- `getNotifications()` - line 29: dùng `http.get` trực tiếp
- `getUserNotifications()` - line 159: dùng `http.get` trực tiếp

**Độ ưu tiên:** 🔥🔥🔥 QUAN TRỌNG (dùng trong MainScreen)

**Cách sửa:**
```dart
// Thêm import
import 'api_client.dart';

// Thay AuthService bằng ApiClient
final ApiClient _apiClient = ApiClient();

// Trong getNotifications():
final response = await _apiClient.get('$_baseUrl/uth/thongbaouth');

// Trong getUserNotifications():
final response = await _apiClient.get('$_userNotifBaseUrl/me/notifications');
```

---

### 2. InteractionService (`interaction_service.dart`)

**Các function cần sửa:**
- `likePost()` - line 38: dùng `http.post` trực tiếp
- `getLikeStatus()` - line 117: dùng `http.get` trực tiếp
- `addComment()` - line 155: dùng `http.post` trực tiếp
- `reportContent()` - line 275: dùng `http.post` trực tiếp

**Độ ưu tiên:** 🔥🔥 QUAN TRỌNG (dùng trong HomePostCard - Like/Comment)

**Cách sửa:**
```dart
// Thêm import
import 'api_client.dart';

// Thay AuthService bằng ApiClient
final ApiClient _apiClient = ApiClient();

// Ví dụ sửa likePost():
final response = await _apiClient.post(
  '$_baseUrl/$postId/like',
  body: {},
);

// Ví dụ sửa getLikeStatus():
final response = await _apiClient.get('$_baseUrl/$postId/like-status');
```

---

### 3. DocumentService (`document_service.dart`)

**Các function cần sửa:**
- `downloadDocument()` - line 189: dùng `http.get` trực tiếp
- `getDocuments()` - line 209: dùng `http.get` trực tiếp
- `createDocument()` - line 225: dùng `http.post` trực tiếp

**Độ ưu tiên:** 🟡 KHẢQUAN TRỌNG (dùng trong DocumentScreen)

**Cách sửa:**
```dart
// Thêm import
import 'api_client.dart';

// Thay AuthService bằng ApiClient
final ApiClient _apiClient = ApiClient();

// downloadDocument() và getDocuments():
final response = await _apiClient.get(url);

// createDocument() - multipart:
final streamedResponse = await _apiClient.multipartRequest(
  'POST',
  url,
  fields: fields,
  files: files,
);
```

---

### 4. SearchService (`search_service.dart`)

**Các function cần sửa:**
- `searchAll()` - line 30: dùng `http.get` trực tiếp

**Độ ưu tiên:** 🟡 KHẢ QUAN TRỌNG (dùng trong SearchScreen)

**Cách sửa:**
```dart
// Thêm import
import 'api_client.dart';

// Thay AuthService bằng ApiClient
final ApiClient _apiClient = ApiClient();

// Trong searchAll():
final response = await _apiClient.get(
  '$_baseUrl/search?query=${Uri.encodeComponent(query)}',
);
```

---

### 5. RelationshipService (`relationship_service.dart`)

**Các function cần sửa:**
- `getFollowers()` - line 36: dùng `http.get` trực tiếp
- `getFollowing()` - line 79: dùng `http.get` trực tiếp

**Độ ưu tiên:** 🟢 ÍT QUAN TRỌNG HƠN (dùng trong FollowListScreen)

**Cách sửa:**
```dart
// Thêm import
import 'api_client.dart';

// Thay AuthService bằng ApiClient
final ApiClient _apiClient = ApiClient();

// Trong getFollowers() và getFollowing():
final response = await _apiClient.get(url);
```

---

### 6. ChatbotService (`chatbot_service.dart`)

**Các function cần sửa:**
- `sendMessage()` - line 16: dùng `http.post` trực tiếp

**Độ ưu tiên:** 🟢 ÍT QUAN TRỌNG HƠN (dùng trong ChatbotScreen)

**Cách sửa:**
```dart
// Thêm import
import 'api_client.dart';

// Thay AuthService bằng ApiClient
final ApiClient _apiClient = ApiClient();

// Trong sendMessage():
final response = await _apiClient.post(
  _apiUrl,
  body: {'message': message},
  timeout: const Duration(seconds: 30),
);
```

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Không xóa AuthService nếu service dùng cho việc khác

Một số service có thể dùng `AuthService` để:
- Lấy username hiện tại: `await _authService.getUsername()`
- Lấy userId: `await _authService.getUserId()`
- Kiểm tra profile completed: `await _authService.isProfileCompleted()`

**→ KHÔNG xóa `AuthService` nếu service cần các function này!**

### 2. Multipart requests cần xử lý khác

Với upload file (multipart/form-data), dùng:

```dart
final streamedResponse = await _apiClient.multipartRequest(
  'POST', // hoặc 'PATCH'
  url,
  fields: {'key': 'value'},
  files: [multipartFile],
  timeout: const Duration(seconds: 30),
);

final response = await http.Response.fromStream(streamedResponse);
```

### 3. Giữ nguyên timeout nếu đã custom

Một số API cần timeout dài hơn:
```dart
// Upload file - timeout 30s
await _apiClient.multipartRequest(..., timeout: const Duration(seconds: 30));

// API chậm - timeout 60s
await _apiClient.get(url, timeout: const Duration(seconds: 60));
```

### 4. Xử lý error vẫn giống như cũ

ApiClient chỉ xử lý 401 (auto-logout), các lỗi khác vẫn trả về bình thường:

```dart
final response = await _apiClient.get(url);

if (response.statusCode == 200) {
  // Success
} else if (response.statusCode == 404) {
  throw Exception('Không tìm thấy');
} else if (response.statusCode == 400) {
  throw Exception('Dữ liệu không hợp lệ');
} else {
  throw Exception('Lỗi Server: ${response.statusCode}');
}
```

---

## 🎯 THỰC HIỆN TỪNG BƯỚC

### Tuần 1: Services quan trọng nhất
1. ✅ ProfileService - **Hoàn thành**
2. ✅ FollowService - **Hoàn thành**
3. ⏳ NotificationService - **Cần làm**

### Tuần 2: Services phụ trợ
4. ⏳ InteractionService
5. ⏳ DocumentService
6. ⏳ SearchService

### Tuần 3: Services ít quan trọng
7. ⏳ RelationshipService
8. ⏳ ChatbotService

---

## ✅ KẾT QUẢ SAU KHI HOÀN THÀNH

- ✅ Tất cả service đều xử lý token đồng nhất qua ApiClient
- ✅ Khi token hết hạn → Tự động logout ở MỌI màn hình
- ✅ Khi server ngủ + token còn hạn → Giữ người dùng đăng nhập
- ✅ Code ngắn gọn hơn, ít bug hơn
- ✅ Dễ maintain và debug hơn

---

**Người tạo:** GitHub Copilot  
**Ngày:** 6/1/2026
