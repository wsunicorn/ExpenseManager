// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(budgetAlertWatcher)
final budgetAlertWatcherProvider = BudgetAlertWatcherProvider._();

final class BudgetAlertWatcherProvider
    extends
        $FunctionalProvider<
          BudgetAlertWatcher,
          BudgetAlertWatcher,
          BudgetAlertWatcher
        >
    with $Provider<BudgetAlertWatcher> {
  BudgetAlertWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetAlertWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetAlertWatcherHash();

  @$internal
  @override
  $ProviderElement<BudgetAlertWatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BudgetAlertWatcher create(Ref ref) {
    return budgetAlertWatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetAlertWatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetAlertWatcher>(value),
    );
  }
}

String _$budgetAlertWatcherHash() =>
    r'ff37c28a46cb38f7e32153ea836754b005bdd33f';

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

final class TransactionRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionRepository,
          TransactionRepository,
          TransactionRepository
        >
    with $Provider<TransactionRepository> {
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'32da0d0106cca33078f62e266d7513d7d430ac91';

/// Ghi chú đã dùng, cho gợi ý ở ô Ghi chú.

@ProviderFor(recentNotes)
final recentNotesProvider = RecentNotesProvider._();

/// Ghi chú đã dùng, cho gợi ý ở ô Ghi chú.

final class RecentNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Ghi chú đã dùng, cho gợi ý ở ô Ghi chú.
  RecentNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentNotesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return recentNotes(ref);
  }
}

String _$recentNotesHash() => r'46f916c9e21859ed23b481cfc116a6094bcab2c3';

/// Điều khiển form nhập.
///
/// Giữ `keepAlive` để trạng thái không mất khi chuyển sang tab Lịch rồi quay
/// lại — người dùng đang gõ dở một khoản mà mất hết là lỗi khó tha thứ.

@ProviderFor(EntryForm)
final entryFormProvider = EntryFormProvider._();

/// Điều khiển form nhập.
///
/// Giữ `keepAlive` để trạng thái không mất khi chuyển sang tab Lịch rồi quay
/// lại — người dùng đang gõ dở một khoản mà mất hết là lỗi khó tha thứ.
final class EntryFormProvider
    extends $NotifierProvider<EntryForm, EntryFormState> {
  /// Điều khiển form nhập.
  ///
  /// Giữ `keepAlive` để trạng thái không mất khi chuyển sang tab Lịch rồi quay
  /// lại — người dùng đang gõ dở một khoản mà mất hết là lỗi khó tha thứ.
  EntryFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryFormProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryFormHash();

  @$internal
  @override
  EntryForm create() => EntryForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntryFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntryFormState>(value),
    );
  }
}

String _$entryFormHash() => r'7dca1bf51a55efedf9f92e8d2083b0e4b917f938';

/// Điều khiển form nhập.
///
/// Giữ `keepAlive` để trạng thái không mất khi chuyển sang tab Lịch rồi quay
/// lại — người dùng đang gõ dở một khoản mà mất hết là lỗi khó tha thứ.

abstract class _$EntryForm extends $Notifier<EntryFormState> {
  EntryFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EntryFormState, EntryFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EntryFormState, EntryFormState>,
              EntryFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
