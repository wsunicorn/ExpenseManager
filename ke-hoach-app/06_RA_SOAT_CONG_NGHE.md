# 06 — Rà soát công nghệ (cập nhật 24/08/2026)

Tài liệu này **thay thế mục 1 của file `02_KIEN_TRUC_DATA.md`**. Mọi lựa chọn đều được kiểm tra lại theo tình hình hệ sinh thái tháng 8/2026.

---

## 1. Phiên bản nền tảng

Flutter 3.44 ra mắt tại Google I/O 2026 cùng Dart 3.12, và Flutter 3.47 đã lên stable, kèm công cụ **Widget Previews** chính thức ổn định — cho phép xem trước widget ngay trong IDE với cache build cục bộ.

**Việc cần làm**: cài bản stable mới nhất (`flutter upgrade`). Đừng ghim phiên bản cũ.

**Việc cần biết trước**: Google đang tách thư viện **Material và Cupertino ra thành package độc lập**, không còn nằm trong lõi SDK, để có thể phát hành cập nhật design mà không phải chờ chu kỳ SDK hằng quý. Khi việc này hoàn tất, bạn sẽ phải thêm một dependency và sửa `import`. Không ảnh hưởng gì bây giờ, nhưng khi thấy cảnh báo migration thì đừng hoảng.

---

## 2. Kết luận rà soát từng lựa chọn

| Hạng mục | Quyết định cũ | Sau rà soát | Thay đổi |
|---|---|---|---|
| Framework | Flutter | **Giữ** | — |
| State management | Riverpod | **Giữ — nhưng dùng Riverpod 3 + code generation** | Có sửa |
| Database | Drift | **Giữ** | — |
| Điều hướng | go_router | **Giữ** | — |
| Biểu đồ | fl_chart | **Giữ làm mặc định** | Có ghi chú |
| Theming | tự viết ThemeData | **Đổi sang `flex_color_scheme`** | **Đổi** |
| Design system | Material 3 | **M3 + chọn lọc Expressive** | **Bổ sung** |
| Widget Android | home_widget | **Giữ** | — |
| Excel | `excel` | **Giữ, có phương án dự phòng** | — |

---

## 3. Chi tiết từng mục

### 3.1 Riverpod — giữ, nhưng phải dùng đúng phiên bản

Đây vẫn là lựa chọn mặc định cho dự án mới năm 2026: compile-safe, không cần `BuildContext`, và nhánh code generation đã xoá gần hết boilerplate vốn là lý lẽ phản đối chính trước đây. Riverpod 3 mang lại `Ref` hợp nhất, tự động retry, và tính năng lưu trữ offline (còn thử nghiệm).

**Sửa so với kế hoạch cũ**: dùng `riverpod_annotation` + `@riverpod` code generation thay vì viết provider bằng tay. Cùng lúc bật `riverpod_lint` để nó bắt lỗi `ref.read` dùng sai chỗ.

Dependencies: `flutter_riverpod`, `riverpod_annotation`; dev: `riverpod_generator`, `riverpod_lint`, `custom_lint`.

> Lưu ý cho người mới: code generation thêm một bước build (`build_runner watch`) và sinh file có diff ồn ào trong git. Chấp nhận được — bạn đã phải chạy `build_runner` cho drift rồi.

**Không đổi sang Bloc**: Bloc mạnh ở đội 10+ người và ngành cần audit trail. App một người dùng riêng thì đó là gánh nặng thuần tuý.

**Không đổi sang Signals**: đang lên nhưng còn non, ít best practice, không đáng mạo hiểm cho người mới.

### 3.2 Drift — giữ nguyên

Không có lựa chọn nào tốt hơn cho nhu cầu "SQL tổng hợp + stream phản ứng" của app này. ObjectBox nhanh hơn cho ghi hàng loạt nhưng bạn không cần, và nó yếu ở truy vấn nhóm/tổng hợp — thứ chiếm 90% màn hình Báo cáo.

### 3.3 Biểu đồ — fl_chart, có hai phương án dự phòng

`fl_chart` vẫn là thư viện biểu đồ phổ biến nhất của cộng đồng, hỗ trợ line, bar, pie, scatter, radar — đủ cho mọi biểu đồ trong đặc tả.

Hai phương án nếu vướng:
- **Syncfusion Charts** — vẽ hơn 30 loại biểu đồ, zoom/pan/trackball mượt. Là gói thương mại, nhưng có **Community License miễn phí** cho cá nhân/công ty dưới 1 triệu USD doanh thu, từ 5 lập trình viên trở xuống. **Bạn đủ điều kiện.** Đổi sang nếu cần biểu đồ phức tạp hơn.
- **Cristalyse** — thư viện mới theo triết lý grammar of graphics (giống `ggplot2`/`plotnine` mà dân Data Science quen). Nếu bạn muốn cảm giác quen thuộc khi dựng biểu đồ, thử cái này ở Phase 5.

### 3.4 Theming — **đổi sang FlexColorScheme**

Đây là thay đổi đáng giá nhất trong lần rà soát này.

