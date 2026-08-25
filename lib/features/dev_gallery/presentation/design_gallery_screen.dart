import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../../shared/widgets/money_text.dart';

/// Trang tra cứu nội bộ của hệ thống thiết kế.
/// Yêu cầu ở `04_LO_TRINH.md` Phase 2.5 và `07_UI_UX.md` mục 7.
///
/// Đây **không phải màn hình của người dùng cuối** — nó là bảng tra cứu để đối
/// chiếu suốt phần còn lại của dự án: mọi component phải trông đúng ở cả chế độ
/// sáng lẫn tối trước khi được dùng trong màn hình thật.
///
/// `ConsumerWidget` là `StatelessWidget` có thêm tham số `ref` để đọc provider.
class DesignGalleryScreen extends ConsumerWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trong build() luôn dùng ref.watch, không bao giờ ref.read
    // (CONVENTIONS.md mục Kiến trúc — đây là nguồn gốc 80% bug của người mới).
    final mode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống thiết kế'),
        actions: [
          IconButton(
            tooltip: switch (mode) {
              ThemeMode.system => 'Theo hệ thống — chạm để sang Sáng',
              ThemeMode.light => 'Sáng — chạm để sang Tối',
              ThemeMode.dark => 'Tối — chạm để theo hệ thống',
            },
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).cycle(),
            icon: Icon(switch (mode) {
              ThemeMode.system => Icons.brightness_auto_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
            }),
          ),
          const SizedBox(width: Tokens.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.screenPadding),
        children: const [
          _Section(
            title: 'Số tiền',
            note: 'Mọi số đều bật tabular figures — chữ số cùng bề rộng nên '
                'các cột thẳng hàng. Dấu + / − luôn có, không dựa vào màu.',
            child: _MoneySamples(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Màu ngữ nghĩa',
            note: 'Định nghĩa theo vai trò, không theo tên màu. '
                'Đổi chế độ sáng/tối ở nút góc trên để kiểm tương phản.',
            child: _ColorSwatches(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Thang chữ',
            note: 'Tối đa 4 cỡ chữ trên một màn hình thật. '
                'Font Be Vietnam Pro — kiểm dấu: ệ ữ ặ Ế Ộ Ỡ.',
            child: _TypeScale(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Nút',
            note: 'Hành động chính luôn nằm ở 1/3 dưới màn hình và chiếm '
                'trọn bề ngang. Vùng chạm tối thiểu 48×48dp.',
            child: _Buttons(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Dòng giao dịch',
            note: 'Bố cục dùng lại ở tab Lịch và màn hình Tìm kiếm.',
            child: _TransactionRows(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Thanh ngân sách',
            note: 'Ba ngưỡng: dưới 80% an toàn, 80–100% cảnh báo, '
                'trên 100% vượt.',
            child: _BudgetBars(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Ô danh mục',
            note: 'Lưới 4 cột × 3 hàng = 12 danh mục hiện cùng lúc, không cuộn. '
                'MoneyNote chỉ hiện được 6.',
            child: _CategoryGrid(),
          ),
          SizedBox(height: Tokens.xl),
          _Section(
            title: 'Trạng thái rỗng',
            note: 'Mọi màn hình phải có: icon nhạt + câu giải thích + nút '
                'hành động. Không bao giờ để màn hình trắng trơn.',
            child: _EmptyState(),
          ),
          SizedBox(height: Tokens.xxxl),
        ],
      ),
    );
  }
}

/// Khung một mục trong gallery: tiêu đề, ghi chú lý do, rồi đến nội dung.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.note,
    required this.child,
  });

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textTheme.titleMedium),
        const SizedBox(height: Tokens.xs),
        Text(
          note,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Tokens.md),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Tokens.lg),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ],
    );
  }
}

class _MoneySamples extends StatelessWidget {
  const _MoneySamples();

