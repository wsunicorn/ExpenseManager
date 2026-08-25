import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/budget_dao.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../entry/presentation/entry_providers.dart';
import '../domain/budget_status.dart';
import 'budget_providers.dart';

/// Tab 4 — Ngân sách. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục E.
///
/// Hai cải tiến so với MoneyNote, cả hai đều nằm ở bảng đặt hạn mức:
/// **"Áp dụng cho các tháng sau"** (MoneyNote bắt đặt lại mỗi tháng) và
/// **"Gợi ý từ 3 tháng gần nhất"** (MoneyNote bắt bạn tự nghĩ ra con số).
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    // Sinh ngân sách lặp lại cho tháng này, nếu tháng trước có bật cờ.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = ref.read(budgetMonthProvider);
      ref.read(budgetRepositoryProvider).ensureMonth(month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(budgetMonthProvider);
    final list = ref.watch(budgetListProvider(month)).value ?? const [];
    final statuses = ref.watch(budgetStatusesProvider(month));

    final tong = list.where((b) => b.isTotalBudget).firstOrNull;
    final theoDanhMuc = list.where((b) => !b.isTotalBudget).toList();

    return Scaffold(
      appBar: AppBar(title: const _MonthSelector(), titleSpacing: 0),
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.savings_outlined,
              message: 'Chưa đặt ngân sách cho tháng này.\n'
                  'Đặt hạn mức để app cảnh báo khi bạn chạm 80% và 100% — '
                  'thứ MoneyNote không có.',
              actionLabel: 'Đặt ngân sách đầu tiên',
              onAction: () => BudgetEditSheet.show(context, month: month),
            )
          : ListView(
              padding: const EdgeInsets.all(Tokens.screenPadding),
              children: [
                if (tong != null) ...[
                  _BudgetCard(
                    data: tong,
                    status: statuses[tong.budget.id],
                    month: month,
                    isTotal: true,
                  ),
                  const SizedBox(height: Tokens.xl),
                ],
                if (theoDanhMuc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Tokens.md),
                    child: Text(
                      'Theo danh mục',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (final b in theoDanhMuc) ...[
                  _BudgetCard(
                    data: b,
                    status: statuses[b.budget.id],
                    month: month,
                    isTotal: false,
                  ),
                  const SizedBox(height: Tokens.md),
                ],
                const SizedBox(height: Tokens.xxxl * 2),
              ],
            ),
      floatingActionButton: list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => BudgetEditSheet.show(context, month: month),
              icon: const Icon(Icons.add),
              label: const Text('Thêm hạn mức'),
            ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final notifier = ref.read(budgetMonthProvider.notifier);

    return Row(
      children: [
        IconButton(
          onPressed: () {
            notifier.shift(-1);
            ref
                .read(budgetRepositoryProvider)
                .ensureMonth(ref.read(budgetMonthProvider));
          },
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Tháng trước',
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy', 'vi').format(month),
              style: context.textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            notifier.shift(1);
            ref
                .read(budgetRepositoryProvider)
                .ensureMonth(ref.read(budgetMonthProvider));
          },
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Tháng sau',
        ),
      ],
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({
    required this.data,
    required this.status,
    required this.month,
    required this.isTotal,
  });

  final BudgetWithSpent data;
  final BudgetStatus? status;
  final DateTime month;
  final bool isTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = status;
    if (s == null) return const SizedBox.shrink();

    final money = context.moneyColors;
    final mauNguong = switch (s.level) {
      BudgetLevel.safe => money.budgetSafe,
      BudgetLevel.warning => money.budgetWarn,
      BudgetLevel.over => money.budgetOver,
    };

    return Card(
      margin: EdgeInsets.zero,
      color: isTotal ? context.colorScheme.surfaceContainerHigh : null,
      child: InkWell(
        borderRadius: Tokens.brMd,
        onTap: () => BudgetEditSheet.show(
          context,
          month: month,
          existing: data,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Tokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isTotal && data.categoryIconCode != null) ...[
                    Icon(
                      AppIcons.resolve(data.categoryIconCode!),
                      size: 20,
                      color: Color(data.categoryColorValue ?? 0xFF888888),
                    ),
                    const SizedBox(width: Tokens.sm),
                  ],
                  Expanded(
                    child: Text(
                      isTotal
                          ? 'Ngân sách tổng'
                          : data.categoryName ?? 'Không rõ danh mục',
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  // Số còn lại mang dấu thật — âm nghĩa là đã vượt.
                  MoneyText(
                    s.remaining,
                    signStyle: MoneySignStyle.signed,
                    color: s.remaining < 0 ? money.budgetOver : null,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: Tokens.md),
              ClipRRect(
                borderRadius: Tokens.brFull,
                child: LinearProgressIndicator(
                  value: s.barValue,
                  minHeight: Tokens.sm,
                  color: mauNguong,
                  backgroundColor:
                      context.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: Tokens.sm),
              Text(
                '${formatPlain(s.spent)} / ${formatMoney(s.limit)} · '
                '${s.percent}%',
                style: context.textTheme.labelSmall,
              ),
              const SizedBox(height: Tokens.xs),
              Text(
                _dongPhu(s),
                style: context.textTheme.labelSmall?.copyWith(
                  color: s.level == BudgetLevel.over || s.isOnTrackToOverspend
                      ? money.budgetOver
                      : context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dòng phụ: mức chi còn được phép mỗi ngày, hoặc cảnh báo nhịp chi.
  ///
  /// Cảnh báo sớm quan trọng hơn cảnh báo lúc đã vượt — đến khi chạm 100% thì
  /// tiền đã tiêu mất rồi.
  String _dongPhu(BudgetStatus s) {
    if (s.level == BudgetLevel.over) {
      return 'Đã vượt hạn mức ${formatMoney(-s.remaining)}.';
    }
    if (s.isOnTrackToOverspend && s.projectedSpend != null) {
      return 'Giữ nhịp này thì cuối tháng sẽ chi ≈${formatCompact(s.projectedSpend!)} đ — vượt hạn mức.';
    }
    final moiNgay = s.dailyAllowance;
    if (moiNgay == null) return 'Kỳ đã kết thúc.';
    return 'Còn ${s.daysRemaining} ngày · có thể tiêu ${formatMoney(moiNgay)}/ngày.';
  }
}

/// Bảng đặt hạn mức. Nút lưu ghim ở đáy như mọi bảng trượt khác.
class BudgetEditSheet extends ConsumerStatefulWidget {
  const BudgetEditSheet({required this.month, super.key, this.existing});

  final DateTime month;
  final BudgetWithSpent? existing;

  static Future<void> show(
    BuildContext context, {
    required DateTime month,
    BudgetWithSpent? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BudgetEditSheet(month: month, existing: existing),
    );
  }

  @override
  ConsumerState<BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<BudgetEditSheet> {
  late final TextEditingController _amountCtrl;

  /// Null nghĩa là ngân sách tổng.
  int? _categoryId;
  late bool _repeatForward;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(
      text: e == null ? '' : formatPlain(e.budget.amount),
    );
    _categoryId = e?.budget.categoryId;
    _repeatForward = e?.budget.repeatForward ?? true;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    final goiY = await ref.read(budgetRepositoryProvider).suggestAmount(
          categoryId: _categoryId,
          month: widget.month,
        );
    if (!mounted) return;

    if (goiY == 0) {
      setState(() => _error = 'Chưa đủ dữ liệu 3 tháng gần nhất để gợi ý.');
      return;
    }
    setState(() {
      _amountCtrl.text = formatPlain(goiY);
      _error = null;
    });
  }

  Future<void> _save() async {
    final amount = parseMoney(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Hạn mức phải lớn hơn 0.');
      return;
    }

    await ref.read(budgetRepositoryProvider).setBudget(
          categoryId: _categoryId,
          year: widget.month.year,
          month: widget.month.month,
          amount: amount,
          repeatForward: _repeatForward,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(budgetRepositoryProvider)
        .removeBudget(widget.existing!.budget.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoryListProvider(CategoryType.expense)).value ?? const [];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Tokens.screenPadding,
                Tokens.screenPadding,
                Tokens.screenPadding,
                Tokens.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEditing ? 'Sửa hạn mức' : 'Hạn mức mới',
                          style: context.textTheme.headlineSmall,
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          tooltip: 'Xoá hạn mức',
                          onPressed: _delete,
                          icon: Icon(
                            Icons.delete_outline,
                            color: context.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Áp dụng cho', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('Toàn bộ chi tiêu'),
                        selected: _categoryId == null,
                        onSelected: _isEditing
                            ? null
                            : (_) => setState(() => _categoryId = null),
                      ),
                      for (final c in categories)
                        ChoiceChip(
                          avatar: Icon(
                            AppIcons.resolve(c.iconCode),
                            size: 18,
                            color: Color(c.colorValue),
                          ),
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: _isEditing
                              ? null
                              : (_) => setState(() => _categoryId = c.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.xl),

                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Hạn mức tháng',
                      suffixText: kCurrencySymbol,
                      errorText: _error,
                      errorMaxLines: 2,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: Tokens.md),

                  // Cải tiến số 2 so với MoneyNote.
                  OutlinedButton.icon(
                    onPressed: _suggest,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Gợi ý từ 3 tháng gần nhất'),
                  ),
                  const SizedBox(height: Tokens.md),

                  // Cải tiến số 1.
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _repeatForward,
                    onChanged: (v) => setState(() => _repeatForward = v),
                    title: const Text('Áp dụng cho các tháng sau'),
                    subtitle: const Text(
                      'Tháng mới sẽ tự có hạn mức này, không phải đặt lại. '
                      'Sửa riêng cho một tháng vẫn được.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.screenPadding,
              Tokens.sm,
              Tokens.screenPadding,
              Tokens.lg,
            ),
            child: SizedBox(
              width: double.infinity,
              height: Tokens.minTouchTarget + Tokens.sm,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Lưu thay đổi' : 'Đặt hạn mức'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
