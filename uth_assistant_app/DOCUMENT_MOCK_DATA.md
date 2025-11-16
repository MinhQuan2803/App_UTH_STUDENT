# Tài liệu màn hình Document - Sử dụng dữ liệu mẫu

## 📝 Tổng quan

Đã cập nhật các màn hình Document để sử dụng **dữ liệu mẫu (mock data)** thay vì gọi API, giúp có thể build và test giao diện mà không cần backend.

---

## ✅ Các file đã sửa

### 1. **document_screen.dart** - Màn hình danh sách tài liệu

**Thay đổi:**
- ❌ Xóa: Import `document_service.dart`, `document_model.dart`
- ❌ Xóa: Logic gọi API `_fetchDocuments()`
- ❌ Xóa: State `_isLoading`, `_error`
- ✅ Thêm: 3 danh sách dữ liệu mẫu
- ✅ Thêm: Method `_buildDocumentList()` đơn giản hơn

**Dữ liệu mẫu:**

```dart
// Tab 1: Tất cả (8 tài liệu)
_mockAllDocuments = [
  {
    'fileType': 'PDF',
    'title': 'Đề cương môn Giải tích 1',
    'uploader': 'Nguyễn Văn A',
    'price': 50,
  },
  {
    'fileType': 'DOCX',
    'title': 'Bài tập lớn Lập trình Web',
    'uploader': 'Trần Thị B',
    'price': 0, // Miễn phí
  },
  // ... 6 tài liệu khác
]

// Tab 2: Của tôi (2 tài liệu)
_mockMyDocuments = [
  {
    'fileType': 'PDF',
    'title': 'Bài giảng của tôi - Lập trình Python',
    'uploader': 'Tôi',
    'price': 80,
  },
  {
    'fileType': 'DOCX',
    'title': 'Bài tập nhóm môn AI',
    'uploader': 'Tôi',
    'price': 0,
  },
]

// Tab 3: Đã thích (2 tài liệu)
_mockLikedDocuments = [
  {
    'fileType': 'PDF',
    'title': 'Đề cương môn Giải tích 1',
    'uploader': 'Nguyễn Văn A',
    'price': 50,
  },
  {
    'fileType': 'PDF',
    'title': 'Slide bài giảng Cơ sở dữ liệu',
    'uploader': 'Lê Văn C',
    'price': 100,
  },
]
```

**Tính năng:**
- ✅ 3 tabs: "Tất cả", "Của tôi", "Đã thích"
- ✅ Hiển thị danh sách tài liệu với loại file, tiêu đề, người đăng, giá
- ✅ Nhấn vào tài liệu → Hiển thị SnackBar với tên tài liệu
- ✅ Hiển thị "Chưa có tài liệu" nếu danh sách rỗng
- ✅ Padding dưới để FAB không che

---

### 2. **upload_document_screen.dart** - Màn hình đăng bán tài liệu

**Thay đổi:**
- ❌ Xóa: Comment code `file_picker` (không cần package)
- ❌ Xóa: Method `_showErrorSnackBar()`
- ✅ Thêm: Import `custom_notification.dart`
- ✅ Thêm: Method `_simulatePickFile()` - Dialog chọn loại file
- ✅ Thêm: Biến `_selectedFileType` để lưu loại file đã chọn
- ✅ Thêm: Hiển thị badge loại file sau khi chọn

**Tính năng:**
- ✅ Nhấn vào box → Hiển thị dialog chọn loại file (PDF, DOCX, XLSX, PPTX)
- ✅ Sau khi chọn → Hiển thị tên file mẫu + badge loại file
- ✅ Form validation:
  - Tiêu đề không được để trống
  - Phải chọn file
  - Giá phải là số hợp lệ (0 = miễn phí)
- ✅ Nhấn "Đăng bán" → Hiển thị thông báo success + quay về

