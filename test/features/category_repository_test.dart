import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/category/data/category_repository.dart';
import 'package:so_thu_chi/features/entry/data/transaction_repository.dart';

/// Quản lý danh mục — `01_DAC_TA_TINH_NANG.md` mục F.2.
void main() {
  late AppDatabase db;
  late CategoryRepository repo;
  late int viId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CategoryRepository(db);
    viId = await db.walletDao.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        type: WalletType.cash,
        iconCode: 1,
        colorValue: 1,
        initialBalance: const Value(10000000),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<int> danhMuc(String ten) async =>
      (await (db.select(db.categories)..where((c) => c.name.equals(ten))).get())
          .single
          .id;

  Future<Category> doc(int id) async =>
      (await (db.select(db.categories)..where((x) => x.id.equals(id))).get())
          .single;

  group('tạo danh mục', () {
    test('tạo được và điền sẵn bản bỏ dấu để tìm không dấu', () async {
      final id = await repo.createCategory(
        name: 'Cà phê sáng',
        type: CategoryType.expense,
        iconCode: 0xe1a5,
        colorValue: 0xFF6D4C41,
      );

      final c = await doc(id);
      expect(c.name, 'Cà phê sáng');
      expect(c.nameAscii, 'ca phe sang');
    });

    test('cắt khoảng trắng thừa ở tên', () async {
      final id = await repo.createCategory(
        name: '   Xăng xe   ',
        type: CategoryType.expense,
        iconCode: 1,
        colorValue: 1,
      );
      expect((await doc(id)).name, 'Xăng xe');
    });

    /// Danh mục mới phải xuống cuối, không chen vào giữa thứ tự đã sắp.
    test('danh mục mới có sortOrder lớn nhất trong cùng loại', () async {
      final cu = await (db.select(db.categories)
            ..where((c) => c.type.equalsValue(CategoryType.expense)))
          .get();
      final maxCu = cu.fold<int>(0, (m, c) => c.sortOrder > m ? c.sortOrder : m);

      final id = await repo.createCategory(
        name: 'Mới toanh',
        type: CategoryType.expense,
        iconCode: 1,
        colorValue: 1,
      );
      expect((await doc(id)).sortOrder, greaterThan(maxCu));
    });
  });

  group('sửa danh mục', () {
    test('đổi tên thì bản bỏ dấu cũng đổi theo', () async {
      final id = await danhMuc('Ăn uống');

      await repo.updateCategory(
        await doc(id),
        name: 'Đi chợ',
        iconCode: 5,
        colorValue: 9,
      );

      final sau = await doc(id);
      expect(sau.name, 'Đi chợ');
      expect(sau.nameAscii, 'di cho');
      expect(sau.iconCode, 5);
      expect(sau.colorValue, 9);
    });

    /// Đổi loại sẽ làm mọi giao dịch cũ nhảy sang vế ngược lại trong báo cáo —
    /// API cố ý không nhận tham số `type`.
    test('loại không đổi được qua updateCategory', () async {
      final id = await danhMuc('Ăn uống');

      await repo.updateCategory(
        await doc(id),
        name: 'Ăn uống',
        iconCode: 1,
        colorValue: 1,
      );

      expect((await doc(id)).type, CategoryType.expense);
    });
  });

  group('xoá và ẩn', () {
    test('xoá được danh mục chưa có giao dịch', () async {
      final id = await repo.createCategory(
        name: 'Thử nghiệm',
        type: CategoryType.expense,
        iconCode: 1,
        colorValue: 1,
      );

      expect(await repo.deleteCategory(id), isA<CategoryActionOk>());
      expect(
        await (db.select(db.categories)..where((c) => c.id.equals(id))).get(),
        isEmpty,
      );
    });

    /// Quy tắc chính của mục F.2: có giao dịch thì chỉ được ẩn.
    test('danh mục đã có giao dịch thì từ chối xoá, gợi ý ẩn', () async {
      final id = await danhMuc('Ăn uống');
      await TransactionRepository(db).saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: viId,
        categoryId: id,
        date: DateTime(2026, 8, 24),
      );

      final r = await repo.deleteCategory(id);
      expect(r, isA<CategoryActionRejected>());
      expect((r as CategoryActionRejected).reason, contains('1 giao dịch'));

      // Dòng vẫn còn nguyên.
      expect(
        await (db.select(db.categories)..where((c) => c.id.equals(id))).get(),
        hasLength(1),
      );
    });

    test('ẩn rồi bỏ ẩn — lịch sử giữ nguyên', () async {
      final id = await danhMuc('Ăn uống');
      await TransactionRepository(db).saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 50000,
        walletId: viId,
        categoryId: id,
        date: DateTime(2026, 8, 24),
      );

      await repo.setArchived(id, archived: true);

      // Lưới chọn ở màn hình Nhập vào không thấy nữa…
      final hienThi = await repo.watchByType(CategoryType.expense).first;
      expect(hienThi.map((c) => c.id), isNot(contains(id)));

      // …nhưng màn hình quản lý vẫn thấy, và giao dịch còn nguyên.
      final tatCa = await repo
          .watchByType(CategoryType.expense, includeArchived: true)
          .first;
      expect(tatCa.map((c) => c.id), contains(id));
      expect(await db.select(db.transactions).get(), hasLength(1));

      await repo.setArchived(id, archived: false);
      final lai = await repo.watchByType(CategoryType.expense).first;
      expect(lai.map((c) => c.id), contains(id));
    });

    test('còn danh mục con thì từ chối xoá', () async {
      final cha = await repo.createCategory(
        name: 'Ăn ngoài',
        type: CategoryType.expense,
        iconCode: 1,
        colorValue: 1,
      );
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Cà phê',
              type: CategoryType.expense,
              iconCode: 1,
              colorValue: 1,
              parentId: Value(cha),
            ),
          );

      final r = await repo.deleteCategory(cha);
      expect(r, isA<CategoryActionRejected>());
      expect((r as CategoryActionRejected).reason, contains('danh mục con'));
    });
  });

  group('sắp xếp', () {
    test('kéo thả đổi thứ tự và giữ nguyên sau khi đọc lại', () async {
      final list = await repo.watchByType(CategoryType.expense).first;
      final ids = list.map((c) => c.id).toList();

      // Đưa phần tử cuối lên đầu.
      final cuoi = ids.removeLast();
      ids.insert(0, cuoi);
      await repo.reorder(ids);

      // Danh mục chưa dùng bao giờ được sắp theo sortOrder, nên phần tử vừa
      // đưa lên đầu phải đứng đầu.
      final sau = await repo.watchByType(CategoryType.expense).first;
      expect(sau.first.id, cuoi);
    });
  });
}
