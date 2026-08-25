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
import '../../entry/presentation/entry_providers.dart';
import 'calendar_providers.dart';
import 'transaction_edit_sheet.dart';

/// Danh sách giao dịch của một ngày, hiện dạng bảng trượt.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C.3.
///
/// Dùng `DraggableScrollableSheet` để bảng mở ở 60% màn hình và kéo lên được
/// toàn màn (file 07 mục 3.3) — ngày nhiều giao dịch thì kéo lên xem hết,
/// ngày ít thì vẫn thấy lịch phía sau để chuyển ngày khác.
class DayTransactionsSheet extends ConsumerWidget {
  const DayTransactionsSheet({required this.day, super.key});

  final DateTime day;

  static Future<void> show(BuildContext context, DateTime day) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DayTransactionsSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dayTransactionsProvider(day));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: Tokens.md),
            Container(
              width: Tokens.xxl,
              height: Tokens.xs,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: Tokens.brFull,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.screenPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'vi').format(day),
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  if (async.value case final list? when list.isNotEmpty)
                    Text(
                      '${list.length} giao dịch',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // Chạm để sửa là thao tác đúng nhưng vô hình: không có mũi tên,
            // không có nút, nên người dùng không đoán ra là dòng bấm được.
            // Một câu ở đây rẻ hơn nhiều so với việc thêm nút vào từng dòng.
            if (async.value case final list? when list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.screenPadding,
                  0,
                  Tokens.screenPadding,
                  Tokens.md,
                ),
                child: Text(
                  'Chạm vào một dòng để sửa · vuốt sang trái để xoá',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: switch (async) {
                AsyncError(:final error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Tokens.xxl),
                      child: Text('Không đọc được giao dịch.\n$error'),
                    ),
                  ),
                AsyncData(:final value) when value.isEmpty => const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Ngày này chưa có giao dịch nào.',
                  ),
                AsyncData(:final value) => ListView.separated(
                    controller: scrollController,
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _TransactionRow(detail: value[i]),
                  ),
                // Chỉ khung rỗng khi đang tải: DB cục bộ trả về gần như tức
                // thì, hiện vòng xoay chỉ làm màn hình nhấp nháy.
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        );
      },
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = detail.transaction;
    final money = context.moneyColors;

    // Màu và dấu theo loại giao dịch. Chuyển ví và điều chỉnh dùng màu trung
    // tính vì chúng không phải thu cũng không phải chi.
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

    final subtitle = switch (tx.type) {
      TransactionType.transfer =>
        '${detail.wallet?.name ?? '?'} → ${detail.toWallet?.name ?? '?'}',
      _ => [
          if (tx.note.isNotEmpty) tx.note,
          if (detail.wallet != null) detail.wallet!.name,
        ].join(' · '),
    };

    final icon = switch (tx.type) {
      TransactionType.transfer => Icons.swap_horiz,
      TransactionType.adjustment => Icons.tune,
      _ => AppIcons.resolve(detail.category?.iconCode ?? 0),
    };

    return Dismissible(
      key: ValueKey(tx.id),
      // Vuốt trái để xoá, có xác nhận (đặc tả mục C.3).
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
          title: const Text('Xoá giao dịch?'),
          content: Text(
            'Xoá "$title" — số dư ví sẽ được tính lại ngay. '
            'Thao tác này không hoàn tác được.',
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
          ref.read(transactionRepositoryProvider).deleteTransactions([tx.id]),
      child: ListTile(
        minTileHeight: Tokens.minTouchTarget,
        // Chạm để sửa. Đặc tả mục C.3 nói vuốt phải để sửa, nhưng vuốt hai
        // hướng trên cùng một dòng rất dễ nhầm — vuốt nhẹ sang phải khi định
        // xoá là mất giao dịch. Giữ vuốt trái cho hành động nguy hiểm (xoá,
        // có xác nhận), còn sửa thì chạm, vì chạm là thao tác người dùng thử
        // đầu tiên với bất kỳ dòng danh sách nào.
        onTap: () => TransactionEditSheet.show(context, detail),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: context.textTheme.titleMedium),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
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
      ),
    );
  }
}