**Demo flow:**
```
1. Nhấn vào box "Nhấn để chọn loại file"
2. Dialog hiển thị: PDF, DOCX, XLSX, PPTX
3. Chọn PDF → File name: "tai-lieu-mau.PDF"
4. Nhập tiêu đề: "Đề cương Giải tích"
5. Nhập mô tả: "Môn Giải tích 1, GV Nguyễn Văn A"
6. Nhập giá: "50" (hoặc "0" nếu miễn phí)
7. Nhấn "Đăng bán"
8. → CustomNotification.success: "Đã đăng bán: tai-lieu-mau.PDF, Giá: 50 điểm"
9. → Navigator.pop() quay về màn hình trước
```

---

## 🎨 UI Features

### DocumentListItem (không thay đổi)
- ✅ Màu card: Xanh nếu có phí, Trắng nếu miễn phí
- ✅ Text color: Trắng nếu có phí, Đen nếu miễn phí
- ✅ Icon file type: Màu khác nhau theo loại file
- ✅ Price tag: "Miễn phí" hoặc số điểm + icon coin

### Upload Screen
- ✅ File picker box với icon upload
- ✅ Badge loại file (PDF/DOCX/XLSX/PPTX) sau khi chọn
- ✅ CustomTextField cho tiêu đề, mô tả, giá
- ✅ CustomButton "Đăng bán"
- ✅ Validation real-time

---

## 🔧 Cách test

### Test Document Screen:
1. Mở app → Tab "Tài liệu"
2. Kiểm tra 3 tabs:
   - **Tất cả**: 8 tài liệu (mix free + paid)
   - **Của tôi**: 2 tài liệu
   - **Đã thích**: 2 tài liệu
3. Nhấn vào bất kỳ tài liệu → SnackBar hiển thị tên

### Test Upload Screen:
1. Từ Document screen → Nhấn FAB (nút +)
2. Màn hình Upload hiển thị
3. Nhấn vào box chọn file
4. Dialog hiển thị 4 loại file
5. Chọn PDF → Tên file + badge PDF xuất hiện
6. Nhập form:
   - Tiêu đề: "Test document"
   - Mô tả: "This is a test"
   - Giá: "100"
7. Nhấn "Đăng bán"
8. → Thông báo success
9. → Quay về Document screen

---

## 🚀 Khi có Backend

Khi backend sẵn sàng, chỉ cần:

### document_screen.dart:
```dart
// BEFORE (Mock data)
final List<Map<String, dynamic>> _mockAllDocuments = [...];

// AFTER (Real API)
List<Document> _allDocuments = [];
bool _isLoading = true;
String? _error;

Future<void> _fetchDocuments() async {
  setState(() => _isLoading = true);
  try {
    final documents = await _documentService.getDocuments();
    setState(() {
      _allDocuments = documents;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}
```

### upload_document_screen.dart:
```dart
// BEFORE (Simulate)
void _simulatePickFile() { ... }

// AFTER (Real file picker)
Future<void> _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(...);
  if (result != null) {
    setState(() => _fileName = result.files.single.name);
  }
}

// BEFORE (Mock submit)
CustomNotification.success(context, 'Đã đăng bán...');
Navigator.pop(context);

// AFTER (Real API)
final result = await _documentService.uploadDocument(
  file: _selectedFile,
  title: _titleController.text,
  description: _descriptionController.text,
  price: int.parse(_priceController.text),
);
```

---

## 📦 Dependencies cần thêm khi có backend

```yaml
dependencies:
  file_picker: ^6.0.0  # Chọn file từ thiết bị
  http: ^1.1.0         # Đã có (dùng cho API calls)
```

---

## ✅ Checklist

- [x] Document screen hiển thị dữ liệu mẫu
- [x] 3 tabs hoạt động đúng
- [x] Upload screen có form đầy đủ
- [x] Validation hoạt động
- [x] File type selection dialog
- [x] CustomNotification hoạt động
- [x] Không có lỗi compile
- [x] UI responsive và đẹp
- [x] Sẵn sàng tích hợp backend

---

## 🎯 Kết luận

Bây giờ bạn có thể:
- ✅ Build và chạy app mà không cần backend
- ✅ Test toàn bộ UI flow
- ✅ Demo cho người dùng/khách hàng
- ✅ Dễ dàng chuyển sang API thật khi backend sẵn sàng

**Hot reload ngay để xem kết quả!** 🚀
