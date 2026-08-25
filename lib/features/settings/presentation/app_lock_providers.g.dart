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
