// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Đã đặt PIN chưa.

@ProviderFor(pinIsSet)
final pinIsSetProvider = PinIsSetProvider._();

/// Đã đặt PIN chưa.

final class PinIsSetProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Đã đặt PIN chưa.
  PinIsSetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinIsSetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinIsSetHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return pinIsSet(ref);
  }
}

String _$pinIsSetHash() => r'185702c9b137250556dc72359b0dffdc09efff02';

/// Đã bật mở khoá bằng vân tay chưa.
///
/// Là `Stream` đọc từ bảng settings, **không phải `FutureBuilder`**. Trước đây
/// dùng FutureBuilder nên bật/tắt xong giao diện không biết mà vẽ lại — phải
/// thoát app vào lại mới thấy công tắc đổi. Mọi trạng thái mà nút bấm làm thay
/// đổi đều phải đi qua provider phản ứng như thế này.

@ProviderFor(biometricEnabled)
final biometricEnabledProvider = BiometricEnabledProvider._();

/// Đã bật mở khoá bằng vân tay chưa.
///
/// Là `Stream` đọc từ bảng settings, **không phải `FutureBuilder`**. Trước đây
/// dùng FutureBuilder nên bật/tắt xong giao diện không biết mà vẽ lại — phải
/// thoát app vào lại mới thấy công tắc đổi. Mọi trạng thái mà nút bấm làm thay
/// đổi đều phải đi qua provider phản ứng như thế này.

final class BiometricEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Đã bật mở khoá bằng vân tay chưa.
  ///
  /// Là `Stream` đọc từ bảng settings, **không phải `FutureBuilder`**. Trước đây
  /// dùng FutureBuilder nên bật/tắt xong giao diện không biết mà vẽ lại — phải
  /// thoát app vào lại mới thấy công tắc đổi. Mọi trạng thái mà nút bấm làm thay
  /// đổi đều phải đi qua provider phản ứng như thế này.
  BiometricEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return biometricEnabled(ref);
  }
}

String _$biometricEnabledHash() => r'78f5e3549bc82597e613015821753c5567b605be';

/// Thiết bị có cảm biến vân tay dùng được không.
///
/// Đọc một lần là đủ — phần cứng không đổi giữa chừng.

@ProviderFor(biometricAvailable)
final biometricAvailableProvider = BiometricAvailableProvider._();

/// Thiết bị có cảm biến vân tay dùng được không.
///
/// Đọc một lần là đủ — phần cứng không đổi giữa chừng.

final class BiometricAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Thiết bị có cảm biến vân tay dùng được không.
  ///
  /// Đọc một lần là đủ — phần cứng không đổi giữa chừng.
  BiometricAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return biometricAvailable(ref);
  }
}

String _$biometricAvailableHash() =>
    r'bbce68c623770bf978dc7ed4f4f4c16deb03f261';

@ProviderFor(appLock)
final appLockProvider = AppLockProvider._();

final class AppLockProvider
    extends
        $FunctionalProvider<
          AppLockController,
          AppLockController,
          AppLockController
        >
    with $Provider<AppLockController> {
  AppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockHash();

  @$internal
  @override
  $ProviderElement<AppLockController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppLockController create(Ref ref) {
    return appLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockController>(value),
    );
  }
}

String _$appLockHash() => r'18df9a93fc1c461f900c7443fc1c87823582b307';
