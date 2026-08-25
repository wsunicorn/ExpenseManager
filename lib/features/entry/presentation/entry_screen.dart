import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/wallet_dao.dart';
import '../../../core/db/database.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../wallet/presentation/wallet_providers.dart';
import '../data/transaction_repository.dart';
import 'entry_providers.dart';
import 'money_keypad.dart';

/// Tab 1 — Nhập vào. Màn hình mặc định khi mở app.
///
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục B, bố cục ở `07_UI_UX.md` mục 3.1.
///
/// Mục tiêu thiết kế duy nhất: **nhập xong một khoản chi trong 3 chạm.**
/// Chỉ số thành công của app này không phải biểu đồ đẹp, mà là bạn có ghi chi
/// tiêu đều đặn 30 ngày liên tục hay không. Nhập một khoản quá 5 giây là bạn bỏ.
class EntryScreen extends ConsumerWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chi nghe `tab` chu khong ca form: man hinh goc chi doi bo cuc khi doi
    // tab. Watch ca form thi go mot ky tu vao o Ghi chu cung ve lai toan bo
    // luoi danh muc.
    final tab = ref.watch(entryFormProvider.select((s) => s.tab));
    final walletsAsync = ref.watch(walletListProvider());

    return Scaffold(
      body: SafeArea(
        child: walletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi đọc ví: $e')),
          data: (wallets) {
            // Chưa có ví thì không nhập được gì — mời tạo ví trước.
            if (wallets.isEmpty) {
              return EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: 'Cần có ít nhất một ví trước khi ghi giao dịch.\n'
                    'Tạo ví và khai số tiền bạn đang có — mọi khoản thu chi '
                    'sau này sẽ được cộng trừ từ con số đó.',
                actionLabel: 'Tạo ví đầu tiên',
                onAction: () => context.go(AppRoutes.wallets),
              );
            }

            return Column(
              children: [
                const _BalanceHeader(),
                const _TabSelector(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.screenPadding,
                    ),
                    children: [
                      const SizedBox(height: Tokens.md),
                      const _DateRow(),
                      const SizedBox(height: Tokens.md),
                      _WalletRow(wallets: wallets),
                      const SizedBox(height: Tokens.md),
                      const _NoteField(),
                      const SizedBox(height: Tokens.md),
                      const _AmountDisplay(),
                      const SizedBox(height: Tokens.lg),
                      if (tab == EntryTab.transfer)
                        const _FeeRow()
                      else
                        const _CategoryGrid(),
                      const SizedBox(height: Tokens.xxxl * 2),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Hành động chính ở 1/3 dưới màn hình, chiếm trọn bề ngang
      // (file 07 mục 1.3 — quy tắc cứng).
      bottomNavigationBar: const _SaveBar(),
    );
  }
}

/// Thẻ số dư ở đầu màn hình — thứ MoneyNote không có.
class _BalanceHeader extends ConsumerWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(totalBalanceProvider).value ?? 0;
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.screenPadding,
        Tokens.md,
        Tokens.screenPadding,
        Tokens.md,
      ),
      child: InkWell(
        borderRadius: Tokens.brMd,
        onTap: () => context.go(AppRoutes.wallets),
        child: Padding(
          padding: const EdgeInsets.all(Tokens.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng tài sản',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Tokens.xs),
                    MoneyText(total, style: context.textTheme.displaySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ba tab Chi / Thu / Chuyển ví.
class _TabSelector extends ConsumerWidget {
  const _TabSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(entryFormProvider).tab;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.screenPadding),
      child: SegmentedButton<EntryTab>(
        segments: [
          for (final tab in EntryTab.values)
            ButtonSegment(value: tab, label: Text(tab.label)),
        ],
        selected: {current},
        showSelectedIcon: false,
        onSelectionChanged: (s) =>
            ref.read(entryFormProvider.notifier).setTab(s.first),
      ),
    );
  }
}

/// Ngày, có mũi tên trái/phải và nút mở lịch — giữ nguyên như MoneyNote.
class _DateRow extends ConsumerWidget {
  const _DateRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(entryFormProvider).date;
    final notifier = ref.read(entryFormProvider.notifier);

    // `DateFormat` với locale 'vi' cần initializeDateFormatting — được gọi
    // trong main(). Dạng "T2, 24/08/2026".
    final label = DateFormat('EEE, dd/MM/yyyy', 'vi').format(date);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Row(
      children: [
        IconButton(
          onPressed: () => notifier.shiftDate(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Ngày trước',
        ),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('vi'),
              );
              if (picked != null) notifier.setDate(picked);
            },
            child: Text(isToday ? 'Hôm nay · $label' : label),
          ),
        ),
        IconButton(
          onPressed: () => notifier.shiftDate(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Ngày sau',
        ),
      ],
    );
  }
}

