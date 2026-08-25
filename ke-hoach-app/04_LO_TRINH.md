# 04 — Lộ trình thực hiện

Giả định: bạn dành **2–3 giờ/ngày**, chưa từng viết Dart/Flutter. Tổng thời gian ước tính **8–11 tuần** để hoàn thành v1. Nếu chỉ cần bản dùng được (Phase 0–4), khoảng **4 tuần**.

Quy tắc: **cuối mỗi phase app phải build và chạy được trên điện thoại**. Không sang phase mới khi phase cũ còn lỗi.

---

## Phase 0 — Môi trường (1–2 ngày)

- [ ] Làm hết `03_SETUP_WINDOWS.md`
- [ ] `flutter doctor` xanh 3 mục đầu
- [ ] Chạy được app demo trên điện thoại thật
- [ ] Thử hot reload thành công
- [ ] Push commit đầu lên GitHub repo private

**Xong khi**: sửa một dòng chữ trong app, thấy nó đổi trên điện thoại trong 1 giây.

---

## Phase 1 — Học Dart & Flutter vừa đủ (4–6 ngày)

Đừng học hết. Học đúng những thứ app này cần.

### Dart (2 ngày)
- [ ] Biến, `final` vs `const`, kiểu dữ liệu
- [ ] **Null safety**: `?`, `!`, `??`, `late` — thứ khác Python nhiều nhất
- [ ] Class, constructor, named parameters, `copyWith`
- [ ] `List`, `Map` và các hàm `map` / `where` / `fold` (giống list comprehension của Python)
- [ ] `Future`, `async`/`await`, `Stream` — **Stream là khái niệm cốt lõi của app này**
- [ ] `enum`, `switch` với pattern matching

Nguồn: `dart.dev/language` — đọc thẳng, khoảng 3 tiếng. Gõ thử ở `dartpad.dev`.

### Flutter (2–3 ngày)
- [ ] Widget tree, `StatelessWidget` vs `StatefulWidget`
- [ ] Layout: `Column`, `Row`, `Expanded`, `Padding`, `SizedBox`, `Stack`
- [ ] `ListView.builder`, `GridView`
- [ ] `Scaffold`, `AppBar`, `BottomNavigationBar`, `TabBar`
- [ ] `showModalBottomSheet`, `showDialog`, `SnackBar`
- [ ] `TextField` + `TextEditingController`
- [ ] `Theme` và `ColorScheme`

### Riverpod 3 (1–2 ngày)
- [ ] `ProviderScope` bọc app
- [ ] Code generation: annotation `@riverpod` + `build_runner`
- [ ] `Provider`, `FutureProvider`, `StreamProvider`, `NotifierProvider`
- [ ] `ref.watch` vs `ref.read` — **nguồn gốc 80% bug của người mới**
- [ ] `ConsumerWidget`

### Bài tập bắt buộc trước khi sang Phase 2
Tự làm một app nhỏ: danh sách ghi chú, thêm/xoá được, lưu bằng `shared_preferences`, có 2 tab. Khoảng 150 dòng. **Không copy** — gõ tay.

---

## Phase 2 — Nền dữ liệu (5–7 ngày)

- [ ] Tạo project thật, cấu hình thư mục theo `02_KIEN_TRUC_DATA.md` mục 2
- [ ] Thêm dependencies bắt buộc
- [ ] Định nghĩa 6 bảng drift: `wallets`, `categories`, `transactions`, `budgets`, `recurring_rules`, `settings`
- [ ] Chạy `build_runner`, sinh code thành công
- [ ] Viết seed data: danh mục mặc định được chèn khi DB tạo lần đầu
- [ ] Viết `WalletDao` với truy vấn số dư (mục 6 của file 02)
- [ ] Viết `money.dart`: `formatMoney()`, `parseMoney()`
- [ ] **Unit test**: công thức số dư, format tiền
- [ ] Màn hình tạm hiển thị danh sách ví + số dư để mắt thấy dữ liệu chạy

**Xong khi**: thêm tay một ví có số dư gốc 5.000.000 và một giao dịch chi 50.000 vào DB, app hiển thị 4.950.000.

---

## Phase 2.5 — Hệ thống thiết kế (2–3 ngày)

Chi tiết đầy đủ ở `07_UI_UX.md` mục 7. Tóm tắt:

