# 02 — Kiến trúc & Dữ liệu

---

> ⚠️ **Mục 1 của file này đã được thay thế bởi `06_RA_SOAT_CONG_NGHE.md`** (rà soát 24/08/2026).
> Thay đổi chính: Riverpod 3 + code generation, thêm `flex_color_scheme` cho theming.
> Các mục 2–9 bên dưới vẫn còn hiệu lực.

## 1. Thư viện sử dụng ~~(đã thay thế — xem file 06)~~

Cài bằng `flutter pub add <tên>`. **Không ghim số phiên bản trong tài liệu này** — luôn lấy bản mới nhất tương thích tại thời điểm bạn cài, vì Flutter cập nhật liên tục.

### Bắt buộc

| Package | Dùng để | Ghi chú |
|---|---|---|
| `flutter_riverpod` | Quản lý state | Dùng `Notifier` / `AsyncNotifier` (API mới), tránh `StateNotifier` cũ |
| `drift` + `drift_flutter` | Cơ sở dữ liệu SQLite | Có `.watch()` trả về Stream → UI tự cập nhật |
| `sqlite3_flutter_libs` | Bản SQLite kèm theo app | Bắt buộc đi cùng drift trên Android |
| `path_provider`, `path` | Tìm thư mục lưu file | |
| `go_router` | Điều hướng | Hỗ trợ deep link cho widget |
| `fl_chart` | Biểu đồ tròn / cột / đường | |
| `intl` | Định dạng ngày & số theo `vi_VN` | |
| `shared_preferences` | Cài đặt nhẹ + cầu nối dữ liệu cho widget | |
| `flutter_local_notifications` | Nhắc nhở, cảnh báo ngân sách | |
| `workmanager` | Job nền hằng ngày cho khoản định kỳ | |
| `home_widget` | Widget màn hình chính | |
| `share_plus` | Chia sẻ file đã xuất | |
| `file_picker` | Chọn file khi restore | |
| `csv` | Xuất/nhập CSV | |
| `excel` | Xuất `.xlsx` | Nếu gặp lỗi, thay bằng `syncfusion_flutter_xlsio` |
| `archive` | Nén/giải nén file backup `.zip` | |
| `local_auth` | Mở khoá bằng vân tay | |
| `package_info_plus` | Hiển thị phiên bản app | |

### Dev dependencies

`drift_dev`, `build_runner`, `flutter_lints`, `riverpod_lint` (tuỳ chọn), `flutter_launcher_icons` (sinh icon app).

### Cố tình KHÔNG dùng

- **`hive`** — không hỗ trợ truy vấn tổng hợp; báo cáo sẽ phải load hết vào RAM rồi tính tay.
- **`get`** (GetX) — trộn state + route + DI, khó bảo trì khi app lớn.
- **`sqflite` thuần** — viết SQL bằng chuỗi, sai chính tả cột chỉ phát hiện lúc chạy.
- **Bất kỳ SDK quảng cáo / analytics nào.**

---

## 2. Cấu trúc thư mục

Tổ chức theo **tính năng** (feature-first), không theo loại file. Khi sửa màn hình Ngân sách, mọi thứ liên quan nằm cùng một chỗ.

```
lib/
├── main.dart
├── app.dart                        # MaterialApp + theme + router
├── core/
│   ├── db/
│   │   ├── database.dart           # class AppDatabase (drift)
│   │   ├── tables/                 # định nghĩa các bảng
│   │   └── daos/                   # truy vấn theo nhóm
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── utils/
│   │   ├── money.dart              # format & parse tiền
│   │   ├── date_range.dart         # tính kỳ tài chính
│   │   └── result.dart
│   └── constants.dart
├── features/
│   ├── onboarding/
│   ├── entry/                      # tab Nhập vào + bàn phím số
│   ├── calendar/                   # tab Lịch + tìm kiếm
│   ├── report/                     # tab Báo cáo + biểu đồ
│   ├── budget/                     # tab Ngân sách
│   ├── wallet/                     # quản lý ví
│   ├── category/                   # quản lý danh mục
│   ├── recurring/                  # khoản định kỳ
│   ├── backup/                     # xuất/nhập, CSV, Excel
│   ├── widget_home/                # cầu nối sang widget Android
│   └── settings/                   # tab Khác
└── shared/
    ├── widgets/                    # nút, thẻ, ô trống dùng chung
    └── providers/                  # provider cấp app (db, settings)
```

