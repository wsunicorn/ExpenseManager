import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/utils/date_range.dart';

/// Test bắt buộc số 4 trong `CONVENTIONS.md`: tính kỳ tài chính khi
/// `month_start_day != 1`.
///
/// Sai ở đây thì báo cáo, ngân sách và lịch sẽ nói ba con số khác nhau cho
/// cùng một tháng — kiểu bug làm người dùng mất niềm tin vào toàn bộ app mà
/// không chỉ ra được chỗ nào sai.
void main() {
  group('daysInMonth', () {
    test('đúng cho tháng 30, 31 ngày', () {
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
      expect(daysInMonth(2026, 12), 31);
    });

    test('tháng 2 năm thường 28 ngày, năm nhuận 29 ngày', () {
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2024, 2), 29);
      // 2000 chia hết 400 → nhuận. 1900 chia hết 100 nhưng không 400 → không nhuận.
      expect(daysInMonth(2000, 2), 29);
      expect(daysInMonth(1900, 2), 28);
    });
  });

  group('clampDayOfMonth', () {
    test('giữ nguyên ngày hợp lệ', () {
      expect(clampDayOfMonth(2026, 8, 15), DateTime(2026, 8, 15));
    });

    test('ngày 31 lùi về ngày cuối tháng ngắn', () {
      expect(clampDayOfMonth(2026, 2, 31), DateTime(2026, 2, 28));
      expect(clampDayOfMonth(2024, 2, 31), DateTime(2024, 2, 29));
      expect(clampDayOfMonth(2026, 4, 31), DateTime(2026, 4, 30));
    });

    test('ngày 29 chỉ tồn tại trong tháng 2 năm nhuận', () {
      expect(clampDayOfMonth(2024, 2, 29), DateTime(2024, 2, 29));
      expect(clampDayOfMonth(2026, 2, 29), DateTime(2026, 2, 28));
    });

    test('chuẩn hoá tháng ngoài khoảng 1–12', () {
      expect(clampDayOfMonth(2026, 13, 5), DateTime(2027, 1, 5));
      expect(clampDayOfMonth(2026, 0, 5), DateTime(2025, 12, 5));
    });
  });

  group('kỳ tài chính bắt đầu ngày 1 — trùng tháng dương lịch', () {
    test('bao trọn tháng', () {
      final p = financialPeriodOf(DateTime(2026, 8, 15));
      expect(p.start, DateTime(2026, 8, 1));
      expect(p.end, DateTime(2026, 8, 31));
      expect(p.dayCount, 31);
    });

    test('tháng 2 năm nhuận', () {
      final p = financialPeriodOf(DateTime(2024, 2, 10));
      expect(p.start, DateTime(2024, 2, 1));
      expect(p.end, DateTime(2024, 2, 29));
      expect(p.dayCount, 29);
    });

    test('ngày đầu và ngày cuối tháng đều thuộc đúng kỳ đó', () {
      expect(financialPeriodOf(DateTime(2026, 8, 1)).start, DateTime(2026, 8, 1));
      expect(financialPeriodOf(DateTime(2026, 8, 31)).end, DateTime(2026, 8, 31));
    });
  });

  group('kỳ tài chính bắt đầu ngày 25 — người lĩnh lương ngày 25', () {
    test('ngày 25 mở kỳ mới', () {
      final p = financialPeriodOf(DateTime(2026, 8, 25), monthStartDay: 25);
      expect(p.start, DateTime(2026, 8, 25));
      expect(p.end, DateTime(2026, 9, 24));
    });

    test('ngày trước mốc vẫn thuộc kỳ mở từ tháng trước', () {
      final p = financialPeriodOf(DateTime(2026, 8, 24), monthStartDay: 25);
      expect(p.start, DateTime(2026, 7, 25));
      expect(p.end, DateTime(2026, 8, 24));
    });

    test('kỳ vắt qua giao thừa', () {
      final p = financialPeriodOf(DateTime(2027, 1, 3), monthStartDay: 25);
      expect(p.start, DateTime(2026, 12, 25));
      expect(p.end, DateTime(2027, 1, 24));
    });

    test('kỳ vắt qua tháng 2 vẫn liền mạch', () {
      final p = financialPeriodOf(DateTime(2026, 2, 10), monthStartDay: 25);
      expect(p.start, DateTime(2026, 1, 25));
      expect(p.end, DateTime(2026, 2, 24));
    });
  });

  group('kỳ tài chính không được hở hay chồng lấn', () {
    /// Đây là bất biến quan trọng nhất: mọi ngày trong năm phải thuộc **đúng
    /// một** kỳ. Hở một ngày là giao dịch biến mất khỏi mọi báo cáo; chồng lấn
    /// là nó bị đếm hai lần.
    test('mọi ngày trong 3 năm thuộc đúng một kỳ, với mọi mốc 1–28', () {
      for (final startDay in [1, 5, 15, 25, 28]) {
        var day = DateTime(2024, 1, 1);
        final cuoi = DateTime(2026, 12, 31);

        while (!day.isAfter(cuoi)) {
          final p = financialPeriodOf(day, monthStartDay: startDay);
          expect(
            p.contains(day),
            isTrue,
            reason: 'ngày $day không nằm trong kỳ $p (mốc $startDay)',
          );
          day = day.add(const Duration(days: 1));
        }
      }
    });

    test('kỳ kế tiếp bắt đầu đúng hôm sau ngày cuối kỳ trước', () {
      for (final startDay in [1, 15, 25, 28]) {
        var p = financialPeriodOf(DateTime(2026, 1, 10), monthStartDay: startDay);
        for (var i = 0; i < 24; i++) {
          final sau = nextPeriod(p, monthStartDay: startDay);
          expect(
            sau.start,
            p.end.add(const Duration(days: 1)),
            reason: 'hở hoặc chồng giữa $p và $sau (mốc $startDay)',
          );
          p = sau;
        }
      }
    });

    test('previousPeriod là nghịch đảo của nextPeriod', () {
      for (final startDay in [1, 25]) {
        final p = financialPeriodOf(DateTime(2026, 8, 15), monthStartDay: startDay);
        final sau = nextPeriod(p, monthStartDay: startDay);
        expect(previousPeriod(sau, monthStartDay: startDay), p);
      }
    });
  });

  group('mốc bắt đầu bị kẹp về 1–28', () {
    /// Cho phép 29–31 sẽ tạo ra kỳ dài ngắn thất thường vì tháng 2 không có
    /// những ngày đó. Kẹp về 28 để mọi tháng đều tồn tại mốc.
    test('giá trị ngoài khoảng được kẹp lại', () {
      final p31 = financialPeriodOf(DateTime(2026, 8, 15), monthStartDay: 31);
      expect(p31.start.day, 28);

      final p0 = financialPeriodOf(DateTime(2026, 8, 15), monthStartDay: 0);
      expect(p0.start.day, 1);
    });
  });

  group('lưới lịch tháng', () {
    test('luôn là bội số của 7 ngày', () {
      for (var m = 1; m <= 12; m++) {
        final days = calendarGridDays(DateTime(2026, m, 1));
        expect(days.length % 7, 0, reason: 'tháng $m ra ${days.length} ô');
      }
    });

    test('bắt đầu đúng Thứ 2 và kết thúc đúng Chủ nhật', () {
      final days = calendarGridDays(DateTime(2026, 8, 1));
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
    });

    test('chứa trọn mọi ngày của tháng', () {
      final days = calendarGridDays(DateTime(2026, 8, 1));
      for (var d = 1; d <= 31; d++) {
        expect(days, contains(DateTime(2026, 8, d)));
      }
    });

    test('đổi được ngày bắt đầu tuần sang Chủ nhật', () {
      final days = calendarGridDays(DateTime(2026, 8, 1), weekStartDay: 7);
      expect(days.first.weekday, DateTime.sunday);
      expect(days.last.weekday, DateTime.saturday);
      expect(days.length % 7, 0);
    });

    test('tháng bắt đầu đúng Thứ 2 không sinh tuần trống ở đầu', () {
      // 01/06/2026 là Thứ 2.
      expect(DateTime(2026, 6, 1).weekday, DateTime.monday);
      final days = calendarGridDays(DateTime(2026, 6, 1));
      expect(days.first, DateTime(2026, 6, 1));
    });
  });

  group('khoảng dương lịch', () {
    test('trọn tháng', () {
      final r = calendarMonthOf(DateTime(2026, 2, 14));
      expect(r.start, DateTime(2026, 2, 1));
      expect(r.end, DateTime(2026, 2, 28));
    });

    test('trọn năm', () {
      final r = calendarYearOf(DateTime(2026, 7, 4));
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2026, 12, 31));
    });
  });

  group('DateRange', () {
    test('contains bỏ qua phần giờ', () {
      final r = DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 31));
      expect(r.contains(DateTime(2026, 8, 15, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 8, 31, 18, 0)), isTrue, reason: 'đóng hai đầu');
      expect(r.contains(DateTime(2026, 9, 1)), isFalse);
    });

    test('dayCount tính cả hai đầu', () {
      expect(DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 1)).dayCount, 1);
      expect(DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 31)).dayCount, 31);
    });
  });
}
