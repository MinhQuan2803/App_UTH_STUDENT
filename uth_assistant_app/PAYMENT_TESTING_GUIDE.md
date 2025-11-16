# Hướng dẫn Test Thanh Toán

## 📋 Tổng quan
App hỗ trợ 2 phương thức thanh toán:
- **VNPay** - Cổng thanh toán ngân hàng
- **MoMo** - Ví điện tử MoMo

## 🔧 API Endpoints Mới

### 1. Tạo Link Thanh Toán
**Endpoint:** `POST /api/payment/create-payment`

**Request Body:**
```json
{
  "amountVND": 100000,
  "provider": "VNPAY" // hoặc "MOMO"
}
```

**Response:**
```json
{
  "message": "Tạo đơn hàng thành công",
  "paymentUrl": "https://...",
  "orderId": "690f26665c8bb483e20bc6d8"
}
```

### 2. Kiểm tra Trạng Thái Đơn Hàng
**Endpoint:** `GET /api/payment/order-status/:orderId`

**Response:**
```json
{
  "success": true,
  "status": "COMPLETED", // hoặc PENDING, FAILED, CANCELLED, EXPIRED
  "data": {
    "userId": "...",
    "amountVND": 100000,
    "pointsToGrant": 100,
    "paymentProvider": "VNPAY"
  }
}
```

### 3. Lấy Số Dư Điểm
**Endpoint:** `GET /api/points/balance`

**Response:**
```json
{
  "success": true,
  "data": {
    "balance": 1620,
    "level": 0,
    "totalEarned": 0,
    "totalSpent": 0
  }
}
```

### 4. Lấy Lịch Sử Điểm
**Endpoint:** `GET /api/points/history?page=1&limit=20`

**Response:**
```json
{
  "success": true,
  "data": {
    "history": [
      {
        "_id": "690f67394f978ad4d824adc9",
        "userId": "68fa21af36aa58e5cd3ba543",
        "type": "EARNED",
        "amount": 100,
        "source": "PAYMENT",
        "description": "Nạp 100 điểm qua VNPay. Mã giao dịch VNPay: 15247314",
        "balanceBefore": 300,
        "balanceAfter": 400,
        "createdAt": "2025-11-08T15:52:25.118+00:00"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalRecords": 100
    }
  }
}
```

### 5. Lấy Lịch Sử Đơn Hàng
**Endpoint:** `GET /api/payment/my-orders?page=1&limit=10`

**Response:**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "_id": "690f671a4f978ad4d824adc4",
        "userId": "68fa21af36aa58e5cd3ba543",
        "amountVND": 100000,
        "pointsToGrant": 100,
        "status": "COMPLETED",
        "paymentProvider": "VNPAY",
        "createdAt": "2025-11-08T15:51:54.916+00:00",
        "updatedAt": "2025-11-08T15:52:25.170+00:00"
      }
    ]
  }
}
```

## 🧪 Thông Tin Test

### VNPay Test Credentials
```
Ngân hàng: NCB
Số thẻ: 9704198526191432198
Tên chủ thẻ: NGUYEN VAN A
Ngày phát hành: 07/15
Mật khẩu OTP: 123456
```

### MoMo Test Instructions
Tham khảo: https://developers.momo.vn/v3/vi/docs/payment/onboarding/test-instructions/

## 📊 Payment Status Flow

```
PENDING → User đang thanh toán
   ↓
COMPLETED → Thanh toán thành công (điểm đã được cộng tự động)
   ↓
FAILED → Thanh toán thất bại
CANCELLED → Người dùng hủy
EXPIRED → Hết hạn thanh toán
```

## 🔄 Luồng Thanh Toán trong App

1. **User chọn gói nạp điểm** (20k, 50k, 100k, 200k)
2. **User chọn phương thức** (MoMo hoặc VNPay)
3. **User nhấn "Nạp điểm"**
   - App gọi `POST /api/payment/create-payment`
   - Nhận `paymentUrl` và `orderId`
4. **Mở WebView** với `paymentUrl`
5. **User thanh toán** trên trang VNPay/MoMo
6. **Polling mechanism** (chạy ngầm):
   - Mỗi 3 giây gọi `GET /api/payment/order-status/:orderId`
   - Tối đa 60 lần (3 phút)
7. **Khi phát hiện status = COMPLETED**:
   - Đóng WebView tự động
   - Reload số dư điểm
   - Hiển thị dialog thành công 🎉
   - Điểm đã được cộng vào tài khoản

## 🛠️ Code Changes Summary

### PaymentService (`payment_service.dart`)
```dart
// ✅ API mới
POST /api/payment/create-payment (body: { amountVND, provider })
GET /api/payment/order-status/:orderId
GET /api/points/balance
GET /api/points/history?page=1&limit=20
GET /api/payment/my-orders?page=1&limit=10

