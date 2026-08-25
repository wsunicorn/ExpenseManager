/// Sinh câu diễn giải tiếng Việt cho màn hình Báo cáo.
///
/// `07_UI_UX.md` mục 1.2 đặt ra yêu cầu: **mỗi màn hình báo cáo phải có ít
/// nhất một câu tiếng Việt tự sinh diễn giải dữ liệu.** Đây là thứ MoneyNote
/// không có, và là khác biệt giữa "trực quan hoá dữ liệu" và "kể chuyện dữ
/// liệu" — một biểu đồ tròn nói "Ăn uống 42%", một câu nói "tháng này bạn ăn
/// ngoài nhiều hơn tháng trước 18%". Chỉ câu thứ hai làm người ta đổi hành vi.
///
/// Toàn bộ file là hàm thuần trên dữ liệu đã tổng hợp — không đụng Flutter,
/// không đụng DB, nên test được trực tiếp.
library;

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/utils/money.dart';

/// Dữ liệu đầu vào để sinh nhận xét.
class ReportContext {
  const ReportContext({
    required this.income,
    required this.expense,
    required this.previousExpense,
    required this.previousIncome,
    required this.categories,
    required this.previousCategories,
    required this.daysElapsed,
    required this.daysTotal,
  });

  /// Tổng thu và chi của kỳ đang xem.
  final int income;
  final int expense;

  /// Cùng chỉ số của kỳ liền trước, để so sánh.
  final int previousExpense;
  final int previousIncome;

  /// Chi theo danh mục, đã sắp giảm dần.
  final List<CategoryTotal> categories;
  final List<CategoryTotal> previousCategories;

  /// Số ngày đã trôi qua trong kỳ và tổng số ngày của kỳ.
  ///
  /// Với kỳ đã kết thúc thì hai số bằng nhau — khi đó không dự báo nữa, vì dự
  /// báo cho quá khứ là vô nghĩa.
  final int daysElapsed;
  final int daysTotal;

  bool get isOngoing => daysElapsed < daysTotal && daysElapsed > 0;
}

/// Một câu nhận xét kèm mức độ quan trọng, để giao diện biết câu nào đưa lên
/// đầu và câu nào chỉ là thông tin phụ.
class Insight {
  const Insight(this.text, {this.tone = InsightTone.neutral});

  final String text;
  final InsightTone tone;
}

enum InsightTone {
  /// Thông tin trung tính.
  neutral,

  /// Đáng chú ý theo hướng tốt.
  good,

  /// Đáng chú ý theo hướng cần để mắt.
  warning,
}

/// Sinh danh sách nhận xét, câu quan trọng nhất đứng đầu.
///
/// Trả danh sách rỗng khi kỳ chưa có giao dịch nào — màn hình sẽ hiện trạng
/// thái rỗng thay vì một câu nhận xét về số 0.
List<Insight> buildInsights(ReportContext ctx) {
  if (ctx.income == 0 && ctx.expense == 0) return const [];

  final out = <Insight>[
    ...?_compareWithPrevious(ctx),
    ...?_topCategoryShift(ctx),
    ...?_dailyAverage(ctx),
    ...?_forecast(ctx),
    ...?_savingsRate(ctx),
  ];
  return out;
}

/// "Chi nhiều hơn kỳ trước 18%."
List<Insight>? _compareWithPrevious(ReportContext ctx) {
  if (ctx.previousExpense == 0 || ctx.expense == 0) return null;

  final delta = ctx.expense - ctx.previousExpense;
  final percent = (delta.abs() * 100 / ctx.previousExpense).round();

  // Dưới 5% là dao động bình thường, nói ra chỉ gây nhiễu.
  if (percent < 5) {
    return const [
      Insight('Chi tiêu kỳ này gần như không đổi so với kỳ trước.'),
    ];
  }

  return [
    Insight(
      delta > 0
          ? 'Chi nhiều hơn kỳ trước $percent% — thêm ${formatMoney(delta.abs())}.'
          : 'Chi ít hơn kỳ trước $percent% — bớt được ${formatMoney(delta.abs())}.',
      tone: delta > 0 ? InsightTone.warning : InsightTone.good,
    ),
  ];
}

