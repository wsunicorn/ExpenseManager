// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tháng đang xem ở tab Ngân sách.

@ProviderFor(BudgetMonth)
final budgetMonthProvider = BudgetMonthProvider._();

/// Tháng đang xem ở tab Ngân sách.
final class BudgetMonthProvider
    extends $NotifierProvider<BudgetMonth, DateTime> {
  /// Tháng đang xem ở tab Ngân sách.
  BudgetMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetMonthHash();

  @$internal
  @override
  BudgetMonth create() => BudgetMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$budgetMonthHash() => r'62f0404de2d05f2835fbea9db668378899bd25e4';

/// Tháng đang xem ở tab Ngân sách.

abstract class _$BudgetMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Trạng thái đã tính của từng khoản ngân sách trong tháng đang xem.
///
/// Tách khỏi truy vấn để phần tính toán vẫn là hàm thuần và test được riêng.

@ProviderFor(budgetStatuses)
final budgetStatusesProvider = BudgetStatusesFamily._();

/// Trạng thái đã tính của từng khoản ngân sách trong tháng đang xem.
///
/// Tách khỏi truy vấn để phần tính toán vẫn là hàm thuần và test được riêng.

final class BudgetStatusesProvider
    extends
        $FunctionalProvider<
          Map<int, BudgetStatus>,
          Map<int, BudgetStatus>,
          Map<int, BudgetStatus>
        >
    with $Provider<Map<int, BudgetStatus>> {
  /// Trạng thái đã tính của từng khoản ngân sách trong tháng đang xem.
  ///
  /// Tách khỏi truy vấn để phần tính toán vẫn là hàm thuần và test được riêng.
  BudgetStatusesProvider._({
    required BudgetStatusesFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'budgetStatusesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetStatusesHash();

  @override
  String toString() {
    return r'budgetStatusesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<int, BudgetStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<int, BudgetStatus> create(Ref ref) {
    final argument = this.argument as DateTime;
    return budgetStatuses(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, BudgetStatus> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, BudgetStatus>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetStatusesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetStatusesHash() => r'b09befc660a3c2546d5ff7f0e598256ff1f8f18a';

/// Trạng thái đã tính của từng khoản ngân sách trong tháng đang xem.
///
/// Tách khỏi truy vấn để phần tính toán vẫn là hàm thuần và test được riêng.

final class BudgetStatusesFamily extends $Family
    with $FunctionalFamilyOverride<Map<int, BudgetStatus>, DateTime> {
  BudgetStatusesFamily._()
    : super(
        retry: null,
        name: r'budgetStatusesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Trạng thái đã tính của từng khoản ngân sách trong tháng đang xem.
  ///
  /// Tách khỏi truy vấn để phần tính toán vẫn là hàm thuần và test được riêng.

  BudgetStatusesProvider call(DateTime month) =>
      BudgetStatusesProvider._(argument: month, from: this);

  @override
  String toString() => r'budgetStatusesProvider';
}

@ProviderFor(budgetRepository)
final budgetRepositoryProvider = BudgetRepositoryProvider._();

final class BudgetRepositoryProvider
    extends
        $FunctionalProvider<
          BudgetRepository,
          BudgetRepository,
          BudgetRepository
        >
    with $Provider<BudgetRepository> {
  BudgetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetRepositoryHash();

  @$internal
  @override
  $ProviderElement<BudgetRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetRepository create(Ref ref) {
    return budgetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetRepository>(value),
    );
  }
}

String _$budgetRepositoryHash() => r'6682cd1119645eaef71ef9973a9f2ebb3df2ca54';
