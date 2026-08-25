import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/daos/transaction_dao.dart';
import 'package:so_thu_chi/features/report/domain/report_insights.dart';

/// Câu diễn giải tự sinh — `07_UI_UX.md` mục 1.2.
///
/// Hàm thuần nên test trực tiếp được. Đáng test kỹ vì đây là chỗ dễ sinh ra
/// câu sai sự thật nhất: chia cho 0, dự báo từ hai ngày đầu kỳ, hay khoe
/// "tiết kiệm được" khi thực ra đang âm.
void main() {
  CategoryTotal dm(int id, String ten, int tien, {int count = 1}) =>
      CategoryTotal(
        categoryId: id,
        name: ten,
        iconCode: 0,
        colorValue: 0,
        amount: tien,
        count: count,
      );

  ReportContext ctx({
    int income = 0,
    int expense = 0,
    int previousIncome = 0,
    int previousExpense = 0,
    List<CategoryTotal> categories = const [],
    List<CategoryTotal> previousCategories = const [],
    int daysElapsed = 30,
    int daysTotal = 30,
  }) =>
      ReportContext(
        income: income,
        expense: expense,
        previousIncome: previousIncome,
        previousExpense: previousExpense,
        categories: categories,
        previousCategories: previousCategories,
        daysElapsed: daysElapsed,
        daysTotal: daysTotal,
      );

  String allText(List<Insight> list) => list.map((i) => i.text).join(' | ');

  group('kỳ rỗng', () {
    test('không có giao dịch thì không sinh câu nào', () {
      expect(buildInsights(ctx()), isEmpty);
    });
  });

  group('so với kỳ trước', () {
    test('chi tăng thì nói rõ phần trăm và số tiền', () {
      final r = buildInsights(ctx(expense: 5900000, previousExpense: 5000000));
      expect(allText(r), contains('Chi nhiều hơn kỳ trước 18%'));
      expect(allText(r), contains('900.000 đ'));
      expect(r.first.tone, InsightTone.warning);
    });

    test('chi giảm thì báo tin tốt', () {
      final r = buildInsights(ctx(expense: 4000000, previousExpense: 5000000));
      expect(allText(r), contains('Chi ít hơn kỳ trước 20%'));
      expect(r.first.tone, InsightTone.good);
    });

    /// Dao động vài phần trăm là bình thường — nói ra chỉ gây nhiễu và làm
    /// người dùng bỏ qua cả những câu thật sự đáng chú ý.
    test('chênh dưới 5% thì nói là gần như không đổi', () {
      final r = buildInsights(ctx(expense: 5100000, previousExpense: 5000000));
      expect(allText(r), contains('gần như không đổi'));
    });

    test('kỳ trước không có dữ liệu thì không so sánh, không chia cho 0', () {
      final r = buildInsights(ctx(expense: 5000000));
      expect(allText(r), isNot(contains('kỳ trước')));
    });
  });

  group('danh mục tăng mạnh nhất', () {
    /// Chỉ ra danh mục **tăng mạnh nhất**, không phải danh mục lớn nhất — biết
    /// mình tốn nhiều cho Tiền nhà thì không hành động được, biết Ăn uống vừa
    /// tăng vọt thì có.
    test('chỉ ra danh mục tăng nhiều nhất, không phải danh mục to nhất', () {
      final r = buildInsights(
        ctx(
          expense: 5000000,
          previousExpense: 4000000,
          categories: [dm(1, 'Tiền nhà', 3000000), dm(2, 'Ăn uống', 2000000)],
          previousCategories: [
            dm(1, 'Tiền nhà', 3000000),
            dm(2, 'Ăn uống', 1000000),
          ],
        ),
      );
      expect(allText(r), contains('Ăn uống'));
      expect(allText(r), isNot(contains('Tăng mạnh nhất là Tiền nhà')));
    });

    test('bỏ qua mức tăng vụn vặt so với tổng chi', () {
      final r = buildInsights(
        ctx(
          expense: 10000000,
          previousExpense: 9000000,
          categories: [dm(1, 'Ăn uống', 100000)],
          previousCategories: [dm(1, 'Ăn uống', 50000)],
        ),
      );
      expect(allText(r), isNot(contains('Tăng mạnh nhất')));
    });

    test('không có danh mục nào tăng thì không nói gì', () {
      final r = buildInsights(
        ctx(
          expense: 3000000,
          previousExpense: 5000000,
          categories: [dm(1, 'Ăn uống', 1000000)],
          previousCategories: [dm(1, 'Ăn uống', 2000000)],
        ),
      );
      expect(allText(r), isNot(contains('Tăng mạnh nhất')));
    });
  });

  group('trung bình mỗi ngày', () {
    test('chia đúng theo số ngày đã trôi qua', () {
      final r = buildInsights(ctx(expense: 3000000, daysElapsed: 20, daysTotal: 31));
      expect(allText(r), contains('150.000 đ/ngày'));
    });

    test('không chia cho 0 khi kỳ chưa có ngày nào trôi qua', () {
      final r = buildInsights(ctx(expense: 100000, daysElapsed: 0, daysTotal: 31));
      expect(allText(r), isNot(contains('/ngày')));
    });
  });

  group('dự báo cuối kỳ', () {
    test('dự báo theo nhịp hiện tại khi kỳ đang dở', () {
      final r = buildInsights(ctx(expense: 3000000, daysElapsed: 15, daysTotal: 30));
      expect(allText(r), contains('Còn 15 ngày'));
      expect(allText(r), contains('≈6tr'));
    });

    /// Dự báo cho kỳ đã kết thúc là vô nghĩa.
    test('kỳ đã xong thì không dự báo', () {
      final r = buildInsights(ctx(expense: 3000000, daysElapsed: 30, daysTotal: 30));
      expect(allText(r), isNot(contains('Giữ nhịp này')));
    });

    /// Suy từ một hai ngày đầu kỳ ra cả tháng thì sai đến mức gây hiểu lầm.
    test('mới qua 2 ngày thì chưa dự báo', () {
      final r = buildInsights(ctx(expense: 500000, daysElapsed: 2, daysTotal: 30));
      expect(allText(r), isNot(contains('Giữ nhịp này')));
    });
  });

  group('tỷ lệ giữ lại', () {
    test('tính đúng phần trăm giữ lại', () {
      final r = buildInsights(ctx(income: 10000000, expense: 6600000));
      expect(allText(r), contains('Giữ lại được 34%'));
      expect(allText(r), contains('3.400.000 đ'));
    });

    test('giữ lại từ 20% trở lên được coi là tin tốt', () {
      final r = buildInsights(ctx(income: 10000000, expense: 5000000));
      expect(
        r.any((i) => i.tone == InsightTone.good && i.text.contains('Giữ lại')),
        isTrue,
      );
    });

    /// Không bao giờ được nói "giữ lại được −20%".
    test('chi vượt thu thì nói thẳng là vượt, không nói phần trăm âm', () {
      final r = buildInsights(ctx(income: 5000000, expense: 6000000));
      expect(allText(r), contains('chi vượt thu 1.000.000 đ'));
      expect(allText(r), isNot(contains('Giữ lại')));
    });

    test('không có thu nhập thì không nói về tỷ lệ giữ lại', () {
      final r = buildInsights(ctx(expense: 1000000));
      expect(allText(r), isNot(contains('Giữ lại')));
    });
  });

  group('gộp lát biểu đồ tròn', () {
    /// Quy tắc cứng của 07_UI_UX.md mục 3.4: tối đa 6 lát + "Khác".
    test('từ 6 danh mục trở xuống thì giữ nguyên', () {
      final list = [for (var i = 0; i < 6; i++) dm(i, 'DM$i', 1000)];
      final r = groupForPieChart(list);
      expect(r.slices, hasLength(6));
      expect(r.otherAmount, 0);
    });

    test('nhiều hơn 6 thì gộp phần đuôi vào "Khác"', () {
      final list = [
        for (var i = 0; i < 10; i++) dm(i, 'DM$i', (10 - i) * 1000, count: 2),
      ];
      final r = groupForPieChart(list);
      expect(r.slices, hasLength(6));
      // 4 danh mục cuối: 4000 + 3000 + 2000 + 1000
      expect(r.otherAmount, 10000);
      expect(r.otherCount, 8);
    });

    test('giữ đúng thứ tự giảm dần khi cắt', () {
      final list = [
        for (var i = 0; i < 10; i++) dm(i, 'DM$i', (10 - i) * 1000),
      ];
      final r = groupForPieChart(list);
      expect(r.slices.first.amount, 10000);
      expect(r.slices.last.amount, 5000);
    });

    test('danh sách rỗng không nổ', () {
      final r = groupForPieChart(const []);
      expect(r.slices, isEmpty);
      expect(r.otherAmount, 0);
    });
  });
}
