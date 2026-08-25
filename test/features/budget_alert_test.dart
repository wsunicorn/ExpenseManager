import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/core/utils/date_range.dart';
import 'package:so_thu_chi/features/entry/data/transaction_repository.dart';

/// Ngân sách được tính đúng sau khi ghi giao dịch, và callback cảnh báo nhận
/// đúng phần chênh — `01_DAC_TA_TINH_NANG.md` mục E.3.
void main() {
  late AppDatabase db;
  late int viId;
  late int dmAnUong;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    viId = await db.walletDao.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        type: WalletType.cash,
        iconCode: 1,
        colorValue: 1,
        initialBalance: const Value(50000000),
      ),
    );
    final rows = await (db.select(db.categories)
          ..where((c) => c.name.equals('Ăn uống')))
        .get();
    dmAnUong = rows.single.id;
  });

  tearDown(() async => db.close());

  test('callback nhận đúng ngày, danh mục và phần chi vừa thêm', () async {
    final ghiNhan = <Map<String, Object>>[];

    final repo = TransactionRepository(
      db,
      onExpenseRecorded: ({
        required DateTime date,
        required int categoryId,
        required int spentDelta,
      }) async {
        ghiNhan.add({
          'date': date,
          'categoryId': categoryId,
          'spentDelta': spentDelta,
        });
      },
    );

    await repo.saveIncomeOrExpense(
      type: TransactionType.expense,
      amount: 250000,
      walletId: viId,
      categoryId: dmAnUong,
      date: DateTime(2026, 8, 24),
    );

    expect(ghiNhan, hasLength(1));
    expect(ghiNhan.single['spentDelta'], 250000);
    expect(ghiNhan.single['categoryId'], dmAnUong);
    expect(ghiNhan.single['date'], DateTime(2026, 8, 24));
  });

  /// Khoản thu không tiêu tiền nên không được kích hoạt cảnh báo ngân sách.
  test('khoản thu không gọi callback', () async {
    var soLan = 0;
    final dmThu = (await (db.select(db.categories)
              ..where((c) => c.type.equalsValue(CategoryType.income))
              ..limit(1))
            .get())
        .single
        .id;

    final repo = TransactionRepository(
      db,
      onExpenseRecorded: ({
        required DateTime date,
        required int categoryId,
        required int spentDelta,
      }) async =>
          soLan++,
    );

    await repo.saveIncomeOrExpense(
      type: TransactionType.income,
      amount: 18000000,
      walletId: viId,
      categoryId: dmThu,
      date: DateTime(2026, 8, 24),
    );

    expect(soLan, 0);
  });

  test('onDataChanged được gọi sau mọi thay đổi dữ liệu', () async {
    var soLan = 0;
    final repo = TransactionRepository(db, onDataChanged: () async => soLan++);

    await repo.saveIncomeOrExpense(
      type: TransactionType.expense,
      amount: 50000,
      walletId: viId,
      categoryId: dmAnUong,
      date: DateTime(2026, 8, 24),
    );
    expect(soLan, 1, reason: 'sau khi ghi');

    final tx = (await db.select(db.transactions).get()).single;
    await repo.deleteTransactions([tx.id]);
    expect(soLan, 2, reason: 'sau khi xoá');
  });

  group('số đã chi của ngân sách', () {
    test('ngân sách danh mục chỉ tính khoản chi thuộc danh mục đó', () async {
      final dmDiLai = (await (db.select(db.categories)
                ..where((c) => c.name.equals('Đi lại')))
              .get())
          .single
          .id;

      await db.budgetDao.upsert(
        BudgetsCompanion.insert(
          categoryId: Value(dmAnUong),
          amount: 3000000,
          year: 2026,
          month: 8,
        ),
      );

      final repo = TransactionRepository(db);
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 250000,
        walletId: viId,
        categoryId: dmAnUong,
        date: DateTime(2026, 8, 10),
      );
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 999000,
        walletId: viId,
        categoryId: dmDiLai,
        date: DateTime(2026, 8, 11),
      );

      final range = calendarMonthOf(DateTime(2026, 8, 1));
      final list = await db.budgetDao
          .watchForMonth(
            year: 2026,
            month: 8,
            from: range.start,
            to: range.end,
          )
          .first;

      expect(list.single.spent, 250000, reason: 'không cộng khoản Đi lại');
    });

    test('ngân sách tổng cộng mọi khoản chi', () async {
      await db.budgetDao.upsert(
        BudgetsCompanion.insert(
          amount: 10000000,
          year: 2026,
          month: 8,
        ),
      );

      final repo = TransactionRepository(db);
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 250000,
        walletId: viId,
        categoryId: dmAnUong,
        date: DateTime(2026, 8, 10),
      );

      final range = calendarMonthOf(DateTime(2026, 8, 1));
      final list = await db.budgetDao
          .watchForMonth(year: 2026, month: 8, from: range.start, to: range.end)
          .first;

      expect(list.single.isTotalBudget, isTrue);
      expect(list.single.spent, 250000);
    });

    /// Chuyển ví không phải tiêu tiền — quy tắc số 3.
    test('chuyển ví không làm tăng số đã chi của ngân sách', () async {
      final viMoMo = await db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: 'MoMo',
          type: WalletType.ewallet,
          iconCode: 1,
          colorValue: 1,
        ),
      );
      await db.budgetDao.upsert(
        BudgetsCompanion.insert(
          amount: 10000000,
          year: 2026,
          month: 8,
        ),
      );

      final repo = TransactionRepository(db);
      await repo.saveTransfer(
        amount: 5000000,
        fromWalletId: viId,
        toWalletId: viMoMo,
        date: DateTime(2026, 8, 10),
      );

      final range = calendarMonthOf(DateTime(2026, 8, 1));
      final list = await db.budgetDao
          .watchForMonth(year: 2026, month: 8, from: range.start, to: range.end)
          .first;

      expect(list.single.spent, 0);
    });
  });

  group('gợi ý hạn mức', () {
    test('chia cho số tháng CÓ dữ liệu, không phải số tháng yêu cầu', () async {
      final repo = TransactionRepository(db);
      // Chỉ một tháng có dữ liệu.
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 3000000,
        walletId: viId,
        categoryId: dmAnUong,
        date: DateTime(2026, 7, 10),
      );

      final tb = await db.budgetDao.averageMonthlySpend(
        categoryId: dmAnUong,
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 7, 31),
      );

      // Chia cho 1 tháng có dữ liệu, không phải 3 — nếu chia 3 sẽ ra 1 triệu
      // và gợi ý thấp một cách vô lý cho người mới dùng app.
      expect(tb, 3000000);
    });

    test('chưa có dữ liệu thì trả 0, không chia cho 0', () async {
      final tb = await db.budgetDao.averageMonthlySpend(
        categoryId: dmAnUong,
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 7, 31),
      );
      expect(tb, 0);
    });
  });
}
