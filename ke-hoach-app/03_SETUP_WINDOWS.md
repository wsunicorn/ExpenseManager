# 03 — Cài đặt môi trường trên Windows

Thời gian ước tính: **2–4 tiếng** (phần lớn là ngồi chờ tải). Dung lượng cần: **~25 GB trống**.

---

## 1. Kiểm tra máy

| Yêu cầu | Mức tối thiểu | Nên có |
|---|---|---|
| Windows | 10 64-bit (bản 1803+) | 11 |
| RAM | 8 GB | 16 GB |
| Ổ đĩa trống | 25 GB | 40 GB |
| Ổ cứng | HDD chạy được nhưng rất chậm | **SSD** |

> Nếu máy chỉ có 8 GB RAM: đừng dùng emulator, cắm thẳng điện thoại vào. Emulator Android ăn ~4 GB.

---

## 2. Cài Git

1. Tải từ `git-scm.com`.
2. Cài với mọi tuỳ chọn mặc định.
3. Kiểm tra trong PowerShell: `git --version`

---

## 3. Cài Android Studio

1. Tải từ `developer.android.com/studio`.
2. Cài đặt, chọn **Standard** installation → nó tự tải Android SDK + emulator.
3. Mở Android Studio → **More Actions** → **SDK Manager**:
   - Tab **SDK Platforms**: tick bản Android API mới nhất ổn định.
   - Tab **SDK Tools**: tick `Android SDK Command-line Tools (latest)`, `Android SDK Build-Tools`, `Android SDK Platform-Tools`. **Bắt buộc có Command-line Tools**, thiếu nó `flutter doctor` sẽ báo lỗi license.
4. Ghi lại đường dẫn SDK (thường `C:\Users\<tên>\AppData\Local\Android\Sdk`).

### Cài plugin
File → Settings → Plugins → tìm và cài **Flutter** (nó sẽ tự kéo theo plugin **Dart**) → khởi động lại.

---

## 4. Cài JDK

Android Studio đã kèm sẵn một bản JBR (JetBrains Runtime). Với Flutter bản mới, thường **không cần cài JDK riêng**.

Nếu `flutter doctor` báo thiếu Java:
1. Cài **Microsoft OpenJDK 17** (`learn.microsoft.com/java/openjdk/download`).
2. Đặt biến môi trường `JAVA_HOME` trỏ tới thư mục cài đặt.
3. Hoặc chỉ thẳng cho Flutter: `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"`

---

## 5. Cài Flutter SDK

1. Tải bản **stable cho Windows** từ `docs.flutter.dev/get-started/install/windows`.
2. Giải nén vào `C:\src\flutter`.
   - **Không** đặt trong `C:\Program Files` (có dấu cách và cần quyền admin → sinh lỗi khó hiểu).
   - **Không** đặt trong thư mục có tiếng Việt có dấu.
3. Thêm vào PATH:
   - Nhấn Win → gõ "environment variables" → **Edit the system environment variables**.
   - **Environment Variables** → mục **User variables** → chọn `Path` → **Edit** → **New** → nhập `C:\src\flutter\bin` → OK hết.
4. Mở **PowerShell mới** (bắt buộc mở mới để nhận PATH):
   ```powershell
   flutter --version
   ```

---

## 6. Chạy flutter doctor

```powershell
flutter doctor
```

Chấp nhận license Android (gõ `y` cho từng mục):
```powershell
flutter doctor --android-licenses
```

Chạy lại `flutter doctor`. Kết quả cần đạt:

```
[√] Flutter
[√] Android toolchain
[√] Android Studio
```

Những dòng này **được phép có dấu X, cứ kệ**:
- `Chrome` — chỉ cần nếu build web.
- `Visual Studio` — chỉ cần nếu build app Windows desktop.
- `Connected device` — sẽ xanh khi cắm điện thoại.

### Lỗi hay gặp

