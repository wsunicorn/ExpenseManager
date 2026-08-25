// `Value` bọc cột tuỳ chọn khi gọi copyWith của lớp drift.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_range.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../entry/presentation/entry_providers.dart';
import '../../entry/presentation/money_keypad.dart';
import '../../wallet/presentation/wallet_providers.dart';
import 'recurring_providers.dart';

/// Nhãn tiếng Việt cho chu kỳ lặp.
String frequencyLabel(RecurrenceFrequency f) => switch (f) {
      RecurrenceFrequency.daily => 'Hằng ngày',
      RecurrenceFrequency.weekly => 'Hằng tuần',
      RecurrenceFrequency.monthly => 'Hằng tháng',
      RecurrenceFrequency.yearly => 'Hằng năm',
    };

/// Quản lý khoản định kỳ. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục H.3.
///
/// MoneyNote không có tính năng này — tiền nhà, tiền điện, phí Internet phải
/// nhập tay mỗi tháng, và đó là lý do người ta quên.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRulesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Khoản định kỳ')),
      body: rules.isEmpty
          ? EmptyState(
              icon: Icons.event_repeat_outlined,
              message: 'Chưa có khoản định kỳ nào.\n'
                  'Đặt một lần cho tiền nhà, tiền điện hay phí Internet — '
                  'app sẽ tự ghi hoặc nhắc bạn khi đến hạn.',
              actionLabel: 'Tạo khoản định kỳ',
              onAction: () => RecurringEditSheet.show(context),
            )
          : ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _RuleRow(rule: rules[i]),
            ),
      floatingActionButton: rules.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => RecurringEditSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
    );
  }
}

class _RuleRow extends ConsumerWidget {
  const _RuleRow({required this.rule});

  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = context.moneyColors;
    final laChi = rule.type == TransactionType.expense;
    final color = laChi ? money.expense : money.income;