Viết `ThemeData` bằng tay tốn hàng trăm dòng và vẫn sót chỗ. `flex_color_scheme` là một "nhà máy ThemeData" nâng cao: hơn 50 bảng màu dựng sẵn, tự sinh bản dark khớp với bản light, hỗ trợ seeded color scheme của M3, và đảm bảo **mọi** widget SDK đều nhận đúng màu — không còn widget lạc màu.

Kèm theo là **Themes Playground**, công cụ web cho phép chỉnh theme trực quan rồi copy thẳng code Dart ra. Với người chưa từng viết Flutter, đây là cách nhanh nhất để có giao diện trông chuyên nghiệp.

Thêm `dynamic_color` để lấy màu hệ thống trên Android 12+ (Material You) — app sẽ tự đổi màu theo hình nền máy bạn.

### 3.5 Material 3 Expressive — dùng chọn lọc, đừng phụ thuộc

Sự thật cần biết: **Flutter SDK chưa hỗ trợ M3 Expressive.** Đội Flutter tuyên bố rõ họ chưa phát triển và chưa nhận đóng góp cho các tính năng Expressive; mọi công việc M3E sẽ diễn ra ở các package Material/Cupertino tách rời sau khi chúng được thiết lập.

Cộng đồng đã lấp chỗ trống: package `material_3_expressive` cung cấp 45 widget M3E với phản hồi nhấn kiểu lò xo, biến hình khối (shape morphing), và design token qua `M3ETheme`.

**Khuyến nghị**: dùng Material 3 chuẩn của SDK làm nền, và **tự tay tái tạo 3–4 hiệu ứng Expressive** quan trọng (nhấn nảy bằng spring, biến hình nút, chuyển cảnh container) thay vì phụ thuộc toàn bộ vào một package cộng đồng có thể ngừng bảo trì. Chi tiết cách làm ở `07_UI_UX.md` mục 5.

Nếu muốn thử package, hãy dùng nó ở **một màn hình duy nhất** trước để đánh giá.

### 3.6 Widget Android — giữ `home_widget`

Không có lựa chọn thay thế nghiêm túc. Vẫn phải viết Kotlin + layout XML như đã dự trù.

---

## 4. Danh sách dependencies cuối cùng

Thay thế bảng ở mục 1 của file 02.

### Lõi
```
flutter_riverpod, riverpod_annotation
drift, drift_flutter, sqlite3_flutter_libs
path_provider, path
go_router
intl
shared_preferences
```

### Giao diện (mới bổ sung)
```
flex_color_scheme      # theming — thay cho viết ThemeData tay
dynamic_color          # Material You Android 12+
google_fonts           # HOẶC nhúng font tĩnh, xem file 07 mục 3
flutter_animate        # motion khai báo, ngắn gọn
fl_chart               # biểu đồ
skeletonizer           # khung xương lúc tải, thay vòng xoay
flutter_slidable       # vuốt trái/phải trên dòng giao dịch
```

### Tính năng
```
flutter_local_notifications, workmanager
home_widget
share_plus, file_picker
csv, excel, archive
local_auth, flutter_secure_storage
package_info_plus
```

### Dev
```
drift_dev, build_runner
riverpod_generator, riverpod_lint, custom_lint
flutter_lints
flutter_launcher_icons, flutter_native_splash
mocktail                 # mock trong test
```

### Vẫn cố tình KHÔNG dùng
`hive`, `getx`, `sqflite` thuần, mọi SDK quảng cáo/analytics. Lý do giữ nguyên như file 02.

---

## 5. Công cụ mới nên dùng ngay

| Công cụ | Dùng để | Ghi chú |
|---|---|---|
| **Widget Previews** (Flutter 3.47) | Xem trước widget trong IDE, không cần chạy app | Rút ngắn vòng lặp UI rất nhiều ở Phase 3–5 |
| **Themes Playground** (web) | Chỉnh theme trực quan → copy code | Làm ở Phase 3, trước khi dựng màn hình |
| **DevTools → Track Widget Rebuilds** | Tìm widget rebuild thừa | Phần lớn phàn nàn "app giật" thực chất là lỗi state management chứ không phải hiệu năng |
| **Material Theme Builder** (web) | Sinh ColorScheme từ màu chủ đạo | Thay thế nếu không dùng Themes Playground |

---

## 6. Những gì KHÔNG đổi và lý do

- **Không chuyển sang Kotlin/Compose**: bạn đã chọn để ngỏ đường đa nền tảng. Quyết định này khoá lại, không mở lại giữa chừng.
- **Không thêm Firebase/Supabase**: yêu cầu là offline hoàn toàn. Thêm cloud là thêm tài khoản, thêm quyền mạng, thêm rủi ro rò rỉ dữ liệu tài chính — đổi lấy thứ bạn không cần.
- **Không dùng AI/LLM trong v1**: hấp dẫn với nền tảng của bạn, nhưng nó thuộc v2. Phân loại giao dịch tự động hay OCR hoá đơn chỉ có nghĩa khi đã có dữ liệu thật để huấn luyện và đánh giá.
