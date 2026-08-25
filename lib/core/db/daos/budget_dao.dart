import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/budgets.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'budget_dao.g.dart';

/// Một dòng ngân sách kèm số đã chi trong kỳ.
///
/// Số đã chi được tính từ giao dịch chứ không lưu sẵn — cùng nguyên tắc với số
/// dư ví: không bao giờ có chuyện con số hiển thị lệch khỏi lịch sử.
class BudgetWithSpent {
  const BudgetWithSpent({
    required this.budget,
    required this.spent,
    this.categoryName,
    this.categoryIconCode,
    this.categoryColorValue,
  });

  final Budget budget;

  /// Đã chi trong kỳ, đơn vị đồng.
  final int spent;

  /// Null với ngân sách tổng.
  final String? categoryName;
  final int? categoryIconCode;
  final int? categoryColorValue;

  bool get isTotalBudget => budget.categoryId == null;
}

@DriftAccessor(tables: [Budgets, Categories, Transactions])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  /// Ngân sách của một tháng, kèm số đã chi.
  ///
  /// Ngân sách tổng (`category_id IS NULL`) tính trên **toàn bộ khoản chi**
  /// trong kỳ; ngân sách danh mục chỉ tính khoản chi thuộc danh mục đó.
  ///
  /// Vẫn lọc `type = 'expense'` — chuyển ví và điều chỉnh không bao giờ được
  /// tính là tiêu tiền.
  Stream<List<BudgetWithSpent>> watchForMonth({
    required int year,
    required int month,
    required DateTime from,
    required DateTime to,
  }) {
    final query = db.customSelect(
      '''
      SELECT
        b.*,
        c.name        AS category_name,
        c.icon_code   AS category_icon,
        c.color_value AS category_color,
        COALESCE((
          SELECT SUM(t.amount) FROM transactions t
          WHERE t.type = 'expense'
            AND t.date BETWEEN ?3 AND ?4
            AND (b.category_id IS NULL OR t.category_id = b.category_id)
        ), 0) AS spent
      FROM budgets b
      LEFT JOIN categories c ON c.id = b.category_id
      WHERE b.year = ?1 AND b.month = ?2
      ORDER BY (b.category_id IS NULL) DESC, spent DESC
      ''',
      variables: [
        Variable<int>(year),
        Variable<int>(month),
        Variable<DateTime>(from),
        Variable<DateTime>(to),
      ],
      readsFrom: {budgets, categories, transactions},
    );

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => BudgetWithSpent(
                  budget: budgets.map(r.data),
                  spent: r.read<int>('spent'),
                  categoryName: r.read<String?>('category_name'),
                  categoryIconCode: r.read<int?>('category_icon'),
                  categoryColorValue: r.read<int?>('category_color'),
                ),
              )
              .toList(),
        );
  }

  Future<Budget?> findFor({
    required int? categoryId,
    required int year,
    required int month,
  }) {
    return (select(budgets)
          ..where(
            (b) =>
                b.year.equals(year) &
                b.month.equals(month) &
                (categoryId == null
                    ? b.categoryId.isNull()
                    : b.categoryId.equals(categoryId)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> upsert(BudgetsCompanion budget) =>
      into(budgets).insertOnConflictUpdate(budget);

  Future<int> deleteById(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  /// Trung bình chi mỗi tháng của một danh mục trong [months] tháng gần nhất.
  ///
  /// Dùng cho nút "Gợi ý từ 3 tháng gần nhất" (mục E.1) — cải tiến so với
  /// MoneyNote, vốn bắt bạn tự nghĩ ra con số từ hư không.
  ///
  /// Chia cho số tháng có dữ liệu chứ không phải [months]: người mới dùng app
  /// được một tháng mà chia cho 3 sẽ ra gợi ý thấp một cách vô lý.
  Future<int> averageMonthlySpend({
    required int? categoryId,
    required DateTime from,
    required DateTime to,
  }) async {
    final row = await db.customSelect(
      '''
      SELECT
        COALESCE(SUM(amount), 0) AS total,
        COUNT(DISTINCT strftime('%Y-%m', date, 'unixepoch')) AS months
      FROM transactions
      WHERE type = 'expense'
        AND date BETWEEN ?1 AND ?2
        ${categoryId == null ? '' : 'AND category_id = ?3'}
      ''',
      variables: [
        Variable<DateTime>(from),
        Variable<DateTime>(to),
        if (categoryId != null) Variable<int>(categoryId),
      ],
      readsFrom: {transactions},
    ).getSingle();

    final total = row.read<int>('total');
    final months = row.read<int>('months');
    return months == 0 ? 0 : total ~/ months;
  }
}
