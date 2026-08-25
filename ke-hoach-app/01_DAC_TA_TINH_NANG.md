# 01 — Đặc tả tính năng & màn hình

Ký hiệu: `[BB]` = bắt buộc v1, `[TC]` = tuỳ chọn nếu còn thời gian.

---

## A. Onboarding (lần mở app đầu tiên)

Đây là phần bạn chưa chụp được ở MoneyNote, nên ta tự thiết kế. 4 bước, có nút "Bỏ qua" ở mọi bước trừ bước 2.

### Bước 1 — Chào mừng `[BB]`
- Logo + tên app + 1 câu: "Sổ thu chi offline. Không quảng cáo. Dữ liệu nằm trên máy bạn."
- Nút: **Bắt đầu**.

### Bước 2 — Tạo ví đầu tiên `[BB]` (không được bỏ qua)
Đây là **điểm khác biệt lớn nhất so với MoneyNote**.

| Trường | Kiểu | Mặc định | Ghi chú |
|---|---|---|---|
| Tên ví | text | "Tiền mặt" | tối đa 50 ký tự |
| Loại ví | chọn | Tiền mặt | Tiền mặt / Ngân hàng / Ví điện tử / Thẻ tín dụng / Tiết kiệm |
| Icon + màu | chọn | ví màu xanh | lưới 24 icon |
| **Số dư hiện có** | tiền | 0 | "Số tiền bạn đang có trong ví này ngay lúc này" |
| Tiền tệ | chọn | VND (đ) | v1 chỉ 1 tiền tệ cho toàn app |

Dưới ô số dư có dòng phụ: *"Mọi khoản thu chi sau này sẽ được cộng/trừ từ con số này."*

### Bước 3 — Chọn danh mục `[BB]`
- Hiện sẵn bộ danh mục mặc định (mục F bên dưới), người dùng bỏ tick những cái không cần.
- Nút: **Dùng bộ mặc định** / **Tuỳ chỉnh**.

### Bước 4 — Tuỳ chọn nhanh `[BB]`
- Giao diện: Sáng / Tối / Theo hệ thống.
- Bật nhắc nhập chi tiêu hằng ngày? (giờ mặc định 21:00)
- Nút: **Xong** → vào tab Nhập vào.

> Lưu cờ `onboarding_done = true` vào bảng `settings`. Có mục "Chạy lại hướng dẫn" trong tab Khác.

---

## B. Tab 1 — Nhập vào (màn hình mặc định khi mở app)

### B.1 Bố cục `[BB]`
Từ trên xuống:

1. **Thẻ số dư** (MoneyNote không có):
   - Dòng lớn: tổng số dư tất cả ví (chỉ tính ví có `includeInTotal = true`).
   - Dòng nhỏ: "Tháng này: +thu / −chi".
   - Bấm vào → mở màn hình Danh sách ví.
2. **Tab Chi tiêu / Thu nhập** (giống MoneyNote) + tab thứ 3: **Chuyển ví**.
3. **Ngày** — có mũi tên `<` `>` và nút mở lịch. Mặc định hôm nay.
4. **Ví** — dropdown, mặc định là ví dùng lần gần nhất.
5. **Ghi chú** — text, có gợi ý autocomplete từ các ghi chú cũ.
6. **Số tiền** — bấm vào mở **bàn phím số tuỳ chỉnh** (mục B.2).
7. **Lưới danh mục** — icon + nhãn, ô cuối là **Chỉnh sửa**. Danh mục dùng gần đây được đẩy lên đầu.
8. **Nút xác nhận lớn**: "Nhập khoản Tiền chi" / "Nhập khoản Tiền thu".

### B.2 Bàn phím số tuỳ chỉnh `[BB]`
- Phím: `0-9`, `000`, `xoá`, `+`, `−`, `×`, `÷`, `=`, và **nút Lưu** ngay trên bàn phím.
- Hiển thị phép tính đang gõ ở trên (VD: `50000 + 25000`), kết quả tự tính khi bấm Lưu.
- Tự chèn dấu phân cách hàng nghìn khi hiển thị: `1.250.000 đ`.
- Lý do: người Việt hay cộng nhiều món trong một hoá đơn. MoneyNote bắt mở máy tính riêng.

