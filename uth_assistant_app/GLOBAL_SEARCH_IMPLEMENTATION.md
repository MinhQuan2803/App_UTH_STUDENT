# Hướng dẫn Tích hợp Global Search API

## Tổng quan
File này ghi nhận quá trình tích hợp API tìm kiếm toàn cục vào màn hình tìm kiếm của ứng dụng.

## API Endpoint
```
GET https://uthstudent.onrender.com/api/search/global?q={query}
```

### Response Structure
```json
{
  "totalResults": 15,
  "users": [
    {
      "_id": "user_id",
      "username": "giang",
      "avatarUrl": "https://res.cloudinary.com/..."
    }
  ],
  "documents": [
    {
      "_id": "doc_id",
      "title": "Tài liệu ABC",
      "description": "Mô tả...",
      "fileUrl": "...",
      "fileType": "PDF",
      "price": 100,
      "uploaderUsername": "giang",
      "uploaderAvatar": "...",
      "downloads": 50
    }
  ],
  "posts": [
    {
      "_id": "post_id",
      "text": "Nội dung bài viết",
      "author": {
        "_id": "...",
        "username": "giang",
        "avatarUrl": "..."
      },
      "media": [],
      "likes": [],
      "comments": [],
      "createdAt": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

## Các file đã tạo/cập nhật

### 1. `lib/services/search_service.dart`
**Chức năng**: Service layer xử lý API call

**Models**:
- `SearchUser`: Model cho user trong kết quả search
  - `id`: String
  - `username`: String
  - `avatarUrl`: String?

- `SearchDocument`: Model cho document trong kết quả search
  - `id`: String
  - `title`: String
  - `description`: String?
  - `fileUrl`: String
  - `fileType`: String
  - `price`: int
  - `uploaderUsername`: String
  - `uploaderAvatar`: String?
  - `downloads`: int

**Methods**:
- `Future<Map<String, dynamic>> globalSearch(String query)`: Gọi API và trả về Map chứa:
  - `users`: List<SearchUser>
  - `posts`: List<Post>
  - `documents`: List<SearchDocument>

**Error Handling**:
- Timeout: 15 giây
- Network error: Hiển thị thông báo mất kết nối
- Server error: Hiển thị mã lỗi và message

### 2. `lib/widgets/user_list_item.dart`
**Chức năng**: Widget hiển thị user trong danh sách search

**UI Elements**:
- CircleAvatar: Hiển thị avatar hoặc chữ cái đầu
- Username: Hiển thị tên người dùng
- Chevron right: Icon mũi tên chỉ sang phải
- InkWell: Hỗ trợ tap navigation

**Navigation**: Khi tap vào → navigate to `/profile` với argument là `username`

### 3. `lib/widgets/document_search_item.dart`
**Chức năng**: Widget hiển thị document trong kết quả search (khác với DocumentListItem ở màn Document)

**UI Elements**:
- File type badge: Hiển thị loại file với màu tương ứng
  - PDF: Đỏ (#E74C3C)
  - DOCX: Xanh dương (#2980B9)
  - XLSX: Xanh lá (#27AE60)
  - PPTX: Cam (#E67E22)
  - ZIP/RAR: Tím (#8E44AD)
- Title: Tên tài liệu (max 2 lines)
- Description: Mô tả (max 2 lines)
- Uploader info: Avatar + username
- Downloads count: Icon + số lượt tải
- Price badge: Hiển thị giá hoặc "Miễn phí"

**Navigation**: Khi tap vào → navigate to `/document-detail` với argument là `documentId`

### 4. `lib/screens/search_screen.dart`
**Thay đổi chính**:

#### State Management
```dart
// Thay đổi từ:
List<NewsArticle> _notificationResults = [];