/// Chọn ví. Ở tab Chuyển ví thì thành hai ô: từ ví → đến ví.
class _WalletRow extends ConsumerWidget {
  const _WalletRow({required this.wallets});

  final List<WalletWithBalance> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(entryFormProvider);
    final notifier = ref.read(entryFormProvider.notifier);

    // Chưa chọn ví thì mặc định ví đầu danh sách, ngay trong lần build này.
    final selected = form.walletId ?? wallets.first.wallet.id;
    if (form.walletId == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => notifier.setWallet(selected),
      );
    }

    if (form.tab != EntryTab.transfer) {
      // Mot vi thi o chon vi khong cho nguoi dung quyet dinh gi - bo di cho
      // man hinh nhap ngan lai mot dong.
      if (wallets.length < 2) return const SizedBox.shrink();

      return _WalletDropdown(
        label: 'Ví',
        wallets: wallets,
        value: selected,
        onChanged: notifier.setWallet,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _WalletDropdown(
            label: 'Từ ví',
            wallets: wallets,
            value: selected,
            onChanged: notifier.setWallet,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.sm),
          child: Icon(Icons.arrow_forward),
        ),
        Expanded(
          child: _WalletDropdown(
            label: 'Đến ví',
            wallets: wallets,
            value: form.toWalletId,
            // Chặn chọn trùng ví nguồn (quy tắc ở mục B.3).
            excludeId: selected,
            onChanged: notifier.setToWallet,
          ),
        ),
      ],
    );
  }
}

class _WalletDropdown extends StatelessWidget {
  const _WalletDropdown({
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

class _NoteField extends ConsumerStatefulWidget {
  const _NoteField();

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(entryFormProvider).note);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Form bị reset sau khi lưu → đồng bộ lại ô nhập.
    ref.listen(entryFormProvider.select((s) => s.note), (_, next) {
      if (next != _ctrl.text) _ctrl.text = next;
    });

    return TextField(
      controller: _ctrl,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Ghi chú',
        hintText: 'Cơm trưa, tiền xăng…',
      ),
      onChanged: ref.read(entryFormProvider.notifier).setNote,
    );
  }
}

/// Ô số tiền lớn. Chạm để mở bàn phím số.
class _AmountDisplay extends ConsumerWidget {
  const _AmountDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soTien = ref.watch(entryFormProvider.select((s) => s.amount));
    final tab = ref.watch(entryFormProvider.select((s) => s.tab));
    final cs = context.colorScheme;
    final money = context.moneyColors;