Mỗi feature con có 3 thư mục: `data/` (repository), `domain/` (model, logic), `presentation/` (màn hình + provider).

```
android/app/src/main/kotlin/.../
├── MainActivity.kt
├── BalanceWidgetProvider.kt        # widget nhỏ 2×1
└── BalanceWidgetLargeProvider.kt   # widget 4×2
android/app/src/main/res/
├── layout/widget_balance.xml
└── xml/widget_balance_info.xml
```

---

## 3. Nguyên tắc kiến trúc

```
UI (Widget)
   ↓ đọc
Provider (Riverpod)
   ↓ gọi
Repository
   ↓ gọi
DAO (drift)
   ↓
SQLite
```

- **UI không bao giờ gọi thẳng DAO.**
- Repository trả về `Stream<T>` cho dữ liệu hiển thị, `Future<T>` cho hành động.
- Logic nghiệp vụ (tính số dư, sinh kỳ định kỳ tiếp theo) nằm ở `domain/`, là hàm thuần — **có thể unit test không cần Flutter**.

---

## 4. Schema cơ sở dữ liệu

### 4.1 `wallets`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AI | |
| name | TEXT | |
| type | TEXT | cash / bank / ewallet / credit / savings |
| iconCode | INTEGER | codePoint của icon |
| colorValue | INTEGER | ARGB |
| **initialBalance** | INTEGER | **số dư gốc, đơn vị đồng** |
| currency | TEXT | mặc định 'VND' |
| includeInTotal | BOOLEAN | mặc định true |
| sortOrder | INTEGER | |
| archivedAt | DATETIME NULL | khác null = đã lưu trữ |
| createdAt | DATETIME | |

### 4.2 `categories`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AI | |
| name | TEXT | |
| type | TEXT | income / expense |
| iconCode | INTEGER | |
| colorValue | INTEGER | |
| parentId | INTEGER NULL | cho danh mục con |
| sortOrder | INTEGER | |
| isArchived | BOOLEAN | |

### 4.3 `transactions` — bảng trung tâm

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AI | |
| type | TEXT | **income / expense / transfer / adjustment** |
| amount | INTEGER | luôn dương, đơn vị đồng |
| walletId | INTEGER FK | ví nguồn (với transfer là ví chuyển đi) |
| toWalletId | INTEGER FK NULL | chỉ dùng khi type = transfer |
| categoryId | INTEGER FK NULL | null với transfer và adjustment |
| date | DATE | ngày giao dịch (không có giờ) |
| note | TEXT | |
| recurringRuleId | INTEGER FK NULL | nếu sinh từ khoản định kỳ |
| createdAt / updatedAt | DATETIME | |

**Quyết định thiết kế**: chuyển ví lưu **1 dòng duy nhất** với `walletId` + `toWalletId`, không lưu 2 dòng đối ứng. Ưu điểm: xoá/sửa không sợ lệch cặp. Nhược điểm: truy vấn số dư phải cộng thêm một mệnh đề — chấp nhận được.

Index cần tạo: `(date)`, `(walletId, date)`, `(categoryId, date)`, `(type, date)`.

### 4.4 `budgets`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AI | |
| categoryId | INTEGER FK NULL | null = ngân sách tổng |
| amount | INTEGER | |
| year, month | INTEGER | |
| repeatForward | BOOLEAN | áp dụng cho các tháng sau |

Ràng buộc UNIQUE `(categoryId, year, month)`.

### 4.5 `recurring_rules`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AI | |
| type, amount, walletId, categoryId, note | | giống transactions — đây là "khuôn" |
| frequency | TEXT | daily / weekly / monthly / yearly |
| interval | INTEGER | mỗi N kỳ, mặc định 1 |
| byWeekday | INTEGER NULL | 1–7, cho weekly |
| byMonthDay | INTEGER NULL | 1–31, cho monthly |
| startDate | DATE | |
| endDate | DATE NULL | |
| nextRunDate | DATE | cột then chốt để quét |
| autoPost | BOOLEAN | true = tự ghi, false = nhắc xác nhận |
| isActive | BOOLEAN | |
| lastPostedDate | DATE NULL | |