// Thành:
List<SearchUser> _userResults = [];
List<Post> _postResults = [];
List<SearchDocument> _documentResults = [];
```

#### API Call Flow
1. User nhập text vào search field
2. Listener `_onSearchChanged()` được trigger
3. Nếu query rỗng → clear results
4. Nếu có query → gọi `_performGlobalSearch()`
5. Service call `SearchService.globalSearch(query)`
6. Parse response và update state
7. UI tự động rebuild với kết quả mới

#### Tab Structure
Đổi từ 3 tab:
- ❌ Thông báo (dùng NewsService - bị xóa)
- ✅ Bài viết
- ✅ Tài liệu

Thành 3 tab mới:
- ✅ Người dùng (dùng Global Search API)
- ✅ Bài viết (dùng Global Search API)
- ✅ Tài liệu (dùng Global Search API)

#### Widget Builders
- `_buildUserList()`: Hiển thị danh sách user với UserListItem
- `_buildPostList()`: Hiển thị danh sách post với HomePostCard
- `_buildDocumentList()`: Hiển thị danh sách document với DocumentSearchItem

## Hành vi ứng dụng

### Empty State
- **Khi chưa search**: Hiển thị text "Nhập từ khóa để tìm kiếm..."
- **Khi search không có kết quả**: Hiển thị "Không tìm thấy [loại] nào."

### Loading State
- Hiển thị CircularProgressIndicator ở giữa màn hình
- Áp dụng cho cả 3 tab

### Error State
- Hiển thị error message từ API
- Màu chữ sử dụng `AppTextStyles.errorText`

### Tab Indicator
- Hiển thị số lượng kết quả ở góc phải trên mỗi tab
- Format: "Người dùng⁵" (superscript)
- Chỉ hiển thị khi count > 0

## Post Callbacks

### onPostDeleted
```dart
void _handlePostDeleted(Post post) {
  setState(() {
    _postResults.removeWhere((p) => p.id == post.id);
    _postCount = _postResults.length;
  });
}
```
- Xóa post khỏi local list
- Cập nhật lại count
- KHÔNG gọi lại API

### onPostUpdated
```dart
void _handlePostUpdated() {
  _performGlobalSearch();
}
```
- Gọi lại API để refresh toàn bộ kết quả
- Đảm bảo dữ liệu mới nhất

## Testing

### Test Cases
1. **Search rỗng**: Không hiển thị gì, placeholder text hiển thị
2. **Search "giang"**: Trả về user, post, document chứa từ khóa
3. **Search không có kết quả**: Hiển thị "Không tìm thấy..."
4. **Network error**: Hiển thị error message
5. **Tap vào user**: Navigate to profile screen
6. **Tap vào document**: Navigate to document detail screen
7. **Tap vào post**: Mở HomePostCard menu (like, comment, share, report)
8. **Delete post**: Post biến mất khỏi list, count giảm
9. **Update post**: Gọi lại API, refresh results

### Endpoint Test
```bash
# Test với curl hoặc Postman
curl "https://uthstudent.onrender.com/api/search/global?q=giang" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Notes
- API không yêu cầu authentication (public search)
- Timeout: 15s (có thể điều chỉnh nếu backend chậm)
- SearchService tự động lấy token từ AuthService nếu cần
- Dữ liệu mock đã bị xóa hoàn toàn, chỉ dùng API thật

## Cấu trúc File
```
lib/
├── screens/
│   └── search_screen.dart          # Màn hình tìm kiếm (ĐÃ REFACTOR)
├── services/
│   └── search_service.dart         # Service gọi API (MỚI)
└── widgets/
    ├── user_list_item.dart         # Widget user card (MỚI)
    ├── document_search_item.dart   # Widget document card (MỚI)
    └── home_post_card.dart         # Widget post card (SỬ DỤNG LẠI)
```

## Changelog
**2024-XX-XX**:
- ✅ Tạo SearchService với globalSearch()
- ✅ Tạo SearchUser và SearchDocument models
- ✅ Tạo UserListItem widget
- ✅ Tạo DocumentSearchItem widget
- ✅ Refactor SearchScreen để dùng Global Search API
- ✅ Xóa NewsService và mock data
- ✅ Update tab labels từ "Thông báo/Bài viết/Tài liệu" sang "Người dùng/Bài viết/Tài liệu"
- ✅ Thêm navigation cho user và document items
- ✅ Format tất cả các file mới
