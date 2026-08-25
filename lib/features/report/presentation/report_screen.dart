import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../domain/report_insights.dart';
import 'report_providers.dart';

/// Tab 3 — Báo cáo. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục D,
/// thứ tự bố cục ở `07_UI_UX.md` mục 3.4.
///
/// Thứ tự từ trên xuống là **quan trọng nhất trước**: thẻ tóm tắt → câu diễn
/// giải → biểu đồ tròn → bảng danh mục → biểu đồ cột. Câu diễn giải đứng thứ
/// hai chứ không phải cuối cùng, vì nó mới là thứ làm người ta thay đổi hành vi.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(reportTotalsProvider).value;
    final coData = totals != null && (totals.income > 0 || totals.expense > 0);

    return Scaffold(
      appBar: AppBar(title: const _PeriodSelector(), titleSpacing: 0),
      body: Column(
        children: [
          const _PeriodTabs(),
          Expanded(
            child: !coData
                ? const EmptyState(
                    icon: Icons.pie_chart_outline,
                    message: 'Kỳ này chưa có khoản thu chi nào.\n'
                        'Ghi vài giao dịch ở tab Nhập vào rồi quay lại đây.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(Tokens.screenPadding),
                    children: const [
                      _SummaryCard(),
                      SizedBox(height: Tokens.lg),
                      _InsightsCard(),
                      SizedBox(height: Tokens.lg),
                      _BreakdownTabs(),
                      SizedBox(height: Tokens.md),
                      _CategoryDonut(),
                      SizedBox(height: Tokens.lg),
                      _CategoryTable(),
                      SizedBox(height: Tokens.lg),
                      _MonthlyBars(),
                      SizedBox(height: Tokens.xxxl),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends ConsumerWidget {
  const _PeriodTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(reportSelectionControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.screenPadding),
      child: SegmentedButton<ReportPeriod>(
        segments: [
          for (final p in ReportPeriod.values)
            ButtonSegment(value: p, label: Text(p.label)),
        ],
        selected: {selection.period},
        showSelectedIcon: false,
        onSelectionChanged: (s) => ref
            .read(reportSelectionControllerProvider.notifier)
            .setPeriod(s.first),
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(reportSelectionControllerProvider);
    final notifier = ref.read(reportSelectionControllerProvider.notifier);

    final label = switch (selection.period) {
      ReportPeriod.month =>
        DateFormat('MMMM yyyy', 'vi').format(selection.anchor),
      ReportPeriod.year => 'Năm ${selection.anchor.year}',
      ReportPeriod.all => 'Toàn kỳ',
    };

    // "Toàn kỳ" không có kỳ trước/sau để chuyển.
    final coTheChuyen = selection.period != ReportPeriod.all;

    return Row(
      children: [
        IconButton(
          onPressed: coTheChuyen ? () => notifier.shift(-1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Kỳ trước',
        ),
        Expanded(
          child: Center(
            child: Text(label, style: context.textTheme.titleMedium),
          ),
        ),
        IconButton(
          onPressed: coTheChuyen ? () => notifier.shift(1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Kỳ sau',
        ),
      ],
    );
  }
}

/// Tab con Chi tiêu / Thu nhập, quyết định biểu đồ tròn và bảng bên dưới vẽ
/// loại nào. Học từ MoneyNote — biểu đồ tròn chỉ vẽ được một loại nên bắt buộc
/// phải có cách đổi.
class _BreakdownTabs extends ConsumerWidget {
  const _BreakdownTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hienTai = ref.watch(reportBreakdownTypeProvider);

    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Chi tiêu'),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Thu nhập'),
        ),
      ],
      selected: {hienTai},
      showSelectedIcon: false,
      onSelectionChanged: (s) =>
          ref.read(reportBreakdownTypeProvider.notifier).set(s.first),
    );
  }
}

/// Thẻ tóm tắt Chi / Thu / Thu chi — giữ nguyên như MoneyNote (mục D.1).
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals =
        ref.watch(reportTotalsProvider).value ?? (income: 0, expense: 0);
    final money = context.moneyColors;
    final net = totals.income - totals.expense;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.lg),
        child: Row(
          children: [
            _SummaryCell(
              label: 'Chi tiêu',
              amount: totals.expense,
              color: money.expense,
            ),
            _SummaryCell(
              label: 'Thu nhập',
              amount: totals.income,
              color: money.income,
            ),
            _SummaryCell(label: 'Thu chi', amount: net, color: null, signed: true),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.amount,
    required this.color,
    this.signed = false,
  });

  final String label;
  final int amount;
  final Color? color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MoneyText(
              amount,
              color: color,
              signStyle:
                  signed ? MoneySignStyle.signed : MoneySignStyle.none,
              style: context.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Câu diễn giải tự sinh — thứ MoneyNote không có.
class _InsightsCard extends ConsumerWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(reportInsightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();

    final money = context.moneyColors;

    return Card(
      margin: EdgeInsets.zero,
      color: context.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final i in insights)
              Padding(
                padding: const EdgeInsets.only(bottom: Tokens.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      switch (i.tone) {
                        InsightTone.good => Icons.trending_down,
                        InsightTone.warning => Icons.trending_up,
                        InsightTone.neutral => Icons.info_outline,
                      },
                      size: 18,
                      color: switch (i.tone) {
                        InsightTone.good => money.income,
                        InsightTone.warning => money.expense,
                        InsightTone.neutral =>
                          context.colorScheme.onSecondaryContainer,
                      },
                    ),
                    const SizedBox(width: Tokens.md),
                    Expanded(
                      child: Text(
                        i.text,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Biểu đồ **donut**, không phải pie đặc — tổng nằm ở giữa lỗ (file 07 mục 3.4).
class _CategoryDonut extends ConsumerStatefulWidget {
  const _CategoryDonut();

  @override
  ConsumerState<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends ConsumerState<_CategoryDonut> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final loai = ref.watch(reportBreakdownTypeProvider);
    final cats =
        ref.watch(reportCategoryTotalsProvider(loai)).value ??
            const <CategoryTotal>[];
    if (cats.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.xxl),
          child: Center(
            child: Text(
              loai == TransactionType.expense
                  ? 'Kỳ này chưa có khoản chi nào.'
                  : 'Kỳ này chưa có khoản thu nào.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final grouped = groupForPieChart(cats);
    final tong = cats.fold(0, (s, c) => s + c.amount);
    final cs = context.colorScheme;

    // Có danh mục nhưng tổng bằng 0 thì mọi phép `amount * 100 / tong` ra NaN,
    // và `NaN.round()` **ném lỗi** chứ không trả 0 — cả thẻ biểu đồ biến thành
    // ô trắng. Trường hợp hiếm, nhưng hỏng thì hỏng ngay giữa màn hình.
    if (tong <= 0) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.xxl),
          child: Center(
            child: Text(
              'Kỳ này chưa có số liệu để vẽ biểu đồ.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[
      for (var i = 0; i < grouped.slices.length; i++)
        _section(grouped.slices[i], i, tong),
      if (grouped.otherAmount > 0)
        PieChartSectionData(
          value: grouped.otherAmount.toDouble(),
          color: cs.outlineVariant,
          title: '${(grouped.otherAmount * 100 / tong).round()}%',
          radius: 56,
          titleStyle: context.textTheme.labelSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loai == TransactionType.expense
                  ? 'Cơ cấu chi tiêu'
                  : 'Cơ cấu thu nhập',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: Tokens.lg),
            SizedBox(
              // Cao hơn vòng tròn để nhãn phần trăm nằm ngoài không bị cắt.
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Nhãn ngữ nghĩa cho trình đọc màn hình (file 07 mục 5).
                  Semantics(
                    label: 'Biểu đồ chi tiêu theo danh mục: '
                        '${cats.take(6).map((c) => '${c.name} '
                            '${(c.amount * 100 / tong).round()} phần trăm').join(', ')}',
                    excludeSemantics: true,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 56,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            // fl_chart trả -1 khi chạm vào lỗ donut hoặc ra
                            // ngoài vòng tròn. Không lọc thì `slices[-1]` ném
                            // RangeError và cả biểu đồ biến mất — đúng lỗi
                            // "chạm vào là trắng xóa".
                            final i = response?.touchedSection
                                ?.touchedSectionIndex;
                            final hopLe = i != null &&
                                i >= 0 &&
                                i < grouped.slices.length;
                            if (_touchedIndex == (hopLe ? i : null)) return;
                            setState(() => _touchedIndex = hopLe ? i : null);
                          },
                        ),
                      ),
                      // Vẽ một lần khi mở, không lặp (file 07 mục 4).
                      duration: Tokens.chart,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loai == TransactionType.expense
                            ? 'Tổng chi'
                            : 'Tổng thu',
                        style: context.textTheme.labelSmall,
                      ),
                      MoneyText(
                        _touchedIndex != null &&
                                _touchedIndex! < grouped.slices.length
                            ? grouped.slices[_touchedIndex!].amount
                            : tong,
                        compact: true,
                        style: context.textTheme.titleMedium,
                      ),
                      if (_touchedIndex != null &&
                          _touchedIndex! < grouped.slices.length)
                        Text(
                          grouped.slices[_touchedIndex!].name,
                          style: context.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Tokens.sm),
            // Số trong biểu đồ là bản rút gọn nên phải ghi rõ (file 07 mục 1.1).
            Text(
              'Số trong biểu đồ đã rút gọn. Xem số đầy đủ ở bảng bên dưới.',
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(CategoryTotal c, int index, int tong) {
    final chon = _touchedIndex == index;
    final phanTram = c.amount * 100 / tong;

    return PieChartSectionData(
      value: c.amount.toDouble(),
      color: Color(c.colorValue),
      // Lát quá mỏng thì nhãn chồng lên nhau thành một vòng chữ rối — bỏ nhãn,
      // số đầy đủ vẫn có ở bảng bên dưới.
      title: phanTram < 4 ? '' : '${phanTram.toStringAsFixed(1)}%',
      radius: chon ? 64 : 56,
      // Đẩy nhãn ra ngoài vòng thay vì đè lên lát màu: chữ trắng trên nền màu
      // nhạt rất khó đọc, và đây cũng là cách MoneyNote làm.
      titlePositionPercentageOffset: 1.45,
      titleStyle: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Bảng chi tiết theo danh mục, có thanh phần trăm (mục D.3).
class _CategoryTable extends ConsumerWidget {
  const _CategoryTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loai = ref.watch(reportBreakdownTypeProvider);
    final cats =
        ref.watch(reportCategoryTotalsProvider(loai)).value ??
            const <CategoryTotal>[];
    if (cats.isEmpty) return const SizedBox.shrink();

    final tong = cats.fold(0, (s, c) => s + c.amount);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết theo danh mục', style: context.textTheme.titleMedium),
            const SizedBox(height: Tokens.lg),
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.only(bottom: Tokens.lg),
                child: _CategoryRow(category: c, total: tong),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.total});

  final CategoryTotal category;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tyLe = total == 0 ? 0.0 : category.amount / total;
    final color = Color(category.colorValue);

    return Column(
      children: [
        Row(
          children: [
            Icon(AppIcons.resolve(category.iconCode), size: 18, color: color),
            const SizedBox(width: Tokens.sm),
            Expanded(
              child: Text(
                category.name,
                style: context.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            MoneyText(category.amount, style: context.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: Tokens.xs),
        ClipRRect(
          borderRadius: Tokens.brFull,
          child: LinearProgressIndicator(
            value: tyLe,
            minHeight: Tokens.sm,
            color: color,
            backgroundColor: context.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: Tokens.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${(tyLe * 100).round()}% · ${category.count} giao dịch',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Biểu đồ cột 12 tháng, hai cột thu/chi cạnh nhau, cuộn ngang (mục D.2).
class _MonthlyBars extends ConsumerWidget {
  const _MonthlyBars();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(trailingMonthlyTotalsProvider).value ??
        const <MonthTotals>[];
    if (months.isEmpty) return const SizedBox.shrink();

    final money = context.moneyColors;
    final maxValue = months.fold<int>(
      0,
      (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thu chi 12 tháng', style: context.textTheme.titleMedium),
            const SizedBox(height: Tokens.lg),
            SizedBox(
              height: 200,
              // Nội dung rộng phải tự cuộn ngang, không để trang bị tràn.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: months.length * 56,
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue * 1.15,
                      barGroups: [
                        for (var i = 0; i < months.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: months[i].income.toDouble(),
                                color: money.income,
                                width: 10,
                                borderRadius: Tokens.brSm,
                              ),
                              BarChartRodData(
                                toY: months[i].expense.toDouble(),
                                color: money.expense,
                                width: 10,
                                borderRadius: Tokens.brSm,
                              ),
                            ],
                          ),
                      ],
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: Tokens.xs),
                                child: Text(
                                  'T${months[i].month}',
                                  style: context.textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    duration: Tokens.chart,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Tokens.sm),
            Row(
              children: [
                _LegendDot(color: money.income, label: 'Thu'),
                const SizedBox(width: Tokens.lg),
                _LegendDot(color: money.expense, label: 'Chi'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Tokens.md,
          height: Tokens.md,
          decoration: BoxDecoration(color: color, borderRadius: Tokens.brSm),
        ),
        const SizedBox(width: Tokens.sm),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }
}
