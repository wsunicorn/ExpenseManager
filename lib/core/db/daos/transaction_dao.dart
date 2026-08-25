import 'package:drift/drift.dart';

import '../../../features/search/domain/transaction_filter.dart';
import '../../utils/text_search.dart';
import '../database.dart';
import '../enums.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';
import '../tables/wallets.dart';

part 'transaction_dao.g.dart';

/// Tổng thu và chi của một ngày, dùng vẽ hai dòng số nhỏ trong ô lịch.
typedef DayTotals = ({int income, int expense});

/// Tổng chi (hoặc thu) của một danh mục trong kỳ, cho biểu đồ tròn và bảng
/// chi tiết ở tab Báo cáo.
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.amount,
    required this.count,
  });

  final int categoryId;
  final String name;
  final int iconCode;
  final int colorValue;

  /// Tổng tiền, luôn dương.
  final int amount;

  /// Số giao dịch — hiện ở bảng chi tiết, giúp phân biệt "một khoản lớn" với
  /// "nhiều khoản nhỏ", hai thứ cần hành động khác hẳn nhau.
  final int count;
}

/// Tổng thu chi của một tháng, cho biểu đồ cột 12 tháng.
typedef MonthTotals = ({int year, int month, int income, int expense});

/// Một giao dịch kèm sẵn danh mục và ví, để danh sách không phải truy vấn thêm
/// cho từng dòng (bài toán N+1 query kinh điển).
class TransactionDetail {
  const TransactionDetail({
    required this.transaction,
    this.category,
    this.wallet,
    this.toWallet,
  });

  final Transaction transaction;

  /// Null với `transfer` và `adjustment`.
  final Category? category;

  final Wallet? wallet;

  /// Chỉ khác null với `transfer`.
  final Wallet? toWallet;
}

