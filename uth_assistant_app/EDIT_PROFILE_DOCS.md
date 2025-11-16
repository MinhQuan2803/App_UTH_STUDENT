# Chức năng Chỉnh sửa Hồ sơ

## Đã thêm:

### 1. **EditProfileScreen** (`lib/screens/edit_profile_screen.dart`)
Màn hình chỉnh sửa hồ sơ với các tính năng:

#### Tính năng chính:
- ✅ **Đổi avatar**: Chọn ảnh từ camera hoặc thư viện
- ✅ **Sửa username**: Với validation (3+ ký tự, chỉ chữ/số/gạch dưới)
- ✅ **Sửa tiểu sử (bio)**: Tối đa 200 ký tự
- ✅ **Tự động phát hiện thay đổi**: Nút "Lưu" chỉ active khi có thay đổi
- ✅ **Preview avatar**: Xem trước ảnh đã chọn trước khi upload
- ✅ **Xử lý lỗi**: Hiển thị lỗi cụ thể (username trùng, file quá lớn, v.v.)
- ✅ **Giới hạn kích thước**: Avatar tối đa 5MB
- ✅ **Tối ưu ảnh**: Tự động resize xuống 800x800px, chất lượng 85%

#### UI/UX:
- Preview avatar tròn với viền xanh
- Nút camera để đổi avatar
- Form validation real-time
- Loading state khi đang lưu
- Nút "Lưu" ở AppBar (hiện khi có thay đổi)
- Opacity 50% khi nút không active

### 2. **Cập nhật ProfileScreen**
- ✅ Import `EditProfileScreen`
- ✅ Nút "Chỉnh sửa hồ sơ" điều hướng đến màn hình edit
- ✅ Auto-reload profile sau khi lưu thành công
- ✅ Force refresh để lấy dữ liệu mới nhất

### 3. **Services đã sẵn sàng**
- ✅ `updateProfileDetails()`: Cập nhật username và bio
- ✅ `updateAvatar()`: Upload ảnh lên Cloudinary
- ✅ Cache tự động cập nhật sau khi edit

## Cách hoạt động:

```dart
// Từ ProfileScreen, nhấn "Chỉnh sửa hồ sơ"
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProfileScreen(
      currentUser: user, // Truyền thông tin hiện tại
    ),
  ),
);

// Trong EditProfileScreen:
// 1. User chọn ảnh từ camera/gallery
// 2. User sửa username và bio
// 3. Nhấn "Lưu"
// 4. Upload avatar (nếu có)
// 5. Update profile details (nếu có thay đổi)
// 6. Clear cache
// 7. Quay về ProfileScreen
// 8. ProfileScreen tự động reload
```

## Backend APIs sử dụng:

### 1. PATCH `/api/users/me/update`
```json
{
  "username": "newusername",
  "bio": "This is my new bio"
}
```

**Response:**
```json
{
  "message": "Cập nhật thông tin thành công.",
  "user": {
    "_id": "...",
    "username": "newusername",
    "bio": "This is my new bio",
    "avatarUrl": "..."
  }
}
```

### 2. PATCH `/api/users/me/avatar`
**Form-data:**
- `avatar`: File (image/jpeg, image/png)

**Response:**
```json
{
  "message": "Cập nhật avatar thành công.",
  "avatarUrl": "https://res.cloudinary.com/.../avatar.jpg"
}
```

## Error Handling:

### Username trùng (409):
```
"Username này đã có người sử dụng"
```

### File quá lớn (400):
```
"Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB."
```

### Token hết hạn (401):
```
"Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại."
```

## Testing:

1. **Test đổi avatar:**
   - Chọn ảnh từ gallery → Preview đúng
   - Chọn ảnh từ camera → Preview đúng
   - Chọn ảnh > 5MB → Hiển thị lỗi
   - Upload thành công → Avatar mới hiển thị

2. **Test sửa username:**
   - Username < 3 ký tự → Validation error
   - Username có ký tự đặc biệt → Validation error
   - Username trùng → Server error 409
   - Username hợp lệ → Lưu thành công

3. **Test sửa bio:**
   - Bio > 200 ký tự → Validation error
   - Bio rỗng → Cho phép (optional)
   - Bio hợp lệ → Lưu thành công

4. **Test phát hiện thay đổi:**
   - Không thay đổi gì → Nút "Lưu" mờ
   - Sửa username → Nút "Lưu" sáng
   - Sửa bio → Nút "Lưu" sáng
   - Chọn ảnh → Nút "Lưu" sáng

## Lưu ý:

- ⚠️ Avatar upload sử dụng Cloudinary (đã config trong backend)
- ⚠️ Username phải unique trong hệ thống
- ⚠️ Bio là optional, có thể để trống
- ⚠️ Cache profile tự động xóa sau khi update
- ⚠️ ProfileScreen tự động reload sau khi edit thành công