    return Dismissible(
      key: ValueKey(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: context.colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.xl),
        child: Icon(
          Icons.delete_outline,
          color: context.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xoá khoản định kỳ?'),
          content: const Text(
            'Các giao dịch đã sinh ra từ quy tắc này vẫn được giữ nguyên. '
            'Chỉ quy tắc bị xoá, nên từ nay sẽ không sinh thêm nữa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Giữ lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xoá'),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(recurringRepositoryProvider).deleteRule(rule.id),
      child: ListTile(
        minTileHeight: Tokens.minTouchTarget,
        onTap: () => RecurringEditSheet.show(context, existing: rule),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Icon(
            rule.autoPost ? Icons.autorenew : Icons.notifications_outlined,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          rule.note.isEmpty ? frequencyLabel(rule.frequency) : rule.note,
          style: context.textTheme.titleMedium,
        ),
        subtitle: Text(
          [
            frequencyLabel(rule.frequency),
            rule.isActive
                ? 'kỳ tới ${DateFormat('dd/MM/yyyy').format(rule.nextRunDate)}'
                : 'đã tắt',
            rule.autoPost ? 'tự ghi' : 'nhắc xác nhận',
          ].join(' · '),
          style: context.textTheme.labelSmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              laChi ? -rule.amount : rule.amount,
              signStyle: MoneySignStyle.signed,
              color: color,
              style: context.textTheme.bodyMedium,
            ),
            Switch(
              value: rule.isActive,
              onChanged: (v) => ref
                  .read(recurringRepositoryProvider)
                  .setActive(rule.id, active: v),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bảng tạo / sửa quy tắc định kỳ.
class RecurringEditSheet extends ConsumerStatefulWidget {
  const RecurringEditSheet({super.key, this.existing});

  final RecurringRule? existing;

  static Future<void> show(BuildContext context, {RecurringRule? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RecurringEditSheet(existing: existing),
    );
  }

  @override
  ConsumerState<RecurringEditSheet> createState() =>
      _RecurringEditSheetState();
}

class _RecurringEditSheetState extends ConsumerState<RecurringEditSheet> {
  late final TextEditingController _noteCtrl;

  late TransactionType _type;
  late int _amount;
  int? _walletId;
  int? _categoryId;
  late RecurrenceFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _autoPost;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _type = e?.type ?? TransactionType.expense;
    _amount = e?.amount ?? 0;
    _walletId = e?.walletId;
    _categoryId = e?.categoryId;
    _frequency = e?.frequency ?? RecurrenceFrequency.monthly;
    _startDate = e?.startDate ?? dateOnly(DateTime.now());
    _endDate = e?.endDate;
    _autoPost = e?.autoPost ?? true;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      setState(() => _error = 'Số tiền phải lớn hơn 0.');
      return;
    }
    if (_walletId == null) {
      setState(() => _error = 'Chọn ví.');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Chọn danh mục.');
      return;
    }

    final repo = ref.read(recurringRepositoryProvider);
    if (_isEditing) {
      await repo.updateRule(
        widget.existing!.copyWith(
          type: _type,
          amount: _amount,
          walletId: _walletId!,
          categoryId: Value(_categoryId),
          note: _noteCtrl.text.trim(),
          frequency: _frequency,
          startDate: _startDate,
          endDate: Value(_endDate),
          autoPost: _autoPost,
        ),
      );
    } else {
      await repo.createRule(
        type: _type,
        amount: _amount,
        walletId: _walletId!,
        categoryId: _categoryId,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        autoPost: _autoPost,
        note: _noteCtrl.text,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider()).value ?? const [];
    final categories = ref
            .watch(
              categoryListProvider(
                _type == TransactionType.income
                    ? CategoryType.income
                    : CategoryType.expense,
              ),
            )
            .value ??
        const [];

    // Mặc định ví đầu tiên.
    if (_walletId == null && wallets.isNotEmpty) {
      _walletId = wallets.first.wallet.id;
    }

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
                  Text(
                    _isEditing ? 'Sửa khoản định kỳ' : 'Khoản định kỳ mới',
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Tokens.xl),

                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Chi'),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Thu'),
                      ),
                    ],
                    selected: {_type},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      // Danh mục chi không dùng được cho khoản thu.
                      _categoryId = null;
                    }),
                  ),
                  const SizedBox(height: Tokens.lg),

                  Material(
                    color: context.colorScheme.surfaceContainerHigh,
                    borderRadius: Tokens.brMd,
                    child: InkWell(
                      borderRadius: Tokens.brMd,
                      onTap: () async {
                        final v = await MoneyKeypad.show(
                          context,
                          initialValue: _amount,
                          submitLabel: 'Xong',
                        );
                        if (v != null) {
                          setState(() {
                            _amount = v;
                            _error = null;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(Tokens.lg),
                        child: Row(
                          children: [
                            Text('Số tiền', style: context.textTheme.labelSmall),
                            const Spacer(),
                            MoneyText(
                              _amount,
                              style: context.textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Tokens.md),

                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tên khoản',
                      hintText: 'Tiền nhà, tiền điện, phí Internet…',
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: Tokens.md),

                  DropdownButtonFormField<int>(
                    initialValue: _walletId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ví'),
                    items: [
                      for (final w in wallets)
                        DropdownMenuItem(
                          value: w.wallet.id,
                          child: Text(w.wallet.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _walletId = v),
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Danh mục', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      for (final c in categories)
                        ChoiceChip(
                          avatar: Icon(
                            AppIcons.resolve(c.iconCode),
                            size: 18,
                            color: Color(c.colorValue),
                          ),
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(() {
                            _categoryId = c.id;
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Chu kỳ', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    children: [
                      for (final f in RecurrenceFrequency.values)
                        ChoiceChip(
                          label: Text(frequencyLabel(f)),
                          selected: _frequency == f,
                          onSelected: (_) => setState(() => _frequency = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.md),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_arrow_outlined),
                    title: const Text('Bắt đầu từ'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(_startDate),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('vi'),
                      );
                      if (picked != null) {
                        setState(() => _startDate = dateOnly(picked));
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.stop_outlined),
                    title: const Text('Kết thúc'),
                    subtitle: Text(
                      _endDate == null
                          ? 'Lặp mãi'
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                    ),
                    trailing: _endDate == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _endDate = null),
                          ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                        locale: const Locale('vi'),
                      );
                      if (picked != null) {
                        setState(() => _endDate = dateOnly(picked));
                      }
                    },
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _autoPost,
                    onChanged: (v) => setState(() => _autoPost = v),
                    title: Text(
                      _autoPost ? 'Tự động ghi' : 'Nhắc xác nhận',
                    ),
                    subtitle: Text(
                      _autoPost
                          ? 'Đến hạn là ghi luôn. Hợp với khoản cố định như '
                              'tiền nhà.'
                          : 'Đến hạn thì hỏi, bạn sửa được số tiền trước khi '
                              'ghi. Hợp với tiền điện — tháng nào cũng khác.',
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
                child: Text(_isEditing ? 'Lưu thay đổi' : 'Tạo khoản định kỳ'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
