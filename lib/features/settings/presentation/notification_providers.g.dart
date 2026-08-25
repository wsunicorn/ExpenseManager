// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'42215a23a56ac7374674a0e13fa13ea2b1a04b11';

/// Đã bật nhắc hằng ngày chưa.

@ProviderFor(reminderEnabled)
final reminderEnabledProvider = ReminderEnabledProvider._();

/// Đã bật nhắc hằng ngày chưa.

final class ReminderEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Đã bật nhắc hằng ngày chưa.
  ReminderEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return reminderEnabled(ref);
  }
}

String _$reminderEnabledHash() => r'66a430cd41b11c18209c523d7cb6578aaf356caf';

/// Giờ nhắc, mặc định 21:00 như đặc tả mục A bước 4.

@ProviderFor(reminderHour)
final reminderHourProvider = ReminderHourProvider._();

/// Giờ nhắc, mặc định 21:00 như đặc tả mục A bước 4.

final class ReminderHourProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Giờ nhắc, mặc định 21:00 như đặc tả mục A bước 4.
  ReminderHourProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderHourProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderHourHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return reminderHour(ref);
  }
}

String _$reminderHourHash() => r'5ed87902ede459d1e568c05583b02e0f1f6b6d3d';

/// Bật/tắt và đặt giờ nhắc.

@ProviderFor(ReminderController)
final reminderControllerProvider = ReminderControllerProvider._();

/// Bật/tắt và đặt giờ nhắc.
final class ReminderControllerProvider
    extends $NotifierProvider<ReminderController, void> {
  /// Bật/tắt và đặt giờ nhắc.
  ReminderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderControllerHash();

  @$internal
  @override
  ReminderController create() => ReminderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderControllerHash() =>
    r'dfb7c515d6c9d579d9dea854e00074eb4852ebdf';

/// Bật/tắt và đặt giờ nhắc.

abstract class _$ReminderController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