### B.3 Tab Chuyển ví `[BB]`
- Trường: Từ ví → Đến ví, Số tiền, Phí chuyển (mặc định 0), Ngày, Ghi chú.
- **Không tính vào Thu nhập hay Chi tiêu** trong báo cáo. Phí chuyển (nếu có) được ghi thành 1 giao dịch chi thuộc danh mục "Phí ngân hàng".
- Chặn: ví nguồn = ví đích.

### B.4 Hành vi sau khi lưu `[BB]`
- Toast "Đã lưu" + nút **Hoàn tác** trong 5 giây.
- Số tiền và ghi chú reset, danh mục và ngày giữ nguyên (để nhập liên tiếp nhanh).
- Nút nổi "Lặp lại giao dịch gần nhất" `[TC]`.

---

## C. Tab 2 — Lịch

### C.1 Lưới lịch tháng `[BB]`
- Giống MoneyNote: Th2 → CN, ngày ngoài tháng làm mờ, hôm nay tô nền.
- **Cải tiến**: trong mỗi ô ngày hiển thị 2 dòng nhỏ — thu (xanh) và chi (đỏ) của ngày đó. MoneyNote để trống các ô.
- Bấm 1 ngày → mở bảng trượt (bottom sheet) danh sách giao dịch ngày đó.

### C.2 Thanh tổng kết `[BB]`
Dưới lịch: Thu nhập | Chi tiêu | Tổng — của tháng đang xem.

### C.3 Danh sách giao dịch `[BB]`
- Mỗi dòng: icon danh mục, tên danh mục, ghi chú, tên ví, số tiền (xanh/đỏ).
- Vuốt trái → Xoá (có xác nhận). Vuốt phải → Sửa.
- Bấm → mở màn hình chi tiết/sửa.

### C.4 Tìm kiếm `[BB]`
Nút kính lúp góc phải mở màn hình tìm kiếm:
- Ô nhập từ khoá (tìm trong ghi chú + tên danh mục).
- Bộ lọc: khoảng ngày, ví, danh mục (nhiều), loại (thu/chi/chuyển), khoảng tiền (từ – đến).
- Kết quả có dòng tổng ở đầu: "38 giao dịch · −4.520.000 đ".
- Nút "Xuất kết quả này ra CSV".

---

## D. Tab 3 — Báo cáo

Có 3 mức: **Hàng tháng / Hàng năm / Toàn kỳ**.

### D.1 Thẻ tóm tắt `[BB]`
Chi tiêu −X | Thu nhập +Y | Thu chi ±Z (giống MoneyNote, giữ nguyên).

### D.2 Biểu đồ `[BB]`
Dùng `fl_chart`:

| Biểu đồ | Loại | Nội dung |
|---|---|---|
| Cơ cấu chi tiêu | Tròn (donut) | Tỷ trọng từng danh mục, bấm vào lát cắt → lọc danh sách bên dưới |
| Thu chi theo tháng | Cột nhóm | 12 tháng, 2 cột thu/chi cạnh nhau |
| Số dư luỹ kế | Đường | Số dư cuối mỗi ngày/tháng — cho thấy xu hướng thật sự |
| So sánh kỳ | Thanh ngang đôi | Tháng này vs tháng trước theo từng danh mục |

### D.3 Bảng chi tiết `[BB]`
Dưới biểu đồ: danh sách danh mục sắp theo số tiền giảm dần, mỗi dòng có thanh tiến độ %, số tiền, số giao dịch. Bấm → xem giao dịch của danh mục đó.

### D.4 Thông tin phái sinh `[BB]`
Dòng chữ nhỏ ở cuối, ví dụ:
- "Trung bình 152.000 đ/ngày trong tháng này."
- "Chi nhiều hơn tháng trước 18% (chủ yếu ở Ăn uống)."
- "Nếu giữ nhịp này, cuối tháng bạn sẽ chi khoảng 4.6 triệu."

### D.5 Xuất báo cáo `[BB]`
Nút chia sẻ góc phải: xuất kỳ đang xem ra `.csv` hoặc `.xlsx` → mở hộp thoại chia sẻ Android (Zalo, Drive, Gmail…). Chi tiết ở mục G.

---

## E. Tab 4 — Ngân sách

