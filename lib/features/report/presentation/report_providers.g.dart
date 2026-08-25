// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportSelectionController)
final reportSelectionControllerProvider = ReportSelectionControllerProvider._();

final class ReportSelectionControllerProvider
    extends $NotifierProvider<ReportSelectionController, ReportSelection> {
  ReportSelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportSelectionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportSelectionControllerHash();

  @$internal
  @override
  ReportSelectionController create() => ReportSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportSelection>(value),
    );
  }
}

String _$reportSelectionControllerHash() =>
    r'9f8741eb4951d82fa9ea8f3d9ff1296b47a76a83';

abstract class _$ReportSelectionController extends $Notifier<ReportSelection> {
  ReportSelection build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReportSelection, ReportSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportSelection, ReportSelection>,
              ReportSelection,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Dang xem co cau Chi tieu hay Thu nhap.
///
/// MoneyNote co hai tab con nay ngay duoi the tom tat, va do la thu app cu
/// lam dung: bieu do tron chi ve duoc mot loai, nen phai co cach doi.

@ProviderFor(ReportBreakdownType)
final reportBreakdownTypeProvider = ReportBreakdownTypeProvider._();

/// Dang xem co cau Chi tieu hay Thu nhap.
///
/// MoneyNote co hai tab con nay ngay duoi the tom tat, va do la thu app cu
/// lam dung: bieu do tron chi ve duoc mot loai, nen phai co cach doi.
final class ReportBreakdownTypeProvider
    extends $NotifierProvider<ReportBreakdownType, TransactionType> {
  /// Dang xem co cau Chi tieu hay Thu nhap.
  ///
  /// MoneyNote co hai tab con nay ngay duoi the tom tat, va do la thu app cu
  /// lam dung: bieu do tron chi ve duoc mot loai, nen phai co cach doi.
  ReportBreakdownTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportBreakdownTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportBreakdownTypeHash();

  @$internal
  @override
  ReportBreakdownType create() => ReportBreakdownType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionType>(value),
    );
  }
}

String _$reportBreakdownTypeHash() =>
    r'800c75f89f9afd04ca7ccd01a2b51c3f6e8a4e48';

/// Dang xem co cau Chi tieu hay Thu nhap.
///
/// MoneyNote co hai tab con nay ngay duoi the tom tat, va do la thu app cu
/// lam dung: bieu do tron chi ve duoc mot loai, nen phai co cach doi.

