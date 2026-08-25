import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/enums.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../entry/presentation/money_keypad.dart';
import '../data/recurring_repository.dart';
import 'recurring_providers.dart';
import 'recurring_screen.dart';

/// Bảng duyệt các kỳ định kỳ đến hạn ở chế độ "nhắc xác nhận".
///
/// Đặc tả mục H.1: chế độ này dành cho khoản mà **số tiền đổi mỗi kỳ** — tiền
/// điện, tiền nước. Vì vậy nút chính không phải "Đồng ý" mà là "Ghi" kèm khả
/// năng sửa số tiền ngay tại chỗ. Bắt người dùng ghi rồi vào sửa lại là thêm
/// bốn chạm cho một việc họ làm mỗi tháng.
class PendingOccurrencesSheet extends ConsumerWidget {
  const PendingOccurrencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const PendingOccurrencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(recurringScanProvider);
    final pending = scan?.pendingConfirmation ?? const <PendingOccurrence>[];

    // Duyệt hết thì tự đóng.
    if (pending.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    return Padding(
      padding: const EdgeInsets.all(Tokens.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khoản định kỳ đến hạn',
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: Tokens.sm),
          Text(
            'Sửa số tiền nếu kỳ này khác, rồi bấm Ghi.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.lg),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pending.length,
              separatorBuilder: (_, _) => const Divider(height: Tokens.xl),
              itemBuilder: (context, i) => _PendingRow(pending: pending[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends ConsumerStatefulWidget {
  const _PendingRow({required this.pending});

  final PendingOccurrence pending;

  @override
  ConsumerState<_PendingRow> createState() => _PendingRowState();
}

class _PendingRowState extends ConsumerState<_PendingRow> {
  late int _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.pending.rule.amount;
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.pending.rule;
    final money = context.moneyColors;
    final color = rule.type == TransactionType.expense
        ? money.expense
        : money.income;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rule.note.isEmpty ? frequencyLabel(rule.frequency) : rule.note,
          style: context.textTheme.titleMedium,
        ),
        Text(
          'Kỳ ${DateFormat('dd/MM/yyyy').format(widget.pending.date)}',
          style: context.textTheme.labelSmall,
        ),
        const SizedBox(height: Tokens.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final v = await MoneyKeypad.show(
                    context,
                    initialValue: _amount,
                    submitLabel: 'Xong',
                  );
                  if (v != null) setState(() => _amount = v);
                },
                child: Text(
                  formatMoney(_amount),
                  style: TextStyle(color: color),
                ),
              ),
            ),
            const SizedBox(width: Tokens.md),
            TextButton(
              onPressed: () =>
                  ref.read(recurringScanProvider.notifier).skip(widget.pending),
              child: const Text('Bỏ qua'),
            ),
            const SizedBox(width: Tokens.sm),
            FilledButton(
              onPressed: () => ref
                  .read(recurringScanProvider.notifier)
                  .confirm(widget.pending, amountOverride: _amount),
              child: const Text('Ghi'),
            ),
          ],
        ),
      ],
    );
  }
}
