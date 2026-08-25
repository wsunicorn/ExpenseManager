# Sổ thu chi

App quản lý thu chi cá nhân trên Android. **Offline hoàn toàn, không quảng cáo, không khoá tính năng nào.**

Dựng để thay app "Sổ thu chi MoneyNote" — xem `ke-hoach-app/00_TONG_QUAN.md` mục 2 để biết giữ gì, sửa gì.

---

## Chạy thử nhanh

```bash
flutter run -d chrome
```

Xem giao diện trong trình duyệt, hot reload trong ~1 giây. **Không chạy được trên web**: thông báo, vân tay, widget màn hình chính — ba thứ đó cần thiết bị Android thật.

## Build APK

```bash
flutter build apk --release --split-per-abi
```

Kết quả ở `build/app/outputs/flutter-apk/`. Máy Android đời mới dùng bản `arm64-v8a` (~24MB).

## Lệnh thường dùng

```bash
dart run build_runner watch        # để chạy nền suốt phiên làm việc
flutter analyze                    # phải sạch trước khi coi là xong một task
flutter test                       # 265 test
```

Sau khi sửa bảng drift hoặc provider có `@riverpod` thì **phải chạy `build_runner`** trước khi analyze.

> `--delete-conflicting-outputs` đã bị `build_runner` mới bỏ; đừng dùng nữa.

---

## Khác gì MoneyNote

| MoneyNote | App này |
|---|---|
| Không có số dư gốc, chỉ cộng trừ từ 0 | Mỗi ví khai **số tiền thật đang có** |
| Một sổ, thêm ví phải trả Premium | Nhiều ví, chuyển tiền giữa ví, miễn phí |
| Xuất dữ liệu khoá Premium | CSV + Excel 4 sheet + sao lưu `.zip`, không giới hạn |
| Đầy quảng cáo | Không một SDK quảng cáo hay analytics nào |
| Báo cáo chỉ có một biểu đồ tròn | Donut, cột 12 tháng, bảng %, **và câu diễn giải tự sinh** |
| Ngân sách chỉ là con số | Cảnh báo 80%/100%, "còn tiêu được bao nhiêu/ngày", cảnh báo sớm theo nhịp chi |
| Không có khoản định kỳ | Tự ghi hoặc nhắc xác nhận, bù được kỳ đã lỡ |
| Không tìm được giao dịch | Tìm **không dấu** + lọc theo ngày/ví/danh mục/khoảng tiền |
| Sửa danh mục chỉ đổi được tên | Đổi tên, icon, màu, kéo thả sắp xếp, ẩn mà không mất lịch sử |
| Ô lịch để trống | Mỗi ngày hiện thu (xanh) và chi (đỏ) |
| Không có widget | Widget 4×2 có nút ghi nhanh |
| — | Hướng dẫn giữ app chạy nền cho MIUI, có nút mở thẳng cài đặt hệ thống |

---

## Kiến trúc

```
UI (ConsumerWidget) → Provider (Riverpod 3) → Repository → DAO (drift) → SQLite
```

UI **không bao giờ** gọi thẳng DAO. Logic nghiệp vụ nằm ở `domain/` dưới dạng hàm thuần, test được không cần Flutter.

Thư mục theo **tính năng**, không theo loại file:

```
lib/
├── core/          db, theme, utils, router, notifications, platform
├── features/      entry, calendar, report, budget, recurring, wallet,
│                  category, search, backup, settings, onboarding, widget_home
└── shared/        widget và provider dùng chung
```

## Ba quy tắc không được phá

1. **Tiền luôn là `int`, đơn vị đồng.** Không bao giờ `double`. Lý do ở `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 5.
2. **Mọi truy vấn báo cáo phải lọc `type IN ('income','expense')`.** Chuyển ví và điều chỉnh số dư không phải thu chi. Quên mệnh đề này là bug phổ biến nhất của app kiểu này.
3. **Đổi schema thì tăng `schemaVersion` và viết `onUpgrade`.** Không bao giờ gỡ app cài lại — trong đó có dữ liệu tài chính thật.

## Hai cái bẫy đã trả giá

**Không dựng `IconData(codePoint)` lúc chạy.** Schema lưu icon dạng số, nhưng dựng động sẽ làm hỏng tree-shaking và `flutter build apk` dừng lại. Dùng bảng tra `const` ở `lib/core/theme/app_icons.dart`. Log build xác nhận: font icon giảm từ 1.6MB xuống 12.8KB.

**Widget test có database cần `tester.runAsync`.** Thân `testWidgets` chạy trong vùng `FakeAsync`, nên mọi I/O thật không bao giờ hoàn tất. Và `pumpAndSettle()` không bao giờ dừng nếu màn hình có `CircularProgressIndicator`.

---

## Test

265 test, chạy trong ~6 giây. Bốn nhóm bắt buộc theo `CONVENTIONS.md`:

| Nhóm | File |
|---|---|
| `nextOccurrence()` — kể cả ngày 29/30/31 và năm nhuận | `test/features/next_occurrence_test.dart` |
| Công thức số dư ví (DB in-memory) | `test/core/balance_test.dart` |
| `parseMoney()` / `formatMoney()` | `test/core/money_test.dart` |
| Kỳ tài chính khi `month_start_day != 1` | `test/core/date_range_test.dart` |

Bài test đáng nhắc nhất: chuỗi 12 tháng của quy tắc "ngày 31 hằng tháng" phải ra `28/2 → 31/3 → 30/4 → 31/5…` chứ không kẹt ở 28 mãi mãi.

---

## Chưa làm

- **Keystore ký release riêng.** Hiện release ký bằng khoá debug — cài lên máy dùng riêng thì được, nhưng cần keystore thật nếu muốn phát hành. Xem `ke-hoach-app/05_BUILD_APK_CI.md`.
- **GitHub Actions tự build khi tạo tag.**
- Ảnh hoá đơn, OCR, đọc SMS ngân hàng, đồng bộ Drive, nhiều tiền tệ, bản iOS — đều đã hoãn sang v2, ghi ở `00_TONG_QUAN.md` mục 3.

## Không bao giờ commit

`key.properties`, `*.jks`, `*.keystore`.
