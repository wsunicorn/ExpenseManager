# 05 — Build file .apk & CI

---

## 1. Hiểu về các loại bản build

| Loại | Lệnh | Dùng khi |
|---|---|---|
| Debug | `flutter run` | Phát triển hằng ngày. Chậm, nặng, có thanh "DEBUG" |
| Profile | `flutter run --profile` | Đo hiệu năng |
| **Release APK** | `flutter build apk` | **Cái bạn cần** — file để cài và dùng thật |
| App Bundle | `flutter build appbundle` | Chỉ cần khi đăng lên Google Play |

Vì app dùng riêng, không lên Play Store → chỉ cần **APK**.

---

## 2. Tạo keystore (chữ ký số)

Android bắt mọi APK phải được ký. Bản debug dùng khoá tạm; bản release cần khoá của bạn.

> **Cực kỳ quan trọng**: mất keystore = không thể cập nhật app đã cài, phải gỡ và cài lại từ đầu (mất dữ liệu nếu chưa backup). Hãy sao lưu file `.jks` vào ít nhất 2 nơi.

Mở PowerShell trong thư mục project:

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\sothuchi-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sothuchi
```

Nếu báo `keytool is not recognized`, dùng bản kèm Android Studio:
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore $env:USERPROFILE\sothuchi-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sothuchi
```

Nó sẽ hỏi mật khẩu và vài thông tin. **Ghi mật khẩu vào trình quản lý mật khẩu ngay.**

---

## 3. Cấu hình ký trong project

### 3.1 Tạo `android/key.properties`

```properties
storePassword=<mật khẩu bạn vừa đặt>
keyPassword=<mật khẩu bạn vừa đặt>
keyAlias=sothuchi
storeFile=C:/Users/<tên>/sothuchi-key.jks
```

> Dùng dấu `/` chứ không phải `\` trong `storeFile`.

### 3.2 Thêm vào `.gitignore`

```
android/key.properties
*.jks
*.keystore
```

**Kiểm tra lại bằng `git status` trước khi commit.** Đẩy keystore lên GitHub là sai lầm không sửa được — phải tạo khoá mới.

### 3.3 Sửa `android/app/build.gradle.kts`

Thêm **trước** khối `android { ... }`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Trong khối `android { ... }`:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

> Nếu project của bạn dùng `build.gradle` (Groovy) thay vì `.kts`, cú pháp hơi khác — hỏi tôi khi tới bước này, tôi viết đúng bản của bạn.

### 3.4 File `android/app/proguard-rules.pro`

```proguard
-keep class io.flutter.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn io.flutter.embedding.**
```

Nếu sau khi bật minify mà app crash lúc mở, tạm đặt `isMinifyEnabled = false` để xác nhận nguyên nhân, rồi thêm rule giữ lại lớp bị xoá.

---

## 4. Đặt tên & phiên bản app

### `pubspec.yaml`
```yaml
version: 1.0.0+1
```
`1.0.0` là versionName (người dùng thấy), `+1` là versionCode (Android dùng để so sánh bản mới). **Mỗi lần build bản mới phải tăng số sau dấu `+`.**

### `android/app/src/main/AndroidManifest.xml`
```xml
<application android:label="Sổ Thu Chi" ...>
```

### Đổi package name
Đã đặt lúc `flutter create --org com.lan.sothuchi`. Nếu cần đổi sau, dùng package `change_app_package_name` — đổi tay rất dễ sót.

---

## 5. Build APK

### Cách 1 — Một file duy nhất (đơn giản nhất)

```powershell
flutter build apk --release
```

Kết quả: `build\app\outputs\flutter-apk\app-release.apk` (~18–25 MB).

### Cách 2 — Tách theo kiến trúc CPU (file nhẹ hơn)

```powershell
flutter build apk --split-per-abi --release
```

Sinh ra 3 file:
- `app-armeabi-v7a-release.apk` — máy cũ 32-bit
- `app-arm64-v8a-release.apk` — **hầu hết máy hiện nay, dùng cái này**
- `app-x86_64-release.apk` — emulator

Mỗi file ~8–10 MB.

---

## 6. Cài lên điện thoại

**Cách nhanh (máy đang cắm USB):**
```powershell
flutter install --release
```

**Cách thủ công:**
1. Copy file `.apk` sang điện thoại (USB, Zalo tự gửi mình, Google Drive).
2. Mở file trên điện thoại.
3. Android hỏi "Cài ứng dụng không rõ nguồn gốc" → vào cài đặt, cho phép ứng dụng đang mở (Files/Chrome) được cài.
4. Xiaomi/MIUI: sau khi cài sẽ có bước quét virus và đếm ngược 10 giây — chờ rồi bấm Cài đặt.

> **Trước khi cài đè bản mới, luôn backup dữ liệu trong app.** Nếu bạn đổi keystore hoặc package name, Android coi đây là app khác và sẽ không cho cài đè.

---

## 7. GitHub Actions — tự build APK

Lợi ích: tạo tag trên GitHub → CI build → tải APK thẳng về điện thoại, không cần mở máy tính.

### 7.1 Đưa keystore lên Secrets

Mã hoá keystore thành base64:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\sothuchi-key.jks")) | Set-Clipboard
```

