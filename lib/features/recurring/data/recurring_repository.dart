import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/text_search.dart';
import '../domain/next_occurrence.dart';

/// Kết quả một lượt quét khoản định kỳ.
class RecurringScanResult {
  const RecurringScanResult({
    required this.postedCount,
    required this.pendingConfirmation,
  });

  /// Số giao dịch đã tự ghi (quy tắc bật `autoPost`).
  final int postedCount;

  /// Các kỳ đến hạn nhưng cần người dùng xác nhận (`autoPost = false`).
  final List<PendingOccurrence> pendingConfirmation;

  bool get isEmpty => postedCount == 0 && pendingConfirmation.isEmpty;
}

/// Một kỳ đến hạn đang chờ xác nhận.
class PendingOccurrence {
  const PendingOccurrence({required this.rule, required this.date});

  final RecurringRule rule;
  final DateTime date;
}

/// Tầng nghiệp vụ của khoản định kỳ. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục H.
class RecurringRepository {
  RecurringRepository(this._db);

  final AppDatabase _db;

  Stream<List<RecurringRule>> watchRules() =>
      (_db.select(_db.recurringRules)
            ..orderBy([
              (r) => OrderingTerm.desc(r.isActive),
              (r) => OrderingTerm.asc(r.nextRunDate),
            ]))
          .watch();

  /// Chuyển một dòng DB thành quy tắc lặp thuần để tính toán.
  static RecurrenceRule toDomain(RecurringRule row) => RecurrenceRule(
        frequency: row.frequency,
        startDate: row.startDate,
        interval: row.interval,
        byWeekday: row.byWeekday,
        byMonthDay: row.byMonthDay,
        endDate: row.endDate,
      );

  Future<int> createRule({
    required TransactionType type,
    required int amount,
    required int walletId,
    required int? categoryId,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    int interval = 1,
    int? byWeekday,
    int? byMonthDay,
    DateTime? endDate,
    bool autoPost = true,
    String note = '',
  }) async {
    final batDau = dateOnly(startDate);

    return _db.into(_db.recurringRules).insert(
          RecurringRulesCompanion.insert(
            type: type,
            amount: amount,
            walletId: walletId,
            categoryId: Value(categoryId),
            note: Value(note.trim()),
            frequency: frequency,
            interval: Value(interval),
            byWeekday: Value(byWeekday),
            byMonthDay: Value(byMonthDay),
            startDate: batDau,
            endDate: Value(endDate == null ? null : dateOnly(endDate)),
            // Kỳ đầu tiên chính là ngày bắt đầu.
            nextRunDate: batDau,
            autoPost: Value(autoPost),
          ),
        );
  }

  Future<void> updateRule(RecurringRule rule) async {
    await _db.update(_db.recurringRules).replace(rule);
  }

