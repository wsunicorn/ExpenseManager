# 00 — Tổng quan kế hoạch: App Sổ Thu Chi (Android)

> Ngày lập: 24/08/2026
> Người thực hiện: Nguyễn Ngọc Lân
> Mục tiêu: tự dựng một app quản lý thu chi cá nhân trên Android, tốt hơn app "Sổ thu chi MoneyNote ver 4.7" đang dùng, và tự build ra file `.apk` để cài.

---

## 1. Quyết định đã chốt

| Hạng mục | Lựa chọn | Lý do |
|---|---|---|
| Công nghệ | **Flutter (Dart)** | Bạn có thể mở rộng sang iOS/desktop sau này mà không viết lại. Hot reload giúp người mới thấy kết quả nhanh. Hệ sinh thái biểu đồ + xuất file mạnh nhất trong 3 lựa chọn. |
| Cơ sở dữ liệu | **Drift (SQLite)** | Type-safe, sinh code sẵn, hỗ trợ stream (UI tự cập nhật khi DB đổi), migration rõ ràng. |
| Quản lý state | **Riverpod 3 + code generation** | Không cần `BuildContext`, dễ test, phù hợp app có nhiều luồng dữ liệu phái sinh (số dư, báo cáo). |
| Lưu trữ | **Offline hoàn toàn** + xuất/nhập file backup | Theo yêu cầu. Không cần server, không cần tài khoản, không rò rỉ dữ liệu tài chính. |
| Nền tảng v1 | **Chỉ Android** | Nhưng code viết theo hướng không phụ thuộc Android, để bật iOS sau chỉ mất công ở phần widget + thông báo. |
| Máy dev | **Windows** | Xem file `03_SETUP_WINDOWS.md`. |
| Build APK | **Máy local (dev) + GitHub Actions (release)** | Local để iterate hằng ngày; CI để tạo APK ký sẵn tải về từ điện thoại. |
| Quảng cáo / Premium | **Không có** | App dùng riêng, mọi tính năng mở khoá. |

### Ghi chú về hệ quả kỹ thuật của việc chọn Flutter

Có **hai phần bắt buộc phải viết code Kotlin native** (không tránh được với bất kỳ framework cross-platform nào):

1. **Widget màn hình chính** — dùng package `home_widget`, phần hiển thị vẫn là `AppWidgetProvider` + layout XML (hoặc Glance) bên Android.
2. **Job chạy nền** cho khoản định kỳ — dùng `workmanager`, cấu hình trong `MainActivity.kt`.

Khối lượng ước tính: ~120–200 dòng Kotlin. Đã tính vào lộ trình (Phase 8).

---

## 2. So sánh với MoneyNote: giữ gì — sửa gì

### Giữ lại (những thứ MoneyNote làm đúng)

- Cấu trúc 5 tab dưới đáy: Nhập vào / Lịch / Báo cáo / Ngân sách / Khác.
- Màn hình nhập giao dịch một trang: Ngày → Ghi chú → Số tiền → Danh mục → nút xác nhận lớn.
- Lưới danh mục dạng icon + nhãn, có ô "Chỉnh sửa" ngay trong lưới.
- Thanh chọn tháng có mũi tên trái/phải + nút mở lịch.
- Lịch tháng có tổng Thu / Chi / Tổng ngay dưới.

### Sửa / bổ sung (điểm yếu của MoneyNote)

