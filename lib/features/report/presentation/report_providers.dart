import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/enums.dart';
import '../../../core/utils/date_range.dart';
import '../../../shared/providers/database_provider.dart';
import '../../entry/presentation/entry_providers.dart';
import '../domain/report_insights.dart';

part 'report_providers.g.dart';

/// Ba mức kỳ báo cáo. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục D.
enum ReportPeriod {
  month('Tháng'),
  year('Năm'),
  all('Toàn kỳ');

  const ReportPeriod(this.label);

  final String label;
}

/// Kỳ đang xem: loại kỳ + ngày neo để biết đang ở tháng/năm nào.
class ReportSelection {
  const ReportSelection({required this.period, required this.anchor});

  final ReportPeriod period;
  final DateTime anchor;

  /// Khoảng ngày tương ứng.
  ///
  /// "Toàn kỳ" dùng một khoảng rộng cố định thay vì đi hỏi DB ngày cũ nhất —
  /// rẻ hơn một truy vấn, và không app sổ thu chi cá nhân nào có giao dịch
  /// ngoài khoảng này.
  DateRange get range => switch (period) {
        ReportPeriod.month => calendarMonthOf(anchor),
        ReportPeriod.year => calendarYearOf(anchor),
        ReportPeriod.all => DateRange(DateTime(2000), DateTime(2100, 12, 31)),
      };

  /// Kỳ liền trước, để so sánh. "Toàn kỳ" thì không có kỳ trước.
  DateRange? get previousRange => switch (period) {
        ReportPeriod.month => calendarMonthOf(
            DateTime(anchor.year, anchor.month - 1),
          ),
        ReportPeriod.year => calendarYearOf(DateTime(anchor.year - 1)),
        ReportPeriod.all => null,
      };

  ReportSelection copyWith({ReportPeriod? period, DateTime? anchor}) =>
      ReportSelection(
        period: period ?? this.period,
        anchor: anchor ?? this.anchor,
      );

  @override
  bool operator ==(Object other) =>
      other is ReportSelection &&
      other.period == period &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(period, anchor);
}

@riverpod
class ReportSelectionController extends _$ReportSelectionController {
  @override
  ReportSelection build() {
    final now = DateTime.now();
    return ReportSelection(
      period: ReportPeriod.month,
      anchor: DateTime(now.year, now.month),
    );
  }

  void setPeriod(ReportPeriod period) =>
      state = state.copyWith(period: period);

  /// Lùi hoặc tiến một kỳ. Không áp dụng cho "Toàn kỳ".
  void shift(int delta) {
    state = switch (state.period) {
      ReportPeriod.month => state.copyWith(
          anchor: DateTime(state.anchor.year, state.anchor.month + delta),
        ),
      ReportPeriod.year => state.copyWith(
          anchor: DateTime(state.anchor.year + delta, state.anchor.month),
        ),
      ReportPeriod.all => state,
    };
  }
}

/// Dang xem co cau Chi tieu hay Thu nhap.
///
/// MoneyNote co hai tab con nay ngay duoi the tom tat, va do la thu app cu
/// lam dung: bieu do tron chi ve duoc mot loai, nen phai co cach doi.
@riverpod
class ReportBreakdownType extends _$ReportBreakdownType {
  @override
  TransactionType build() => TransactionType.expense;

  void set(TransactionType type) => state = type;
}

/// Tổng thu chi của kỳ đang xem.
@riverpod
Stream<DayTotals> reportTotals(Ref ref) {
  final range = ref.watch(reportSelectionControllerProvider).range;
  return ref
      .watch(transactionRepositoryProvider)
      .watchTotals(range.start, range.end);
}

/// Tổng theo danh mục của kỳ đang xem.
@riverpod
Stream<List<CategoryTotal>> reportCategoryTotals(
  Ref ref,
  TransactionType type,
) {
  final range = ref.watch(reportSelectionControllerProvider).range;
  return ref.watch(appDatabaseProvider).transactionDao.watchCategoryTotals(
        from: range.start,
        to: range.end,
        type: type,
      );
}

/// Tổng theo danh mục của **kỳ trước**, chỉ để sinh câu so sánh.
@riverpod
Stream<List<CategoryTotal>> previousCategoryTotals(
  Ref ref,
  TransactionType type,
) {
  final prev = ref.watch(reportSelectionControllerProvider).previousRange;
  if (prev == null) return Stream.value(const []);

  return ref.watch(appDatabaseProvider).transactionDao.watchCategoryTotals(
        from: prev.start,
        to: prev.end,
        type: type,
      );
}

/// Tổng thu chi của kỳ trước.
@riverpod
Stream<DayTotals> previousTotals(Ref ref) {
  final prev = ref.watch(reportSelectionControllerProvider).previousRange;
  if (prev == null) return Stream.value((income: 0, expense: 0));

  return ref
      .watch(transactionRepositoryProvider)
      .watchTotals(prev.start, prev.end);
}

/// Mười hai tháng gần nhất tính từ kỳ đang xem — cho biểu đồ cột.
@riverpod
Stream<List<MonthTotals>> trailingMonthlyTotals(Ref ref) {
  final anchor = ref.watch(reportSelectionControllerProvider).anchor;
  final end = calendarMonthOf(anchor).end;
  final start = DateTime(anchor.year, anchor.month - 11, 1);

  return ref
      .watch(appDatabaseProvider)
      .transactionDao
      .watchMonthlyTotals(start, end);
}

/// Câu diễn giải tự sinh cho kỳ đang xem.
@riverpod
List<Insight> reportInsights(Ref ref) {
  final selection = ref.watch(reportSelectionControllerProvider);
  final totals = ref.watch(reportTotalsProvider).value;
  final prevTotals = ref.watch(previousTotalsProvider).value;
  final cats =
      ref.watch(reportCategoryTotalsProvider(TransactionType.expense)).value;
  final prevCats =
      ref.watch(previousCategoryTotalsProvider(TransactionType.expense)).value;

  if (totals == null) return const [];

  final range = selection.range;
  final today = dateOnly(DateTime.now());

  // Số ngày đã trôi qua trong kỳ. Kỳ đã kết thúc thì bằng tổng số ngày; kỳ
  // trong tương lai thì bằng 0.
  final daysTotal = range.dayCount;
  final daysElapsed = today.isAfter(range.end)
      ? daysTotal
      : today.isBefore(range.start)
          ? 0
          : today.difference(range.start).inDays + 1;

  return buildInsights(
    ReportContext(
      income: totals.income,
      expense: totals.expense,
      previousIncome: prevTotals?.income ?? 0,
      previousExpense: prevTotals?.expense ?? 0,
      categories: cats ?? const [],
      previousCategories: prevCats ?? const [],
      daysElapsed: daysElapsed,
      daysTotal: daysTotal,
    ),
  );
}
