import 'package:drift/drift.dart';

import '../enums.dart';
import 'categories.dart';
import 'wallets.dart';

/// Khuôn sinh giao dịch định kỳ — tiền nhà, tiền điện, phí Internet.
/// Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.5.
///
/// MoneyNote không có tính năng này, phải nhập tay mỗi tháng.
///
/// Bản ghi ở đây **không phải giao dịch** — nó là công thức. Giao dịch thật
/// được sinh ra khi đến hạn và mang `recurringRuleId` trỏ về đây.
@TableIndex(name: 'idx_rule_next_run', columns: {#nextRunDate, #isActive})
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  // ── Phần "khuôn": giống hệt các cột tương ứng của transactions ────────────
  TextColumn get type => textEnum<TransactionType>()();

  IntColumn get amount => integer()();

  IntColumn get walletId => integer().references(Wallets, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  TextColumn get note => text().withDefault(const Constant(''))();

  // ── Phần lịch lặp ─────────────────────────────────────────────────────────
  TextColumn get frequency => textEnum<RecurrenceFrequency>()();

  /// Lặp mỗi N kỳ. `frequency = monthly` + `interval = 3` là mỗi quý.
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// 1–7 (Thứ 2 → Chủ nhật), chỉ dùng khi `frequency = weekly`.
  IntColumn get byWeekday => integer().nullable()();

  /// 1–31, chỉ dùng khi `frequency = monthly`.
  ///
  /// **Chỗ dễ sai nhất toàn app**: quy tắc "mỗi tháng ngày 31" gặp tháng 2
  /// phải lùi về ngày cuối tháng. Xử lý nằm trong hàm thuần `nextOccurrence()`
  /// ở `features/recurring/domain/`, và hàm đó phải có unit test **trước khi**
  /// viết màn hình (Phase 7, file 04).
  IntColumn get byMonthDay => integer().nullable()();

  DateTimeColumn get startDate => dateTime()();

  /// Null nghĩa là lặp mãi.
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Cột then chốt để quét: mỗi lần mở app, tìm mọi quy tắc có
  /// `nextRunDate <= hôm nay` rồi xử lý bù cả những kỳ đã lỡ.
  DateTimeColumn get nextRunDate => dateTime()();

  /// `true` = đến hạn tự ghi luôn (hợp với tiền nhà cố định).
  /// `false` = gửi thông báo nhắc xác nhận (hợp với tiền điện, số tiền đổi
  /// mỗi tháng).
  BoolColumn get autoPost => boolean().withDefault(const Constant(true))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get lastPostedDate => dateTime().nullable()();
}
