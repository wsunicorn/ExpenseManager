import 'package:drift/drift.dart';

import '../enums.dart';

/// Ví tiền. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.1.
///
/// Đây là **điểm khác biệt lớn nhất so với MoneyNote**: mỗi ví có số dư gốc
/// khai báo lúc tạo, nên app biết bạn thực sự có bao nhiêu tiền chứ không chỉ
/// cộng trừ từ 0.
///
/// Drift sinh ra lớp `Wallet` (một dòng) và `WalletsCompanion` (dùng khi chèn
/// hoặc cập nhật, cho phép bỏ trống cột nào không đụng tới).
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();

  TextColumn get type => textEnum<WalletType>()();

  /// `codePoint` của `IconData`. Lưu số thay vì tên để không phụ thuộc vào
  /// bảng tra icon có thể đổi giữa các phiên bản Flutter.
  IntColumn get iconCode => integer()();

  /// Màu dạng ARGB 32-bit.
  IntColumn get colorValue => integer()();

  /// **Số dư gốc, đơn vị đồng.** Số tiền đang có trong ví ngay lúc tạo.
  /// Mọi thu chi sau này được cộng trừ từ con số này.
  ///
  /// `int` chứ không bao giờ `double` — xem `core/utils/money.dart`.
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();

  /// v1 chỉ dùng một loại tiền cho toàn app. Cột này để mở đường cho v2.
  TextColumn get currency =>
      text().withLength(max: 8).withDefault(const Constant('VND'))();

  /// Có cộng vào "Tổng tài sản" ở đầu app hay không. Ví tiết kiệm dài hạn
  /// thường được tắt cờ này.
  BoolColumn get includeInTotal =>
      boolean().withDefault(const Constant(true))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Khác null nghĩa là đã lưu trữ.
  ///
  /// Ví đã có giao dịch **không được xoá cứng**, chỉ được lưu trữ — nếu không
  /// lịch sử giao dịch sẽ trỏ vào ví không tồn tại (quy tắc số 5, file 01 mục K).
  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
