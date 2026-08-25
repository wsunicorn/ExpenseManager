import 'package:drift/drift.dart';

import '../enums.dart';

/// Danh mục thu / chi. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.2.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Bản bỏ dấu của [name], để tìm kiếm không dấu tìm được cả theo tên danh
  /// mục. Thêm ở schemaVersion 2.
  TextColumn get nameAscii => text().withDefault(const Constant(''))();

  TextColumn get type => textEnum<CategoryType>()();

  IntColumn get iconCode => integer()();

  IntColumn get colorValue => integer()();

  /// Danh mục con, ví dụ Ăn uống → Cà phê. Tính năng `[TC]` của v1
  /// (file 01 mục F.2) — cột có sẵn để không phải migration sau này.
  ///
  /// `references` sinh khoá ngoại trỏ về chính bảng này.
  IntColumn get parentId =>
      integer().nullable().references(Categories, #id)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Ẩn khỏi lưới chọn nhưng giữ nguyên lịch sử.
  ///
  /// Danh mục đã có giao dịch **không được xoá cứng** — chỉ được ẩn
  /// (file 01 mục F.2).
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}