### E.1 Đặt ngân sách `[BB]`
- **Tổng ngân sách** tháng + ngân sách riêng từng danh mục (giống MoneyNote).
- **Cải tiến 1**: nút "Áp dụng cho các tháng sau" — MoneyNote bắt đặt lại mỗi tháng.
- **Cải tiến 2**: nút "Gợi ý từ 3 tháng gần nhất" — điền sẵn mức trung bình đã chi.

### E.2 Hiển thị `[BB]`
Mỗi dòng danh mục:
- Thanh tiến độ: xanh (< 80%), vàng (80–100%), đỏ (> 100%).
- Text: `1.850.000 / 3.000.000 đ · còn 1.150.000 đ`.
- Dòng phụ: `Còn 12 ngày · có thể tiêu 95.000 đ/ngày`.

### E.3 Cảnh báo `[BB]`
Thông báo cục bộ khi một danh mục chạm 80% và 100% ngân sách. Bật/tắt trong Cài đặt.

---

## F. Danh mục & Ví

### F.1 Danh mục mặc định `[BB]`

**Chi tiêu**: Ăn uống · Chi tiêu hàng ngày · Quần áo · Mỹ phẩm · Phí giao lưu · Y tế · Giáo dục · Tiền điện nước · Đi lại · Phí liên lạc · Tiền nhà · Giải trí · Phí ngân hàng · Khác

**Thu nhập**: Tiền lương · Tiền phụ cấp · Tiền thưởng · Thu nhập phụ · Đầu tư · Thu nhập khác

(Bộ này bám theo MoneyNote + bổ sung Giải trí và Phí ngân hàng.)

### F.2 Quản lý danh mục `[BB]`
- Thêm / sửa / xoá / đổi icon / đổi màu / kéo thả sắp xếp.
- **Không cho xoá cứng** danh mục đã có giao dịch → chỉ cho **ẩn** (`isArchived`), giữ nguyên lịch sử.
- Danh mục con `[TC]` (VD: Ăn uống → Ăn sáng / Cà phê / Đi chợ).

### F.3 Quản lý ví `[BB]`
- Danh sách ví: tên, icon, số dư hiện tại, có/không tính vào tổng.
- Thêm ví: các trường như bước 2 onboarding.
- **Điều chỉnh số dư**: nhập số dư thực tế đang có → app tự tạo một giao dịch loại `adjustment` bằng phần chênh lệch. Dùng khi đếm lại ví tiền mặt thấy lệch.
- Lưu trữ ví (archive) thay vì xoá nếu ví đã có giao dịch.

---

## G. Xuất dữ liệu & Backup

### G.1 Xuất CSV `[BB]`
Cột: `ngay, loai, so_tien, tien_te, vi, danh_muc, ghi_chu, vi_dich, id`
- Mã hoá **UTF-8 có BOM** để Excel trên Windows không vỡ tiếng Việt. Đây là lỗi kinh điển, đừng quên.
- Chọn khoảng thời gian trước khi xuất.

### G.2 Xuất Excel `[BB]`
File `.xlsx` nhiều sheet:
1. `GiaoDich` — bảng đầy đủ, có auto-filter.
2. `TheoDanhMuc` — pivot tổng theo danh mục × tháng.
3. `TheoVi` — số dư đầu kỳ, thu, chi, số dư cuối kỳ từng ví.
4. `TongQuan` — tóm tắt kỳ.

### G.3 Backup & Restore `[BB]`
- **Backup**: nén file DB + file cấu hình thành `sothuchi_backup_YYYYMMDD_HHmm.zip`, lưu vào thư mục người dùng chọn hoặc chia sẻ đi.
- **Restore**: chọn file zip → cảnh báo "Dữ liệu hiện tại sẽ bị thay thế" → nhập xong khởi động lại app.
- **Backup tự động** `[TC]`: mỗi 7 ngày ghi vào thư mục nội bộ, giữ 5 bản gần nhất.

---

## H. Khoản định kỳ

### H.1 Tạo quy tắc `[BB]`
Trường: loại (thu/chi), ví, danh mục, số tiền, ghi chú, chu kỳ (ngày / tuần / tháng / năm), khoảng lặp (mỗi N kỳ), ngày bắt đầu, ngày kết thúc (hoặc không).

Chế độ:
- **Tự động ghi**: đến hạn là tạo giao dịch luôn (hợp với tiền nhà cố định).
- **Nhắc xác nhận**: gửi thông báo, bạn bấm vào để duyệt hoặc bỏ qua (hợp với tiền điện, số tiền thay đổi mỗi tháng).

