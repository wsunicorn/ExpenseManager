import 'package:drift/drift.dart';

import '../enums.dart';
import 'categories.dart';
import 'recurring_rules.dart';
import 'wallets.dart';

/// Bảng trung tâm của app. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.3.
///
/// Bốn chỉ mục dưới đây bám đúng bốn kiểu truy vấn app thực sự chạy:
/// lịch theo ngày, số dư theo ví, báo cáo theo danh mục, tổng thu/chi theo loại.
/// Thiếu chúng thì mỗi lần mở tab Báo cáo SQLite phải quét toàn bảng.
@TableIndex(name: 'idx_tx_date', columns: {#date})
@TableIndex(name: 'idx_tx_wallet_date', columns: {#walletId, #date})
@TableIndex(name: 'idx_tx_category_date', columns: {#categoryId, #date})
@TableIndex(name: 'idx_tx_type_date', columns: {#type, #date})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => textEnum<TransactionType>()();

  /// Số tiền, đơn vị đồng. **Luôn dương**, trừ loại `adjustment` được phép âm
  /// (ngoại lệ duy nhất — xem `TransactionType.adjustment`).
  ///
  /// Không có ràng buộc CHECK ở tầng DB vì ngoại lệ đó; việc chặn `amount <= 0`
  /// nằm ở tầng repository, nơi biết được loại giao dịch.
  IntColumn get amount => integer()();

  /// Ví nguồn. Với `transfer` đây là ví **chuyển đi**.
  ///
  /// `@ReferenceName` là bắt buộc ở đây: bảng này có **hai** khoá ngoại cùng
  /// trỏ vào `wallets`, nên drift không tự đặt tên quan hệ được và sẽ bỏ qua
  /// việc sinh filter cho cả hai nếu không nói rõ.
  @ReferenceName('outgoingTransactions')
  IntColumn get walletId => integer().references(Wallets, #id)();

  /// Ví đích. **Chỉ dùng khi `type == transfer`**, null với ba loại còn lại.
  @ReferenceName('incomingTransactions')
  IntColumn get toWalletId =>
      integer().nullable().references(Wallets, #id)();

  /// Null với `transfer` và `adjustment` — hai loại đó không thuộc danh mục nào.
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  /// **Ngày thuần, không có giờ**, chuẩn hoá về nửa đêm giờ địa phương
  /// (file 02 mục 8). Dùng `DateUtils.dateOnly()` trước khi lưu, nếu không
  /// hai giao dịch cùng ngày nhưng khác giờ sẽ rơi vào hai nhóm khác nhau.
  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().withDefault(const Constant(''))();

  /// Bản đã bỏ dấu và viết thường của [note], chỉ dùng để tìm kiếm.
  ///
  /// Thêm ở schemaVersion 2. Lý do phải lưu sẵn thay vì tính lúc truy vấn:
  /// SQLite không có hàm bỏ dấu Unicode, nên `LIKE` không bao giờ khớp được
  /// `'com trua'` với `'Cơm trưa'`.
  ///
  /// **Luôn ghi qua `normalizeForSearch()`** trong `core/utils/text_search.dart`.
  /// Ghi tay một chuỗi chuẩn hoá kiểu khác là cách chắc chắn để tìm không ra
  /// mà không hiểu vì sao.
  TextColumn get noteAscii => text().withDefault(const Constant(''))();

  /// Khác null nếu giao dịch được sinh tự động từ một khoản định kỳ.
  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