@DriftAccessor(tables: [Transactions, Categories, Wallets])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<int> insertTransaction(TransactionsCompanion tx) =>
      into(transactions).insert(tx);

  Future<bool> updateTransaction(Transaction tx) =>
      update(transactions).replace(tx);

  Future<int> deleteById(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<Transaction?> findById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Giao dịch trong một khoảng ngày, mới nhất trước.
  ///
  /// `join` với `useColumns: false` cho ví đích: ta cần bảng đó để đọc dữ liệu
  /// nhưng không muốn drift trộn cột trùng tên với ví nguồn.
  Stream<List<TransactionDetail>> watchBetween(DateTime from, DateTime to) {
    final toWallets = alias(wallets, 'to_w');

    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      leftOuterJoin(wallets, wallets.id.equalsExp(transactions.walletId)),
      leftOuterJoin(toWallets, toWallets.id.equalsExp(transactions.toWalletId)),
    ])
      ..where(transactions.date.isBetweenValues(from, to))
      ..orderBy([
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TransactionDetail(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                  toWallet: row.readTableOrNull(toWallets),
                ),
              )
              .toList(),
        );
  }

  /// Tổng thu và tổng chi trong khoảng ngày.
  ///
  /// **Lọc `type IN ('income','expense')`** — chuyển ví và điều chỉnh không bao
  /// giờ được tính vào báo cáo thu/chi. Quên mệnh đề này là bug phổ biến nhất
  /// của app kiểu này: chuyển tiền từ ví nọ sang ví kia bị đếm thành chi tiêu
  /// và báo cáo phồng lên vô lý.
  Stream<({int income, int expense})> watchTotals(DateTime from, DateTime to) {
    final query = db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0) AS inc,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS exp
      FROM transactions
      WHERE type IN ('income', 'expense')
        AND date BETWEEN ?1 AND ?2
      ''',
      variables: [
        Variable<DateTime>(from),
        Variable<DateTime>(to),
      ],
      readsFrom: {transactions},
    );

    return query.watchSingle().map(
          (row) => (income: row.read<int>('inc'), expense: row.read<int>('exp')),
        );
  }

  /// Tìm kiếm giao dịch theo bộ lọc. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C.4.
  ///
  /// Dựng mệnh đề WHERE động: mỗi tiêu chí bỏ trống thì không thêm điều kiện
  /// nào, nên truy vấn vẫn dùng được chỉ mục thay vì quét toàn bảng.
  ///
  /// **Tìm không dấu**: từ khoá được chuẩn hoá rồi so với cột `note_ascii` và
  /// `category.name_ascii` — hai cột lưu sẵn bản đã bỏ dấu, viết thường (thêm
  /// ở schemaVersion 2). Nhờ vậy gõ "com trua" ra được "Cơm trưa".
  Stream<List<TransactionDetail>> watchFiltered(TransactionFilter f) {
    final toWallets = alias(wallets, 'to_w');

    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      leftOuterJoin(wallets, wallets.id.equalsExp(transactions.walletId)),
      leftOuterJoin(toWallets, toWallets.id.equalsExp(transactions.toWalletId)),
    ]);

    // Bắt đầu bằng điều kiện luôn đúng rồi chồng thêm — gọn hơn nhiều so với
    // ghép chuỗi SQL, và không thể sinh ra câu lệnh sai cú pháp.
    Expression<bool> where = const Constant(true);

    final kw = normalizeForSearch(f.keyword);
    if (kw.isNotEmpty) {
      final pattern = '%$kw%';
      where = where &
          (transactions.noteAscii.like(pattern) |
              categories.nameAscii.like(pattern));
    }

    if (f.from != null) {
      where = where & transactions.date.isBiggerOrEqualValue(f.from!);
    }
    if (f.to != null) {
      where = where & transactions.date.isSmallerOrEqualValue(f.to!);
    }

    if (f.walletIds.isNotEmpty) {
      // Ví đích cũng tính: lọc theo ví "MoMo" phải ra cả khoản chuyển đến MoMo.
      where = where &
          (transactions.walletId.isIn(f.walletIds) |
              transactions.toWalletId.isIn(f.walletIds));
    }

    if (f.categoryIds.isNotEmpty) {
      where = where & transactions.categoryId.isIn(f.categoryIds);
    }

    if (f.types.isNotEmpty) {
      where = where &
          transactions.type.isIn(f.types.map((t) => t.name).toList());
    }

    // So trên trị tuyệt đối vì adjustment được phép âm.
    if (f.minAmount != null) {
      where = where & transactions.amount.abs().isBiggerOrEqualValue(f.minAmount!);
    }
    if (f.maxAmount != null) {
      where = where & transactions.amount.abs().isSmallerOrEqualValue(f.maxAmount!);
    }

    query
      ..where(where)
      ..orderBy([
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TransactionDetail(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  wallet: row.readTableOrNull(wallets),
                  toWallet: row.readTableOrNull(toWallets),
                ),
              )
              .toList(),
        );
  }

  /// Tổng thu và chi **theo từng ngày** trong khoảng, để vẽ lưới lịch tháng.
  ///
  /// Cải tiến so với MoneyNote: mỗi ô ngày hiện hai dòng số nhỏ (thu xanh,
  /// chi đỏ) thay vì để trống. Nhờ vậy liếc một cái là thấy ngày nào tiêu
  /// nhiều — đó mới là lý do người ta mở tab Lịch.
  ///
  /// Gộp sẵn ở tầng SQL thay vì kéo hết giao dịch về rồi cộng trong Dart:
  /// một tháng có thể vài trăm dòng, và lưới lịch được vẽ lại mỗi lần cuộn.
  ///
  /// Vẫn lọc `type IN ('income','expense')` — chuyển ví và điều chỉnh không
  /// bao giờ hiện lên như thu hay chi.
  Stream<Map<DateTime, DayTotals>> watchDailyTotals(
    DateTime from,
    DateTime to,
  ) {
    final query = db.customSelect(
      '''
      SELECT
        date,
        COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0) AS inc,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS exp
      FROM transactions
      WHERE type IN ('income', 'expense')
        AND date BETWEEN ?1 AND ?2
      GROUP BY date
      ''',
      variables: [Variable<DateTime>(from), Variable<DateTime>(to)],
      readsFrom: {transactions},
    );

    return query.watch().map((rows) {
      final map = <DateTime, DayTotals>{};
      for (final row in rows) {
        final d = row.read<DateTime>('date');
        map[DateTime(d.year, d.month, d.day)] =
            (income: row.read<int>('inc'), expense: row.read<int>('exp'));
      }
      return map;
    });
  }

  /// Tổng theo danh mục trong một kỳ, sắp giảm dần.
  ///
  /// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục D.2 và D.3.
  ///
  /// **Chỉ nhận `income` hoặc `expense`.** Chuyển ví và điều chỉnh không thuộc
  /// danh mục nào nên tự khắc bị loại, nhưng mệnh đề lọc vẫn được viết tường
  /// minh để câu truy vấn tự nói lên ý định của nó.
  Stream<List<CategoryTotal>> watchCategoryTotals({
    required DateTime from,
    required DateTime to,
    required TransactionType type,
  }) {
    final query = db.customSelect(
      '''
      SELECT
        c.id            AS category_id,
        c.name          AS name,
        c.icon_code     AS icon_code,
        c.color_value   AS color_value,
        SUM(t.amount)   AS total,
        COUNT(*)        AS cnt
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      WHERE t.type = ?1
        AND t.date BETWEEN ?2 AND ?3
      GROUP BY c.id
      ORDER BY total DESC
      ''',
      variables: [
        Variable<String>(type.name),
        Variable<DateTime>(from),
        Variable<DateTime>(to),
      ],
      readsFrom: {transactions, categories},
    );

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => CategoryTotal(
                  categoryId: r.read<int>('category_id'),
                  name: r.read<String>('name'),
                  iconCode: r.read<int>('icon_code'),
                  colorValue: r.read<int>('color_value'),
                  amount: r.read<int>('total'),
                  count: r.read<int>('cnt'),
                ),
              )
              .toList(),
        );
  }

  /// Tổng thu chi từng tháng trong một khoảng — cho biểu đồ cột 12 tháng.
  ///
  /// Gộp theo `strftime` ở tầng SQL. Kéo hết giao dịch cả năm về rồi gom trong
  /// Dart cũng chạy, nhưng biểu đồ được vẽ lại mỗi lần đổi kỳ.
  Stream<List<MonthTotals>> watchMonthlyTotals(
    DateTime from,
    DateTime to,
  ) {
    final query = db.customSelect(
      '''
      SELECT
        CAST(strftime('%Y', date, 'unixepoch') AS INTEGER) AS y,
        CAST(strftime('%m', date, 'unixepoch') AS INTEGER) AS m,
        COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0) AS inc,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS exp
      FROM transactions
      WHERE type IN ('income', 'expense')
        AND date BETWEEN ?1 AND ?2
      GROUP BY y, m
      ORDER BY y ASC, m ASC
      ''',
      variables: [Variable<DateTime>(from), Variable<DateTime>(to)],
      readsFrom: {transactions},
    );

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => (
                  year: r.read<int>('y'),
                  month: r.read<int>('m'),
                  income: r.read<int>('inc'),
                  expense: r.read<int>('exp'),
                ),
              )
              .toList(),
        );
  }

  /// Ghi chú đã dùng, mới nhất trước — dùng cho gợi ý autocomplete ở ô Ghi chú
  /// (đặc tả mục B.1 điểm 5).
  Future<List<String>> recentNotes({int limit = 20}) async {
    final rows = await db.customSelect(
      '''
      SELECT note, MAX(created_at) AS last_used
      FROM transactions
      WHERE note <> ''
      GROUP BY note
      ORDER BY last_used DESC
      LIMIT ?1
      ''',
      variables: [Variable<int>(limit)],
      readsFrom: {transactions},
    ).get();
    return rows.map((r) => r.read<String>('note')).toList();
  }
}
