/// Tính trạng thái một khoản ngân sách.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục E, ngưỡng màu ở `07_UI_UX.md` mục 2.3.
///
/// Hàm thuần — test được không cần Flutter hay DB. Đây là chỗ dễ sai lặng lẽ:
/// chia cho 0 khi hạn mức bằng 0, hoặc tính "còn tiêu được bao nhiêu mỗi ngày"
/// ra số âm rồi hiển thị như một lời khuyên.
library;

/// Ba mức cảnh báo ngân sách.
enum BudgetLevel {
  /// Dùng dưới 80% hạn mức.
  safe,

  /// Dùng 80–100%.
  warning,

  /// Vượt quá 100%.
  over,
}

/// Trạng thái đã tính xong của một khoản ngân sách.
class BudgetStatus {
  const BudgetStatus({
    required this.limit,
    required this.spent,
    required this.daysRemaining,
    required this.daysTotal,
  });

  /// Hạn mức, đơn vị đồng.
  final int limit;

  /// Đã chi, đơn vị đồng. Luôn ≥ 0.
  final int spent;

  /// Số ngày còn lại của kỳ, tính cả hôm nay.
  final int daysRemaining;

  final int daysTotal;

  /// Còn lại bao nhiêu. **Âm nghĩa là đã vượt.**
  int get remaining => limit - spent;

  /// Tỷ lệ đã dùng, 0.0 → 1.0+. Hạn mức 0 thì coi như đã dùng hết, không chia
  /// cho 0.
  double get ratio {
    if (limit <= 0) return spent > 0 ? 1.0 : 0.0;
    return spent / limit;
  }

  /// Phần trăm làm tròn để hiển thị.
  int get percent => (ratio * 100).round();

  /// Tỷ lệ dùng cho thanh tiến độ — **kẹp ở 1.0** vì thanh không vẽ quá 100%
  /// được. Con số thật vẫn nằm ở [percent].
  double get barValue => ratio.clamp(0.0, 1.0);

  BudgetLevel get level {
    if (ratio > 1.0) return BudgetLevel.over;
    if (ratio >= 0.8) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }

  /// Còn tiêu được bao nhiêu mỗi ngày cho tới hết kỳ.
  ///
  /// Trả `null` khi đã vượt hạn mức hoặc kỳ đã hết — lúc đó không có lời
  /// khuyên nào hợp lý, và hiển thị một con số âm chỉ gây hiểu lầm.
  int? get dailyAllowance {
    if (remaining <= 0 || daysRemaining <= 0) return null;
    return remaining ~/ daysRemaining;
  }

  /// Nhịp chi hiện tại có đang dẫn tới vượt hạn mức không.
  ///
  /// Cảnh báo sớm quan trọng hơn cảnh báo lúc đã vượt: đến khi chạm 100% thì
  /// tiền đã tiêu mất rồi.
  bool get isOnTrackToOverspend {
    final daysElapsed = daysTotal - daysRemaining;
    if (daysElapsed <= 0 || limit <= 0) return false;
    final duBao = spent * daysTotal ~/ daysElapsed;
    return duBao > limit;
  }

  /// Dự báo chi cả kỳ theo nhịp hiện tại. `null` khi chưa đủ dữ liệu.
  int? get projectedSpend {
    final daysElapsed = daysTotal - daysRemaining;
    if (daysElapsed <= 0) return null;
    return spent * daysTotal ~/ daysElapsed;
  }
}

/// Hai ngưỡng cần bắn thông báo, theo mục E.3.
///
/// Trả về ngưỡng vừa bị vượt qua khi đi từ [before] sang [after], hoặc `null`
/// nếu không vượt ngưỡng nào.
///
/// So hai trạng thái thay vì chỉ nhìn trạng thái hiện tại, để **mỗi ngưỡng chỉ
/// báo đúng một lần**. Nhìn mỗi trạng thái hiện tại sẽ bắn thông báo lại sau
/// mỗi giao dịch khi đã ở vùng trên 80%.
BudgetLevel? crossedThreshold(BudgetStatus before, BudgetStatus after) {
  if (before.level == after.level) return null;
  // Chỉ báo khi đi lên. Xoá bớt giao dịch làm tụt về mức an toàn thì không
  // cần thông báo gì.
  if (after.level.index <= before.level.index) return null;
  return after.level;
}