/// "Chủ yếu ở Ăn uống, tăng 320.000 đ."
///
/// Chỉ ra **danh mục tăng mạnh nhất** thay vì danh mục lớn nhất: biết mình
/// tiêu nhiều cho Tiền nhà thì không hành động được, nhưng biết Ăn uống vừa
/// tăng vọt thì có.
List<Insight>? _topCategoryShift(ReportContext ctx) {
  if (ctx.categories.isEmpty || ctx.previousCategories.isEmpty) return null;

  final truoc = {
    for (final c in ctx.previousCategories) c.categoryId: c.amount,
  };

  CategoryTotal? tangNhat;
  var mucTang = 0;
  for (final c in ctx.categories) {
    final delta = c.amount - (truoc[c.categoryId] ?? 0);
    if (delta > mucTang) {
      mucTang = delta;
      tangNhat = c;
    }
  }

  if (tangNhat == null || mucTang <= 0) return null;

  // Bỏ qua mức tăng vụn vặt so với tổng chi.
  if (ctx.expense > 0 && mucTang * 100 / ctx.expense < 5) return null;

  return [
    Insight(
      'Tăng mạnh nhất là ${tangNhat.name}, thêm ${formatMoney(mucTang)} '
      'so với kỳ trước.',
      tone: InsightTone.warning,
    ),
  ];
}

/// "Trung bình 152.000 đ/ngày trong kỳ này."
List<Insight>? _dailyAverage(ReportContext ctx) {
  if (ctx.expense == 0 || ctx.daysElapsed <= 0) return null;

  final trungBinh = ctx.expense ~/ ctx.daysElapsed;
  return [
    Insight('Trung bình ${formatMoney(trungBinh)}/ngày trong kỳ này.'),
  ];
}

/// "Nếu giữ nhịp này, cuối kỳ bạn sẽ chi khoảng 4,6tr."
///
/// Chỉ dự báo khi kỳ **đang diễn ra dở**. Dự báo cho kỳ đã xong là vô nghĩa,
/// và dự báo từ một hai ngày đầu kỳ thì sai đến mức gây hiểu lầm.
List<Insight>? _forecast(ReportContext ctx) {
  if (!ctx.isOngoing || ctx.expense == 0) return null;
  if (ctx.daysElapsed < 3) return null;

  final duBao = ctx.expense * ctx.daysTotal ~/ ctx.daysElapsed;
  final conLai = ctx.daysTotal - ctx.daysElapsed;

  return [
    Insight(
      'Còn $conLai ngày. Giữ nhịp này thì cuối kỳ chi khoảng '
      '≈${formatCompact(duBao)} đ.',
    ),
  ];
}

/// "Bạn giữ lại được 34% thu nhập kỳ này."
List<Insight>? _savingsRate(ReportContext ctx) {
  if (ctx.income <= 0) return null;

  final giuLai = ctx.income - ctx.expense;
  final tyLe = (giuLai * 100 / ctx.income).round();

  if (giuLai < 0) {
    return [
      Insight(
        'Kỳ này chi vượt thu ${formatMoney(-giuLai)}.',
        tone: InsightTone.warning,
      ),
    ];
  }

  return [
    Insight(
      'Giữ lại được $tyLe% thu nhập kỳ này (${formatMoney(giuLai)}).',
      tone: tyLe >= 20 ? InsightTone.good : InsightTone.neutral,
    ),
  ];
}

/// Gộp các danh mục nhỏ thành một lát "Khác" cho biểu đồ tròn.
///
/// `07_UI_UX.md` mục 3.4: **tối đa 6 lát + lát "Khác"** — nhiều hơn thì không
/// đọc được, các lát mỏng chồng nhãn lên nhau thành một vòng chữ rối.
({List<CategoryTotal> slices, int otherAmount, int otherCount}) groupForPieChart(
  List<CategoryTotal> categories, {
  int maxSlices = 6,
}) {
  if (categories.length <= maxSlices) {
    return (slices: categories, otherAmount: 0, otherCount: 0);
  }

  final giuLai = categories.take(maxSlices).toList();
  final gop = categories.skip(maxSlices);

  return (
    slices: giuLai,
    otherAmount: gop.fold(0, (sum, c) => sum + c.amount),
    otherCount: gop.fold(0, (sum, c) => sum + c.count),
  );
}