Trên GitHub: **Settings → Secrets and variables → Actions → New repository secret**, tạo 4 secret:

| Tên | Giá trị |
|---|---|
| `KEYSTORE_BASE64` | chuỗi vừa copy |
| `STORE_PASSWORD` | mật khẩu keystore |
| `KEY_PASSWORD` | mật khẩu key |
| `KEY_ALIAS` | `sothuchi` |

> Chỉ làm việc này với repo **private**.

### 7.2 File `.github/workflows/build-apk.yml`

```yaml
name: Build APK

on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Khoi phuc keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Tao key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.STORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release --split-per-abi

      - uses: actions/upload-artifact@v4
        with:
          name: apk
          path: build/app/outputs/flutter-apk/*.apk

      - name: Tao release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v2
        with:
          files: build/app/outputs/flutter-apk/*.apk
```

> `storeFile=keystore.jks` là đường dẫn tương đối so với `android/app/` — trên CI khác với máy local, đó là lý do dùng giá trị khác.

### 7.3 Cách phát hành

```powershell
git tag v1.0.1
git push origin v1.0.1
```

Chờ ~5 phút → vào tab **Releases** của repo trên điện thoại → tải `app-arm64-v8a-release.apk` → cài.

---

## 8. Xử lý lỗi build hay gặp

| Lỗi | Nguyên nhân & cách sửa |
|---|---|
| `Execution failed for task ':app:validateSigningRelease'` | Sai đường dẫn `storeFile` hoặc sai mật khẩu trong `key.properties` |
| `Keystore was tampered with, or password was incorrect` | Sai mật khẩu, hoặc file `.jks` hỏng khi copy |
| `Could not resolve all files for configuration` | Mạng chặn Gradle. Thử VPN hoặc chạy lại |
| App crash ngay khi mở bản release (debug thì chạy) | Do minify. Đặt `isMinifyEnabled = false` để xác nhận, rồi thêm `-keep` rule |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Bản cũ ký bằng khoá khác. Gỡ app cũ (backup dữ liệu trước!) |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | versionCode mới nhỏ hơn bản đã cài. Tăng số sau dấu `+` |
| Build lâu bất thường trên Windows | Loại trừ thư mục project khỏi Windows Defender |

---

## 9. Checklist trước mỗi lần phát hành

- [ ] Tăng `version` trong `pubspec.yaml`
- [ ] `flutter analyze` sạch
- [ ] `flutter test` xanh
- [ ] Thử migration DB từ bản cũ lên bản mới (không được mất dữ liệu)
- [ ] Test bản release trên máy thật ít nhất 30 phút
- [ ] Backup keystore vẫn còn ở 2 nơi
- [ ] Ghi lại thay đổi vào `CHANGELOG.md`
