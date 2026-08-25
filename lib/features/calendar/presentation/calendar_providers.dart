import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/utils/date_range.dart';
import '../../../shared/providers/database_provider.dart';
import '../../entry/presentation/entry_providers.dart';

part 'calendar_providers.g.dart';

/// Tháng đang xem ở tab Lịch. Luôn chuẩn hoá về ngày 1 để dùng làm khoá.
@riverpod
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) =>
      state = DateTime(month.year, month.month);

  /// Lùi hoặc tiến [delta] tháng. `DateTime` tự xử lý tràn năm.
  void shift(int delta) =>
      state = DateTime(state.year, state.month + delta);

  void goToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}

/// Ngày đang chọn trong lưới lịch. `null` nghĩa là chưa chọn ngày nào.
@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  DateTime? build() => null;

  void select(DateTime? day) =>
      state = day == null ? null : dateOnly(day);
}

/// Tổng thu/chi từng ngày của tháng đang xem.
///
/// Lấy theo **toàn bộ lưới lịch** chứ không chỉ trong tháng: lưới có cả vài
/// ngày của tháng trước và tháng sau, và những ô đó cũng phải hiện số nếu ngày
/// đó có giao dịch — bỏ trống sẽ khiến người dùng tưởng ngày đó không tiêu gì.
@riverpod
Stream<Map<DateTime, DayTotals>> monthDailyTotals(Ref ref, DateTime month) {
  final days = calendarGridDays(month);
  return ref
      .watch(appDatabaseProvider)
      .transactionDao
      .watchDailyTotals(days.first, days.last);
}

/// Tổng thu/chi của riêng tháng dương lịch đang xem — cho thanh tổng kết dưới
/// lưới. Chỉ tính ngày trong tháng, không tính ngày lấp của tháng kề.
@riverpod
Stream<DayTotals> monthTotals(Ref ref, DateTime month) {
  final range = calendarMonthOf(month);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTotals(range.start, range.end);
}

/// Giao dịch của một ngày, mới nhất trước.
@riverpod
Stream<List<TransactionDetail>> dayTransactions(Ref ref, DateTime day) {
  final d = dateOnly(day);
  return ref.watch(transactionRepositoryProvider).watchBetween(d, d);
}
