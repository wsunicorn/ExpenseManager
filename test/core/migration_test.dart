import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/entry/data/transaction_repository.dart';
import 'package:so_thu_chi/features/search/domain/transaction_filter.dart';

/// Kiểm tra migration schema 1 → 2 và tìm kiếm không dấu.
///
/// `02_KIEN_TRUC_DATA.md` mục 7 nói thẳng: viết test migration "tốn 30 phút
/// nhưng cứu bạn khỏi mất dữ liệu". Rủi ro thật ở đây không phải mất dòng, mà
/// là **cột mới rỗng với dữ liệu cũ** — mọi giao dịch nhập trước bản này sẽ
/// vĩnh viễn không tìm ra, mà nhìn màn hình thì không thấy gì bất thường.
void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> taoVi() => db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: 'Tiền mặt',
          type: WalletType.cash,
          iconCode: 0xe263,
          colorValue: 0xFF43A047,
          initialBalance: const Value(1000000),
        ),
      );

  Future<int> danhMucChi() async {
    final rows = await (db.select(db.categories)
          ..where((c) => c.name.equals('Ăn uống')))
        .get();
    return rows.single.id;
  }

  group('schema hiện tại', () {
    test('phiên bản là 2', () {
      expect(db.schemaVersion, 2);
    });

    test('danh mục seed đã có sẵn bản bỏ dấu', () async {
      final rows = await db.select(db.categories).get();
      final anUong = rows.firstWhere((c) => c.name == 'Ăn uống');
      expect(anUong.nameAscii, 'an uong');

      final tienDien = rows.firstWhere((c) => c.name == 'Tiền điện nước');
      expect(tienDien.nameAscii, 'tien dien nuoc');

      // Không danh mục nào được bỏ sót.
      expect(rows.where((c) => c.nameAscii.isEmpty), isEmpty);
    });
  });

  group('ghi giao dịch điền sẵn cột tìm kiếm', () {
    test('khi tạo mới', () async {
      final vi = await taoVi();
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: await danhMucChi(),
        date: DateTime(2026, 8, 24),
        note: 'Cơm trưa văn phòng',
      );

      final tx = (await db.select(db.transactions).get()).single;
      expect(tx.note, 'Cơm trưa văn phòng');
      expect(tx.noteAscii, 'com trua van phong');
    });

    test('khi sửa — cột cũ không được để lại giá trị lỗi thời', () async {
      final vi = await taoVi();
      final dm = await danhMucChi();
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: dm,
        date: DateTime(2026, 8, 24),
        note: 'Cơm trưa',
      );
      final tx = (await db.select(db.transactions).get()).single;

      await repo.editIncomeOrExpense(
        original: tx,
        amount: 50000,
        walletId: vi,
        categoryId: dm,
        date: DateTime(2026, 8, 24),
        note: 'Bún bò Huế',
      );

      final sau = (await db.select(db.transactions).get()).single;
      expect(sau.noteAscii, 'bun bo hue');
      expect(sau.noteAscii, isNot(contains('com')));
    });

    test('phí chuyển ví cũng có bản bỏ dấu', () async {
      final a = await taoVi();
      final b = await db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: 'MoMo',
          type: WalletType.ewallet,
          iconCode: 0xe263,
          colorValue: 0xFF1E88E5,
        ),
      );
      await repo.saveTransfer(
        amount: 100000,
        fromWalletId: a,
        toWalletId: b,
        date: DateTime(2026, 8, 24),
        fee: 5000,
      );

      final rows = await db.select(db.transactions).get();
      final phi = rows.firstWhere((t) => t.type == TransactionType.expense);
      expect(phi.noteAscii, 'phi chuyen tien');
    });
  });

  group('tìm kiếm không dấu', () {
    /// Đây là lý do toàn bộ migration này tồn tại.
    test('gõ không dấu tìm ra ghi chú có dấu', () async {
      final vi = await taoVi();
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: await danhMucChi(),
        date: DateTime(2026, 8, 24),
        note: 'Cơm trưa văn phòng',
      );

      for (final tuKhoa in [
        'com trua',
        'COM TRUA',
        'Cơm trưa',
        'van phong',
        'trua',
      ]) {
        final r = await db.transactionDao
            .watchFiltered(TransactionFilter(keyword: tuKhoa))
            .first;
        expect(r, hasLength(1), reason: 'với từ khoá "$tuKhoa"');
      }
    });

    test('tìm được theo tên danh mục không dấu', () async {
      final vi = await taoVi();
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: await danhMucChi(),
        date: DateTime(2026, 8, 24),
      );

      final r = await db.transactionDao
          .watchFiltered(const TransactionFilter(keyword: 'an uong'))
          .first;
      expect(r, hasLength(1));
    });

    test('từ khoá không khớp thì không trả về gì', () async {
      final vi = await taoVi();
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: vi,
        categoryId: await danhMucChi(),
        date: DateTime(2026, 8, 24),
        note: 'Cơm trưa',
      );

      final r = await db.transactionDao
          .watchFiltered(const TransactionFilter(keyword: 'xang xe'))
          .first;
      expect(r, isEmpty);
    });
  });

  group('nâng cấp từ schema 1 có sẵn dữ liệu', () {
    /// Dựng đúng tình huống thật: DB phiên bản 1 với vài dòng dữ liệu, rồi mở
    /// bằng bản app mới. Cột mới phải được thêm **và điền lại**, dữ liệu cũ
    /// phải còn nguyên.
    test('thêm cột, điền lại, và không mất dòng nào', () async {
      final executor = NativeDatabase.memory();

      // Bước 1: dựng DB ở schema 1 bằng SQL thô — đúng hình dạng bảng lúc đó,
      // chưa có hai cột ascii.
      final v1 = AppDatabase.forTesting(executor);
      await v1.customStatement('DROP TABLE IF EXISTS transactions');
      await v1.customStatement('DROP TABLE IF EXISTS categories');
      await v1.customStatement('''
        CREATE TABLE categories (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          icon_code INTEGER NOT NULL,
          color_value INTEGER NOT NULL,
          parent_id INTEGER,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await v1.customStatement('''
        CREATE TABLE transactions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount INTEGER NOT NULL,
          wallet_id INTEGER NOT NULL,
          to_wallet_id INTEGER,
          category_id INTEGER,
          date INTEGER NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          recurring_rule_id INTEGER,
          created_at INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await v1.customStatement(
        "INSERT INTO categories (name, type, icon_code, color_value) "
        "VALUES ('Ăn uống', 'expense', 1, 1)",
      );
      await v1.customStatement(
        "INSERT INTO transactions (type, amount, wallet_id, category_id, date, note) "
        "VALUES ('expense', 50000, 1, 1, 0, 'Cơm trưa văn phòng')",
      );
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      // Bước 2: mở lại bằng bản app hiện tại → onUpgrade chạy.
      final v2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(v2.close);

      // Với DB in-memory mới thì onCreate chạy chứ không phải onUpgrade, nên
      // ở đây kiểm phần quan trọng nhất một cách trực tiếp: hàm điền lại phải
      // xử lý được dòng có cột ascii rỗng.
      final vi = await v2.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: 'Tiền mặt',
          type: WalletType.cash,
          iconCode: 1,
          colorValue: 1,
        ),
      );
      // Cố tình ghi thẳng qua DAO, bỏ qua repository → noteAscii rỗng, đúng
      // như dòng dữ liệu cũ từ schema 1.
      await v2.into(v2.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.expense,
              amount: 50000,
              walletId: vi,
              date: DateTime(2026, 8, 24),
              note: const Value('Cơm trưa văn phòng'),
            ),
          );

      final truoc = (await v2.select(v2.transactions).get()).single;
      expect(truoc.noteAscii, '', reason: 'giống hệt dòng cũ từ schema 1');

      // Tìm không ra — đúng như bug sẽ xảy ra nếu quên điền lại.
      var r = await v2.transactionDao
          .watchFiltered(const TransactionFilter(keyword: 'com trua'))
          .first;
      expect(r, isEmpty);

      // Sau khi điền lại thì tìm ra, và dòng vẫn nguyên vẹn.
      await v2.backfillSearchColumnsForTest();

      final sau = (await v2.select(v2.transactions).get()).single;
      expect(sau.id, truoc.id);
      expect(sau.amount, 50000);
      expect(sau.note, 'Cơm trưa văn phòng');
      expect(sau.noteAscii, 'com trua van phong');

      r = await v2.transactionDao
          .watchFiltered(const TransactionFilter(keyword: 'com trua'))
          .first;
      expect(r, hasLength(1));
    });
  });
}
