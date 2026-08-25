import 'package:drift/drift.dart';

import 'categories.dart';

/// Ngân sách theo tháng. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.4.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// **Null nghĩa là ngân sách tổng** cho cả tháng, không thuộc danh mục nào.
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  /// Hạn mức, đơn vị đồng.
  IntColumn get amount => integer()();

  IntColumn get year => integer()();

  /// 1–12.
  IntColumn get month => integer()();

  /// "Áp dụng cho các tháng sau" — cải tiến so với MoneyNote, vốn bắt đặt lại
  /// ngân sách mỗi tháng (file 01 mục E.1).
  BoolColumn get repeatForward =>
      boolean().withDefault(const Constant(false))();

  /// Mỗi danh mục chỉ có một ngân sách trong một tháng.
  ///
  /// Lưu ý về SQLite: trong ràng buộc UNIQUE, nhiều dòng có `category_id`
  /// NULL **không** bị coi là trùng nhau. Nghĩa là ràng buộc này không chặn
  /// được hai ngân sách tổng cùng tháng — việc đó phải do repository lo.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {categoryId, year, month},
      ];
}
