import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mở các trang cài đặt hệ thống liên quan tới việc giữ app chạy nền.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục H.2.
///
/// Cài đặt bằng `MethodChannel` thay vì thêm một package: chỉ cần ba intent,
/// và trang "Tự khởi động" của MIUI vốn không có API chuẩn — phải gọi thẳng
/// tên component của Xiaomi, việc mà không package nào làm thay được cho đủ
/// các hãng.
///
/// Trên web mọi hàm trả `false` thay vì ném lỗi.
abstract final class SystemSettings {
  static const MethodChannel _channel = MethodChannel('sothuchi/system_settings');

  static bool get isSupported => !kIsWeb;

  /// Máy có phải Xiaomi / Redmi / POCO không.
  ///
  /// Dùng để quyết định có nhấn mạnh phần hướng dẫn hay không — trên máy khác
  /// thì phần này vẫn có, chỉ bớt nổi bật.
  static Future<bool> isMiui() async {
    if (!isSupported) return false;
    return await _invoke<bool>('isMiui') ?? false;
  }

  /// Trang thông tin app. Luôn có trên mọi máy Android.
  static Future<bool> openAppSettings() => _call('openAppSettings');

  /// Trang tối ưu hoá pin.
  static Future<bool> openBatterySettings() => _call('openBatterySettings');

  /// Trang "Tự khởi động" của hãng. Lùi về trang thông tin app nếu máy không
  /// có trang riêng.
  static Future<bool> openAutoStartSettings() => _call('openAutoStartSettings');

  static Future<bool> _call(String method) async {
    if (!isSupported) return false;
    return await _invoke<bool>(method) ?? false;
  }

  static Future<T?> _invoke<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      // ROM tuỳ biến không có trang đó — không đáng làm sập màn hình.
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
