// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tháng đang xem ở tab Lịch. Luôn chuẩn hoá về ngày 1 để dùng làm khoá.

@ProviderFor(SelectedMonth)
final selectedMonthProvider = SelectedMonthProvider._();

/// Tháng đang xem ở tab Lịch. Luôn chuẩn hoá về ngày 1 để dùng làm khoá.
final class SelectedMonthProvider
    extends $NotifierProvider<SelectedMonth, DateTime> {
  /// Tháng đang xem ở tab Lịch. Luôn chuẩn hoá về ngày 1 để dùng làm khoá.
  SelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMonthHash();

  @$internal
  @override
  SelectedMonth create() => SelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedMonthHash() => r'2542a9f466dd0c9090d7181ab45f448a9ad96233';

/// Tháng đang xem ở tab Lịch. Luôn chuẩn hoá về ngày 1 để dùng làm khoá.

abstract class _$SelectedMonth extends $Notifier<DateTime> {
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

/// Ngày đang chọn trong lưới lịch. `null` nghĩa là chưa chọn ngày nào.

@ProviderFor(SelectedDay)
final selectedDayProvider = SelectedDayProvider._();

/// Ngày đang chọn trong lưới lịch. `null` nghĩa là chưa chọn ngày nào.
final class SelectedDayProvider
    extends $NotifierProvider<SelectedDay, DateTime?> {
  /// Ngày đang chọn trong lưới lịch. `null` nghĩa là chưa chọn ngày nào.
  SelectedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDayHash();

  @$internal
  @override
  SelectedDay create() => SelectedDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$selectedDayHash() => r'c8932e17d6615b88f01c02eac7ec3c4f9889b92c';

/// Ngày đang chọn trong lưới lịch. `null` nghĩa là chưa chọn ngày nào.

abstract class _$SelectedDay extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Tổng thu/chi từng ngày của tháng đang xem.
///
/// Lấy theo **toàn bộ lưới lịch** chứ không chỉ trong tháng: lưới có cả vài
/// ngày của tháng trước và tháng sau, và những ô đó cũng phải hiện số nếu ngày
/// đó có giao dịch — bỏ trống sẽ khiến người dùng tưởng ngày đó không tiêu gì.

@ProviderFor(monthDailyTotals)
final monthDailyTotalsProvider = MonthDailyTotalsFamily._();

/// Tổng thu/chi từng ngày của tháng đang xem.
///
/// Lấy theo **toàn bộ lưới lịch** chứ không chỉ trong tháng: lưới có cả vài
/// ngày của tháng trước và tháng sau, và những ô đó cũng phải hiện số nếu ngày
/// đó có giao dịch — bỏ trống sẽ khiến người dùng tưởng ngày đó không tiêu gì.

final class MonthDailyTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, DayTotals>>,
          Map<DateTime, DayTotals>,
          Stream<Map<DateTime, DayTotals>>
        >
    with
        $FutureModifier<Map<DateTime, DayTotals>>,
        $StreamProvider<Map<DateTime, DayTotals>> {
  /// Tổng thu/chi từng ngày của tháng đang xem.
  ///
  /// Lấy theo **toàn bộ lưới lịch** chứ không chỉ trong tháng: lưới có cả vài
  /// ngày của tháng trước và tháng sau, và những ô đó cũng phải hiện số nếu ngày
  /// đó có giao dịch — bỏ trống sẽ khiến người dùng tưởng ngày đó không tiêu gì.
  MonthDailyTotalsProvider._({
    required MonthDailyTotalsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'monthDailyTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthDailyTotalsHash();

  @override
  String toString() {
    return r'monthDailyTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<DateTime, DayTotals>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<DateTime, DayTotals>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthDailyTotals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthDailyTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthDailyTotalsHash() => r'344b0be113f60433a8778f25ea8dd20c820b85b0';

/// Tổng thu/chi từng ngày của tháng đang xem.
///
/// Lấy theo **toàn bộ lưới lịch** chứ không chỉ trong tháng: lưới có cả vài
/// ngày của tháng trước và tháng sau, và những ô đó cũng phải hiện số nếu ngày
/// đó có giao dịch — bỏ trống sẽ khiến người dùng tưởng ngày đó không tiêu gì.

final class MonthDailyTotalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<DateTime, DayTotals>>, DateTime> {
  MonthDailyTotalsFamily._()
    : super(
        retry: null,
        name: r'monthDailyTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tổng thu/chi từng ngày của tháng đang xem.
  ///
  /// Lấy theo **toàn bộ lưới lịch** chứ không chỉ trong tháng: lưới có cả vài
  /// ngày của tháng trước và tháng sau, và những ô đó cũng phải hiện số nếu ngày
  /// đó có giao dịch — bỏ trống sẽ khiến người dùng tưởng ngày đó không tiêu gì.

  MonthDailyTotalsProvider call(DateTime month) =>
      MonthDailyTotalsProvider._(argument: month, from: this);

  @override
  String toString() => r'monthDailyTotalsProvider';
}

/// Tổng thu/chi của riêng tháng dương lịch đang xem — cho thanh tổng kết dưới
/// lưới. Chỉ tính ngày trong tháng, không tính ngày lấp của tháng kề.

@ProviderFor(monthTotals)
final monthTotalsProvider = MonthTotalsFamily._();

/// Tổng thu/chi của riêng tháng dương lịch đang xem — cho thanh tổng kết dưới
/// lưới. Chỉ tính ngày trong tháng, không tính ngày lấp của tháng kề.

final class MonthTotalsProvider
    extends
        $FunctionalProvider<AsyncValue<DayTotals>, DayTotals, Stream<DayTotals>>
    with $FutureModifier<DayTotals>, $StreamProvider<DayTotals> {
  /// Tổng thu/chi của riêng tháng dương lịch đang xem — cho thanh tổng kết dưới
  /// lưới. Chỉ tính ngày trong tháng, không tính ngày lấp của tháng kề.
  MonthTotalsProvider._({
    required MonthTotalsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'monthTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthTotalsHash();

  @override
  String toString() {
    return r'monthTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DayTotals> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DayTotals> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthTotals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthTotalsHash() => r'd56dcf037faf9e403a98ae50375acdf7599ef50a';

/// Tổng thu/chi của riêng tháng dương lịch đang xem — cho thanh tổng kết dưới
/// lưới. Chỉ tính ngày trong tháng, không tính ngày lấp của tháng kề.

final class MonthTotalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DayTotals>, DateTime> {
  MonthTotalsFamily._()
    : super(
        retry: null,
        name: r'monthTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tổng thu/chi của riêng tháng dương lịch đang xem — cho thanh tổng kết dưới
  /// lưới. Chỉ tính ngày trong tháng, không tính ngày lấp của tháng kề.

  MonthTotalsProvider call(DateTime month) =>
      MonthTotalsProvider._(argument: month, from: this);

  @override
  String toString() => r'monthTotalsProvider';
}

/// Giao dịch của một ngày, mới nhất trước.

@ProviderFor(dayTransactions)
final dayTransactionsProvider = DayTransactionsFamily._();

/// Giao dịch của một ngày, mới nhất trước.

final class DayTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransactionDetail>>,
          List<TransactionDetail>,
          Stream<List<TransactionDetail>>
        >
    with
        $FutureModifier<List<TransactionDetail>>,
        $StreamProvider<List<TransactionDetail>> {
  /// Giao dịch của một ngày, mới nhất trước.
  DayTransactionsProvider._({
    required DayTransactionsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dayTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayTransactionsHash();

  @override
  String toString() {
    return r'dayTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TransactionDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TransactionDetail>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return dayTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayTransactionsHash() => r'6f443ab1cd7a69a01b3e930cab88cdd5112e4ce3';

/// Giao dịch của một ngày, mới nhất trước.

final class DayTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TransactionDetail>>, DateTime> {
  DayTransactionsFamily._()
    : super(
        retry: null,
        name: r'dayTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Giao dịch của một ngày, mới nhất trước.

  DayTransactionsProvider call(DateTime day) =>
      DayTransactionsProvider._(argument: day, from: this);

  @override
  String toString() => r'dayTransactionsProvider';
}
