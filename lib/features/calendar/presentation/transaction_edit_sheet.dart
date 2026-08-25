import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/daos/wallet_dao.dart';
import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_range.dart';
import '../../../shared/widgets/money_text.dart';
import '../../entry/data/transaction_repository.dart';
import '../../entry/presentation/entry_providers.dart';
import '../../entry/presentation/money_keypad.dart';
import '../../wallet/presentation/wallet_providers.dart';

/// Sửa một giao dịch đã ghi. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C.3.
///
/// Bố cục theo cùng nguyên tắc với màn hình Nhập vào: nội dung cuộn được, nút
/// lưu **ghim ở đáy** để không bao giờ bị đẩy ra ngoài tầm nhìn.
class TransactionEditSheet extends ConsumerStatefulWidget {
  const TransactionEditSheet({required this.detail, super.key});

  final TransactionDetail detail;

  static Future<void> show(BuildContext context, TransactionDetail detail) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionEditSheet(detail: detail),
    );
  }

  @override
  ConsumerState<TransactionEditSheet> createState() =>
      _TransactionEditSheetState();
}

class _TransactionEditSheetState extends ConsumerState<TransactionEditSheet> {
  late final TextEditingController _noteCtrl;

  late int _amount;
  late DateTime _date;
  late int _walletId;
  int? _toWalletId;
  int? _categoryId;

  Transaction get _tx => widget.detail.transaction;

  /// Điều chỉnh số dư chỉ cho sửa ngày và ghi chú — xem `editAdjustmentMeta`.
  bool get _isAdjustment => _tx.type == TransactionType.adjustment;

