import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/utils/text_search.dart';

/// Kết quả một thao tác có thể bị nghiệp vụ từ chối.
sealed class CategoryActionResult {
  const CategoryActionResult();
}

class CategoryActionOk extends CategoryActionResult {
  const CategoryActionOk();
}

class CategoryActionRejected extends CategoryActionResult {
  const CategoryActionRejected(this.reason);

  /// Câu tiếng Việt hiển thị thẳng cho người dùng.
  final String reason;
}

/// Tầng nghiệp vụ của danh mục. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục F.2.
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<Category>> watchByType(
    CategoryType type, {
    bool includeArchived = false,
  }) =>
      _db.categoryDao.watchByType(type, includeArchived: includeArchived);

  Future<int> createCategory({
    required String name,
    required CategoryType type,
    required int iconCode,
    required int colorValue,
  }) async {
    final ten = name.trim();

    // sortOrder đẩy xuống cuối danh sách cùng loại, để danh mục mới không chen
    // vào giữa những cái người dùng đã sắp.
    final cungLoai = await (_db.select(_db.categories)
          ..where((c) => c.type.equalsValue(type)))
        .get();
    final thuTu = cungLoai.fold<int>(
      0,
      (max, c) => c.sortOrder > max ? c.sortOrder : max,
    );

    return _db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: ten,
        nameAscii: Value(normalizeForSearch(ten)),
        type: type,
        iconCode: iconCode,
        colorValue: colorValue,
        sortOrder: Value(thuTu + 1),
      ),
    );
  }

  /// Sửa danh mục. **Không cho đổi `type`** — đổi một danh mục chi thành thu
  /// sẽ làm mọi giao dịch cũ thuộc nó nhảy sang vế ngược lại trong báo cáo,
  /// và không có cách nào nhận ra điều đó đã xảy ra.
  Future<void> updateCategory(
    Category original, {
    required String name,
    required int iconCode,
    required int colorValue,
  }) async {
    final ten = name.trim();
    await _db.categoryDao.updateCategory(
      original.copyWith(
        name: ten,
        nameAscii: normalizeForSearch(ten),
        iconCode: iconCode,
        colorValue: colorValue,
      ),
    );
  }

  /// Xoá danh mục. **Chỉ thành công khi chưa có giao dịch nào dùng nó.**
  ///
  /// Đặc tả mục F.2: danh mục đã có giao dịch chỉ được **ẩn**, giữ nguyên lịch
  /// sử. Xoá cứng sẽ khiến các giao dịch cũ mất tên danh mục và báo cáo hiện
  /// một khoảng trống không giải thích được.
  Future<CategoryActionResult> deleteCategory(int categoryId) async {
    final soGiaoDich = await _db.categoryDao.countTransactions(categoryId);
    if (soGiaoDich > 0) {
      return CategoryActionRejected(
        'Danh mục này đang có $soGiaoDich giao dịch nên không xoá được. '
        'Hãy ẩn nó — danh mục biến khỏi lưới chọn nhưng lịch sử vẫn nguyên.',
      );
    }

    // Danh mục con trỏ vào nó cũng phải được gỡ trước, nếu không khoá ngoại
    // sẽ chặn.
    final coCon = await (_db.select(_db.categories)
          ..where((c) => c.parentId.equals(categoryId)))
        .get();
    if (coCon.isNotEmpty) {
      return CategoryActionRejected(
        'Danh mục này còn ${coCon.length} danh mục con. Xoá chúng trước.',
      );
    }

    await (_db.delete(_db.categories)..where((c) => c.id.equals(categoryId)))
        .go();
    return const CategoryActionOk();
  }

  Future<void> setArchived(int categoryId, {required bool archived}) =>
      _db.categoryDao.setArchived(categoryId, archived: archived);

  /// Sắp xếp lại sau khi người dùng kéo thả.
  Future<void> reorder(List<int> orderedIds) =>
      _db.categoryDao.reorder(orderedIds);

  Future<int> countTransactions(int categoryId) =>
      _db.categoryDao.countTransactions(categoryId);
}