  Future<void> setActive(int id, {required bool active}) async {
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id)))
        .write(RecurringRulesCompanion(isActive: Value(active)));
  }

  Future<void> deleteRule(int id) async {
    await (_db.delete(_db.recurringRules)..where((r) => r.id.equals(id))).go();
  }

  /// Quét mọi quy tắc đến hạn và xử lý bù các kỳ đã lỡ.
  ///
  /// Đây là **lớp đảm bảo** trong đặc tả mục H.2 — luôn hoạt động, không phụ
  /// thuộc hệ điều hành có giết tiến trình nền hay không. Gọi mỗi lần mở app.
  ///
  /// Lớp thứ hai (`workmanager` chạy nền hằng ngày) chỉ để thông báo đến đúng
  /// hạn khi app đang đóng; nó **không** phải nơi duy nhất sinh giao dịch. Trên
  /// MIUI, tiến trình nền bị giết rất mạnh, nên thiết kế phải sống được khi
  /// lớp nền không bao giờ chạy.
  Future<RecurringScanResult> scanAndPost({DateTime? now}) async {
    final homNay = dateOnly(now ?? DateTime.now());

    final rules = await (_db.select(_db.recurringRules)
          ..where((r) => r.isActive.equals(true)))
        .get();

    var daGhi = 0;
    final choXacNhan = <PendingOccurrence>[];

    for (final row in rules) {
      final quyTac = toDomain(row);

      // Mốc để dò: kỳ đã ghi gần nhất, hoặc lùi một ngày trước ngày bắt đầu
      // để chính ngày bắt đầu cũng được tính là một kỳ.
      final moc = row.lastPostedDate ??
          row.startDate.subtract(const Duration(days: 1));

      final loSot = missedOccurrences(
        quyTac,
        lastPosted: moc,
        until: homNay,
      );
      if (loSot.isEmpty) continue;

      if (row.autoPost) {
        // Ghi hết trong một transaction: hoặc đủ, hoặc không dòng nào.
        await _db.transaction(() async {
          for (final ngay in loSot) {
            await _db.into(_db.transactions).insert(
                  TransactionsCompanion.insert(
                    type: row.type,
                    amount: row.amount,
                    walletId: row.walletId,
                    categoryId: Value(row.categoryId),
                    date: ngay,
                    note: Value(row.note),
                    noteAscii: Value(normalizeForSearch(row.note)),
                    recurringRuleId: Value(row.id),
                  ),
                );
          }
          await _capNhatMoc(row, quyTac, loSot.last, homNay);
        });
        daGhi += loSot.length;
      } else {
        // Chế độ nhắc xác nhận: không ghi gì, chỉ báo lên.
        for (final ngay in loSot) {
          choXacNhan.add(PendingOccurrence(rule: row, date: ngay));
        }
      }
    }

    return RecurringScanResult(
      postedCount: daGhi,
      pendingConfirmation: choXacNhan,
    );
  }

  /// Ghi một kỳ mà người dùng vừa xác nhận, cho phép sửa số tiền.
  ///
  /// Sửa được số tiền là điểm mấu chốt của chế độ nhắc xác nhận: tiền điện
  /// tháng nào cũng khác, ghi cứng một con số thì tính năng vô dụng.
  Future<void> confirmOccurrence(
    PendingOccurrence pending, {
    int? amountOverride,
  }) async {
    final row = pending.rule;
    final quyTac = toDomain(row);

    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              type: row.type,
              amount: amountOverride ?? row.amount,
              walletId: row.walletId,
              categoryId: Value(row.categoryId),
              date: pending.date,
              note: Value(row.note),
              noteAscii: Value(normalizeForSearch(row.note)),
              recurringRuleId: Value(row.id),
            ),
          );
      await _capNhatMoc(row, quyTac, pending.date, pending.date);
    });
  }

  /// Bỏ qua một kỳ: không ghi giao dịch, nhưng vẫn đẩy mốc lên để lần sau
  /// không hỏi lại.
  Future<void> skipOccurrence(PendingOccurrence pending) async {
    await _capNhatMoc(
      pending.rule,
      toDomain(pending.rule),
      pending.date,
      pending.date,
    );
  }

  /// Cập nhật `lastPostedDate` và `nextRunDate` sau khi xử lý xong tới [daXuLy].
  ///
  /// Quy tắc hết hạn (`nextOccurrence` trả null) thì tự tắt — để nó ở trạng
  /// thái bật với `nextRunDate` cũ sẽ khiến mỗi lần quét lại dò lại vô ích.
  Future<void> _capNhatMoc(
    RecurringRule row,
    RecurrenceRule quyTac,
    DateTime daXuLy,
    DateTime homNay,
  ) async {
    final ke = nextOccurrence(quyTac, after: daXuLy);

    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(row.id)))
        .write(
      RecurringRulesCompanion(
        lastPostedDate: Value(daXuLy),
        nextRunDate: Value(ke ?? daXuLy),
        isActive: Value(ke != null),
      ),
    );
  }
}