  bool get _isTransfer => _tx.type == TransactionType.transfer;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: _tx.note);
    _amount = _tx.amount;
    _date = _tx.date;
    _walletId = _tx.walletId;
    _toWalletId = _tx.toWalletId;
    _categoryId = _tx.categoryId;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(transactionRepositoryProvider);

    final result = switch (_tx.type) {
      TransactionType.adjustment => await repo.editAdjustmentMeta(
          original: _tx,
          date: _date,
          note: _noteCtrl.text,
        ),
      TransactionType.transfer => await repo.editTransfer(
          original: _tx,
          amount: _amount,
          fromWalletId: _walletId,
          toWalletId: _toWalletId ?? _walletId,
          date: _date,
          note: _noteCtrl.text,
        ),
      _ => await repo.editIncomeOrExpense(
          original: _tx,
          amount: _amount,
          walletId: _walletId,
          categoryId: _categoryId ?? 0,
          date: _date,
          note: _noteCtrl.text,
        ),
    };

    if (!mounted) return;

    switch (result) {
      case SaveRejected(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
      case SaveOk():
        Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: const Text(
          'Số dư ví sẽ được tính lại ngay. Thao tác này không hoàn tác được.',
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
    );
    if (!(ok ?? false) || !mounted) return;

    await ref.read(transactionRepositoryProvider).deleteTransactions([_tx.id]);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider()).value ?? const [];
    final money = context.moneyColors;

    final (tieuDe, mau) = switch (_tx.type) {
      TransactionType.income => ('Sửa khoản thu', money.income),
      TransactionType.expense => ('Sửa khoản chi', money.expense),
      TransactionType.transfer => ('Sửa chuyển ví', money.transfer),
      TransactionType.adjustment => ('Điều chỉnh số dư', money.adjustment),
    };

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
                          tieuDe,
                          style: context.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xoá giao dịch',
                        onPressed: _delete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: context.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.lg),

                  // ── Số tiền ────────────────────────────────────────────
                  if (_isAdjustment)
                    _ReadOnlyRow(
                      label: 'Số tiền',
                      note: 'Số tiền của một điều chỉnh là phần chênh lệch đã '
                          'tính lúc đếm lại ví. Sửa bằng tay sẽ làm số dư nói '
                          'dối — muốn đổi thì xoá rồi điều chỉnh lại.',
                      child: MoneyText(
                        _amount,
                        signStyle: MoneySignStyle.signed,
                        color: mau,
                        style: context.textTheme.headlineSmall,
                      ),
                    )
                  else
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
                          if (v != null) setState(() => _amount = v);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Tokens.lg),
                          child: Row(
                            children: [
                              Text(
                                'Số tiền',
                                style: context.textTheme.labelSmall,
                              ),
                              const Spacer(),
                              MoneyText(
                                _amount,
                                color: mau,
                                style: context.textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: Tokens.md),

                  // ── Ngày ───────────────────────────────────────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_date),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('vi'),
                      );
                      if (picked != null) {
                        setState(() => _date = dateOnly(picked));
                      }
                    },
                  ),

                  // ── Ví ─────────────────────────────────────────────────
                  if (_isTransfer) ...[
                    _WalletPicker(
                      label: 'Từ ví',
                      wallets: wallets,
                      value: _walletId,
                      onChanged: (v) => setState(() => _walletId = v),
                    ),
                    const SizedBox(height: Tokens.md),
                    _WalletPicker(
                      label: 'Đến ví',
                      wallets: wallets,
                      value: _toWalletId,
                      excludeId: _walletId,
                      onChanged: (v) => setState(() => _toWalletId = v),
                    ),
                  ] else
                    _WalletPicker(
                      label: 'Ví',
                      wallets: wallets,
                      value: _walletId,
                      onChanged: (v) => setState(() => _walletId = v),
                    ),
                  const SizedBox(height: Tokens.md),

                  // ── Danh mục ───────────────────────────────────────────
                  if (!_isTransfer && !_isAdjustment) ...[
                    Text('Danh mục', style: context.textTheme.labelSmall),
                    const SizedBox(height: Tokens.sm),
                    _CategoryPicker(
                      type: _tx.type == TransactionType.income
                          ? CategoryType.income
                          : CategoryType.expense,
                      selectedId: _categoryId,
                      onSelected: (id) => setState(() => _categoryId = id),
                    ),
                    const SizedBox(height: Tokens.md),
                  ],

                  TextField(
                    controller: _noteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                  ),
                ],
              ),
            ),
          ),

          // Nút lưu ghim ở đáy — cùng nguyên tắc với bảng trượt tạo ví.
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
                child: const Text('Lưu thay đổi'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô chỉ đọc kèm lời giải thích vì sao không sửa được.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.note,
    required this.child,
  });

  final String label;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Tokens.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: Tokens.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: context.textTheme.labelSmall),
              const Spacer(),
              child,
            ],
          ),
          const SizedBox(height: Tokens.sm),
          Text(
            note,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPicker extends StatelessWidget {
  const _WalletPicker({
    required this.label,
    required this.wallets,
    required this.value,
    required this.onChanged,
    this.excludeId,
  });

  final String label;
  final List<WalletWithBalance> wallets;
  final int? value;
  final int? excludeId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = wallets.where((w) => w.wallet.id != excludeId).toList();

    return DropdownButtonFormField<int>(
      initialValue: items.any((w) => w.wallet.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final w in items)
          DropdownMenuItem(
            value: w.wallet.id,
            child: Row(
              children: [
                Icon(
                  AppIcons.resolve(w.wallet.iconCode),
                  size: 18,
                  color: Color(w.wallet.colorValue),
                ),
                const SizedBox(width: Tokens.sm),
                Expanded(
                  child: Text(w.wallet.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Lưới danh mục nằm ngang, cuộn được — gọn hơn lưới 4 cột khi đang sửa.
class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    required this.type,
    required this.selectedId,
    required this.onSelected,
  });

  final CategoryType type;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryListProvider(type)).value ?? const [];

    return Wrap(
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
            selected: selectedId == c.id,
            onSelected: (_) => onSelected(c.id),
          ),
      ],
    );
  }
}
