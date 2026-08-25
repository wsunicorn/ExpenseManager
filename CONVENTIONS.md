# CONVENTIONS.md — Quy ước làm việc của dự án

File này là quy ước bắt buộc cho mọi phiên làm việc. Đặt ở thư mục gốc của project Flutter.

---

## Dự án

App sổ thu chi cá nhân trên Android, offline hoàn toàn, không quảng cáo. Thay thế app "Sổ thu chi MoneyNote" mà chủ dự án đang dùng.

**Người dùng duy nhất**: chính chủ dự án. Không phát hành lên Play Store.

**Đặc tả đầy đủ nằm trong thư mục `ke-hoach-app/`.** Đọc file liên quan trước khi code:

| File | Khi nào đọc |
|---|---|
| `00_TONG_QUAN.md` | Đầu mỗi phiên — nắm phạm vi và quyết định đã chốt |
| `01_DAC_TA_TINH_NANG.md` | Trước khi làm bất kỳ màn hình nào |
| `02_KIEN_TRUC_DATA.md` | Khi động vào DB, model, truy vấn (mục 1 đã bị thay bởi file 06) |
| `04_LO_TRINH.md` | Xác định đang ở phase nào |
| `05_BUILD_APK_CI.md` | Khi build release |
| `06_RA_SOAT_CONG_NGHE.md` | **Nguồn chân lý về dependencies** |
| `07_UI_UX.md` | Trước khi viết bất kỳ widget giao diện nào |

---

## Stack (không tự ý đổi)

- **Flutter** stable mới nhất, **Dart** đi kèm
- **Riverpod 3** + code generation (`@riverpod`) — không dùng `StateNotifier` cũ, không dùng Provider/Bloc/GetX
- **Drift** (SQLite) — không dùng Hive, không dùng sqflite thuần
- **go_router** điều hướng
- **flex_color_scheme** theming — không viết `ThemeData` tay
- **fl_chart** biểu đồ
- **home_widget** + Kotlin cho widget màn hình chính

Muốn thêm dependency mới: **hỏi trước**, nêu lý do và phương án thay thế.

---

## Quy tắc bắt buộc

### Tiền tệ
- **Lưu tiền bằng `int`, đơn vị đồng. Không bao giờ dùng `double`.**
- Format qua `NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)`.
- Mọi `Text` hiển thị số tiền phải bật `FontFeature.tabularFigures()`.
- Ngoại lệ duy nhất cho quy tắc "amount luôn dương": giao dịch loại `adjustment` được phép âm.

### Nghiệp vụ
- Số dư ví = `initialBalance` + thu − chi + chuyển đến − chuyển đi + điều chỉnh.
- Giao dịch loại `transfer` và `adjustment` **không được tính vào báo cáo thu/chi**. Mọi truy vấn báo cáo phải lọc `type IN ('income','expense')`.
- Chuyển ví lưu **một dòng duy nhất** (`walletId` + `toWalletId`), không lưu cặp đối ứng.
- Không cho phép xoá cứng ví/danh mục đã có giao dịch — chỉ archive.

### Kiến trúc
- Luồng: `UI → Provider (Riverpod) → Repository → DAO (drift) → SQLite`. **UI không gọi thẳng DAO.**
- Logic nghiệp vụ nằm ở `domain/` dưới dạng hàm thuần, test được không cần Flutter.
- Tổ chức thư mục theo **tính năng** (`features/<tên>/{data,domain,presentation}`), không theo loại file.
- Trong `build()` luôn dùng `ref.watch`, không dùng `ref.read`.

### Giao diện
- **Không hardcode màu, khoảng cách, bo góc.** Mọi giá trị lấy từ `core/theme/tokens.dart` hoặc `ColorScheme`.
- Khoảng cách chỉ theo thang 4dp: 4 / 8 / 12 / 16 / 24 / 32 / 48.
- Không dùng màu làm phương tiện truyền tin duy nhất — số tiền luôn có dấu `+` / `−`.
- Vùng chạm tối thiểu 48×48dp.
- Mọi màn hình phải có trạng thái rỗng tử tế (icon + câu giải thích + nút hành động).
- Hành động chính nằm ở 1/3 dưới màn hình.
- Không animation nào vượt 400ms (trừ biểu đồ vẽ lần đầu 600–800ms). Không animation lặp vô hạn.

### Migration
- Mỗi lần đổi schema drift phải tăng `schemaVersion` và viết `onUpgrade`.
- **Không bao giờ đề xuất "gỡ app cài lại" để xử lý lỗi DB** — có dữ liệu thật trong đó.

---

## Lệnh thường dùng

```bash
flutter pub get
dart run build_runner watch --delete-conflicting-outputs   # để chạy nền suốt phiên
flutter analyze
flutter test
flutter run                       # debug trên máy đang cắm
flutter build apk --release --split-per-abi
```

Sau khi sửa bảng drift hoặc provider có `@riverpod` → **phải chạy `build_runner`** trước khi analyze.

---

## Cách làm việc mong muốn

Chủ dự án **chưa từng viết Dart/Flutter** (nền tảng Python/Data Science). Vì vậy:

1. **Giải thích trước khi viết.** Nêu ngắn gọn cách tiếp cận rồi mới code.
2. **Từng bước nhỏ, chạy được.** Không sinh 500 dòng một lượt. Mỗi bước phải `flutter run` lên được.
3. **Giải thích khái niệm Dart lạ** khi gặp lần đầu: `late`, `??`, `sealed class`, `Stream`, `copyWith`.
4. **Chỉ rõ file nào đang sửa** và vì sao.
5. Khi có nhiều cách làm, **nêu 2 phương án + đánh đổi**, để chủ dự án chọn.
6. **Không im lặng đổi quyết định đã chốt** trong `00_TONG_QUAN.md`. Muốn đổi thì nói rõ và hỏi.
7. Viết `flutter analyze` sạch trước khi báo xong một task.

---

## Test tối thiểu (không được bỏ)

1. `nextOccurrence()` — sinh kỳ định kỳ, kể cả ngày 29/30/31 và năm nhuận.
2. Công thức tính số dư ví (DB in-memory).
3. `parseMoney()` / `formatMoney()`.
4. Tính kỳ tài chính khi `month_start_day != 1`.

---

## Không làm

- Không thêm SDK quảng cáo, analytics, crash reporting.
- Không thêm Firebase/Supabase hay bất kỳ dịch vụ cloud nào — app phải offline hoàn toàn.
- Không commit `key.properties`, `*.jks`, `*.keystore`.
- Không thêm tính năng AI/LLM trong v1 (đã hoãn sang v2).
