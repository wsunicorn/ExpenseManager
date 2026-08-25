/// Sinh kỳ tiếp theo cho khoản định kỳ.
/// Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.5.
///
/// `04_LO_TRINH.md` Phase 7 gọi đây là **"chỗ dễ sai nhất trong toàn app"** và
/// yêu cầu viết unit test **trước khi** dựng màn hình. Lý do: bug ở đây không
/// làm app sập, nó chỉ âm thầm sinh giao dịch sai ngày — hoặc bỏ sót, hoặc
/// nhân đôi — và bạn chỉ phát hiện sau vài tháng khi số liệu đã hỏng.
///
/// Ba cái bẫy cụ thể:
/// 1. **Ngày 31 trong tháng chỉ có 30 ngày**, và ngày 29/2 ở năm không nhuận.
/// 2. **Không được trôi ngày**: quy tắc "ngày 31 hằng tháng" gặp tháng 2 phải
///    lùi về 28, nhưng tháng 3 kế tiếp phải quay lại đúng ngày 31 — chứ không
///    phải kẹt ở 28 mãi mãi.
/// 3. **Bù kỳ đã lỡ**: app không mở trong ba tháng thì lúc mở lại phải sinh đủ
///    ba giao dịch, không phải một.
library;

import '../../../core/db/enums.dart';
import '../../../core/utils/date_range.dart';

/// Quy tắc lặp, tách khỏi bảng DB để test được mà không cần drift.
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    required this.startDate,
    this.interval = 1,
    this.byWeekday,
    this.byMonthDay,
    this.endDate,
  });

  final RecurrenceFrequency frequency;

  /// Ngày bắt đầu — cũng là kỳ đầu tiên.
  final DateTime startDate;

  /// Lặp mỗi N kỳ. `monthly` + `interval: 3` là mỗi quý.
  final int interval;

  /// 1–7 (Thứ 2 → Chủ nhật). Chỉ dùng với `weekly`; bỏ trống thì lấy thứ của
  /// [startDate].
  final int? byWeekday;

  /// 1–31. Chỉ dùng với `monthly`; bỏ trống thì lấy ngày của [startDate].
  ///
  /// **Giữ nguyên số gốc kể cả khi tháng hiện tại không có ngày đó** — đây
  /// chính là chìa khoá để không bị trôi ngày.
  final int? byMonthDay;

  /// Null nghĩa là lặp mãi.
  final DateTime? endDate;

  /// Ngày trong tháng mà quy tắc nhắm tới.
  int get targetMonthDay => byMonthDay ?? startDate.day;

  /// Thứ trong tuần mà quy tắc nhắm tới.
  int get targetWeekday => byWeekday ?? startDate.weekday;
}

/// Kỳ kế tiếp **sau** [after], theo [rule].
///
/// Trả `null` khi quy tắc đã kết thúc (vượt `endDate`).
///
/// Luôn tính từ [rule.startDate] cộng dần theo bội của `interval`, **không**
/// tính từ ngày hiện tại. Nhờ vậy quy tắc "ngày 31 hằng tháng" gặp tháng 2 lùi
/// về 28 nhưng tháng 3 vẫn quay lại đúng ngày 31.
DateTime? nextOccurrence(RecurrenceRule rule, {required DateTime after}) {
  final moc = dateOnly(after);
  final batDau = dateOnly(rule.startDate);

  // Chưa tới ngày bắt đầu thì kỳ đầu tiên chính là ngày bắt đầu.
  if (moc.isBefore(batDau)) {
    return _capIfWithinEnd(batDau, rule);
  }

  final ketQua = switch (rule.frequency) {
    RecurrenceFrequency.daily => _nextDaily(rule, batDau, moc),
    RecurrenceFrequency.weekly => _nextWeekly(rule, batDau, moc),
    RecurrenceFrequency.monthly => _nextMonthly(rule, batDau, moc),
    RecurrenceFrequency.yearly => _nextYearly(rule, batDau, moc),
  };

  return _capIfWithinEnd(ketQua, rule);
}

DateTime? _capIfWithinEnd(DateTime? day, RecurrenceRule rule) {
  if (day == null) return null;
  final ket = rule.endDate;
  if (ket != null && day.isAfter(dateOnly(ket))) return null;
  return day;
}

