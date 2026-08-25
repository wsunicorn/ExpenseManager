# 07 — UI/UX & Hệ thống thiết kế

Mục tiêu của file này: để bạn — một người làm Data Science, không phải designer — vẫn ra được một app **trông có gu**, không phải bằng năng khiếu, mà bằng một hệ thống ràng buộc rõ ràng.

---

## 1. Bốn nguyên tắc chi phối mọi quyết định

### 1.1 Tin cậy đứng trước đẹp
Tiền bạc là chủ đề gây căng thẳng. Giao diện đẹp mà làm người dùng nghi ngờ con số thì vô dụng. Cụ thể:
- Số dư luôn hiển thị **cách tính** khi bấm vào ("5.000.000 gốc + 2.100.000 thu − 1.850.000 chi").
- Mọi hành động xoá đều có Hoàn tác hoặc xác nhận.
- Không bao giờ làm tròn số tiền trong màn hình chính. Chỉ rút gọn ở biểu đồ, và ghi rõ "≈".

### 1.2 Kể chuyện, không chỉ vẽ số
Xu hướng thiết kế fintech 2026 đang dịch từ *trực quan hoá dữ liệu* sang *kể chuyện dữ liệu*. Một biểu đồ tròn nói "Ăn uống 42%". Một câu nói "Tháng này bạn ăn ngoài nhiều hơn tháng trước 18%, chủ yếu vào cuối tuần." Câu thứ hai mới làm người ta thay đổi hành vi.

Mỗi màn hình báo cáo phải có **ít nhất một câu tiếng Việt tự sinh** diễn giải dữ liệu.

### 1.3 Một tay, một ngón cái
Người ta ghi chi tiêu lúc đang đứng ở quán, cầm điện thoại một tay. Thiết kế 2026 nghiêng hẳn về bottom sheet và cử chỉ vuốt để thao tác bằng một tay khi đang di chuyển.

Quy tắc cứng: **mọi hành động chính phải nằm trong 1/3 dưới màn hình.** Nút "Lưu" không bao giờ ở trên cùng.

### 1.4 Giảm ma sát nhập liệu
Chỉ số thành công thật sự của app này không phải là biểu đồ đẹp, mà là **bạn có nhập chi tiêu đều đặn 30 ngày liên tục hay không**. Nếu nhập một khoản mất hơn 5 giây, bạn sẽ bỏ.

Mục tiêu: **nhập xong một khoản chi trong 3 chạm** — mở widget → gõ số → chạm danh mục (danh mục gần đây đã nổi lên đầu, tự lưu).

---

## 2. Design token

Không dùng số bất kỳ trong code. Mọi giá trị lấy từ token. Đặt trong `core/theme/tokens.dart`.

### 2.1 Khoảng cách — thang 4dp
```
xs = 4    sm = 8    md = 12   lg = 16
xl = 24   xxl = 32  xxxl = 48
```
Padding màn hình = `lg` (16). Khoảng cách giữa các thẻ = `md` (12). Trong thẻ = `lg`.

### 2.2 Bo góc
```
radiusSm = 8    (chip, ô nhỏ)
radiusMd = 16   (thẻ, ô danh mục)
radiusLg = 28   (bottom sheet, nút lớn)
radiusFull = 999 (chip lọc, nút tròn)
```
M3 dùng bo góc lớn hơn M2 nhiều. Đừng dùng 4px — trông như app 2018.

### 2.3 Màu — vai trò ngữ nghĩa, không phải tên màu

Định nghĩa theo **vai trò**, không bao giờ gọi `Colors.red` trong widget:

| Token | Vai trò | Gợi ý |
|---|---|---|
| `income` | Thu nhập | Xanh dương/lục đậm |
| `expense` | Chi tiêu | Đỏ cam |
| `transfer` | Chuyển ví | Xám trung tính |
| `budgetSafe` / `budgetWarn` / `budgetOver` | < 80% / 80-100% / > 100% | Lục / Hổ phách / Đỏ |
| `surface`, `surfaceContainer`, `outline` | Nền, thẻ, viền | Lấy từ ColorScheme M3 |

> **Lưu ý bối cảnh Việt Nam**: trong chứng khoán Việt, đỏ = tăng, xanh = giảm — ngược với phương Tây. Nhưng trong app sổ thu chi thì quy ước phổ biến (và MoneyNote đang dùng) là **đỏ = chi, xanh = thu**. Giữ quy ước này để bạn không phải học lại.