### H.2 Cơ chế chạy `[BB]`
Hai lớp, phòng khi lớp kia bị hệ điều hành giết:

1. **Khi mở app**: quét mọi quy tắc có `nextRunDate <= hôm nay` và xử lý bù cho cả những ngày đã lỡ. Đây là lớp đảm bảo — luôn hoạt động.
2. **WorkManager chạy 1 lần/ngày**: làm việc tương tự khi app đóng, để thông báo đến đúng hạn.

> **Lưu ý MIUI/Xiaomi**: máy bạn nhiều khả năng là Xiaomi/Redmi (theo thanh trạng thái trong ảnh chụp). MIUI giết tiến trình nền rất mạnh. Trong Cài đặt của app phải có mục hướng dẫn bật "Tự khởi động" và "Không giới hạn pin" cho app, kèm nút mở thẳng trang cài đặt hệ thống.

### H.3 Màn hình quản lý `[BB]`
Danh sách quy tắc: tên, số tiền, chu kỳ, "kỳ tới: 01/09/2026". Bật/tắt bằng switch. Vuốt để xoá.

---

## I. Widget màn hình chính `[BB]`

Hai kích thước:

| Kích thước | Nội dung |
|---|---|
| 2×1 nhỏ | Chi hôm nay + số dư tổng |
| 4×2 vừa | Số dư tổng · Thu/Chi tháng này · thanh tiến độ ngân sách tổng · 3 nút nhập nhanh (Ăn uống / Đi lại / Khác) |

- Bấm vào số → mở app. Bấm nút nhập nhanh → mở thẳng màn hình nhập với danh mục đã chọn sẵn.
- Cập nhật khi: lưu/xoá/sửa giao dịch, và mỗi khi app vào nền.
- Kỹ thuật: `home_widget` + `AppWidgetProvider` Kotlin + layout XML. Dữ liệu truyền qua `SharedPreferences` dùng chung.

---

## J. Cài đặt (tab Khác)

`[BB]` trừ khi ghi khác:

- Giao diện: Sáng / Tối / Hệ thống; chọn màu chủ đề (6 màu, mặc định đỏ giống MoneyNote).
- Tiền tệ & định dạng số (`1.000.000` vs `1,000,000`).
- Ngày bắt đầu tháng tài chính (mặc định 1, nhưng ai lĩnh lương ngày 25 có thể đổi).
- Ngày bắt đầu tuần (Th2 / CN).
- Khoá app: PIN 4 số + vân tay (`local_auth`).
- Nhắc nhập chi tiêu hằng ngày (chọn giờ).
- Cảnh báo ngân sách bật/tắt.
- Quản lý ví / danh mục / khoản định kỳ.
- Xuất dữ liệu / Backup / Restore.
- Hướng dẫn giữ app chạy nền (MIUI).
- Xoá toàn bộ dữ liệu (2 lớp xác nhận).
- Thông tin app + phiên bản.

---

## K. Quy tắc nghiệp vụ (quan trọng — đọc kỹ trước khi code)

1. **Số dư ví** = `initialBalance` + Σ(thu) − Σ(chi) + Σ(chuyển đến) − Σ(chuyển đi) + Σ(điều chỉnh).
2. **Tổng tài sản** = Σ số dư của các ví có `includeInTotal = true`.
3. **Chuyển ví không phải thu/chi.** Mọi truy vấn báo cáo phải lọc `type IN ('income','expense')`.
4. **Điều chỉnh số dư (`adjustment`)** không tính vào báo cáo thu/chi, chỉ ảnh hưởng số dư ví.
5. **Xoá ví** chỉ được phép khi ví không có giao dịch; ngược lại chỉ được lưu trữ (archive).
6. **Xoá giao dịch chuyển ví** phải xoá cả cặp bản ghi (nếu lưu 2 dòng) hoặc dòng duy nhất (nếu lưu 1 dòng — xem `02_KIEN_TRUC_DATA.md` mục 4).
7. **Thẻ tín dụng**: số dư âm là bình thường, không cảnh báo.
8. **Không cho nhập số tiền ≤ 0.**
9. **Giao dịch tương lai** được phép nhập, nhưng báo cáo mặc định chỉ tính đến hôm nay; có switch "Bao gồm giao dịch tương lai".
