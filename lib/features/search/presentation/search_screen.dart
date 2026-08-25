import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../calendar/presentation/transaction_edit_sheet.dart';
import '../../entry/presentation/entry_providers.dart';
import '../../wallet/presentation/wallet_providers.dart';
import 'search_providers.dart';

/// Tìm kiếm và lọc giao dịch. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C.4.
///
/// MoneyNote không có tính năng này — không tìm được giao dịch cũ là lý do
/// người ta phải nhớ bằng đầu thay vì tra bằng app.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final results = ref.watch(searchResultsProvider);
    final summary = ref.watch(searchSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const _SearchField(),
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: () => _FilterSheet.show(context),
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          if (!filter.isEmpty)
            IconButton(
              tooltip: 'Xoá bộ lọc',
              onPressed: () => ref.read(searchFilterProvider.notifier).clear(),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          const SizedBox(width: Tokens.sm),
        ],
      ),
      body: Column(
        children: [
          if (!filter.isEmpty) _SummaryHeader(summary: summary),
          Expanded(
            child: switch (results) {
              AsyncError(:final error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Tokens.xxl),
                    child: Text('Lỗi tìm kiếm.\n$error'),
                  ),
                ),
              AsyncData(:final value) when value.isEmpty => EmptyState(
                  icon: filter.isEmpty
                      ? Icons.search
                      : Icons.search_off_outlined,
                  message: filter.isEmpty
                      ? 'Gõ từ khoá để tìm trong ghi chú và tên danh mục, '
                          'hoặc mở bộ lọc để tìm theo ngày, ví, danh mục và '
                          'khoảng tiền.'
                      : 'Không có giao dịch nào khớp.\n'
                          'Thử bỏ bớt một tiêu chí lọc.',
                  actionLabel: filter.isEmpty ? null : 'Xoá bộ lọc',
                  onAction: filter.isEmpty
                      ? null
                      : () => ref.read(searchFilterProvider.notifier).clear(),
                ),
              AsyncData(:final value) => ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _ResultRow(detail: value[i]),
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(searchFilterProvider).keyword);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nút "Xoá bộ lọc" reset state — đồng bộ lại ô nhập.
    ref.listen(searchFilterProvider.select((f) => f.keyword), (_, next) {
      if (next != _ctrl.text) _ctrl.text = next;
    });

    return TextField(
      controller: _ctrl,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Tìm trong ghi chú, danh mục…',
        border: InputBorder.none,
      ),
      onChanged: ref.read(searchFilterProvider.notifier).setKeyword,
    );
  }
}

