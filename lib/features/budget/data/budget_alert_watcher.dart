import '../../../core/db/database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/date_range.dart';
import '../domain/budget_status.dart';

/// Theo dõi ngân sách và bắn cảnh báo khi vừa vượt ngưỡng.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục E.3.
///
/// Gọi **sau mỗi lần ghi hoặc sửa giao dịch chi**. Không dùng stream tự động
/// vì stream phát lại cả khi mở màn hình, và khi đó sẽ bắn thông báo cho một
/// ngưỡng đã vượt từ tuần trước.
///
/// Cách chống báo trùng: so trạng thái **trước và sau** giao dịch. Chỉ báo khi
/// mức cảnh báo thực sự nhảy lên — xem [crossedThreshold]. Nhìn mỗi trạng thái
/// hiện tại sẽ bắn thông báo lại sau từng khoản chi khi đã ở vùng trên 80%.
class BudgetAlertWatcher {
  BudgetAlertWatcher(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  /// Kiểm ngân sách của tháng chứa [date] và báo nếu vừa vượt ngưỡng.
  ///
  /// [spentDelta] là phần chi vừa được thêm vào, dùng để dựng lại trạng thái
  /// trước đó mà không phải chụp ảnh DB trước khi ghi.
  Future<void> checkAfterExpense({
    required DateTime date,
    required int categoryId,
    required int spentDelta,
  }) async {
    if (!NotificationService.isSupported) return;
    if (spentDelta <= 0) return;

    final range = calendarMonthOf(date);
    final list = await _db.budgetDao
        .watchForMonth(
          year: date.year,
          month: date.month,
          from: range.start,
          to: range.end,
        )
        .first;
    if (list.isEmpty) return;

    final homNay = dateOnly(DateTime.now());
    final conLai = homNay.isAfter(range.end)
        ? 0
        : homNay.isBefore(range.start)
            ? range.dayCount
            : range.end.difference(homNay).inDays + 1;

    for (final b in list) {
      // Chỉ xét ngân sách tổng và ngân sách của đúng danh mục vừa chi.
      final lienQuan =
          b.budget.categoryId == null || b.budget.categoryId == categoryId;
      if (!lienQuan) continue;

      final sau = BudgetStatus(
        limit: b.budget.amount,
        spent: b.spent,
        daysRemaining: conLai,
        daysTotal: range.dayCount,
      );
      final truoc = BudgetStatus(
        limit: b.budget.amount,
        spent: b.spent - spentDelta,
        daysRemaining: conLai,
        daysTotal: range.dayCount,
      );

      final nguong = crossedThreshold(truoc, sau);
      if (nguong == null) continue;

      await _notifications.showBudgetAlert(
        budgetId: b.budget.id,
        categoryName: b.categoryName ?? 'Toàn bộ chi tiêu',
        spent: sau.spent,
        limit: sau.limit,
        isOver: nguong == BudgetLevel.over,
      );
    }
  }
}
