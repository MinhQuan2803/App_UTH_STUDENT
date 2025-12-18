# Hướng Dẫn Test Token Refresh & Auto Logout

## Cơ Chế Hiện Tại

### 1. Auto Refresh Token
**Khi nào refresh:**
- Token còn < 120 giây (2 phút) → Tự động refresh trước
- Token đã hết hạn → Refresh ngay

**Flow:**
```
User gọi API
    ↓
getValidToken() check remaining time
    ↓
< 120s? → Gọi refreshAccessToken()
    ↓
┌─────────────┬────────────────┬─────────────┐
│   Success   │  NetworkError  │   Failed    │
│  (200 OK)   │  (Timeout/503) │ (401/403)   │
└─────────────┴────────────────┴─────────────┘
      ↓              ↓                ↓
  Token mới    Token cũ (nếu     Logout +
  + Continue   chưa hết hạn)    → Login screen
               + Continue
```

### 2. Xử Lý 401 Unauthorized
**Khi API trả về 401:**
```
API Response: 401
    ↓
ApiClient._makeRequestWithRetry()
    ↓
Gọi refreshAccessToken()
    ↓
┌─────────────┬────────────────┬─────────────┐
│   Success   │  NetworkError  │   Failed    │
└─────────────┴────────────────┴─────────────┘
      ↓              ↓                ↓
  Retry API    Retry API       Logout +
  với token    với token     → Login screen
  mới          cũ
```

### 3. Giữ Phiên Đăng Nhập
**Không logout khi:**
- ❌ Network error (timeout, no internet)
- ❌ Server đang sleep/restart
- ❌ Token còn hạn nhưng server không phản hồi

**Chỉ logout khi:**
- ✅ Refresh token thật sự hết hạn (backend trả 401/403)
- ✅ User chủ động logout
- ✅ Token bị server reject

## Test Cases

### Test 1: Token Sắp Hết Hạn (< 2 phút)
**Mục đích:** Verify auto refresh trước khi hết hạn

**Cách test:**
1. Đăng nhập vào app
2. Đợi token còn < 2 phút (hoặc modify code để test nhanh)
3. Thực hiện action bất kỳ (like post, comment, load profile)
4. **Kết quả mong đợi:**
   - Log: `⚠ Token sắp hết hạn (còn XXs), refreshing...`
   - Log: `✓ Refresh Success`
   - Action thành công
   - KHÔNG logout

**Check log:**
```
I/flutter: ⚠ Token sắp hết hạn (còn 90s), refreshing...
I/flutter: === REFRESHING TOKEN (Wait 90s) ===
I/flutter: ✓ Refresh Success
I/flutter: ✓ API call success
```

### Test 2: Token Đã Hết Hạn
**Mục đích:** Verify auto refresh khi token expired

**Cách test:**
1. Đăng nhập vào app
2. Đợi token hết hạn hoàn toàn (> 24h)
3. Mở app lại (splash screen)
4. **Kết quả mong đợi:**
   - Splash screen gọi `getValidToken()`
   - Auto refresh token
   - Vào home screen
   - KHÔNG logout (nếu refresh token còn hạn)

### Test 3: Network Error Khi Refresh
**Mục đích:** Verify giữ session khi mất mạng

**Cách test:**
1. Đăng nhập vào app
2. Tắt wifi/data
3. Thực hiện action (like, comment, etc.)
4. **Kết quả mong đợi:**
   - Log: `⚠ Network error, using old token`
   - Hiển thị error "Không có kết nối mạng"
   - KHÔNG logout
   - App vẫn giữ phiên đăng nhập

**Check log:**
```
I/flutter: === REFRESHING TOKEN (Wait 90s) ===
I/flutter: ⚠ Network/Server Sleep Error: TimeoutException
I/flutter: ⚠ Network error, using old token
```

### Test 4: Server Sleep/Restart
**Mục đích:** Verify giữ session khi server đang restart

**Cách test:**
1. Đăng nhập vào app
2. Backend restart server
3. Ngay lập tức thử gọi API
4. **Kết quả mong đợi:**
   - Request timeout/503
   - `RefreshResult.networkError`
   - KHÔNG logout
   - Retry thành công khi server online lại

### Test 5: Refresh Token Thật Sự Hết Hạn
**Mục đích:** Verify auto logout khi refresh token hết hạn

**Cách test:**
1. Đăng nhập vào app
2. Đợi refresh token hết hạn (thường > 7 ngày)
3. Mở app lại
4. **Kết quả mong đợi:**
   - Backend trả 401/403 khi refresh
   - `RefreshResult.failed`
   - Auto logout
   - Chuyển về login screen

