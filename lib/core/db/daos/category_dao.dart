import 'package:drift/drift.dart';

import '../database.dart';
import '../enums.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'category_dao.g.dart';

/// Truy vấn danh mục thu / chi.
@DriftAccessor(tables: [Categories, Transactions])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Danh mục theo loại, **danh mục dùng gần đây được đẩy lên đầu**.
  ///
  /// Đặc tả `01_DAC_TA_TINH_NANG.md` mục B.1 điểm 7. Mục tiêu là "nhập xong
  /// một khoản chi trong 3 chạm" (file 07 mục 1.4): danh mục bạn hay dùng phải
  /// nằm sẵn ở hàng đầu, không phải tìm.
  ///
  /// `last_used IS NULL` đứng trước trong ORDER BY để nhóm chưa dùng bao giờ
  /// rơi xuống cuối; trong nhóm đó vẫn giữ thứ tự người dùng tự sắp.
  Stream<List<Category>> watchByType(
    CategoryType type, {
    bool includeArchived = false,
  }) {
    final query = db.customSelect(
      '''
      SELECT c.*, MAX(t.created_at) AS last_used
      FROM categories c
      LEFT JOIN transactions t ON t.category_id = c.id
      WHERE c.type = ?1 ${includeArchived ? '' : 'AND c.is_archived = 0'}
      GROUP BY c.id
      ORDER BY (last_used IS NULL) ASC, last_used DESC, c.sort_order ASC
      ''',
      variables: [Variable<String>(type.name)],
      readsFrom: {categories, transactions},
    );

    return query
        .watch()
        .map((rows) => rows.map((r) => categories.map(r.data)).toList());
  }

  Future<Category?> findById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Tìm danh mục theo tên. Dùng để lấy "Phí ngân hàng" khi ghi phí chuyển ví.
  Future<Category?> findByName(String name, CategoryType type) {
    return (select(categories)
          ..where((c) => c.name.equals(name) & c.type.equalsValue(type))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<bool> updateCategory(Category category) =>
      update(categories).replace(category);

  /// Đếm giao dịch thuộc một danh mục — quyết định được xoá hay chỉ được ẩn.
  Future<int> countTransactions(int categoryId) async {
    final row = await db.customSelect(
      'SELECT COUNT(*) AS c FROM transactions WHERE category_id = ?1',
      variables: [Variable<int>(categoryId)],
      readsFrom: {transactions},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<int> setArchived(int categoryId, {required bool archived}) =>
      (update(categories)..where((c) => c.id.equals(categoryId)))
          .write(CategoriesCompanion(isArchived: Value(archived)));

  Future<void> reorder(List<int> orderedIds) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(categories)..where((c) => c.id.equals(orderedIds[i])))
            .write(CategoriesCompanion(sortOrder: Value(i)));
      }
    });
  }
}
