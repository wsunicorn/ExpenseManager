import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/features/budget/domain/budget_status.dart';

/// Trạng thái ngân sách — `01_DAC_TA_TINH_NANG.md` mục E.
void main() {
  BudgetStatus st({
    int limit = 3000000,
    int spent = 0,
    int daysRemaining = 12,
    int daysTotal = 31,
  }) =>
      BudgetStatus(
        limit: limit,
        spent: spent,
        daysRemaining: daysRemaining,
        daysTotal: daysTotal,
      );

  group('ba ngưỡng màu', () {
    test('dưới 80% là an toàn', () {
      expect(st(spent: 1850000).level, BudgetLevel.safe);
      expect(st(spent: 2399999).level, BudgetLevel.safe);
    });

    test('từ 80% đến 100% là cảnh báo', () {
      expect(st(spent: 2400000).level, BudgetLevel.warning);
      expect(st(spent: 3000000).level, BudgetLevel.warning);
    });

    test('trên 100% là vượt', () {
      expect(st(spent: 3000001).level, BudgetLevel.over);
      expect(st(spent: 5000000).level, BudgetLevel.over);
    });
  });

  group('phần trăm và thanh tiến độ', () {
    test('tính đúng phần trăm', () {
      expect(st(spent: 1500000).percent, 50);
      expect(st(spent: 1850000).percent, 62);
    });

    /// Thanh tiến độ không vẽ quá 100% được, nhưng con số thật phải giữ nguyên.
    test('thanh kẹp ở 100% nhưng phần trăm vẫn báo thật', () {
      final s = st(spent: 4500000);
      expect(s.barValue, 1.0);
      expect(s.percent, 150);
    });

    /// Hạn mức 0 mà chia thẳng là crash.
    test('hạn mức 0 không chia cho 0', () {
      expect(st(limit: 0, spent: 0).ratio, 0.0);
      expect(st(limit: 0, spent: 100000).ratio, 1.0);
      expect(st(limit: 0, spent: 100000).level, BudgetLevel.warning);
    });
  });

  group('còn lại và mức chi mỗi ngày', () {
    test('tính đúng số còn lại', () {
      expect(st(spent: 1850000).remaining, 1150000);
    });

    test('chia đều phần còn lại cho số ngày còn lại', () {
      // 1.150.000 / 12 ngày
      expect(st(spent: 1850000).dailyAllowance, 95833);
    });

    /// Hiển thị "còn tiêu được −50.000 đ/ngày" là vô nghĩa.
    test('đã vượt hạn mức thì không đưa ra mức chi mỗi ngày', () {
      expect(st(spent: 4000000).dailyAllowance, isNull);
    });

    test('hết ngày trong kỳ thì cũng không đưa ra mức chi', () {
      expect(st(spent: 1000000, daysRemaining: 0).dailyAllowance, isNull);
    });
  });

  group('cảnh báo sớm theo nhịp chi', () {
    /// Đến khi chạm 100% thì tiền đã tiêu mất rồi — cảnh báo sớm mới có ích.
    test('nhận ra nhịp chi đang dẫn tới vượt hạn mức', () {
      // Qua 15/30 ngày đã tiêu 2 triệu trên hạn mức 3 triệu → dự báo 4 triệu.
      final s = st(spent: 2000000, daysRemaining: 15, daysTotal: 30);
      expect(s.isOnTrackToOverspend, isTrue);
      expect(s.projectedSpend, 4000000);
    });

    test('nhịp chi vừa phải thì không cảnh báo', () {
      final s = st(spent: 1000000, daysRemaining: 15, daysTotal: 30);
      expect(s.isOnTrackToOverspend, isFalse);
      expect(s.projectedSpend, 2000000);
    });

    test('đầu kỳ chưa có ngày nào trôi qua thì chưa dự báo', () {
      final s = st(spent: 0, daysRemaining: 30, daysTotal: 30);
      expect(s.isOnTrackToOverspend, isFalse);
      expect(s.projectedSpend, isNull);
    });
  });

  group('ngưỡng thông báo', () {
    /// Mỗi ngưỡng chỉ báo đúng một lần, nếu không sẽ bắn thông báo lại sau
    /// từng giao dịch khi đã ở vùng trên 80%.
    test('báo khi vừa vượt qua 80%', () {
      final truoc = st(spent: 2000000);
      final sau = st(spent: 2500000);
      expect(crossedThreshold(truoc, sau), BudgetLevel.warning);
    });

    test('báo khi vừa vượt qua 100%', () {
      final truoc = st(spent: 2500000);
      final sau = st(spent: 3100000);
      expect(crossedThreshold(truoc, sau), BudgetLevel.over);
    });

    test('không báo lại khi vẫn ở cùng một mức', () {
      expect(crossedThreshold(st(spent: 2500000), st(spent: 2600000)), isNull);
      expect(crossedThreshold(st(spent: 3100000), st(spent: 3500000)), isNull);
    });

    test('không báo khi tụt xuống mức thấp hơn', () {
      expect(crossedThreshold(st(spent: 3100000), st(spent: 1000000)), isNull);
      expect(crossedThreshold(st(spent: 2500000), st(spent: 1000000)), isNull);
    });

    test('nhảy thẳng từ an toàn lên vượt thì báo mức vượt', () {
      expect(crossedThreshold(st(spent: 100000), st(spent: 5000000)),
          BudgetLevel.over);
    });
  });
}
