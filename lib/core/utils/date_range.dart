/// Tính kỳ tài chính và các khoảng ngày dùng chung.
/// Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 8, `01_DAC_TA_TINH_NANG.md` mục J.
///
/// **Kỳ tài chính không nhất thiết trùng tháng dương lịch.** Người lĩnh lương
/// ngày 25 có thể đặt `monthStartDay = 25`; khi đó "tháng 8" của họ chạy từ
/// 25/07 đến 24/08. Mọi báo cáo, ngân sách và lịch phải dùng cùng một định
/// nghĩa kỳ, nếu không các con số sẽ mâu thuẫn nhau giữa các màn hình.
///
/// Toàn bộ file là hàm thuần trên `DateTime` — test được không cần Flutter.
library;

/// Một khoảng ngày đóng ở cả hai đầu: `[start, end]`.
///
/// Đóng hai đầu chứ không nửa mở, vì cột `date` trong DB là **ngày thuần**
/// (không có giờ) và truy vấn dùng `BETWEEN` — vốn cũng đóng hai đầu. Trộn hai
/// quy ước là cách chắc chắn nhất để mất hoặc đếm trùng giao dịch ngày cuối kỳ.
class DateRange {
  const DateRange(this.start, this.end);

  /// Ngày đầu kỳ, nửa đêm giờ địa phương.
  final DateTime start;

  /// Ngày cuối kỳ, nửa đêm giờ địa phương. **Nằm trong kỳ.**
  final DateTime end;

  /// Số ngày trong kỳ, tính cả hai đầu.
  int get dayCount => end.difference(start).inDays + 1;

  bool contains(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  String toString() => 'DateRange($start → $end)';

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Cắt bỏ phần giờ, giữ lại ngày thuần ở giờ địa phương.
///
/// Tự viết thay vì dùng `DateUtils.dateOnly` của Flutter để file này không phụ
/// thuộc Flutter — nhờ vậy test chạy được bằng `dart test` thuần.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Số ngày của một tháng. Xử lý đúng năm nhuận.
///
/// Mẹo: `DateTime(year, month + 1, 0)` là "ngày 0 của tháng sau", mà Dart hiểu
/// là ngày cuối cùng của tháng này. Cũng đúng khi `month == 12` — nó tự nhảy
/// sang tháng 1 năm sau.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Kẹp một ngày trong tháng về ngày cuối tháng nếu tháng đó không có ngày ấy.
///
/// Ví dụ ngày 31 trong tháng 2 năm thường → 28, năm nhuận → 29. Đây là hàm
/// dùng chung cho cả kỳ tài chính lẫn khoản định kỳ hằng tháng ở Phase 7.
DateTime clampDayOfMonth(int year, int month, int day) {
  // Chuẩn hoá tháng ngoài khoảng 1–12 (ví dụ tháng 13 = tháng 1 năm sau).
  final normalized = DateTime(year, month, 1);
  final last = daysInMonth(normalized.year, normalized.month);
  return DateTime(normalized.year, normalized.month, day < last ? day : last);
}

/// Kỳ tài chính chứa [day], theo `monthStartDay` trong cài đặt.
///
/// - `monthStartDay = 1` → trùng tháng dương lịch.
/// - `monthStartDay = 25` → kỳ chạy từ ngày 25 tháng trước tới ngày 24 tháng này.
///
/// [monthStartDay] được kẹp về 1–28. Giới hạn 28 là cố ý: mọi tháng đều có
/// ngày 28, nên kỳ không bao giờ bị nhảy cóc hay chồng lấn. Cho phép 29–31 sẽ
/// tạo ra các kỳ dài ngắn thất thường và người dùng không đoán được.
DateRange financialPeriodOf(DateTime day, {int monthStartDay = 1}) {
  final startDay = monthStartDay.clamp(1, 28);
  final d = dateOnly(day);

  // Ngày trong tháng còn nhỏ hơn mốc bắt đầu → vẫn thuộc kỳ mở từ tháng trước.
  final start = d.day >= startDay
      ? DateTime(d.year, d.month, startDay)
      : DateTime(d.year, d.month - 1, startDay);

  // Kết thúc là hôm trước mốc bắt đầu của kỳ kế tiếp.
  final nextStart = DateTime(start.year, start.month + 1, startDay);
  return DateRange(start, nextStart.subtract(const Duration(days: 1)));
}

/// Kỳ tài chính liền trước [range]. Dùng cho so sánh "kỳ này vs kỳ trước".
DateRange previousPeriod(DateRange range, {int monthStartDay = 1}) =>
    financialPeriodOf(
      range.start.subtract(const Duration(days: 1)),
      monthStartDay: monthStartDay,
    );

/// Kỳ tài chính liền sau [range].
DateRange nextPeriod(DateRange range, {int monthStartDay = 1}) =>
    financialPeriodOf(
      range.end.add(const Duration(days: 1)),
      monthStartDay: monthStartDay,
    );

/// Trọn một tháng dương lịch. Dùng cho lưới lịch — lịch luôn vẽ theo tháng
/// dương lịch dù kỳ tài chính bắt đầu ngày nào, vì người ta đọc lịch theo
/// tháng thật.
DateRange calendarMonthOf(DateTime day) {
  final start = DateTime(day.year, day.month, 1);
  return DateRange(start, DateTime(day.year, day.month, daysInMonth(day.year, day.month)));
}

/// Trọn một năm dương lịch.
DateRange calendarYearOf(DateTime day) =>
    DateRange(DateTime(day.year, 1, 1), DateTime(day.year, 12, 31));

/// Lưới ngày để vẽ lịch tháng: luôn đủ tuần trọn vẹn, kể cả ngày của tháng
/// trước và tháng sau lấp vào hai đầu.
///
/// [weekStartDay] theo quy ước `DateTime`: 1 = Thứ 2 … 7 = Chủ nhật. Mặc định
/// Thứ 2 như lịch Việt Nam.
///
/// Trả về đúng bội số của 7 ngày, để `GridView` 7 cột không bao giờ có ô thừa.
List<DateTime> calendarGridDays(DateTime month, {int weekStartDay = 1}) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month, daysInMonth(month.year, month.month));

  // Số ngày phải lùi lại để chạm đúng đầu tuần.
  final leading = (first.weekday - weekStartDay + 7) % 7;
  final gridStart = first.subtract(Duration(days: leading));

  // Số ngày phải kéo thêm để lấp nốt tuần cuối.
  final trailing = (weekStartDay + 6 - last.weekday + 7) % 7;
  final total = last.difference(gridStart).inDays + 1 + trailing;

  return [
    for (var i = 0; i < total; i++) gridStart.add(Duration(days: i)),
  ];
}