  @override
  Widget build(BuildContext context) {
    const amounts = [12450000, -3200000, 8000000, -50000, 999, 0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng tài sản', style: context.textTheme.labelSmall),
        MoneyText(12450000, style: context.textTheme.displaySmall),
        const SizedBox(height: Tokens.lg),
        for (final a in amounts)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MoneyText(
                  a,
                  signStyle: MoneySignStyle.signed,
                  style: context.textTheme.bodyMedium,
                ),
                MoneyText(
                  a,
                  compact: true,
                  signStyle: MoneySignStyle.signed,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  @override
  Widget build(BuildContext context) {
    final m = context.moneyColors;
    final cs = context.colorScheme;
    final items = <(String, Color)>[
      ('income', m.income),
      ('expense', m.expense),
      ('transfer', m.transfer),
      ('adjustment', m.adjustment),
      ('budgetSafe', m.budgetSafe),
      ('budgetWarn', m.budgetWarn),
      ('budgetOver', m.budgetOver),
      ('primary', cs.primary),
      ('secondary', cs.secondary),
      ('surfaceContainer', cs.surfaceContainer),
      ('outline', cs.outline),
    ];
    return Wrap(
      spacing: Tokens.md,
      runSpacing: Tokens.md,
      children: [
        for (final (name, color) in items)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: Tokens.xxxl,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: Tokens.brSm,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                const SizedBox(height: Tokens.xs),
                Text(name, style: context.textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.textTheme;
    final samples = <(String, TextStyle?)>[
      ('displaySmall 36 — số dư lớn', t.displaySmall),
      ('headlineSmall 24 — tiêu đề màn hình', t.headlineSmall),
      ('titleMedium 16 — tên danh mục', t.titleMedium),
      ('bodyMedium 14 — nội dung chính', t.bodyMedium),
      ('labelSmall 11 — nhãn phụ, ngày tháng', t.labelSmall),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, style) in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.sm),
            child: Text(label, style: style),
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: Tokens.minTouchTarget + Tokens.sm,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Nhập khoản Tiền chi'),
          ),
        ),
        const SizedBox(height: Tokens.md),
        Row(
          children: [
            OutlinedButton(onPressed: () {}, child: const Text('Huỷ')),
            const SizedBox(width: Tokens.md),
            TextButton(onPressed: () {}, child: const Text('Hoàn tác')),
          ],
        ),
        const SizedBox(height: Tokens.md),
        Wrap(
          spacing: Tokens.sm,
          children: [
            FilterChip(
              label: const Text('Tháng này'),
              selected: true,
              onSelected: (_) {},
            ),
            FilterChip(
              label: const Text('Tháng trước'),
              selected: false,
              onSelected: (_) {},
            ),
            FilterChip(
              label: const Text('Toàn kỳ'),
              selected: false,
              onSelected: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionRows extends StatelessWidget {
  const _TransactionRows();

  @override
  Widget build(BuildContext context) {
    final m = context.moneyColors;
    final rows = <(IconData, String, String, String, int, Color)>[
      (
        Icons.restaurant,
        'Ăn uống',
        'Cơm trưa văn phòng',
        'Tiền mặt',
        -50000,
        m.expense,
      ),
      (
        Icons.payments,
        'Tiền lương',
        'Lương tháng 8',
        'Vietcombank',
        18000000,
        m.income,
      ),
      (
        Icons.swap_horiz,
        'Chuyển ví',
        'Tiền mặt → MoMo',
        '',
        -500000,
        m.transfer,
      ),
      (
        Icons.tune,
        'Điều chỉnh',
        'Đếm lại ví tiền mặt',
        'Tiền mặt',
        -23000,
        m.adjustment,
      ),
    ];
    return Column(
      children: [
        for (final (icon, name, note, wallet, amount, color) in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: Tokens.minTouchTarget,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(name, style: context.textTheme.titleMedium),
            subtitle: Text(
              wallet.isEmpty ? note : '$note · $wallet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall,
            ),
            trailing: MoneyText(
              amount,
              signStyle: MoneySignStyle.signed,
              color: color,
              style: context.textTheme.titleMedium,
            ),
          ),
      ],
    );
  }
}

class _BudgetBars extends StatelessWidget {
  const _BudgetBars();

  @override
  Widget build(BuildContext context) {
    final m = context.moneyColors;
    final rows = <(String, int, int)>[
      ('Ăn uống', 1850000, 3000000),
      ('Đi lại', 880000, 1000000),
      ('Giải trí', 1400000, 1000000),
    ];
    return Column(
      children: [
        for (final (name, spent, budget) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: context.textTheme.titleMedium),
                    MoneyText(
                      budget - spent,
                      signStyle: MoneySignStyle.signed,
                      style: context.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: Tokens.sm),
                ClipRRect(
                  borderRadius: Tokens.brFull,
                  child: LinearProgressIndicator(
                    value: (spent / budget).clamp(0.0, 1.0),
                    minHeight: Tokens.sm,
                    backgroundColor: context.colorScheme.surfaceContainerHighest,
                    color: spent > budget
                        ? m.budgetOver
                        : spent / budget >= 0.8
                            ? m.budgetWarn
                            : m.budgetSafe,
                  ),
                ),
                const SizedBox(height: Tokens.xs),
                Text(
                  '${(spent * 100 / budget).round()}% · còn 12 ngày',
                  style: context.textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.restaurant, 'Ăn uống'),
      (Icons.shopping_basket_outlined, 'Hàng ngày'),
      (Icons.checkroom, 'Quần áo'),
      (Icons.face_retouching_natural, 'Mỹ phẩm'),
      (Icons.local_bar_outlined, 'Giao lưu'),
      (Icons.medical_services_outlined, 'Y tế'),
      (Icons.school_outlined, 'Giáo dục'),
      (Icons.bolt_outlined, 'Điện nước'),
      (Icons.directions_bus_outlined, 'Đi lại'),
      (Icons.phone_iphone, 'Liên lạc'),
      (Icons.home_outlined, 'Tiền nhà'),
      (Icons.edit_outlined, 'Chỉnh sửa'),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Tokens.sm,
      crossAxisSpacing: Tokens.sm,
      childAspectRatio: 0.95,
      children: [
        for (var i = 0; i < items.length; i++)
          _CategoryTile(
            icon: items[i].$1,
            label: items[i].$2,
            selected: i == 0,
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Material(
      color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: Tokens.brMd,
      child: InkWell(
        borderRadius: Tokens.brMd,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(Tokens.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              ),
              const SizedBox(height: Tokens.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color:
                      selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: Tokens.xxxl,
          color: context.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: Tokens.md),
        Text(
          'Chưa có giao dịch nào trong tháng 8.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: Tokens.lg),
        FilledButton.tonal(
          onPressed: () {},
          child: const Text('Ghi khoản chi đầu tiên'),
        ),
      ],
    );
  }
}