- [ ] Thu thập 10 ảnh tham chiếu (Mobbin / Dribbble), ghi chú **cấu trúc** chứ không phải phong cách
- [ ] Chốt bảng màu bằng Themes Playground → xuất code `flex_color_scheme`
- [ ] Nhúng font Be Vietnam Pro, bật `FontFeature.tabularFigures()` cho số tiền
- [ ] Viết `tokens.dart` (spacing 4dp, radius, duration) + `ThemeExtension` cho income/expense/budget
- [ ] Dựng trang "Design Gallery" nội bộ hiển thị mọi component ở cả sáng và tối
- [ ] Kiểm tương phản ≥ 4.5:1 và cỡ chữ hệ thống 130%

**Xong khi**: có một trang gallery cho thấy nút, thẻ, chip, ô danh mục đều đúng màu ở cả hai chế độ.

---

## Phase 3 — Nhập giao dịch (7–10 ngày)

- [ ] Khung app: `BottomNavigationBar` 5 tab, `go_router`
- [ ] Theme sáng/tối, bảng màu, font chữ, định dạng số `vi_VN`
- [ ] Màn hình Nhập vào: tab Chi/Thu, chọn ngày, chọn ví, ghi chú
- [ ] **Bàn phím số tuỳ chỉnh** có `+ − × ÷` (mục B.2 file 01)
- [ ] Lưới danh mục có icon, màu, nút "Chỉnh sửa"
- [ ] Lưu giao dịch → hiện SnackBar có nút Hoàn tác
- [ ] Thẻ số dư ở đầu màn hình
- [ ] Màn hình Quản lý ví: thêm/sửa/lưu trữ, điều chỉnh số dư
- [ ] Màn hình Quản lý danh mục: thêm/sửa/ẩn/kéo thả sắp xếp
- [ ] Tab Chuyển ví

**Xong khi**: dùng app nhập được chi tiêu thật của bạn trong 1 ngày, không thấy vướng.

---

## Phase 4 — Lịch & danh sách (4–6 ngày)

- [ ] Lưới lịch tháng tự viết (đừng dùng package — bạn cần hiển thị 2 dòng số trong mỗi ô)
- [ ] Thu/chi hiển thị trong từng ô ngày
- [ ] Thanh tổng Thu | Chi | Tổng
- [ ] Bottom sheet danh sách giao dịch theo ngày
- [ ] Vuốt trái xoá, vuốt phải sửa
- [ ] Màn hình sửa giao dịch
- [ ] Màn hình tìm kiếm + bộ lọc đầy đủ

**Xong khi**: bạn dùng app này thay MoneyNote được rồi. Đây là mốc quan trọng nhất — **bắt đầu nhập dữ liệu thật từ đây**.

---

## Phase 5 — Báo cáo & biểu đồ (5–7 ngày)

- [ ] Truy vấn tổng hợp: theo danh mục, theo tháng, số dư luỹ kế
- [ ] Thẻ tóm tắt Chi/Thu/Thu chi
- [ ] Biểu đồ tròn danh mục (`fl_chart`), bấm lát cắt để lọc
- [ ] Biểu đồ cột 12 tháng
- [ ] Biểu đồ đường số dư luỹ kế
- [ ] Bảng chi tiết theo danh mục có thanh %
- [ ] So sánh kỳ này vs kỳ trước
- [ ] Dòng nhận xét tự động (trung bình/ngày, dự báo cuối tháng)
- [ ] Chuyển kỳ: Tháng / Năm / Toàn kỳ

---

## Phase 6 — Ngân sách (3–4 ngày)

- [ ] Màn hình đặt ngân sách tổng + theo danh mục
- [ ] Thanh tiến độ đổi màu theo ngưỡng
- [ ] Tính "còn tiêu được bao nhiêu mỗi ngày"
- [ ] Nút "Áp dụng cho các tháng sau"
- [ ] Nút "Gợi ý từ 3 tháng gần nhất"
- [ ] Thông báo cảnh báo 80% / 100%

---

## Phase 7 — Khoản định kỳ (4–6 ngày)

- [ ] Viết `nextOccurrence()` **kèm unit test trước** (ngày 29/30/31, năm nhuận)
- [ ] Màn hình tạo/sửa quy tắc định kỳ
- [ ] Quét khi mở app, xử lý bù các kỳ đã lỡ
- [ ] `workmanager` chạy 1 lần/ngày
- [ ] `flutter_local_notifications`: xin quyền `POST_NOTIFICATIONS` (Android 13+)
- [ ] Chế độ tự ghi vs nhắc xác nhận
- [ ] Màn hình hướng dẫn bật Tự khởi động cho MIUI + nút mở cài đặt hệ thống