Cấu hình bằng `flex_color_scheme` với seed color, thêm `income`/`expense` làm `ThemeExtension` riêng.

**Không bao giờ chỉ dùng màu để truyền tin.** Số tiền luôn có dấu `+` hoặc `−` đứng trước — người mù màu chiếm khoảng 8% nam giới.

### 2.4 Typography

Font phải **hỗ trợ đầy đủ dấu tiếng Việt**. Nhiều font đẹp bị vỡ dấu (ệ, ữ, ặ) hoặc dấu chồng lên chữ hoa. Ba lựa chọn an toàn:

| Font | Nhận xét |
|---|---|
| **Be Vietnam Pro** | Thiết kế riêng cho tiếng Việt, dấu cân đối. Lựa chọn đề xuất. |
| **Inter** | Trung tính, rất dễ đọc ở cỡ nhỏ, hỗ trợ vi tốt |
| **Roboto** | Mặc định Android, an toàn tuyệt đối, hơi nhạt nhoà |

**Nhúng font tĩnh vào assets thay vì dùng `google_fonts` tải runtime** — app offline không nên phụ thuộc mạng để hiển thị chữ.

**Chi tiết quan trọng cho app tiền**: bật **tabular figures** (chữ số cùng bề rộng) cho mọi con số tiền:
```dart
TextStyle(fontFeatures: [FontFeature.tabularFigures()])
```
Không có nó, các cột số trong danh sách sẽ so le, trông nghiệp dư ngay lập tức.

Thang cỡ chữ (dùng `Theme.of(context).textTheme`, không hardcode):
```
displaySmall  36  — số dư lớn trên đầu app
headlineSmall 24  — tiêu đề màn hình
titleMedium   16  — tên danh mục, tiêu đề thẻ
bodyMedium    14  — nội dung chính
labelSmall    11  — nhãn phụ, ngày tháng
```

### 2.5 Độ nổi (elevation)
M3 dùng **màu nền phân tầng** thay vì đổ bóng. Dùng `surfaceContainerLow/High` để phân biệt lớp, hạn chế `shadow`. Bóng chỉ dành cho phần tử thật sự nổi lên trên nội dung (FAB, bottom sheet).

---

## 3. Bố cục từng màn hình

### 3.1 Nhập vào

```
┌─────────────────────────────┐
│  Tổng tài sản               │  ← displaySmall, tabular
│  12.450.000 đ               │
│  Tháng này  +8.0tr  −3.2tr  │  ← labelSmall
├─────────────────────────────┤
│   Chi   │   Thu   │ Chuyển  │  ← segmented, 3 tab
├─────────────────────────────┤
│  ‹  24/08/2026 (T2)  ›  📅  │
│  Ví: 💵 Tiền mặt         ▾  │
│  Ghi chú:  ____________     │
├─────────────────────────────┤
│           50.000 đ          │  ← displaySmall, chạm để mở bàn phím
├─────────────────────────────┤
│  🍽    🧴    👕    💄       │  ← lưới 4 cột
│  🥂    💊    📚    ⚡       │
│  🚆    📱    🏠    ⚙️        │
├─────────────────────────────┤
│      [  Lưu khoản chi  ]    │  ← nút full-width, ở đáy
└─────────────────────────────┘
```

**Cải tiến mật độ so với MoneyNote**: MoneyNote dùng cỡ chữ rất lớn nên chỉ hiện được 6 danh mục trên một màn hình, phải cuộn. Ở đây lưới 4 cột × 3 hàng cho **12 danh mục hiện cùng lúc** — không cuộn, không tìm.

### 3.2 Bàn phím số
Chiếm 45% chiều cao dưới, hiện bằng bottom sheet trượt lên:
- 4 cột: `7 8 9 ÷` / `4 5 6 ×` / `1 2 3 −` / `000 0 . +`
- Cột phải cùng: `⌫` và nút `Lưu` màu chủ đạo cao gấp đôi.
- Dòng trên hiển thị phép tính đang gõ, mờ hơn kết quả.
- **Haptic nhẹ mỗi lần chạm phím** (`HapticFeedback.selectionClick()`), haptic trung bình khi lưu. Đây là chi tiết nhỏ tạo cảm giác "app xịn".

### 3.3 Lịch
- Ô ngày: số ngày ở giữa, hai dòng số nhỏ (thu xanh / chi đỏ) bên dưới, cỡ 9-10.
- Ngày hôm nay: nền `primaryContainer`, không phải viền — viền dễ lẫn.
- Ngày được chọn: chấm tròn đặc dưới số.
- Chạm ngày → bottom sheet trượt lên chiếm 60% màn, kéo lên được toàn màn hình.