/// Dòng tổng ở đầu kết quả: "38 giao dịch · −4.520.000 đ".
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final SearchSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.screenPadding,
        vertical: Tokens.md,
      ),
      child: Row(
        children: [
          Text(
            '${summary.count} giao dịch',
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(width: Tokens.sm),
          Text('·', style: context.textTheme.bodyMedium),
          const SizedBox(width: Tokens.sm),
          MoneyText(
            summary.net,
            signStyle: MoneySignStyle.signed,
            style: context.textTheme.bodyMedium,
          ),
          const Spacer(),
          Tooltip(
            message: 'Chênh lệch chỉ tính thu và chi.\n'
                'Chuyển ví và điều chỉnh số dư không được cộng vào.',
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    final tx = detail.transaction;
    final money = context.moneyColors;

    final (color, signed) = switch (tx.type) {
      TransactionType.income => (money.income, tx.amount),
      TransactionType.expense => (money.expense, -tx.amount),
      TransactionType.transfer => (money.transfer, -tx.amount),
      TransactionType.adjustment => (money.adjustment, tx.amount),
    };

    final title = switch (tx.type) {
      TransactionType.transfer => 'Chuyển ví',
      TransactionType.adjustment => 'Điều chỉnh số dư',
      _ => detail.category?.name ?? 'Không rõ danh mục',
    };

    return ListTile(
      minTileHeight: Tokens.minTouchTarget,
      onTap: () => TransactionEditSheet.show(context, detail),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.16),
        child: Icon(
          switch (tx.type) {
            TransactionType.transfer => Icons.swap_horiz,
            TransactionType.adjustment => Icons.tune,
            _ => AppIcons.resolve(detail.category?.iconCode ?? 0),
          },
          color: color,
          size: 20,
        ),
      ),
      title: Text(title, style: context.textTheme.titleMedium),
      subtitle: Text(
        [
          DateFormat('dd/MM/yyyy').format(tx.date),
          if (tx.note.isNotEmpty) tx.note,
          if (detail.wallet != null) detail.wallet!.name,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelSmall,
      ),
      trailing: MoneyText(
        signed,
        signStyle: MoneySignStyle.signed,
        color: color,
        style: context.textTheme.titleMedium,
      ),
    );
  }
}

/// Bảng lọc đầy đủ. Nút "Xong" ghim ở đáy — cùng nguyên tắc với mọi bảng trượt
/// khác trong app.
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final notifier = ref.read(searchFilterProvider.notifier);
    final wallets = ref.watch(walletListProvider()).value ?? const [];
    final expenseCats =
        ref.watch(categoryListProvider(CategoryType.expense)).value ?? const [];
    final incomeCats =
        ref.watch(categoryListProvider(CategoryType.income)).value ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(Tokens.screenPadding),
            shrinkWrap: true,
            children: [
              Text('Bộ lọc', style: context.textTheme.headlineSmall),
              const SizedBox(height: Tokens.xl),

              _FilterGroup(
                label: 'Loại giao dịch',
                child: Wrap(
                  spacing: Tokens.sm,
                  children: [
                    for (final t in TransactionType.values)
                      FilterChip(
                        label: Text(switch (t) {
                          TransactionType.income => 'Thu',
                          TransactionType.expense => 'Chi',
                          TransactionType.transfer => 'Chuyển ví',
                          TransactionType.adjustment => 'Điều chỉnh',
                        }),
                        selected: filter.types.contains(t),
                        onSelected: (_) => notifier.toggleType(t),
                      ),
                  ],
                ),
              ),

              _FilterGroup(
                label: 'Khoảng ngày',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    filter.from == null && filter.to == null
                        ? 'Mọi thời gian'
                        : '${_d(filter.from)} → ${_d(filter.to)}',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: const Locale('vi'),
                      initialDateRange: filter.from != null && filter.to != null
                          ? DateTimeRange(start: filter.from!, end: filter.to!)
                          : null,
                    );
                    if (picked != null) {
                      notifier.setDateRange(picked.start, picked.end);
                    }
                  },
                ),
              ),

              if (wallets.isNotEmpty)
                _FilterGroup(
                  label: 'Ví',
                  child: Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      for (final w in wallets)
                        FilterChip(
                          avatar: Icon(
                            AppIcons.resolve(w.wallet.iconCode),
                            size: 18,
                            color: Color(w.wallet.colorValue),
                          ),
                          label: Text(w.wallet.name),
                          selected: filter.walletIds.contains(w.wallet.id),
                          onSelected: (_) => notifier.toggleWallet(w.wallet.id),
                        ),
                    ],
                  ),
                ),

              _FilterGroup(
                label: 'Khoảng tiền',
                child: _AmountRangeRow(
                  min: filter.minAmount,
                  max: filter.maxAmount,
                  onChanged: notifier.setAmountRange,
                ),
              ),

              _FilterGroup(
                label: 'Danh mục chi',
                child: _CategoryChips(
                  categories: expenseCats,
                  selected: filter.categoryIds,
                  onToggle: notifier.toggleCategory,
                ),
              ),

              _FilterGroup(
                label: 'Danh mục thu',
                child: _CategoryChips(
                  categories: incomeCats,
                  selected: filter.categoryIds,
                  onToggle: notifier.toggleCategory,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.screenPadding,
            Tokens.sm,
            Tokens.screenPadding,
            Tokens.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: notifier.clear,
                  child: const Text('Xoá hết'),
                ),
              ),
              const SizedBox(width: Tokens.md),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: Tokens.minTouchTarget + Tokens.sm,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Xem kết quả'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _d(DateTime? d) =>
      d == null ? '…' : DateFormat('dd/MM/yyyy').format(d);
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelSmall),
          const SizedBox(height: Tokens.sm),
          child,
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  final List<dynamic> categories;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.sm,
      runSpacing: Tokens.sm,
      children: [
        for (final c in categories)
          FilterChip(
            avatar: Icon(
              AppIcons.resolve(c.iconCode as int),
              size: 18,
              color: Color(c.colorValue as int),
            ),
            label: Text(c.name as String),
            selected: selected.contains(c.id as int),
            onSelected: (_) => onToggle(c.id as int),
          ),
      ],
    );
  }
}

class _AmountRangeRow extends StatefulWidget {
  const _AmountRangeRow({
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int? min;
  final int? max;
  final void Function(int? min, int? max) onChanged;

  @override
  State<_AmountRangeRow> createState() => _AmountRangeRowState();
}

class _AmountRangeRowState extends State<_AmountRangeRow> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
      text: widget.min == null ? '' : formatPlain(widget.min!),
    );
    _maxCtrl = TextEditingController(
      text: widget.max == null ? '' : formatPlain(widget.max!),
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(
        parseMoney(_minCtrl.text),
        parseMoney(_maxCtrl.text),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Từ',
              suffixText: kCurrencySymbol,
            ),
            onChanged: (_) => _emit(),
          ),
        ),
        const SizedBox(width: Tokens.md),
        Expanded(
          child: TextField(
            controller: _maxCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Đến',
              suffixText: kCurrencySymbol,
            ),
            onChanged: (_) => _emit(),
          ),
        ),
      ],
    );
  }
}
