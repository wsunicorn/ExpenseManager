import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_range.dart';
import '../../../shared/widgets/money_text.dart';
import 'calendar_providers.dart';
import 'day_transactions_sheet.dart';

/// Tab 2 — Lịch. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C,
/// bố cục ở `07_UI_UX.md` mục 3.3.
///
/// Lưới lịch **tự viết**, không dùng package: mỗi ô phải hiện hai dòng số nhỏ
/// (thu xanh / chi đỏ) — không package lịch nào cho phép việc đó mà không phải
/// chống lại nó. Đây cũng là cải tiến chính so với MoneyNote, vốn để trống mọi
/// ô ngày nên tab Lịch gần như vô dụng.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const _MonthSelector(),
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            onPressed: () => context.go(AppRoutes.search),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Về tháng này',
            onPressed: () =>
                ref.read(selectedMonthProvider.notifier).goToToday(),
            icon: const Icon(Icons.today_outlined),
          ),
          const SizedBox(width: Tokens.sm),
        ],
      ),
      body: Column(
        children: [
          const _WeekdayHeader(),
          Expanded(child: _MonthGrid(month: month)),
          const Divider(height: 1),
          _SummaryBar(month: month),
        ],
      ),
    );
  }
}

/// Thanh chọn tháng: mũi tên trái/phải + chạm để mở bộ chọn tháng.
/// Giữ nguyên cách MoneyNote làm — đây là thứ MoneyNote làm đúng.
class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);

    return Row(
      children: [
        IconButton(
          tooltip: 'Tháng trước',
          onPressed: () => notifier.shift(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: month,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('vi'),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) notifier.setMonth(picked);
            },
            child: Text(
              DateFormat('MMMM yyyy', 'vi').format(month),
              style: context.textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Tháng sau',
          onPressed: () => notifier.shift(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  /// Bắt đầu từ Thứ 2 như lịch Việt Nam.
  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.sm),
      child: Row(
        children: [
          for (final l in _labels)
            Expanded(
              child: Center(
                child: Text(
                  l,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: l == 'CN'
                        ? context.moneyColors.expense
                        : context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = calendarGridDays(month);
    final totals = ref.watch(monthDailyTotalsProvider(month)).value ?? const {};
    final selected = ref.watch(selectedDayProvider);
    final today = dateOnly(DateTime.now());

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.xs),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        // Ô cao hơn rộng để chứa số ngày cộng hai dòng số tiền.
        childAspectRatio: 1 / (days.length > 35 ? 1.25 : 1.15),
      ),
      itemBuilder: (context, i) {
        final day = days[i];
        return _DayCell(
          day: day,
          inMonth: day.month == month.month,
          isToday: day == today,
          isSelected: selected == day,
          totals: totals[day],
          onTap: () {
            ref.read(selectedDayProvider.notifier).select(day);
            DayTransactionsSheet.show(context, day);
          },
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.totals,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final DayTotals? totals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final money = context.moneyColors;

    // Ngày ngoài tháng làm mờ chứ không ẩn — người dùng vẫn cần thấy tuần trọn.
    final dayColor = inMonth ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        // Hôm nay tô nền, không dùng viền — viền dễ lẫn với ô được chọn
        // (file 07 mục 3.3).
        color: isToday ? cs.primaryContainer : Colors.transparent,
        borderRadius: Tokens.brSm,
        child: InkWell(
          borderRadius: Tokens.brSm,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Tokens.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isToday ? cs.onPrimaryContainer : dayColor,
                    fontWeight: isToday ? FontWeight.w600 : null,
                  ),
                ),
                // Hai dòng số nhỏ. Giữ chỗ cố định kể cả khi rỗng để lưới
                // không so le giữa ngày có và không có giao dịch.
                SizedBox(
                  height: 24,
                  child: totals == null
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (totals!.income > 0)
                              _MiniAmount(
                                amount: totals!.income,
                                color: money.income,
                              ),
                            if (totals!.expense > 0)
                              _MiniAmount(
                                amount: totals!.expense,
                                color: money.expense,
                              ),
                          ],
                        ),
                ),
                // Chấm tròn đặc dưới số cho ngày đang chọn.
                SizedBox(
                  height: Tokens.xs + 2,
                  child: isSelected
                      ? Container(
                          width: Tokens.xs,
                          height: Tokens.xs,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Số tiền rút gọn trong ô lịch. Cỡ 9–10 theo file 07 mục 3.3.
class _MiniAmount extends StatelessWidget {
  const _MiniAmount({required this.amount, required this.color});

  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: MoneyText(
        amount,
        compact: true,
        color: color,
        style: const TextStyle(fontSize: 10, height: 1.1),
      ),
    );
  }
}

/// Thanh tổng kết Thu | Chi | Tổng của tháng đang xem.
class _SummaryBar extends ConsumerWidget {
  const _SummaryBar({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthTotalsProvider(month)).value ??
        (income: 0, expense: 0);
    final money = context.moneyColors;
    final net = totals.income - totals.expense;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.screenPadding,
          vertical: Tokens.md,
        ),
        child: Row(
          children: [
            _SummaryCell(
              label: 'Thu nhập',
              amount: totals.income,
              color: money.income,
              sign: MoneySignStyle.none,
            ),
            _SummaryCell(
              label: 'Chi tiêu',
              amount: totals.expense,
              color: money.expense,
              sign: MoneySignStyle.none,
            ),
            // Chênh lệch mang dấu thật vì nó có thể âm.
            _SummaryCell(
              label: 'Thu chi',
              amount: net,
              color: null,
              sign: MoneySignStyle.signed,
            ),
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
    required this.sign,
  });

  final String label;
  final int amount;
  final Color? color;
  final MoneySignStyle sign;

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
              signStyle: sign,
              style: context.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
