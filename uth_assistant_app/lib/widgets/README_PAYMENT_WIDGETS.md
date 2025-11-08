# Payment Widgets - Tài liệu hướng dẫn

## Mục đích
File này chứa các **reusable widgets** được tạo để sử dụng cho màn hình thanh toán (Wallet Screen) và các màn hình liên quan. Giúp code dễ bảo trì, tái sử dụng và nhất quán.

## Danh sách Widgets

### 1. BalanceCard
**Mô tả:** Thẻ hiển thị số dư ví với gradient đẹp mắt

**Parameters:**
- `balance` (int): Số dư hiện tại
- `isLoading` (bool): Trạng thái đang tải
- `onHistoryTap` (VoidCallback): Callback khi nhấn nút lịch sử

**Sử dụng:**
```dart
BalanceCard(
  balance: _currentBalance,
  isLoading: _isLoadingBalance,
  onHistoryTap: () {
    Navigator.push(context, MaterialPageRoute(...));
  },
)
```

---

### 2. PackageOption
**Mô tả:** Widget để chọn gói nạp điểm (20k, 50k, 100k, 200k)

**Parameters:**
- `points` (String): Số điểm của gói (vd: "50")
- `amount` (String): Số tiền tương ứng (vd: "50.000đ")
- `isSelected` (bool): Có đang được chọn không
- `onTap` (VoidCallback): Callback khi nhấn

**Sử dụng:**
```dart
PackageOption(
  points: '50',
  amount: '50.000đ',
  isSelected: _selectedPackage == '50',
  onTap: () => _selectPackage('50'),
)
```

---

### 3. PaymentMethodOption
**Mô tả:** Widget tùy chọn phương thức thanh toán (MoMo, ZaloPay)

**Parameters:**
- `logoAsset` (String): Đường dẫn logo SVG
- `title` (String): Tên phương thức (vd: "Ví MoMo")
- `isSelected` (bool): Có đang được chọn không
- `onTap` (VoidCallback): Callback khi nhấn

**Sử dụng:**
```dart
PaymentMethodOption(
  logoAsset: AppAssets.iconMomo,
  title: 'Ví MoMo',
  isSelected: _selectedMethod == 'momo',
  onTap: () => setState(() => _selectedMethod = 'momo'),
)
```

---

### 4. OrDivider
**Mô tả:** Divider với text "HOẶC" ở giữa

**Sử dụng:**
```dart
const OrDivider()
```

---

### 5. SectionHeader
**Mô tả:** Tiêu đề section với subtitle tùy chọn

**Parameters:**
- `title` (String): Tiêu đề chính
- `subtitle` (String?): Mô tả phụ (tùy chọn)

**Sử dụng:**
```dart
const SectionHeader(
  title: 'Chọn gói nạp điểm',
  subtitle: '1 Điểm = 1.000đ',
)
```

---

### 6. PaymentSummary
**Mô tả:** Hiển thị tổng tiền thanh toán

**Parameters:**
- `amount` (int): Số tiền
- `currency` (String): Đơn vị (mặc định: 'đ')

**Sử dụng:**
```dart
PaymentSummary(
  amount: 50000,
  currency: 'đ',
)
```

---

### 7. PaymentWaitingDialog
**Mô tả:** Dialog hiển thị khi đang chờ thanh toán

**Parameters:**
- `onCancel` (VoidCallback): Callback khi nhấn hủy

**Sử dụng:**
```dart
showDialog(
  context: context,
  builder: (context) => PaymentWaitingDialog(
    onCancel: () {
      _pollingTimer?.cancel();
      Navigator.pop(context);
    },
  ),
)
```

---

## Constants trong AppAssets (app_theme.dart)

### Payment Configuration
```dart
// Tỷ lệ quy đổi điểm sang VND
static const int pointToVndRate = 1000; // 1 điểm = 1000đ

// Số điểm nạp tối thiểu
static const int minPoints = 10;

// Thời gian polling (giây)
static const int pollingIntervalSeconds = 3;

// Số lần polling tối đa
static const int maxPollingAttempts = 60; // 60 x 3s = 3 phút

// Delay giữa các dialog (ms)
static const int dialogDelayMs = 300;

// Delay đóng WebView (ms)
static const int webViewCloseDelayMs = 100;
```

