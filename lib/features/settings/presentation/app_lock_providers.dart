import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../onboarding/presentation/onboarding_providers.dart';
import '../domain/app_lock.dart';

part 'app_lock_providers.g.dart';

/// Khoá cài đặt cho phần khoá app.
abstract final class LockKeys {
  static const String pinHash = 'pin_hash';
  static const String biometricEnabled = 'biometric_enabled';
  static const String reminderHour = 'reminder_hour';
  static const String reminderEnabled = 'reminder_enabled';
}

/// Đã đặt PIN chưa.
@riverpod
Stream<bool> pinIsSet(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(LockKeys.pinHash)
    .map((v) => v != null && v.isNotEmpty);

/// Đã bật mở khoá bằng vân tay chưa.
///
/// Là `Stream` đọc từ bảng settings, **không phải `FutureBuilder`**. Trước đây
/// dùng FutureBuilder nên bật/tắt xong giao diện không biết mà vẽ lại — phải
/// thoát app vào lại mới thấy công tắc đổi. Mọi trạng thái mà nút bấm làm thay
/// đổi đều phải đi qua provider phản ứng như thế này.
@riverpod
Stream<bool> biometricEnabled(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(LockKeys.biometricEnabled)
    .map((v) => v == 'true');

/// Thiết bị có cảm biến vân tay dùng được không.
///
/// Đọc một lần là đủ — phần cứng không đổi giữa chừng.
@riverpod
Future<bool> biometricAvailable(Ref ref) =>
    ref.watch(appLockProvider).canUseBiometrics();

@Riverpod(keepAlive: true)
AppLockController appLock(Ref ref) => AppLockController(
      ref.watch(settingsRepositoryProvider),
    );

/// Đặt, đổi, gỡ PIN và mở khoá bằng sinh trắc.
class AppLockController {
  AppLockController(this._settings);

  final SettingsRepository _settings;
  final LocalAuthentication _auth = LocalAuthentication();

  /// Sinh trắc chỉ có trên thiết bị thật.
  bool get biometricSupported => !kIsWeb;

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError('PIN phải đúng $kPinLength chữ số');
    }
    await _settings.write(LockKeys.pinHash, hashPin(pin));
  }

  Future<bool> verify(String pin) async {
    final luu = await _settings.read(LockKeys.pinHash);
    if (luu == null || luu.isEmpty) return true;
    return verifyPin(pin, luu);
  }

  /// Gỡ khoá app. Ghi chuỗi rỗng thay vì xoá dòng, để phần còn lại của app
  /// luôn đọc được khoá này mà không phải xử lý trường hợp thiếu.
  Future<void> removePin() async {
    await _settings.write(LockKeys.pinHash, '');
    await _settings.write(LockKeys.biometricEnabled, 'false');
  }

  Future<bool> get isLockEnabled async {
    final v = await _settings.read(LockKeys.pinHash);
    return v != null && v.isNotEmpty;
  }

  Future<bool> get isBiometricEnabled async =>
      await _settings.read(LockKeys.biometricEnabled) == 'true';

  Future<void> setBiometricEnabled({required bool enabled}) =>
      _settings.write(LockKeys.biometricEnabled, enabled.toString());

  /// Thiết bị có vân tay / khuôn mặt dùng được không.
  Future<bool> canUseBiometrics() async {
    if (!biometricSupported) return false;
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on Exception {
      // Thiết bị không hỗ trợ hoặc plugin lỗi — coi như không có, đừng làm
      // sập màn hình khoá vì một tính năng phụ.
      return false;
    }
  }

  /// Mở khoá bằng vân tay. Trả `false` khi thất bại hoặc người dùng huỷ.
  Future<bool> authenticateBiometric() async {
    if (!biometricSupported) return false;
    try {
      // local_auth bản mới bỏ `AuthenticationOptions`, các tuỳ chọn thành
      // tham số phẳng.
      return await _auth.authenticate(
        localizedReason: 'Mở khoá Sổ thu chi',
        biometricOnly: true,
      );
    } on Exception {
      return false;
    }
  }
}