DateTime _nextDaily(RecurrenceRule rule, DateTime batDau, DateTime moc) {
  final soNgay = moc.difference(batDau).inDays;
  // Số kỳ đã qua, làm tròn xuống, rồi nhảy sang kỳ kế tiếp.
  final kyTiepTheo = (soNgay ~/ rule.interval) + 1;
  return batDau.add(Duration(days: kyTiepTheo * rule.interval));
}

DateTime _nextWeekly(RecurrenceRule rule, DateTime batDau, DateTime moc) {
  // Mốc tuần đầu tiên: ngày đúng thứ mong muốn, tính từ tuần của startDate.
  final lech = (rule.targetWeekday - batDau.weekday + 7) % 7;
  final kyDau = batDau.add(Duration(days: lech));

  if (moc.isBefore(kyDau)) return kyDau;

  final soTuan = moc.difference(kyDau).inDays ~/ 7;
  final kyTiepTheo = (soTuan ~/ rule.interval) + 1;
  return kyDau.add(Duration(days: kyTiepTheo * rule.interval * 7));
}

DateTime _nextMonthly(RecurrenceRule rule, DateTime batDau, DateTime moc) {
  final ngayGoc = rule.targetMonthDay;

  // Số tháng đã trôi qua kể từ tháng bắt đầu.
  var soThang = (moc.year - batDau.year) * 12 + (moc.month - batDau.month);
  // Quy về bội của interval, làm tròn xuống.
  soThang = (soThang ~/ rule.interval) * rule.interval;

  // Thử kỳ của chính tháng đó trước — có thể nó còn nằm sau mốc.
  var ungVien = clampDayOfMonth(batDau.year, batDau.month + soThang, ngayGoc);

  // Chưa qua mốc thì nhảy thêm một chu kỳ, lặp cho tới khi vượt.
  //
  // Vòng lặp chứ không phải một phép cộng: khi ngày gốc bị kẹp lại (31 → 28),
  // kỳ kế tiếp có thể rơi vào cùng một ngày, và cộng một lần là chưa đủ.
  while (!ungVien.isAfter(moc)) {
    soThang += rule.interval;
    ungVien = clampDayOfMonth(batDau.year, batDau.month + soThang, ngayGoc);
  }
  return ungVien;
}

DateTime _nextYearly(RecurrenceRule rule, DateTime batDau, DateTime moc) {
  var soNam = moc.year - batDau.year;
  soNam = (soNam ~/ rule.interval) * rule.interval;

  var ungVien = clampDayOfMonth(
    batDau.year + soNam,
    batDau.month,
    batDau.day,
  );

  while (!ungVien.isAfter(moc)) {
    soNam += rule.interval;
    ungVien = clampDayOfMonth(batDau.year + soNam, batDau.month, batDau.day);
  }
  return ungVien;
}

/// Mọi kỳ đã đến hạn mà chưa được ghi, từ [lastPosted] tới [until].
///
/// Dùng khi mở app: quét quy tắc có `nextRunDate <= hôm nay` và **xử lý bù cả
/// những ngày đã lỡ** (đặc tả mục H.2). App không mở trong ba tháng thì lúc mở
/// lại phải sinh đủ ba giao dịch — MoneyNote không có tính năng này nên vấn đề
/// không tồn tại, còn ở đây bỏ sót là mất tiền trong sổ.
///
/// [maxCatchUp] chặn trường hợp bệnh lý: quy tắc hằng ngày bắt đầu từ 5 năm
/// trước sẽ sinh gần 2000 giao dịch một lúc. Chặn ở đây an toàn hơn là để nó
/// treo app.
List<DateTime> missedOccurrences(
  RecurrenceRule rule, {
  required DateTime lastPosted,
  required DateTime until,
  int maxCatchUp = 60,
}) {
  final ketQua = <DateTime>[];
  final den = dateOnly(until);
  var moc = dateOnly(lastPosted);

  while (ketQua.length < maxCatchUp) {
    final tiep = nextOccurrence(rule, after: moc);
    if (tiep == null || tiep.isAfter(den)) break;
    ketQua.add(tiep);
    moc = tiep;
  }
  return ketQua;
}