    final color = switch (tab) {
      EntryTab.expense => money.expense,
      EntryTab.income => money.income,
      EntryTab.transfer => money.transfer,
    };

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: Tokens.brMd,
      child: InkWell(
        borderRadius: Tokens.brMd,
        onTap: () async {
          final value = await MoneyKeypad.show(
            context,
            initialValue: soTien,
          );
          if (value != null) {
            ref.read(entryFormProvider.notifier).setAmount(value);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(Tokens.lg),
          child: Row(
            children: [
              Text('Số tiền', style: context.textTheme.labelSmall),
              const Spacer(),
              MoneyText(
                soTien,
                color: soTien > 0 ? color : cs.onSurfaceVariant,
                style: context.textTheme.displaySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phí chuyển ví — chỉ hiện ở tab Chuyển ví.
class _FeeRow extends ConsumerWidget {
  const _FeeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fee = ref.watch(entryFormProvider.select((s) => s.fee));

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: const Text('Phí chuyển'),
        subtitle: const Text(
          'Ghi thành một khoản chi riêng thuộc danh mục "Phí ngân hàng", '
          'không gộp vào số tiền chuyển.',
        ),
        trailing: MoneyText(fee, style: context.textTheme.titleMedium),
        onTap: () async {
          final value = await MoneyKeypad.show(
            context,
            initialValue: fee,
            submitLabel: 'Xong',
          );
          if (value != null) ref.read(entryFormProvider.notifier).setFee(value);
        },
      ),
    );
  }
}

/// Lưới danh mục 4 cột. 12 ô hiện cùng lúc, không phải cuộn để tìm.
class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(entryFormProvider.select((s) => s.tab));
    final dangChon = ref.watch(entryFormProvider.select((s) => s.categoryId));
    final type = tab.categoryType!;
    final categoriesAsync = ref.watch(categoryListProvider(type));

    return categoriesAsync.when(
      loading: () => const SizedBox(height: 200),
      error: (e, _) => Text('Lỗi đọc danh mục: $e'),
      data: (categories) {
        if (categories.isEmpty) {
          return const EmptyState(
            icon: Icons.category_outlined,
            message: 'Chưa có danh mục nào cho loại này.',
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: Tokens.sm,
            crossAxisSpacing: Tokens.sm,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, i) {
            final c = categories[i];
            return _CategoryTile(
              category: c,
              selected: dangChon == c.id,
              onTap: () =>
                  ref.read(entryFormProvider.notifier).setCategory(c.id),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final color = Color(category.colorValue);

    return Material(
      color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: Tokens.brMd,
      child: InkWell(
        borderRadius: Tokens.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.resolve(category.iconCode), size: 24, color: color),
              const SizedBox(height: Tokens.xs),
              Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: selected ? cs.onSecondaryContainer : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút lưu ở đáy màn hình.
class _SaveBar extends ConsumerWidget {
  const _SaveBar();

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final form = ref.read(entryFormProvider);
    final repo = ref.read(transactionRepositoryProvider);

    final result = switch (form.tab) {
      EntryTab.transfer => await repo.saveTransfer(
          amount: form.amount,
          fromWalletId: form.walletId!,
          toWalletId: form.toWalletId!,
          date: form.date,
          fee: form.fee,
          note: form.note,
        ),
      _ => await repo.saveIncomeOrExpense(
          type: form.tab.transactionType,
          amount: form.amount,
          walletId: form.walletId!,
          categoryId: form.categoryId!,
          date: form.date,
          note: form.note,
        ),
    };

    if (!context.mounted) return;

    switch (result) {
      case SaveRejected(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
      case SaveOk():
        ref.read(entryFormProvider.notifier).resetAfterSave();
        // Không hiện SnackBar "Đã lưu / Hoàn tác" nữa.
        //
        // Đặc tả mục B.4 có yêu cầu nút Hoàn tác, nhưng chủ dự án dùng thật
        // rồi và thấy nó vướng: thanh này che mất nút Lưu, và khi nhập liên
        // tiếp vài khoản thì nó chồng lên nhau không tắt kịp.
        //
        // Hoàn tác vẫn còn đường khác và tiện hơn: sang tab Lịch, chạm ngày
        // vừa nhập, vuốt trái để xoá.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chi nghe hai thu quyet dinh nut nay trong nhu the nao.
    final coTheLuu = ref.watch(entryFormProvider.select((s) => s.canSave));
    final tab = ref.watch(entryFormProvider.select((s) => s.tab));

    final hasWallets =
        (ref.watch(walletListProvider()).value ?? const []).isNotEmpty;
    if (!hasWallets) return const SizedBox.shrink();

    final label = switch (tab) {
      EntryTab.expense => 'Nhập khoản Tiền chi',
      EntryTab.income => 'Nhập khoản Tiền thu',
      EntryTab.transfer => 'Chuyển tiền',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.screenPadding),
        child: SizedBox(
          width: double.infinity,
          height: Tokens.minTouchTarget + Tokens.sm,
          child: FilledButton(
            onPressed: coTheLuu ? () => _save(context, ref) : null,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
