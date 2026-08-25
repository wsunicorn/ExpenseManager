import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/recurring/domain/next_occurrence.dart';

/// Test bắt buộc số 1 trong `CONVENTIONS.md`: `nextOccurrence()`, kể cả ngày
/// 29/30/31 và năm nhuận.
///
/// `04_LO_TRINH.md` Phase 7 nói viết test này **trước khi** dựng màn hình.
/// Bug ở đây không làm app sập — nó chỉ âm thầm sinh giao dịch sai ngày, và
/// chỉ lộ ra sau vài tháng khi số liệu đã hỏng.
void main() {
  RecurrenceRule rule({
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    int interval = 1,
    int? byWeekday,
    int? byMonthDay,
    DateTime? endDate,
  }) =>
      RecurrenceRule(
        frequency: frequency,
        startDate: startDate,
        interval: interval,
        byWeekday: byWeekday,
        byMonthDay: byMonthDay,
        endDate: endDate,
      );

  group('hằng ngày', () {
    test('kỳ kế tiếp là hôm sau', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 8, 1),
      );
      expect(
        nextOccurrence(r, after: DateTime(2026, 8, 10)),
        DateTime(2026, 8, 11),
      );
    });

    test('mỗi 3 ngày bám đúng mốc bắt đầu', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 8, 1),
        interval: 3,
      );
      // Các kỳ: 1, 4, 7, 10, 13…
      expect(nextOccurrence(r, after: DateTime(2026, 8, 1)), DateTime(2026, 8, 4));
      expect(nextOccurrence(r, after: DateTime(2026, 8, 5)), DateTime(2026, 8, 7));
      expect(nextOccurrence(r, after: DateTime(2026, 8, 7)), DateTime(2026, 8, 10));
    });

    test('chưa tới ngày bắt đầu thì kỳ đầu là chính ngày bắt đầu', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 9, 1),
      );
      expect(
        nextOccurrence(r, after: DateTime(2026, 8, 20)),
        DateTime(2026, 9, 1),
      );
    });

    test('vượt ngày kết thúc thì trả null', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
      );
      expect(nextOccurrence(r, after: DateTime(2026, 8, 4)), DateTime(2026, 8, 5));
      expect(nextOccurrence(r, after: DateTime(2026, 8, 5)), isNull);
    });
  });

  group('hằng tuần', () {
    test('rơi đúng thứ đã chọn', () {
      // 01/08/2026 là Thứ 7. Chọn Thứ 2 → kỳ đầu là Thứ 2 gần nhất **từ ngày
      // bắt đầu trở đi**, tức 03/08, chứ không phải nhảy hẳn sang tuần sau.
      final r = rule(
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 8, 1),
        byWeekday: DateTime.monday,
      );
      final tiep = nextOccurrence(r, after: DateTime(2026, 8, 1))!;
      expect(tiep.weekday, DateTime.monday);
      expect(tiep, DateTime(2026, 8, 3));

      // Và kỳ sau đó cách đúng một tuần.
      expect(nextOccurrence(r, after: tiep), DateTime(2026, 8, 10));
    });

    test('không chọn thứ thì lấy thứ của ngày bắt đầu', () {
      final r = rule(
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 8, 5),
      );
      final tiep = nextOccurrence(r, after: DateTime(2026, 8, 5))!;
      expect(tiep, DateTime(2026, 8, 12));
      expect(tiep.weekday, DateTime(2026, 8, 5).weekday);
    });

    test('mỗi 2 tuần', () {
      final r = rule(
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 8, 3),
        interval: 2,
      );
      expect(nextOccurrence(r, after: DateTime(2026, 8, 3)), DateTime(2026, 8, 17));
      expect(nextOccurrence(r, after: DateTime(2026, 8, 17)), DateTime(2026, 8, 31));
    });
  });

  group('hằng tháng — ngày thường', () {
    test('cùng ngày tháng sau', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 15),
      );
      expect(
        nextOccurrence(r, after: DateTime(2026, 8, 15)),
        DateTime(2026, 9, 15),
      );
    });

    test('vắt qua giao thừa', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 12, 10),
      );
      expect(
        nextOccurrence(r, after: DateTime(2026, 12, 10)),
        DateTime(2027, 1, 10),
      );
    });

    test('mỗi quý', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 5),
        interval: 3,
      );
      expect(nextOccurrence(r, after: DateTime(2026, 1, 5)), DateTime(2026, 4, 5));
      expect(nextOccurrence(r, after: DateTime(2026, 4, 5)), DateTime(2026, 7, 5));
    });
  });

  group('hằng tháng — ngày 29, 30, 31', () {
    /// Bẫy số 1: tháng ngắn không có ngày đó.
    test('ngày 31 lùi về ngày cuối tháng ngắn', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 31),
      );
      expect(nextOccurrence(r, after: DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(nextOccurrence(r, after: DateTime(2026, 3, 15)), DateTime(2026, 3, 31));
      expect(nextOccurrence(r, after: DateTime(2026, 3, 31)), DateTime(2026, 4, 30));
    });

    /// Bẫy số 2, cái khó nhất: sau khi bị kẹp về 28, tháng sau phải quay lại
    /// đúng ngày 31 chứ không kẹt ở 28 mãi mãi.
    test('không bị trôi ngày sau khi bị kẹp', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 31),
      );

      var moc = DateTime(2026, 1, 31);
      final chuoi = <DateTime>[];
      for (var i = 0; i < 12; i++) {
        moc = nextOccurrence(r, after: moc)!;
        chuoi.add(moc);
      }

      expect(chuoi, [
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 31),
        DateTime(2026, 6, 30),
        DateTime(2026, 7, 31),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 31),
      ]);
    });

    test('ngày 30 cũng không trôi', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 30),
      );
      expect(nextOccurrence(r, after: DateTime(2026, 1, 30)), DateTime(2026, 2, 28));
      expect(nextOccurrence(r, after: DateTime(2026, 2, 28)), DateTime(2026, 3, 30));
    });

    test('ngày 29 ở năm nhuận thì rơi đúng 29/2', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 29),
      );
      expect(nextOccurrence(r, after: DateTime(2024, 1, 29)), DateTime(2024, 2, 29));
    });

    test('ngày 29 ở năm thường lùi về 28/2', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 29),
      );
      expect(nextOccurrence(r, after: DateTime(2026, 1, 29)), DateTime(2026, 2, 28));
    });

    test('byMonthDay ghi đè ngày của startDate', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 3),
        byMonthDay: 25,
      );
      expect(nextOccurrence(r, after: DateTime(2026, 8, 3)), DateTime(2026, 8, 25));
      expect(nextOccurrence(r, after: DateTime(2026, 8, 25)), DateTime(2026, 9, 25));
    });
  });

  group('hằng năm', () {
    test('cùng ngày năm sau', () {
      final r = rule(
        frequency: RecurrenceFrequency.yearly,
        startDate: DateTime(2026, 3, 15),
      );
      expect(
        nextOccurrence(r, after: DateTime(2026, 3, 15)),
        DateTime(2027, 3, 15),
      );
    });

    /// 29/2 chỉ tồn tại 4 năm một lần.
    test('sinh nhật 29/2 lùi về 28/2 ở năm thường', () {
      final r = rule(
        frequency: RecurrenceFrequency.yearly,
        startDate: DateTime(2024, 2, 29),
      );
      expect(nextOccurrence(r, after: DateTime(2024, 2, 29)), DateTime(2025, 2, 28));
      expect(nextOccurrence(r, after: DateTime(2027, 3, 1)), DateTime(2028, 2, 29));
    });
  });

  group('bù kỳ đã lỡ', () {
    /// Đặc tả mục H.2: app không mở ba tháng thì lúc mở lại phải sinh đủ ba
    /// giao dịch, không phải một.
    test('sinh đủ mọi kỳ đã lỡ', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 5, 10),
      );

      final loSot = missedOccurrences(
        r,
        lastPosted: DateTime(2026, 5, 10),
        until: DateTime(2026, 8, 24),
      );

      expect(loSot, [
        DateTime(2026, 6, 10),
        DateTime(2026, 7, 10),
        DateTime(2026, 8, 10),
      ]);
    });

    test('không có kỳ nào lỡ thì trả danh sách rỗng', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 10),
      );
      expect(
        missedOccurrences(
          r,
          lastPosted: DateTime(2026, 8, 10),
          until: DateTime(2026, 8, 24),
        ),
        isEmpty,
      );
    });

    test('dừng ở ngày kết thúc của quy tắc', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 7, 1),
      );
      final loSot = missedOccurrences(
        r,
        lastPosted: DateTime(2026, 5, 10),
        until: DateTime(2026, 8, 24),
      );
      expect(loSot, [DateTime(2026, 6, 10)]);
    });

    /// Quy tắc hằng ngày bắt đầu từ 5 năm trước sẽ sinh gần 2000 giao dịch một
    /// lúc — chặn ở đây an toàn hơn là để app treo.
    test('chặn số kỳ bù tối đa', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2020, 1, 1),
      );
      final loSot = missedOccurrences(
        r,
        lastPosted: DateTime(2020, 1, 1),
        until: DateTime(2026, 8, 24),
        maxCatchUp: 60,
      );
      expect(loSot, hasLength(60));
    });
  });
}