abstract class _$ReportBreakdownType extends $Notifier<TransactionType> {
  TransactionType build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionType, TransactionType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionType, TransactionType>,
              TransactionType,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Tổng thu chi của kỳ đang xem.

@ProviderFor(reportTotals)
final reportTotalsProvider = ReportTotalsProvider._();

/// Tổng thu chi của kỳ đang xem.

final class ReportTotalsProvider
    extends
        $FunctionalProvider<AsyncValue<DayTotals>, DayTotals, Stream<DayTotals>>
    with $FutureModifier<DayTotals>, $StreamProvider<DayTotals> {
  /// Tổng thu chi của kỳ đang xem.
  ReportTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportTotalsHash();

  @$internal
  @override
  $StreamProviderElement<DayTotals> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DayTotals> create(Ref ref) {
    return reportTotals(ref);
  }
}

String _$reportTotalsHash() => r'dfced6203ac215a06443f9c474151d75ba21c9ea';

/// Tổng theo danh mục của kỳ đang xem.

@ProviderFor(reportCategoryTotals)
final reportCategoryTotalsProvider = ReportCategoryTotalsFamily._();

/// Tổng theo danh mục của kỳ đang xem.

final class ReportCategoryTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryTotal>>,
          List<CategoryTotal>,
          Stream<List<CategoryTotal>>
        >
    with
        $FutureModifier<List<CategoryTotal>>,
        $StreamProvider<List<CategoryTotal>> {
  /// Tổng theo danh mục của kỳ đang xem.
  ReportCategoryTotalsProvider._({
    required ReportCategoryTotalsFamily super.from,
    required TransactionType super.argument,
  }) : super(
         retry: null,
         name: r'reportCategoryTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportCategoryTotalsHash();

  @override
  String toString() {
    return r'reportCategoryTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CategoryTotal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryTotal>> create(Ref ref) {
    final argument = this.argument as TransactionType;
    return reportCategoryTotals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportCategoryTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportCategoryTotalsHash() =>
    r'9882ec2d7250074f6f6c6039ad133cb1d630140b';

/// Tổng theo danh mục của kỳ đang xem.

final class ReportCategoryTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<CategoryTotal>>,
          TransactionType
        > {
  ReportCategoryTotalsFamily._()
    : super(
        retry: null,
        name: r'reportCategoryTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tổng theo danh mục của kỳ đang xem.

  ReportCategoryTotalsProvider call(TransactionType type) =>
      ReportCategoryTotalsProvider._(argument: type, from: this);

  @override
  String toString() => r'reportCategoryTotalsProvider';
}

/// Tổng theo danh mục của **kỳ trước**, chỉ để sinh câu so sánh.

@ProviderFor(previousCategoryTotals)
final previousCategoryTotalsProvider = PreviousCategoryTotalsFamily._();

/// Tổng theo danh mục của **kỳ trước**, chỉ để sinh câu so sánh.

final class PreviousCategoryTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryTotal>>,
          List<CategoryTotal>,
          Stream<List<CategoryTotal>>
        >
    with
        $FutureModifier<List<CategoryTotal>>,
        $StreamProvider<List<CategoryTotal>> {
  /// Tổng theo danh mục của **kỳ trước**, chỉ để sinh câu so sánh.
  PreviousCategoryTotalsProvider._({
    required PreviousCategoryTotalsFamily super.from,
    required TransactionType super.argument,
  }) : super(
         retry: null,
         name: r'previousCategoryTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$previousCategoryTotalsHash();

  @override
  String toString() {
    return r'previousCategoryTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CategoryTotal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryTotal>> create(Ref ref) {
    final argument = this.argument as TransactionType;
    return previousCategoryTotals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PreviousCategoryTotalsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$previousCategoryTotalsHash() =>
    r'2dc135f6a7b3380f6a65036e78d7f0dda33a7c7c';

/// Tổng theo danh mục của **kỳ trước**, chỉ để sinh câu so sánh.

final class PreviousCategoryTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<CategoryTotal>>,
          TransactionType
        > {
  PreviousCategoryTotalsFamily._()
    : super(
        retry: null,
        name: r'previousCategoryTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tổng theo danh mục của **kỳ trước**, chỉ để sinh câu so sánh.

  PreviousCategoryTotalsProvider call(TransactionType type) =>
      PreviousCategoryTotalsProvider._(argument: type, from: this);

  @override
  String toString() => r'previousCategoryTotalsProvider';
}

/// Tổng thu chi của kỳ trước.

@ProviderFor(previousTotals)
final previousTotalsProvider = PreviousTotalsProvider._();

/// Tổng thu chi của kỳ trước.

final class PreviousTotalsProvider
    extends
        $FunctionalProvider<AsyncValue<DayTotals>, DayTotals, Stream<DayTotals>>
    with $FutureModifier<DayTotals>, $StreamProvider<DayTotals> {
  /// Tổng thu chi của kỳ trước.
  PreviousTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'previousTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$previousTotalsHash();

  @$internal
  @override
  $StreamProviderElement<DayTotals> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DayTotals> create(Ref ref) {
    return previousTotals(ref);
  }
}

String _$previousTotalsHash() => r'28582ae5de26f45ec097dcc792abf0ae3307fb9a';

/// Mười hai tháng gần nhất tính từ kỳ đang xem — cho biểu đồ cột.

@ProviderFor(trailingMonthlyTotals)
final trailingMonthlyTotalsProvider = TrailingMonthlyTotalsProvider._();

/// Mười hai tháng gần nhất tính từ kỳ đang xem — cho biểu đồ cột.

final class TrailingMonthlyTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MonthTotals>>,
          List<MonthTotals>,
          Stream<List<MonthTotals>>
        >
    with
        $FutureModifier<List<MonthTotals>>,
        $StreamProvider<List<MonthTotals>> {
  /// Mười hai tháng gần nhất tính từ kỳ đang xem — cho biểu đồ cột.
  TrailingMonthlyTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trailingMonthlyTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trailingMonthlyTotalsHash();

  @$internal
  @override
  $StreamProviderElement<List<MonthTotals>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MonthTotals>> create(Ref ref) {
    return trailingMonthlyTotals(ref);
  }
}

String _$trailingMonthlyTotalsHash() =>
    r'9b25264cd1e05e9e7883ad4407a3f381e0ecf743';

/// Câu diễn giải tự sinh cho kỳ đang xem.

@ProviderFor(reportInsights)
final reportInsightsProvider = ReportInsightsProvider._();

/// Câu diễn giải tự sinh cho kỳ đang xem.

final class ReportInsightsProvider
    extends $FunctionalProvider<List<Insight>, List<Insight>, List<Insight>>
    with $Provider<List<Insight>> {
  /// Câu diễn giải tự sinh cho kỳ đang xem.
  ReportInsightsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportInsightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportInsightsHash();

  @$internal
  @override
  $ProviderElement<List<Insight>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Insight> create(Ref ref) {
    return reportInsights(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Insight> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Insight>>(value),
    );
  }
}

String _$reportInsightsHash() => r'c93d93cf90cc140e356200afff22579344819f80';