---

## Phase 8 — Xuất dữ liệu & Widget (5–7 ngày)

- [ ] Xuất CSV (**UTF-8 có BOM**)
- [ ] Xuất Excel nhiều sheet
- [ ] Backup ra `.zip`, restore từ `.zip`
- [ ] Chia sẻ file qua `share_plus`
- [ ] Widget 2×1: layout XML + `AppWidgetProvider` Kotlin
- [ ] Widget 4×2 có nút nhập nhanh
- [ ] Cập nhật widget qua `home_widget` mỗi khi dữ liệu đổi
- [ ] Deep link từ widget vào màn hình nhập

> Đây là phase khó nhất — có Kotlin, XML layout Android, và cơ chế cập nhật widget khá khó debug. Dự trù thêm vài ngày.

---

## Phase 9 — Onboarding & hoàn thiện (4–5 ngày)

- [ ] 4 màn hình onboarding
- [ ] Icon app (`flutter_launcher_icons`) + màn hình khởi động
- [ ] Khoá bằng PIN + vân tay
- [ ] Nhắc nhập chi tiêu hằng ngày
- [ ] Đổi màu chủ đề
- [ ] Xử lý trạng thái rỗng ("Chưa có giao dịch nào") cho mọi màn hình
- [ ] Kiểm tra dark mode toàn bộ màn hình
- [ ] `flutter analyze` không còn cảnh báo
- [ ] Nhờ 1–2 người dùng thử, ghi lại chỗ họ lúng túng

---

## Phase 10 — Build & phát hành (2–3 ngày)

- [ ] Làm theo `05_BUILD_APK_CI.md`
- [ ] Tạo keystore, cấu hình ký release
- [ ] Bật minify + shrink resources
- [ ] Build APK release, cài lên máy, dùng thử 3 ngày
- [ ] Dựng GitHub Actions tự build khi tạo tag
- [ ] Viết README cho repo

---

## Bảng theo dõi tiến độ

| Phase | Nội dung | Ước tính | Bắt đầu | Xong |
|---|---|---|---|---|
| 0 | Môi trường | 1–2 ngày | | |
| 1 | Học Dart/Flutter | 4–6 ngày | | |
| 2 | Nền dữ liệu | 5–7 ngày | | |
| 2.5 | Hệ thống thiết kế | 2–3 ngày | | |
| 3 | Nhập giao dịch | 7–10 ngày | | |
| 4 | Lịch & danh sách | 4–6 ngày | | |
| 5 | Báo cáo & biểu đồ | 5–7 ngày | | |
| 6 | Ngân sách | 3–4 ngày | | |
| 7 | Khoản định kỳ | 4–6 ngày | | |
| 8 | Xuất dữ liệu & Widget | 5–7 ngày | | |
| 9 | Onboarding & hoàn thiện | 4–5 ngày | | |
| 10 | Build & phát hành | 2–3 ngày | | |

---

## Cách rút ngắn nếu gấp

Bản dùng được tối thiểu = **Phase 0 → 4** (khoảng 4 tuần). Lúc đó bạn đã có: nhiều ví, số dư gốc, nhập thu chi, lịch, tìm kiếm — tức là **đã hơn MoneyNote free** ở khoản số dư gốc, nhiều ví và không quảng cáo. Các phase sau bổ sung dần trong lúc vẫn dùng app hằng ngày.

Ưu tiên nếu phải cắt: Phase 5 (báo cáo) > Phase 8 (xuất dữ liệu) > Phase 6 (ngân sách) > Phase 7 (định kỳ) > widget.

---

## Bẫy thường gặp với người mới

| Bẫy | Cách tránh |
|---|---|
| Thiết kế UI đẹp trước khi có dữ liệu chạy | Làm DB trước (Phase 2), UI xấu cũng được, đẹp sau |
| Dùng `ref.read` trong `build()` | Trong `build()` luôn dùng `ref.watch` |
| Quên chạy `build_runner` sau khi sửa bảng drift | Cứ để `build_runner watch` chạy nền |
| Lưu tiền bằng `double` | Đọc lại mục 5 file 02 |
| Không commit git nhiều ngày | Commit mỗi khi một tính năng nhỏ chạy được |
| Cài lại app khi lỗi DB → mất dữ liệu thật | Luôn viết migration; test trên bản debug riêng |
| Copy code AI sinh ra mà không hiểu | Nếu không giải thích được một dòng, đừng giữ nó |
