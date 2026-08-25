// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recurringRepository)
final recurringRepositoryProvider = RecurringRepositoryProvider._();

final class RecurringRepositoryProvider
    extends
        $FunctionalProvider<
          RecurringRepository,
          RecurringRepository,
          RecurringRepository
        >
    with $Provider<RecurringRepository> {
  RecurringRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecurringRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecurringRepository create(Ref ref) {
    return recurringRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringRepository>(value),
    );
  }
}

String _$recurringRepositoryHash() =>
    r'eda3e86ceac2cbfc5fea101413e45a6600a0d798';

/// Kết quả lượt quét gần nhất, để giao diện biết có gì cần báo cho người dùng.

@ProviderFor(RecurringScan)
final recurringScanProvider = RecurringScanProvider._();

/// Kết quả lượt quét gần nhất, để giao diện biết có gì cần báo cho người dùng.
final class RecurringScanProvider
    extends $NotifierProvider<RecurringScan, RecurringScanResult?> {
  /// Kết quả lượt quét gần nhất, để giao diện biết có gì cần báo cho người dùng.
  RecurringScanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringScanProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringScanHash();

  @$internal
  @override
  RecurringScan create() => RecurringScan();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringScanResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringScanResult?>(value),
    );
  }
}

String _$recurringScanHash() => r'caffcdc5cc1ffa954bc1f9622549542e3621d298';

/// Kết quả lượt quét gần nhất, để giao diện biết có gì cần báo cho người dùng.

abstract class _$RecurringScan extends $Notifier<RecurringScanResult?> {
  RecurringScanResult? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecurringScanResult?, RecurringScanResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecurringScanResult?, RecurringScanResult?>,
              RecurringScanResult?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