| Triệu chứng | Cách xử lý |
|---|---|
| `'flutter' is not recognized` | PATH chưa đúng, hoặc chưa mở cửa sổ terminal mới |
| `Unable to find bundled Java version` | Chạy `flutter config --jdk-dir` như mục 4 |
| `cmdline-tools component is missing` | Vào SDK Manager tick `Android SDK Command-line Tools` |
| Tải Gradle chậm/đứng lần build đầu | Bình thường — lần đầu tải ~500 MB, để yên 10–20 phút |
| Antivirus làm build chậm khủng khiếp | Loại trừ `C:\src\flutter` và thư mục project khỏi Windows Defender |

---

## 7. Kết nối điện thoại thật (khuyến nghị hơn emulator)

1. Trên điện thoại: **Cài đặt → Giới thiệu điện thoại** → bấm **Số phiên bản MIUI** (hoặc "Build number") **7 lần** → hiện "Bạn đã là nhà phát triển".
2. **Cài đặt → Cài đặt bổ sung → Tuỳ chọn nhà phát triển**:
   - Bật **Gỡ lỗi USB (USB debugging)**.
   - Với Xiaomi: bật thêm **Cài đặt qua USB (Install via USB)** — cần đăng nhập tài khoản Mi và có SIM.
   - Bật **USB debugging (Security settings)** nếu có.
3. Cắm cáp USB → chọn chế độ **Truyền tệp (MTP)**, không phải "Chỉ sạc".
4. Trên điện thoại hiện hộp thoại "Cho phép gỡ lỗi USB?" → tick "Luôn cho phép" → OK.
5. Kiểm tra:
   ```powershell
   flutter devices
   ```
   Phải thấy tên máy bạn.

> Nếu không thấy: cài **driver USB của hãng** (Xiaomi: Mi USB Driver), hoặc đổi cáp — nhiều cáp chỉ có dây sạc, không có dây dữ liệu.

---

## 8. Tạo project và chạy thử

```powershell
cd C:\Users\<tên>\Documents
flutter create --org com.lan.sothuchi --platforms=android so_thu_chi
cd so_thu_chi
flutter run
```

Lần build đầu mất 5–15 phút. App demo đếm số sẽ hiện trên điện thoại.

**Thử hot reload**: sửa dòng chữ trong `lib/main.dart`, lưu file, nhấn `r` trong terminal → thay đổi hiện ra sau chưa tới 1 giây. Đây là lý do chính để chọn Flutter.

Nhấn `q` để thoát.

---

## 9. Thiết lập Git cho project

```powershell
git init
git add .
git commit -m "Khởi tạo project Flutter"
```

Tạo repo **private** trên GitHub (đừng để public — sau này file `key.properties` chứa mật khẩu keystore rất dễ lỡ tay commit), rồi:

```powershell
git remote add origin https://github.com/wsunicorn/so-thu-chi.git
git branch -M main
git push -u origin main
```

Kiểm tra file `.gitignore` (Flutter tạo sẵn) đã có `/build/`, `.dart_tool/`. Thêm thủ công:

```
android/key.properties
*.jks
*.keystore
```

---

## 10. Cấu hình IDE

Dùng Android Studio hoặc VS Code đều được. **VS Code nhẹ hơn nhiều** — nếu máy 8 GB RAM thì dùng VS Code, chỉ mở Android Studio khi cần SDK Manager hay sửa file Kotlin.

VS Code: cài extension **Flutter** (kéo theo Dart).

Bật format tự động (`settings.json`):
```json
{
  "editor.formatOnSave": true,
  "dart.previewFlutterUiGuides": true
}
```

---

## 11. Lệnh dùng hằng ngày

| Lệnh | Công dụng |
|---|---|
| `flutter run` | Chạy debug trên máy đang cắm |
| `r` / `R` (trong lúc run) | Hot reload / hot restart |
| `flutter pub get` | Tải thư viện sau khi sửa `pubspec.yaml` |
| `dart run build_runner build --delete-conflicting-outputs` | Sinh code drift sau khi sửa bảng |
| `dart run build_runner watch` | Tự sinh lại khi lưu file |
| `flutter analyze` | Bắt lỗi tĩnh |
| `flutter test` | Chạy unit test |
| `flutter clean` | Xoá cache khi build lỗi kỳ lạ |
