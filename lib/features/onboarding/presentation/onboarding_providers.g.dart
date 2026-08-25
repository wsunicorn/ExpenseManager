// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Đọc và ghi bảng cài đặt khoá–giá trị.

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// Đọc và ghi bảng cài đặt khoá–giá trị.

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// Đọc và ghi bảng cài đặt khoá–giá trị.
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'2de17899c89cd144d3e134172002d79d8b2f2dfd';

/// Đã chạy xong onboarding chưa.
///
/// Trả `null` khi còn đang đọc — giao diện phải chờ, không được đoán. Đoán sai
/// sẽ chớp màn hình onboarding một nhịp rồi nhảy vào app, hoặc tệ hơn là bắt
/// người dùng làm lại onboarding mỗi lần mở.

@ProviderFor(onboardingDone)
final onboardingDoneProvider = OnboardingDoneProvider._();

/// Đã chạy xong onboarding chưa.
///
/// Trả `null` khi còn đang đọc — giao diện phải chờ, không được đoán. Đoán sai
/// sẽ chớp màn hình onboarding một nhịp rồi nhảy vào app, hoặc tệ hơn là bắt
/// người dùng làm lại onboarding mỗi lần mở.

final class OnboardingDoneProvider
    extends $FunctionalProvider<AsyncValue<bool?>, bool?, Stream<bool?>>
    with $FutureModifier<bool?>, $StreamProvider<bool?> {
  /// Đã chạy xong onboarding chưa.
  ///
  /// Trả `null` khi còn đang đọc — giao diện phải chờ, không được đoán. Đoán sai
  /// sẽ chớp màn hình onboarding một nhịp rồi nhảy vào app, hoặc tệ hơn là bắt
  /// người dùng làm lại onboarding mỗi lần mở.
  OnboardingDoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingDoneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingDoneHash();

  @$internal
  @override
  $StreamProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool?> create(Ref ref) {
    return onboardingDone(ref);
  }
}

String _$onboardingDoneHash() => r'285d850e1bf3ed55110c6a6d6483eebef19ee1bd';

/// Ngày bắt đầu kỳ tài chính, 1–28.

@ProviderFor(monthStartDay)
final monthStartDayProvider = MonthStartDayProvider._();

/// Ngày bắt đầu kỳ tài chính, 1–28.

final class MonthStartDayProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Ngày bắt đầu kỳ tài chính, 1–28.
  MonthStartDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthStartDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthStartDayHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return monthStartDay(ref);
  }
}

String _$monthStartDayHash() => r'0a89e81c2829e59da3b6a1305417f194104a2732';
