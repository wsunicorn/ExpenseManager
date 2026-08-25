// Import đầy đủ chứ không chỉ `Value`: toán tử `&` để ghép mệnh đề WHERE là
// một extension của drift, `show Value` sẽ không kéo nó theo.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/daos/budget_dao.dart';
import '../../../core/db/database.dart';
import '../../../core/utils/date_range.dart';
import '../../../shared/providers/database_provider.dart';
import '../domain/budget_status.dart';

part 'budget_providers.g.dart';

/// Tháng đang xem ở tab Ngân sách.
@riverpod
class BudgetMonth extends _$BudgetMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void shift(int delta) =>
      state = DateTime(state.year, state.month + delta);

  void goToThisMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}

/// Ngân sách của tháng đang xem, kèm số đã chi.
///
/// Viết tay vì kiểu trả về nhắc tới `BudgetWithSpent`, lớp này thì lại ôm
/// `Budget` — một lớp drift nằm trong file `part`. Xem chú thích dài ở
/// `categoryListProvider` trong `entry_providers.dart` để biết vì sao
/// `riverpod_generator` không xử lý được trường hợp đó.
final budgetListProvider =
    StreamProvider.family<List<BudgetWithSpent>, DateTime>((ref, month) {
  final range = calendarMonthOf(month);
  return ref.watch(appDatabaseProvider).budgetDao.watchForMonth(
        year: month.year,
        month: month.month,
        from: range.start,
        to: range.end,
      );
});

/// Trạng thái đã tính của từng khoản ngân sách trong tháng đang xem.
///
/// Tách khỏi truy vấn để phần tính toán vẫn là hàm thuần và test được riêng.
@riverpod
Map<int, BudgetStatus> budgetStatuses(Ref ref, DateTime month) {
  final list = ref.watch(budgetListProvider(month)).value ?? const [];
  final range = calendarMonthOf(month);
  final today = dateOnly(DateTime.now());

  // Số ngày còn lại tính cả hôm nay. Tháng đã qua thì bằng 0; tháng tương lai
  // thì bằng cả tháng.
  final daysRemaining = today.isAfter(range.end)
      ? 0
      : today.isBefore(range.start)
          ? range.dayCount
          : range.end.difference(today).inDays + 1;

  return {
    for (final b in list)
      b.budget.id: BudgetStatus(
        limit: b.budget.amount,
        spent: b.spent,
        daysRemaining: daysRemaining,
        daysTotal: range.dayCount,
      ),
  };
}

@Riverpod(keepAlive: true)
BudgetRepository budgetRepository(Ref ref) =>
    BudgetRepository(ref.watch(appDatabaseProvider));

/// Tầng nghiệp vụ của ngân sách.
class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  /// Đặt hoặc cập nhật hạn mức cho một danh mục (hoặc ngân sách tổng nếu
  /// [categoryId] là null) trong một tháng.
  ///
  /// [repeatForward] áp dụng cho cả các tháng sau — cải tiến so với MoneyNote,
  /// vốn bắt đặt lại mỗi tháng (mục E.1). Ở đây chỉ ghi cờ; việc sinh ngân
  /// sách cho tháng mới do [ensureMonth] làm khi mở tháng đó.
  Future<void> setBudget({
    required int? categoryId,
    required int year,
    required int month,
    required int amount,
    bool repeatForward = false,
  }) async {
    final existing = await _db.budgetDao
        .findFor(categoryId: categoryId, year: year, month: month);

    await _db.budgetDao.upsert(
      BudgetsCompanion(
        id: existing == null ? const Value.absent() : Value(existing.id),
        categoryId: Value(categoryId),
        year: Value(year),
        month: Value(month),
        amount: Value(amount),
        repeatForward: Value(repeatForward),
      ),
    );
  }

  Future<void> removeBudget(int id) => _db.budgetDao.deleteById(id);

  /// Sinh ngân sách cho [month] từ các khoản tháng trước có bật `repeatForward`.
  ///
  /// Gọi khi mở tab Ngân sách. Chỉ tạo khoản còn thiếu — không bao giờ ghi đè
  /// hạn mức người dùng đã tự sửa cho tháng này.
  Future<void> ensureMonth(DateTime month) async {
    final truoc = DateTime(month.year, month.month - 1);

    final nguon = await (_db.select(_db.budgets)
          ..where(
            (b) =>
                b.year.equals(truoc.year) &
                b.month.equals(truoc.month) &
                b.repeatForward.equals(true),
          ))
        .get();
    if (nguon.isEmpty) return;

    final daCo = await (_db.select(_db.budgets)
          ..where(
            (b) => b.year.equals(month.year) & b.month.equals(month.month),
          ))
        .get();
    final khoaDaCo = daCo.map((b) => b.categoryId).toSet();

    await _db.transaction(() async {
      for (final b in nguon) {
        if (khoaDaCo.contains(b.categoryId)) continue;
        await _db.budgetDao.upsert(
          BudgetsCompanion.insert(
            categoryId: Value(b.categoryId),
            amount: b.amount,
            year: month.year,
            month: month.month,
            repeatForward: const Value(true),
          ),
        );
      }
    });
  }

  /// Gợi ý hạn mức từ mức chi trung bình [months] tháng gần nhất.
  Future<int> suggestAmount({
    required int? categoryId,
    required DateTime month,
    int months = 3,
  }) {
    final den = calendarMonthOf(DateTime(month.year, month.month - 1)).end;
    final tu = calendarMonthOf(DateTime(month.year, month.month - months)).start;

    return _db.budgetDao.averageMonthlySpend(
      categoryId: categoryId,
      from: tu,
      to: den,
    );
  }
}