**Xử lý ngày 31**: quy tắc "mỗi tháng ngày 31" trong tháng 2 → lùi về ngày cuối tháng. Viết hàm `nextOccurrence()` là hàm thuần và **viết unit test cho nó trước tiên** — đây là chỗ dễ sai nhất trong toàn app.

### 4.6 `settings`

Bảng key-value đơn giản: `key TEXT PK`, `value TEXT`. Dùng cho `onboarding_done`, `theme_mode`, `month_start_day`, `pin_hash`…

---

## 5. Quy ước về tiền — ĐỌC KỸ

**Lưu tiền bằng `int`, đơn vị là đồng. Tuyệt đối không dùng `double`.**

Lý do: `double` là số dấu phẩy động nhị phân, `0.1 + 0.2 != 0.3`. Với hàng nghìn giao dịch, sai số tích luỹ khiến số dư lệch mà không tài nào tìm ra nguyên nhân.

- VND không có đơn vị nhỏ hơn đồng → lưu thẳng số đồng: `50000` = 50.000 đ.
- Nếu sau này thêm USD, đổi sang lưu theo **đơn vị nhỏ nhất** (cent) và thêm cột `currencyExponent`.
- Format hiển thị: `NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)`.
- `int` trong Dart trên Android là 64-bit → dư sức cho mọi con số VND.

---

## 6. Truy vấn số dư

Số dư ví `w`:

```sql
SELECT
  w.initial_balance
  + COALESCE(SUM(CASE
      WHEN t.type = 'income'     AND t.wallet_id    = w.id THEN  t.amount
      WHEN t.type = 'expense'    AND t.wallet_id    = w.id THEN -t.amount
      WHEN t.type = 'transfer'   AND t.wallet_id    = w.id THEN -t.amount
      WHEN t.type = 'transfer'   AND t.to_wallet_id = w.id THEN  t.amount
      WHEN t.type = 'adjustment' AND t.wallet_id    = w.id THEN  t.amount
      ELSE 0 END), 0) AS balance
FROM wallets w
LEFT JOIN transactions t
  ON t.wallet_id = w.id OR t.to_wallet_id = w.id
WHERE w.id = :walletId
GROUP BY w.id;
```

Lưu ý: với `adjustment`, cột `amount` được phép **âm** (đây là ngoại lệ duy nhất của quy tắc "luôn dương"), vì điều chỉnh có thể giảm số dư. Ghi rõ ngoại lệ này vào comment trong code.

Trong drift, bọc câu này thành `customSelect(...).watch()` để UI tự cập nhật.

---

## 7. Migration

- Bắt đầu `schemaVersion = 1`.
- **Mỗi lần đổi bảng phải tăng version và viết `onUpgrade`** — không bao giờ xoá app cài lại khi đã có dữ liệu thật.
- Bật `drift` schema test: lưu snapshot schema vào `drift_schemas/` và viết test migration. Việc này tốn 30 phút nhưng cứu bạn khỏi mất dữ liệu.

---

## 8. Xử lý múi giờ và ngày

- Lưu `date` là **ngày thuần** (không giờ, không timezone), chuẩn hoá về nửa đêm giờ địa phương.
- Kỳ báo cáo tính theo `month_start_day` trong settings, không cứng là ngày 1.
- Dùng `DateUtils.dateOnly()` của Flutter để cắt phần giờ trước khi lưu.

---

## 9. Kiểm thử tối thiểu

Không cần phủ 100%, nhưng **bắt buộc** viết test cho:

1. `nextOccurrence()` — sinh kỳ định kỳ (kể cả ngày 29/30/31, năm nhuận).
2. Công thức tính số dư (dựng DB in-memory, thêm vài giao dịch, so kết quả).
3. `parseMoney()` / `formatMoney()` — dấu chấm ngăn cách nghìn.
4. Tính kỳ tài chính khi `month_start_day != 1`.

Chạy: `flutter test`.
