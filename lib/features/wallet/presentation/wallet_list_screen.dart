import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/daos/wallet_dao.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../data/wallet_repository.dart';
import 'wallet_form_sheet.dart';
import 'wallet_providers.dart';

/// Danh sách ví kèm số dư hiện tại.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục F.3.
class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider());
    final totalAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ví của tôi')),
      body: walletsAsync.when(
        // `skeletonizer` sẽ thay chỗ này ở Phase 9; vòng xoay tạm dùng vì DB
        // cục bộ trả về gần như tức thì, người dùng hầu như không kịp thấy.
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.xxl),
            child: Text('Không đọc được danh sách ví.\n$e'),
          ),
        ),
        data: (wallets) {
          if (wallets.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message:
                  'Chưa có ví nào.\n'
                  'Tạo ví đầu tiên và khai số tiền bạn đang có — '
                  'mọi khoản thu chi sau này sẽ được cộng trừ từ con số đó.',
              actionLabel: 'Tạo ví đầu tiên',
              onAction: () => WalletFormSheet.show(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(Tokens.screenPadding),
            children: [
              _TotalCard(total: totalAsync.value ?? 0),
              const SizedBox(height: Tokens.lg),
              for (final w in wallets) ...[
                _WalletCard(data: w),
                const SizedBox(height: Tokens.md),
              ],
              const SizedBox(height: Tokens.xxxl),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => WalletFormSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ví'),
      ),
    );
  }
}

/// Thẻ tổng tài sản ở đầu màn hình.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng tài sản',
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: Tokens.xs),
            // Số đếm lên khi giá trị đổi — hiệu ứng "Expressive" tự viết,
            // file 07 mục 4. Rẻ tiền, hiệu quả cao.
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: total, end: total),
              duration: Tokens.counter,
              builder: (context, value, _) => MoneyText(
                value,
                style: context.textTheme.displaySmall?.copyWith(
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: Tokens.xs),
            Text(
              'Chỉ gồm ví được bật "Tính vào Tổng tài sản".',
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  const _WalletCard({required this.data});

  final WalletWithBalance data;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.deleteWallet(data.wallet.id);
    if (!context.mounted) return;

    switch (result) {
      case WalletActionOk():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xoá ví ${data.wallet.name}.')),
        );
      // Ví còn giao dịch: không xoá được, mời lưu trữ thay thế.
      case WalletActionRejected(:final reason):
        final archive = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Không xoá được ví'),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Để nguyên'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Lưu trữ ví'),
              ),
            ],
          ),
        );
        if (archive ?? false) {
          await repo.archiveWallet(data.wallet.id);
        }
    }
  }

  Future<void> _adjustBalance(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: formatPlain(data.balance));
    final actual = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Điều chỉnh số dư'),
        // `AlertDialog.content` KHÔNG tự cuộn. Đoạn giải thích dài cộng ô nhập
        // sẽ tràn trên màn hình thấp hoặc khi bàn phím hiện lên.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đếm lại ví thấy lệch? Nhập số tiền thực tế đang có. '
                'App sẽ ghi một giao dịch điều chỉnh bằng đúng phần chênh lệch, '
                'thay vì sửa thẳng số dư — nhờ vậy lịch sử luôn khớp với số dư.',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: Tokens.lg),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Số dư thực tế',
                  suffixText: kCurrencySymbol,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, parseMoney(ctrl.text)),
            child: const Text('Điều chỉnh'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (actual == null || !context.mounted) return;

    final id = await ref
        .read(walletRepositoryProvider)
        .adjustBalance(walletId: data.wallet.id, actualBalance: actual);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          id == null
              ? 'Số dư đã khớp, không cần điều chỉnh.'
              : 'Đã ghi giao dịch điều chỉnh.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = data.wallet;
    final color = Color(w.colorValue);
    final archived = w.archivedAt != null;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: Tokens.brMd,
        onTap: () => WalletFormSheet.show(context, existing: w),
        child: Padding(
          padding: const EdgeInsets.all(Tokens.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                child: Icon(AppIcons.resolve(w.iconCode), color: color),
              ),
              const SizedBox(width: Tokens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name, style: context.textTheme.titleMedium),
                    const SizedBox(height: Tokens.xs),
                    Text(
                      [
                        walletTypeLabel(w.type),
                        if (!w.includeInTotal) 'không tính vào tổng',
                        if (archived) 'đã lưu trữ',
                      ].join(' · '),
                      style: context.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    data.balance,
                    style: context.textTheme.titleMedium,
                    // Số dư âm ở thẻ tín dụng là bình thường nên không tô đỏ
                    // cảnh báo — chỉ dùng màu chữ mặc định (quy tắc số 7).
                  ),
                  const SizedBox(height: Tokens.xs),
                  Text(
                    'gốc ${formatPlain(w.initialBalance)}',
                    style: context.textTheme.labelSmall,
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      await WalletFormSheet.show(context, existing: w);
                    case 'adjust':
                      await _adjustBalance(context, ref);
                    case 'archive':
                      await ref
                          .read(walletRepositoryProvider)
                          .archiveWallet(w.id);
                    case 'unarchive':
                      await ref
                          .read(walletRepositoryProvider)
                          .unarchiveWallet(w.id);
                    case 'delete':
                      await _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa ví')),
                  const PopupMenuItem(
                    value: 'adjust',
                    child: Text('Điều chỉnh số dư'),
                  ),
                  if (archived)
                    const PopupMenuItem(
                      value: 'unarchive',
                      child: Text('Bỏ lưu trữ'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Lưu trữ'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