| Vấn đề của MoneyNote | Hướng giải quyết trong app mới |
|---|---|
| **Không có số dư gốc.** App chỉ cộng trừ từ 0, không biết bạn thực sự có bao nhiêu tiền. | Mỗi ví có **số dư ban đầu** (`initialBalance`) khai báo lúc tạo. Số dư hiện tại = số dư ban đầu + thu − chi. Hiển thị nổi bật ở đầu app. |
| **Một sổ duy nhất.** "Thêm hoặc chỉnh sửa tài khoản" bị khoá sau vương miện Premium. | **Nhiều ví miễn phí**: Tiền mặt, MoMo, ngân hàng, ví điện tử… Có **chuyển tiền giữa ví** (không tính vào thu/chi). |
| **Xuất dữ liệu bị khoá Premium** (icon vương miện ở "Đầu ra dữ liệu"). | Xuất **CSV + Excel (.xlsx)** không giới hạn, kèm backup/restore toàn bộ DB. |
| **Đầy quảng cáo** (banner Netmarble ở mọi màn hình + 9 mục app AD trong tab Khác). | Không có bất kỳ SDK quảng cáo nào. |
| **Báo cáo mỏng**: chỉ có tổng thu/chi và một biểu đồ tròn. | Bộ báo cáo: tròn theo danh mục, cột theo tháng, đường số dư luỹ kế, so sánh tháng này vs tháng trước, top 5 danh mục tăng mạnh nhất. |
| **Ngân sách chỉ là con số**, không cảnh báo. | Ngân sách theo danh mục + **cảnh báo 80% / 100%** qua thông báo, thanh tiến độ đổi màu, tính "còn tiêu được bao nhiêu/ngày". |
| **Không có khoản định kỳ.** Tiền nhà, tiền điện, phí Internet phải nhập tay mỗi tháng. | **Khoản định kỳ**: tự sinh giao dịch hoặc nhắc xác nhận theo chu kỳ ngày/tuần/tháng/năm. |
| **Không có widget.** | Widget màn hình chính: số dư + chi tiêu hôm nay + nút nhập nhanh. |
| **Không tìm kiếm được giao dịch.** | Tìm kiếm theo ghi chú, lọc theo khoảng tiền / danh mục / ví / khoảng ngày. |
| **Nhập liệu chậm** (gõ số bằng bàn phím hệ thống). | Bàn phím số riêng có phép tính `+ − × ÷`, gợi ý danh mục dùng gần đây, nút "lặp lại giao dịch gần nhất". |
| **Không có dark mode.** | Sáng / Tối / Theo hệ thống. |

---

## 3. Phạm vi

### Có trong v1

1. Onboarding lần đầu (chọn tiền tệ, tạo ví đầu tiên + số dư gốc, chọn danh mục).
2. Nhiều ví, chuyển tiền giữa ví, điều chỉnh số dư.
3. Nhập thu / chi với danh mục tuỳ biến (thêm, sửa, xoá, đổi icon, đổi màu, sắp xếp).
4. Lịch tháng + danh sách giao dịch theo ngày.
5. Báo cáo tháng / năm / toàn kỳ, có biểu đồ.
6. Ngân sách theo tháng, tổng và theo danh mục, có cảnh báo.
7. Khoản thu/chi định kỳ.
8. Tìm kiếm + lọc giao dịch.
9. Xuất CSV / Excel, backup & restore file `.zip`.
10. Widget màn hình chính.
11. Dark mode, đổi màu chủ đề.
12. Khoá app bằng vân tay / mã PIN.

### Để sau v1 (ghi lại để không quên)

- Ảnh hoá đơn đính kèm giao dịch.
- Quét hoá đơn bằng OCR (đây là chỗ nền tảng AI của bạn có thể toả sáng — nhưng để v2).
- Đọc SMS ngân hàng để gợi ý giao dịch.
- Đồng bộ Google Drive.
- Nhiều loại tiền tệ trong cùng một sổ.
- Bản iOS.

---

## 4. Bộ tài liệu kế hoạch

| File | Nội dung |
|---|---|
| `00_TONG_QUAN.md` | File này — quyết định, phạm vi, so sánh. |
| `01_DAC_TA_TINH_NANG.md` | Đặc tả từng màn hình, từng luồng, quy tắc nghiệp vụ. |
| `02_KIEN_TRUC_DATA.md` | Kiến trúc code, cấu trúc thư mục, schema DB, công thức tính số dư. |
| `03_SETUP_WINDOWS.md` | Cài đặt môi trường trên Windows từ số 0, chạy app lên điện thoại. |
| `04_LO_TRINH.md` | Lộ trình 10 phase, checklist từng phase, ước lượng thời gian, cách học Dart. |
| `05_BUILD_APK_CI.md` | Tạo keystore, build APK release, GitHub Actions, cài lên máy. |
| `06_RA_SOAT_CONG_NGHE.md` | **Rà soát stack 24/08/2026** — thay thế mục 1 của file 02. |
| `07_UI_UX.md` | Design token, bố cục màn hình, motion, accessibility, quy trình làm UI. |

---

## 5. Nguyên tắc làm việc

1. **Mỗi phase phải chạy được.** Không viết 3 phase rồi mới bấm run lần đầu.
2. **Commit sau mỗi tính năng nhỏ.** Git là mạng lưới an toàn duy nhất.
3. **Không tối ưu sớm.** App cá nhân, vài nghìn giao dịch — SQLite thừa sức.
4. **Tiền lưu bằng số nguyên (đơn vị đồng), không dùng `double`.** Xem `02_KIEN_TRUC_DATA.md` mục 5.
5. **Test trên máy thật từ Phase 1**, không chỉ emulator — vì widget và thông báo hành xử khác nhau, đặc biệt trên MIUI/Xiaomi.
