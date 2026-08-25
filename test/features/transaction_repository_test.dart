import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/entry/data/transaction_repository.dart';

/// Quy tắc nghiệp vụ ở `01_DAC_TA_TINH_NANG.md` mục K.
///
/// Quan trọng nhất là quy tắc số 3: **chuyển ví không phải thu/chi.** Đây là
/// bug phổ biến nhất của app sổ thu chi — chuyển 5 triệu từ ngân hàng sang ví
/// tiền mặt bị đếm thành chi 5 triệu, báo cáo tháng phồng lên vô lý và người
/// dùng mất niềm tin vào toàn bộ con số.
void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  final ngay = DateTime(2026, 8, 24);
  final dauThang = DateTime(2026, 8, 1);
  final cuoiThang = DateTime(2026, 8, 31);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> taoVi(String ten, int soDuGoc) => db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: ten,
          type: WalletType.cash,
          iconCode: 0xe263,
          colorValue: 0xFF43A047,
          initialBalance: Value(soDuGoc),
        ),
      );

  Future<int> danhMuc(CategoryType type) async {
    final rows = await (db.select(db.categories)
          ..where((c) => c.type.equalsValue(type))
          ..limit(1))
        .get();
    return rows.single.id;
  }

  group('ghi thu / chi', () {
    test('ghi được khoản chi và trừ đúng số dư', () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      final result = await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: await danhMuc(CategoryType.expense),
        date: ngay,
        note: 'Cơm trưa',
      );

      expect(result, isA<SaveOk>());
      expect((result as SaveOk).ids, hasLength(1));
      expect(await db.walletDao.watchBalance(vi).first, 950000);
    });

    /// Quy tắc số 8.
    test('từ chối số tiền bằng 0 hoặc âm', () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      final dm = await danhMuc(CategoryType.expense);

      for (final soTien in [0, -1000]) {
        final r = await repo.saveIncomeOrExpense(
          type: TransactionType.expense,
          amount: soTien,
          walletId: vi,
          categoryId: dm,
          date: ngay,
        );
        expect(r, isA<SaveRejected>(), reason: 'với số tiền $soTien');
      }
      // Không dòng nào được ghi.
      expect(await db.select(db.transactions).get(), isEmpty);
    });

    test('ngày được cắt bỏ phần giờ trước khi lưu', () async {
      final vi = await taoVi('Tiền mặt', 0);
      await repo.saveIncomeOrExpense(
        type: TransactionType.income,
        amount: 100000,
        walletId: vi,
        categoryId: await danhMuc(CategoryType.income),
        date: DateTime(2026, 8, 24, 15, 42, 7),
      );

      final tx = (await db.select(db.transactions).get()).single;
      expect(tx.date, DateTime(2026, 8, 24));
    });

    test('ghi chú được cắt khoảng trắng thừa', () async {
      final vi = await taoVi('Tiền mặt', 0);
      await repo.saveIncomeOrExpense(
        type: TransactionType.income,
        amount: 100000,
        walletId: vi,
        categoryId: await danhMuc(CategoryType.income),
        date: ngay,
        note: '   Lương tháng 8   ',
      );
      expect((await db.select(db.transactions).get()).single.note,
          'Lương tháng 8');
    });
  });

  group('chuyển ví', () {
    test('từ chối khi ví nguồn trùng ví đích', () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      final r = await repo.saveTransfer(
        amount: 100000,
        fromWalletId: vi,
        toWalletId: vi,
        date: ngay,
      );
      expect(r, isA<SaveRejected>());
      expect(
        (r as SaveRejected).reason,
        contains('khác nhau'),
      );
    });

    test('từ chối phí âm', () async {
      final a = await taoVi('A', 1000000);
      final b = await taoVi('B', 0);
      final r = await repo.saveTransfer(
        amount: 100000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
        fee: -5000,
      );
      expect(r, isA<SaveRejected>());
    });

    /// Quy tắc số 3 — mấu chốt của cả nhóm test này.
    test('KHÔNG được tính vào tổng thu hay tổng chi của báo cáo', () async {
      final a = await taoVi('Ngân hàng', 10000000);
      final b = await taoVi('Tiền mặt', 0);

      await repo.saveTransfer(
        amount: 5000000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
      );

      final totals = await repo.watchTotals(dauThang, cuoiThang).first;
      expect(totals.income, 0, reason: 'chuyển ví không phải thu nhập');
      expect(totals.expense, 0, reason: 'chuyển ví không phải chi tiêu');
    });

    test('điều chỉnh cũng không vào báo cáo thu/chi', () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.adjustment,
              amount: -23000,
              walletId: vi,
              date: ngay,
            ),
          );

      final totals = await repo.watchTotals(dauThang, cuoiThang).first;
      expect(totals.income, 0);
      expect(totals.expense, 0);
      // Nhưng số dư thì có đổi.
      expect(await db.walletDao.watchBalance(vi).first, 977000);
    });

    test('phí chuyển thành khoản chi riêng thuộc "Phí ngân hàng"', () async {
      final a = await taoVi('Ngân hàng', 10000000);
      final b = await taoVi('Tiền mặt', 0);

      final r = await repo.saveTransfer(
        amount: 5000000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
        fee: 11000,
      );

      // Hai dòng: một chuyển, một chi phí.
      expect((r as SaveOk).ids, hasLength(2));

      final all = await db.select(db.transactions).get();
      final phi = all.firstWhere((t) => t.type == TransactionType.expense);
      final danhMucPhi = await db.categoryDao.findById(phi.categoryId!);
      expect(danhMucPhi!.name, kBankFeeCategoryName);

      // Phí trừ vào ví nguồn.
      expect(await db.walletDao.watchBalance(a).first, 10000000 - 5000000 - 11000);
      expect(await db.walletDao.watchBalance(b).first, 5000000);

      // Phí thì CÓ vào báo cáo chi — vì nó thật sự làm bạn nghèo đi.
      final totals = await repo.watchTotals(dauThang, cuoiThang).first;
      expect(totals.expense, 11000);
    });

    test('không có phí thì chỉ ghi đúng một dòng', () async {
      final a = await taoVi('A', 1000000);
      final b = await taoVi('B', 0);
      final r = await repo.saveTransfer(
        amount: 100000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
      );
      expect((r as SaveOk).ids, hasLength(1));
    });
  });

  group('sửa giao dịch', () {
    test('sửa số tiền thì số dư tính lại ngay', () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      final dm = await danhMuc(CategoryType.expense);

      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: dm,
        date: ngay,
      );
      expect(await db.walletDao.watchBalance(vi).first, 950000);

      final tx = (await db.select(db.transactions).get()).single;
      final r = await repo.editIncomeOrExpense(
        original: tx,
        amount: 80000,
        walletId: vi,
        categoryId: dm,
        date: ngay,
      );

      expect(r, isA<SaveOk>());
      expect(await db.walletDao.watchBalance(vi).first, 920000);
    });

    /// Cùng bộ quy tắc với lúc tạo — không được có đường vòng nào lách được.
    test('sửa về số tiền ≤ 0 bị từ chối, dữ liệu cũ giữ nguyên', () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      final dm = await danhMuc(CategoryType.expense);

      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: dm,
        date: ngay,
      );
      final tx = (await db.select(db.transactions).get()).single;

      final r = await repo.editIncomeOrExpense(
        original: tx,
        amount: 0,
        walletId: vi,
        categoryId: dm,
        date: ngay,
      );

      expect(r, isA<SaveRejected>());
      expect((await db.select(db.transactions).get()).single.amount, 50000);
      expect(await db.walletDao.watchBalance(vi).first, 950000);
    });

    test('đổi ví thì số dư cả hai ví đều đổi theo', () async {
      final a = await taoVi('Tiền mặt', 1000000);
      final b = await taoVi('MoMo', 1000000);
      final dm = await danhMuc(CategoryType.expense);

      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: a,
        categoryId: dm,
        date: ngay,
      );
      final tx = (await db.select(db.transactions).get()).single;

      await repo.editIncomeOrExpense(
        original: tx,
        amount: 50000,
        walletId: b,
        categoryId: dm,
        date: ngay,
      );

      expect(await db.walletDao.watchBalance(a).first, 1000000);
      expect(await db.walletDao.watchBalance(b).first, 950000);
    });

    test('sửa ngày cũng cắt bỏ phần giờ', () async {
      final vi = await taoVi('Tiền mặt', 0);
      final dm = await danhMuc(CategoryType.income);
      await repo.saveIncomeOrExpense(
        type: TransactionType.income,
        amount: 100000,
        walletId: vi,
        categoryId: dm,
        date: ngay,
      );
      final tx = (await db.select(db.transactions).get()).single;

      await repo.editIncomeOrExpense(
        original: tx,
        amount: 100000,
        walletId: vi,
        categoryId: dm,
        date: DateTime(2026, 9, 2, 11, 30),
      );

      expect(
        (await db.select(db.transactions).get()).single.date,
        DateTime(2026, 9, 2),
      );
    });

    test('sửa chuyển ví: từ chối khi hai ví trùng nhau', () async {
      final a = await taoVi('A', 1000000);
      final b = await taoVi('B', 0);
      await repo.saveTransfer(
        amount: 100000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
      );
      final tx = (await db.select(db.transactions).get()).single;

      final r = await repo.editTransfer(
        original: tx,
        amount: 100000,
        fromWalletId: a,
        toWalletId: a,
        date: ngay,
      );

      expect(r, isA<SaveRejected>());
    });

    test('sửa chuyển ví không đụng tới dòng phí đi kèm', () async {
      final a = await taoVi('A', 1000000);
      final b = await taoVi('B', 0);
      await repo.saveTransfer(
        amount: 100000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
        fee: 5000,
      );

      final all = await db.select(db.transactions).get();
      final chuyen =
          all.firstWhere((t) => t.type == TransactionType.transfer);

      await repo.editTransfer(
        original: chuyen,
        amount: 200000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
      );

      final sau = await db.select(db.transactions).get();
      final phi = sau.firstWhere((t) => t.type == TransactionType.expense);
      expect(phi.amount, 5000, reason: 'phí phải giữ nguyên');
      expect(await db.walletDao.watchBalance(a).first, 1000000 - 200000 - 5000);
    });

    /// Số tiền của điều chỉnh là phần chênh đã tính lúc đếm lại ví. Cho sửa
    /// bằng tay sẽ khiến số dư nói dối mà không truy ngược được.
    test('điều chỉnh chỉ sửa được ngày và ghi chú, không sửa số tiền',
        () async {
      final vi = await taoVi('Tiền mặt', 1000000);
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.adjustment,
              amount: -23000,
              walletId: vi,
              date: ngay,
            ),
          );
      final tx = (await db.select(db.transactions).get()).single;

      await repo.editAdjustmentMeta(
        original: tx,
        date: DateTime(2026, 8, 26),
        note: 'Đếm lại ví buổi tối',
      );

      final sau = (await db.select(db.transactions).get()).single;
      expect(sau.amount, -23000, reason: 'số tiền không đổi');
      expect(sau.date, DateTime(2026, 8, 26));
      expect(sau.note, 'Đếm lại ví buổi tối');
      expect(await db.walletDao.watchBalance(vi).first, 977000);
    });
  });

  group('hoàn tác', () {
    test('xoá được mọi dòng vừa ghi, kể cả cặp chuyển ví có phí', () async {
      final a = await taoVi('A', 1000000);
      final b = await taoVi('B', 0);

      final r = await repo.saveTransfer(
        amount: 100000,
        fromWalletId: a,
        toWalletId: b,
        date: ngay,
        fee: 5000,
      ) as SaveOk;

      expect(await db.walletDao.watchBalance(a).first, 895000);

      await repo.deleteTransactions(r.ids);

      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.walletDao.watchBalance(a).first, 1000000);
      expect(await db.walletDao.watchBalance(b).first, 0);
    });
  });

  group('tổng thu chi theo kỳ', () {
    test('cộng đúng thu và chi trong kỳ, bỏ giao dịch ngoài kỳ', () async {
      final vi = await taoVi('Tiền mặt', 0);
      final dmThu = await danhMuc(CategoryType.income);
      final dmChi = await danhMuc(CategoryType.expense);

      await repo.saveIncomeOrExpense(
        type: TransactionType.income,
        amount: 18000000,
        walletId: vi,
        categoryId: dmThu,
        date: DateTime(2026, 8, 5),
      );
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 3200000,
        walletId: vi,
        categoryId: dmChi,
        date: DateTime(2026, 8, 20),
      );
      // Tháng trước — không được tính.
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 999000,
        walletId: vi,
        categoryId: dmChi,
        date: DateTime(2026, 7, 15),
      );

      final totals = await repo.watchTotals(dauThang, cuoiThang).first;
      expect(totals.income, 18000000);
      expect(totals.expense, 3200000);
    });

    test('kỳ không có giao dịch trả 0, không phải null', () async {
      final totals = await repo.watchTotals(dauThang, cuoiThang).first;
      expect(totals.income, 0);
      expect(totals.expense, 0);
    });
  });
}