### 3.4 Báo cáo
Thứ tự từ trên xuống, quan trọng nhất trước:
1. Thẻ tóm tắt (Chi / Thu / Chênh lệch).
2. **Câu diễn giải** — đây là thứ MoneyNote không có.
3. Biểu đồ tròn danh mục.
4. Danh sách danh mục có thanh %.
5. Biểu đồ cột 12 tháng (cuộn ngang).

Biểu đồ tròn: **donut chứ không phải pie đặc**, số tổng ở giữa lỗ. Tối đa 6 lát + lát "Khác" gộp phần còn lại — nhiều hơn thì không đọc được.

### 3.5 Trạng thái rỗng
Mỗi màn hình phải có trạng thái rỗng tử tế: một icon nhạt, một câu giải thích, và **một nút hành động**.

> "Chưa có giao dịch nào trong tháng 8.
>  [ Ghi khoản chi đầu tiên ]"

Không bao giờ để màn hình trắng trơn với chữ "Không có dữ liệu" như MoneyNote đang làm.

---

## 4. Chuyển động (motion)

Chuyển động là ranh giới rõ nhất giữa app nghiệp dư và app chuyên nghiệp. Quy tắc:

| Loại | Thời lượng | Đường cong |
|---|---|---|
| Phản hồi chạm (ripple, scale) | 100ms | `easeOut` |
| Chuyển tab, hiện/ẩn | 200ms | `easeInOutCubic` |
| Bottom sheet trượt | 300ms | spring (`Curves.easeOutBack` nhẹ) |
| Biểu đồ vẽ lần đầu | 600–800ms | `easeOutCubic`, chạy **một lần**, không lặp |
| Chuyển màn hình | 250ms | `SharedAxisTransition` |

Ba quy tắc không được vi phạm:
1. **Không animation nào vượt 400ms** trừ biểu đồ vẽ lần đầu. Chậm hơn là cảm giác lag.
2. **Không lặp vô hạn.** Animation lặp làm phân tán và tốn pin.
3. **Tôn trọng `MediaQuery.disableAnimations`** — người dùng bật giảm chuyển động thì tắt hết.

Dùng `flutter_animate` để viết ngắn gọn:
```dart
Text('12.450.000 đ')
  .animate()
  .fadeIn(duration: 200.ms)
  .slideY(begin: 0.1, end: 0);
```

### Cảm giác "Expressive" tự làm
Vì SDK chưa có M3 Expressive, ba hiệu ứng đáng tự viết:
- **Nhấn nảy bằng spring**: `AnimatedScale` xuống 0.96 khi nhấn, dùng `SpringSimulation` khi thả.
- **Số đếm lên**: khi số dư thay đổi, chạy `TweenAnimationBuilder` đếm từ giá trị cũ sang mới trong 400ms. Rẻ tiền, hiệu quả cực cao.
- **Biến hình container**: ô danh mục nở ra thành bottom sheet chi tiết bằng `Hero` + `Material` transition.

---

## 5. Khả năng tiếp cận (accessibility)

Không phải để tuân thủ quy định — mà vì bạn sẽ dùng app này ngoài nắng, lúc mệt, một tay.

- **Vùng chạm tối thiểu 48×48dp.** Ô danh mục nhỏ hơn thì bọc `SizedBox`.
- **Tương phản chữ/nền ≥ 4.5:1** cho chữ thường, ≥ 3:1 cho chữ lớn. Kiểm bằng Themes Playground hoặc công cụ contrast checker.
- **Cỡ chữ co giãn**: dùng `MediaQuery.textScalerOf(context)`, không khoá `textScaleFactor = 1.0`. Test với cỡ chữ hệ thống 130%.
- **Biểu đồ có nhãn ngữ nghĩa**: bọc `Semantics(label: 'Biểu đồ chi tiêu: Ăn uống 42 phần trăm, ...')` và có nút "Xem dạng bảng".
- **Dark mode thật sự tối**: không phải xám #303030. Dùng surface tối của M3, và có tuỳ chọn "True black" (`flex_color_scheme` hỗ trợ sẵn) cho màn OLED.

---

## 6. Quy trình làm UI cho người không phải designer

Đừng mở Figma vẽ từ đầu. Làm theo trình tự này:

### Bước 1 — Thu thập tham chiếu (1 buổi)
Vào **Mobbin** (mobbin.com, mục Finance) và **Dribbble** tìm "expense tracker app". Lưu **10 ảnh chụp màn hình** bạn thấy dễ nhìn.

Quan trọng: **chép cấu trúc, đừng chép phong cách.** Ghi lại: họ đặt số dư ở đâu? Bao nhiêu thông tin trên một màn? Nút chính nằm chỗ nào? Đó là thứ dùng được. Còn màu tím gradient của họ thì bỏ qua.

### Bước 2 — Chốt bảng màu (1 tiếng)
Mở **Themes Playground**, chọn một scheme dựng sẵn gần với gu bạn, tinh chỉnh, copy code. Đừng tự phối màu từ đầu — đó là kỹ năng mất nhiều năm.

**Ràng buộc tự đặt**: 1 màu chủ đạo + 1 màu nhấn + thang xám. Hết. Mọi giao diện xấu đều xấu vì quá nhiều màu.

### Bước 3 — Dựng thẳng bằng Widget Previews
Bỏ qua Figma. Với Widget Previews của Flutter 3.47, bạn dựng widget thật và xem ngay trong IDE — nhanh hơn vẽ mockup rồi dịch sang code.

### Bước 4 — Kiểm tra bằng 5 câu hỏi
Với mỗi màn hình đã dựng, tự hỏi:
1. Nếu chỉ liếc 1 giây, mắt rơi vào đâu? Đó có phải thứ quan trọng nhất không?
2. Có bao nhiêu cỡ chữ khác nhau trên màn này? Quá 4 là loạn.
3. Khoảng cách có nhất quán không, hay có chỗ 10px chỗ 14px?
4. Ngón cái phải với bao xa để chạm nút chính?
5. Màn hình này lúc chưa có dữ liệu trông thế nào?

### Bước 5 — Golden test
Sau khi màn hình ổn định, chụp golden test (`flutter test --update-goldens`). Sau này lỡ sửa theme làm vỡ layout, test sẽ báo ngay.

---

## 7. Bổ sung lộ trình

Chèn vào `04_LO_TRINH.md`:

**Phase 2.5 — Hệ thống thiết kế (2–3 ngày)** — làm ngay trước Phase 3:
- [ ] Thu thập 10 ảnh tham chiếu, ghi chú cấu trúc
- [ ] Chốt bảng màu bằng Themes Playground, xuất code `flex_color_scheme`
- [ ] Nhúng font Be Vietnam Pro vào assets, bật tabular figures cho số tiền
- [ ] Viết `tokens.dart`: spacing, radius, duration
- [ ] Viết `ThemeExtension` cho `income` / `expense` / `budgetSafe/Warn/Over`
- [ ] Dựng trang "Design Gallery" nội bộ hiển thị mọi component (nút, thẻ, chip, ô danh mục) ở cả sáng và tối — đây là bảng tra cứu của bạn suốt phần còn lại
- [ ] Kiểm tương phản, kiểm cỡ chữ 130%

Bổ sung vào **Phase 9**:
- [ ] Rà 5 câu hỏi kiểm tra cho mọi màn hình
- [ ] Golden test cho 6 màn hình chính
- [ ] Thêm haptic feedback vào bàn phím số và nút lưu
- [ ] Kiểm mọi trạng thái rỗng

---

## 8. Sai lầm thị giác thường gặp — và cách tránh

| Sai lầm | Hậu quả | Cách sửa |
|---|---|---|
| Trộn widget M2 và M3 | Bo góc, khoảng cách lệch nhau | Chỉ dùng component M3 |
| Hardcode màu trong widget | Dark mode vỡ, đổi theme phải sửa 200 chỗ | Luôn qua `ColorScheme` / token |
| Lạm dụng đổ bóng | Trông rối, cũ | M3 dùng nền phân tầng, không phải bóng |
| Bỏ qua thứ bậc chữ | Mọi thứ trông ngang nhau, mắt không biết nhìn đâu | Dùng `textTheme`, tối đa 4 cỡ/màn |
| Khoảng cách tuỳ hứng | Cảm giác "không chỉn chu" mà không rõ vì sao | Chỉ dùng thang 4dp |
| Số tiền không tabular | Cột số so le | `FontFeature.tabularFigures()` |
| Vòng xoay khi tải | Cảm giác chậm | `skeletonizer` — khung xương giữ layout ổn định |
| Quá nhiều lát biểu đồ tròn | Không đọc được | Tối đa 6 + "Khác" |