### Payment Return URL Keywords
```dart
// Danh sách từ khóa để phát hiện returnUrl
static const List<String> paymentReturnUrlKeywords = [
  'ngrok-free.dev',
  'vnpay-return',
  'payment-result',
];
```

### Default Payment Packages
```dart
// Gói nạp điểm mặc định
static const Map<String, Map<String, dynamic>> defaultPaymentPackages = {
  '20': {'amount': 20000, 'label': '20.000đ'},
  '50': {'amount': 50000, 'label': '50.000đ'},
  '100': {'amount': 100000, 'label': '100.000đ'},
  '200': {'amount': 200000, 'label': '200.000đ'},
};

// Gói được chọn mặc định
static const String defaultSelectedPackage = '50';
```

### UI Constants
```dart
// Border Radius
static const double borderRadiusSmall = 8.0;
static const double borderRadiusMedium = 10.0;
static const double borderRadiusLarge = 12.0;

// Padding & Spacing
static const double paddingSmall = 8.0;
static const double paddingMedium = 12.0;
static const double paddingLarge = 16.0;
static const double paddingXLarge = 20.0;

// Icon Sizes
static const double iconSizeSmall = 16.0;
static const double iconSizeMedium = 24.0;
static const double iconSizeLarge = 32.0;

// Avatar Sizes
static const double avatarSizeSmall = 32.0;
static const double avatarSizeMedium = 40.0;
static const double avatarSizeLarge = 80.0;

// Button Heights
static const double buttonHeightSmall = 36.0;
static const double buttonHeightMedium = 44.0;
static const double buttonHeightLarge = 50.0;
```

### Message Constants
```dart
// Success Messages
static const String paymentSuccessTitle = 'Thanh toán thành công! 🎉';
static const String paymentSuccessMessage = 'Số điểm đã được cộng vào tài khoản của bạn.';

// Error Messages
static const String paymentFailedTitle = 'Thanh toán thất bại';
static const String paymentFailedMessage = 'Giao dịch không thành công. Vui lòng thử lại.';

// Timeout Messages
static const String paymentTimeoutTitle = 'Hết thời gian chờ';
static const String paymentTimeoutMessage = 'Vui lòng kiểm tra lại trạng thái giao dịch trong lịch sử.';

// Waiting Messages
static const String paymentWaitingMessage = 'Đang chờ xác nhận thanh toán...';
static const String paymentProcessingMessage = 'Vui lòng hoàn tất thanh toán trên VNPay';

// Validation Messages
static const String invalidPointsTitle = 'Số điểm không hợp lệ';
static const String invalidPointsMessage = 'Vui lòng nhập số điểm bạn muốn nạp (lớn hơn 0).';
static const String minAmountTitle = 'Số tiền quá nhỏ';
static const String minAmountMessage = 'Số tiền nạp tối thiểu là 10.000đ (tương ứng 10 điểm).';
```

---

## Lợi ích của việc sử dụng Widgets và Constants

### 1. **Dễ bảo trì**
- Thay đổi UI chỉ cần sửa ở 1 nơi
- Tránh duplicate code

### 2. **Tái sử dụng**
- Dùng widgets ở nhiều màn hình khác nhau
- Đảm bảo UI nhất quán

### 3. **Dễ nâng cấp**
- Thay đổi giá trị constants dễ dàng
- Không cần tìm kiếm hardcoded values

### 4. **Testing**
- Test widgets độc lập
- Mock data dễ dàng

---

## Hướng dẫn mở rộng

### Thêm widget mới:
1. Tạo widget trong `payment_widgets.dart`
2. Document parameters và usage
3. Thêm vào file README này

### Thêm constant mới:
1. Thêm vào `AppAssets` trong `app_theme.dart`
2. Comment chú thích bằng tiếng Việt
3. Cập nhật README

---

**Tác giả:** UTH Assistant Team  
**Ngày tạo:** 2025-11-08  
**Version:** 1.0.0