**Check log:**
```
I/flutter: === REFRESHING TOKEN (Wait 90s) ===
I/flutter: ✗ Refresh Failed (Server rejected)
I/flutter: ❌ Refresh token failed, user needs to re-login
I/flutter: Navigating to /login
```

### Test 6: API Call Với Token Hết Hạn
**Mục đích:** Verify ApiClient tự động retry

**Cách test:**
1. Token hết hạn
2. Gọi API bất kỳ (load posts, profile, etc.)
3. **Kết quả mong đợi:**
   - API trả 401
   - ApiClient auto refresh
   - Retry API với token mới
   - Success

**Check log:**
```
I/flutter: ⚠️ Got 401, attempting to refresh token...
I/flutter: === REFRESHING TOKEN (Wait 90s) ===
I/flutter: ✓ Refresh Success
I/flutter: ✅ Token refreshed, retrying request...
I/flutter: ✓ API success
```

### Test 7: Splash Screen → Home (Token Valid)
**Cách test:**
1. Đăng nhập
2. Close app hoàn toàn
3. Mở app lại
4. **Kết quả mong đợi:**
   - Splash screen 2s
   - Check token
   - Vào home screen
   - KHÔNG cần đăng nhập lại

### Test 8: Splash Screen → Login (No Token)
**Cách test:**
1. Chưa đăng nhập hoặc đã logout
2. Mở app
3. **Kết quả mong đợi:**
   - Splash screen 2s
   - Check token = null
   - Vào login screen

## Debug Commands

### 1. Kiểm tra token remaining time
Thêm vào code test:
```dart
final token = await _authService.getToken();
if (token != null) {
  final remaining = JwtDecoder.getRemainingTime(token);
  print('Token còn: ${remaining.inSeconds}s');
}
```

### 2. Force expire token (để test)
Thêm vào AuthService:
```dart
// ONLY FOR TESTING
Future<void> expireTokenForTesting() async {
  final oldToken = await getToken();
  // Tạo token fake đã hết hạn
  // Hoặc đơn giản xóa token
  await _storage.delete(key: _tokenKey);
}
```

### 3. Mock network error
Tắt wifi/data trên thiết bị test

### 4. Mock server error
Stop backend server tạm thời

## Checklist Kiểm Tra

### Auto Refresh
- [ ] Token < 2 phút → Auto refresh trước
- [ ] Token hết hạn → Auto refresh
- [ ] Refresh success → Continue với token mới
- [ ] Refresh network error → Continue với token cũ (nếu còn hạn)
- [ ] Refresh failed → Logout

### ApiClient Retry
- [ ] API trả 401 → Auto refresh → Retry
- [ ] Retry success → Continue
- [ ] Retry failed → Logout

### Session Management
- [ ] Network error → KHÔNG logout
- [ ] Server sleep → KHÔNG logout
- [ ] Refresh token hết hạn → Logout
- [ ] Manual logout → Clear tokens + navigate login

### Splash Screen
- [ ] Token valid → Home
- [ ] Token null → Login
- [ ] Token expired nhưng refresh success → Home
- [ ] Token expired và refresh failed → Login

## Known Issues & Fixes

### Issue 1: App logout khi mất mạng tạm thời
**Fix:** ✅ Đã fix - `RefreshResult.networkError` không logout

### Issue 2: Token hết hạn giữa chừng request
**Fix:** ✅ Đã fix - `getValidToken()` refresh trước 2 phút

### Issue 3: Server restart → App logout
**Fix:** ✅ Đã fix - Timeout/503 trả về `networkError`, không logout

### Issue 4: Splash screen không check token
**Fix:** ✅ Đã fix - Dùng `getValidToken()` thay vì `getToken()`

## Monitoring & Logs

### Production Logs (Keep These)
```dart
✓ Refresh Success          // Token refresh thành công
✗ Refresh Failed           // Token bị reject
⚠ Network error, keeping session // Giữ session khi lỗi mạng
⚠ Token sắp hết hạn        // Auto refresh trước
```

### Debug Logs (Remove in Production)
```dart
=== REFRESHING TOKEN ===    // Đang refresh
=== GET VALID TOKEN ===     // Check token
Token còn: XXs              // Remaining time
```

## Best Practices

1. **Luôn dùng `getValidToken()` thay vì `getToken()`**
   - ✅ `getValidToken()` - Auto refresh
   - ❌ `getToken()` - Không auto refresh

2. **Dùng ApiClient cho mọi HTTP request**
   - ApiClient có built-in retry logic

3. **Không logout khi network error**
   - Chỉ logout khi token thật sự bị reject

4. **Log rõ ràng để debug**
   - Success: ✓
   - Error: ✗
   - Warning: ⚠

5. **Timeout hợp lý**
   - 90s cho refresh token (server có thể đang sleep)
   - 30s cho API calls thông thường
