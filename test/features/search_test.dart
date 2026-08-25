// `hide isNull`: drift cũng xuất một hàm `isNull` để dựng mệnh đề SQL, trùng
// tên với matcher `isNull` của test. Ẩn bản của drift đi vì file này chỉ cần
// `Value` và `Transaction`.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/entry/data/transaction_repository.dart';
import 'package:so_thu_chi/features/search/domain/transaction_filter.dart';

/// Tìm kiếm và lọc giao dịch — `01_DAC_TA_TINH_NANG.md` mục C.4.
void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  late int viTienMat;
  late int viMoMo;
  late int dmAnUong;
  late int dmDiLai;
  late int dmLuong;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);

    Future<int> taoVi(String ten) => db.walletDao.insertWallet(
          WalletsCompanion.insert(
            name: ten,
            type: WalletType.cash,
            iconCode: 0xe263,
            colorValue: 0xFF43A047,
            initialBalance: const Value(10000000),
          ),
        );

    viTienMat = await taoVi('Tiền mặt');
    viMoMo = await taoVi('MoMo');

    Future<int> dm(String ten) async {
      final rows = await (db.select(db.categories)
            ..where((c) => c.name.equals(ten)))
          .get();
      return rows.single.id;
    }

    dmAnUong = await dm('Ăn uống');
    dmDiLai = await dm('Đi lại');
    dmLuong = await dm('Tiền lương');

    // Bộ dữ liệu mẫu trải trên hai tháng, hai ví, ba danh mục.
    await repo.saveIncomeOrExpense(
      type: TransactionType.expense,
      amount: 50000,
      walletId: viTienMat,
      categoryId: dmAnUong,
      date: DateTime(2026, 8, 5),
      note: 'Com trua van phong',
    );
    await repo.saveIncomeOrExpense(
      type: TransactionType.expense,
      amount: 250000,
      walletId: viMoMo,
      categoryId: dmAnUong,
      date: DateTime(2026, 8, 20),
      note: 'Lien hoan cuoi thang',
    );
    await repo.saveIncomeOrExpense(
      type: TransactionType.expense,
      amount: 15000,
      walletId: viTienMat,
      categoryId: dmDiLai,
      date: DateTime(2026, 8, 20),
      note: 'Gui xe',
    );
    await repo.saveIncomeOrExpense(
      type: TransactionType.income,
      amount: 18000000,
      walletId: viMoMo,
      categoryId: dmLuong,
      date: DateTime(2026, 7, 25),
      note: 'Luong thang 7',
    );
    await repo.saveTransfer(
      amount: 2000000,
      fromWalletId: viMoMo,
      toWalletId: viTienMat,
      date: DateTime(2026, 8, 10),
    );
  });

  tearDown(() async => db.close());

  Future<List<Transaction>> tim(TransactionFilter f) async {
    final rows = await db.transactionDao.watchFiltered(f).first;
    return rows.map((r) => r.transaction).toList();
  }

  group('bộ lọc rỗng', () {
    test('trả về mọi giao dịch, mới nhất trước', () async {
      final r = await tim(const TransactionFilter());
      expect(r, hasLength(5));
      expect(r.first.date, DateTime(2026, 8, 20));
      expect(r.last.date, DateTime(2026, 7, 25));
    });

    test('isEmpty đúng và activeCount bằng 0', () {
      const f = TransactionFilter();
      expect(f.isEmpty, isTrue);
      expect(f.activeCount, 0);
    });
  });

  group('tìm theo từ khoá', () {
    test('tìm trong ghi chú', () async {
      final r = await tim(const TransactionFilter(keyword: 'Gui xe'));
      expect(r, hasLength(1));
      expect(r.single.amount, 15000);
    });

    test('khớp một phần, không phân biệt hoa thường với chữ ASCII', () async {
      final r = await tim(const TransactionFilter(keyword: 'com'));
      expect(r, hasLength(1));
    });

    test('tìm được cả trong tên danh mục', () async {
      final r = await tim(const TransactionFilter(keyword: 'Ăn uống'));
      expect(r, hasLength(2));
    });

    test('từ khoá chỉ có khoảng trắng bị bỏ qua', () async {
      final r = await tim(const TransactionFilter(keyword: '   '));
      expect(r, hasLength(5));
    });
  });

  group('lọc theo ngày', () {
    test('chỉ lấy giao dịch trong khoảng, đóng hai đầu', () async {
      final r = await tim(
        TransactionFilter(
          from: DateTime(2026, 8, 1),
          to: DateTime(2026, 8, 31),
        ),
      );
      expect(r, hasLength(4), reason: 'loại khoản lương tháng 7');
    });

    test('ngày biên được tính vào', () async {
      final r = await tim(
        TransactionFilter(
          from: DateTime(2026, 8, 20),
          to: DateTime(2026, 8, 20),
        ),
      );
      expect(r, hasLength(2));
    });
  });

  group('lọc theo ví', () {
    /// Lọc theo ví phải bắt cả vế nhận của giao dịch chuyển — nếu không, khoản
    /// 2 triệu chuyển đến Tiền mặt sẽ biến mất khi lọc ví Tiền mặt.
    test('bắt cả giao dịch chuyển đến ví đó', () async {
      final r = await tim(TransactionFilter(walletIds: {viTienMat}));
      // 2 khoản chi từ Tiền mặt + 1 khoản chuyển đến Tiền mặt.
      expect(r, hasLength(3));
      expect(
        r.where((t) => t.type == TransactionType.transfer),
        hasLength(1),
      );
    });

    test('chọn nhiều ví thì lấy hợp của chúng', () async {
      final r = await tim(TransactionFilter(walletIds: {viTienMat, viMoMo}));
      expect(r, hasLength(5));
    });
  });

  group('lọc theo loại và danh mục', () {
    test('lọc loại chi', () async {
      final r = await tim(
        const TransactionFilter(types: {TransactionType.expense}),
      );
      expect(r, hasLength(3));
    });

    test('lọc được cả loại chuyển ví', () async {
      final r = await tim(
        const TransactionFilter(types: {TransactionType.transfer}),
      );
      expect(r, hasLength(1));
    });

    test('lọc theo danh mục', () async {
      final r = await tim(TransactionFilter(categoryIds: {dmAnUong}));
      expect(r, hasLength(2));
    });
  });

  group('lọc theo khoảng tiền', () {
    test('từ – đến, đóng hai đầu', () async {
      final r = await tim(
        const TransactionFilter(minAmount: 15000, maxAmount: 50000),
      );
      expect(r, hasLength(2));
    });

    test('chỉ có cận dưới', () async {
      final r = await tim(const TransactionFilter(minAmount: 1000000));
      expect(r, hasLength(2), reason: 'khoản lương và khoản chuyển ví');
    });

    /// Điều chỉnh được phép âm — lọc theo độ lớn phải bắt được nó.
    test('so trên trị tuyệt đối nên bắt được điều chỉnh âm', () async {
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.adjustment,
              amount: -23000,
              walletId: viTienMat,
              date: DateTime(2026, 8, 15),
            ),
          );

      final r = await tim(
        const TransactionFilter(minAmount: 20000, maxAmount: 30000),
      );
      expect(r, hasLength(1));
      expect(r.single.amount, -23000);
    });
  });

  group('kết hợp nhiều tiêu chí', () {
    test('các tiêu chí giao nhau, không phải hợp', () async {
      final r = await tim(
        TransactionFilter(
          types: const {TransactionType.expense},
          walletIds: {viTienMat},
          from: DateTime(2026, 8, 1),
          to: DateTime(2026, 8, 31),
        ),
      );
      expect(r, hasLength(2));
    });

    test('activeCount đếm đúng số nhóm tiêu chí đang bật', () {
      final f = TransactionFilter(
        keyword: 'com',
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 31),
        walletIds: const {1},
        minAmount: 1000,
      );
      // từ khoá + khoảng ngày + ví + khoảng tiền = 4
      expect(f.activeCount, 4);
      expect(f.isEmpty, isFalse);
    });
  });

  group('TransactionFilter là value object', () {
    /// Bộ lọc được dùng làm tham số provider — thiếu `==` thì mỗi lần gõ một
    /// ký tự sẽ dựng provider mới và truy vấn lại từ đầu.
    test('hai bộ lọc cùng nội dung thì bằng nhau', () {
      final a = TransactionFilter(
        keyword: 'x',
        walletIds: const {1, 2},
        types: const {TransactionType.income},
        from: DateTime(2026, 1, 1),
      );
      final b = TransactionFilter(
        keyword: 'x',
        walletIds: const {2, 1},
        types: const {TransactionType.income},
        from: DateTime(2026, 1, 1),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('khác nội dung thì khác nhau', () {
      expect(
        const TransactionFilter(keyword: 'a'),
        isNot(const TransactionFilter(keyword: 'b')),
      );
      expect(
        const TransactionFilter(walletIds: {1}),
        isNot(const TransactionFilter(walletIds: {2})),
      );
    });

    test('copyWith xoá được khoảng ngày và khoảng tiền', () {
      final f = TransactionFilter(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 2, 1),
        minAmount: 100,
        maxAmount: 200,
      );
      expect(f.copyWith(clearDates: true).from, isNull);
      expect(f.copyWith(clearDates: true).to, isNull);
      expect(f.copyWith(clearAmounts: true).minAmount, isNull);
      expect(f.copyWith(clearAmounts: true).maxAmount, isNull);
    });
  });
}