// ❌ API cũ (đã xóa)
POST /api/payment/vnpay/create-payment-link
GET /api/payment/vnpay/order-status/:vnpTxnRef
GET /api/users/me/points
GET /api/users/me/points/history
GET /api/payment/vnpay/my-orders
```

### WalletScreen (`wallet_screen.dart`)
```dart
// Thay đổi chính:
- Sử dụng orderId thay vì vnpTxnRef
- Hỗ trợ cả VNPAY và MOMO provider
- Status check: SUCCESS | COMPLETED
- Tự động phát hiện provider từ _selectedMethod
```

### AppAssets (`app_theme.dart`)
```dart
// Thêm keywords cho MoMo
paymentReturnUrlKeywords = [
  'ngrok-free.dev',
  'vnpay-return', 
  'payment-result',
  'momo-return', // MoMo
  'test-payment.momo.vn', // MoMo domain
]
```

## ⚠️ Lưu ý về Múi Giờ

**Vấn đề:**
- VNPay: Múi giờ +7 (Vietnam)
- Render.com: Múi giờ 0 (UTC)
- MongoDB: Lưu UTC

**Giải pháp:**
- Backend cần convert thời gian khi tạo payment URL
- Frontend hiển thị thời gian theo múi giờ local
- Sử dụng `toLocal()` khi parse DateTime

```dart
// Ví dụ convert
DateTime utcTime = DateTime.parse(createdAt);
DateTime localTime = utcTime.toLocal();
```

## 🎯 Testing Checklist

### VNPay Flow
- [ ] Chọn gói 50k
- [ ] Chọn phương thức VNPay
- [ ] Nhấn "Nạp điểm"
- [ ] WebView mở trang VNPay
- [ ] Nhập thông tin test card
- [ ] Nhập OTP: 123456
- [ ] Xác nhận thanh toán
- [ ] WebView tự động đóng
- [ ] Dialog "Thanh toán thành công" hiển thị
- [ ] Số dư điểm tăng thêm 50
- [ ] Kiểm tra lịch sử giao dịch

### MoMo Flow
- [ ] Chọn gói 100k
- [ ] Chọn phương thức MoMo
- [ ] Nhấn "Nạp điểm"
- [ ] WebView mở trang MoMo
- [ ] Thực hiện thanh toán test
- [ ] WebView tự động đóng
- [ ] Dialog "Thanh toán thành công" hiển thị
- [ ] Số dư điểm tăng thêm 100
- [ ] Kiểm tra lịch sử giao dịch

### Error Cases
- [ ] Hủy thanh toán → Dialog "Thanh toán thất bại"
- [ ] Timeout (3 phút) → Dialog "Hết thời gian chờ"
- [ ] Mất kết nối → Dialog lỗi kết nối

## 📱 Screenshots Expected

1. **Wallet Screen**
   - Số dư hiện tại
   - Các gói nạp (20k, 50k, 100k, 200k)
   - Phương thức (MoMo, VNPay)
   - Nút "Nạp điểm"

2. **WebView Payment**
   - Trang VNPay/MoMo
   - Form nhập thông tin

3. **Success Dialog**
   - Icon success ✅
   - "Thanh toán thành công! 🎉"
   - "Số điểm đã được cộng vào tài khoản"

4. **Transaction History**
   - 2 tabs: Lịch sử điểm + Đơn hàng
   - Hiển thị thời gian, số tiền, trạng thái

---

**Version:** 2.0.0  
**Last Updated:** 2025-11-12  
**Author:** UTH Assistant Team
