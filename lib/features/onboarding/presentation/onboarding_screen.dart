import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/tables/app_settings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../wallet/presentation/wallet_form_sheet.dart';
import '../../wallet/presentation/wallet_providers.dart';
import 'onboarding_providers.dart';

/// Onboarding lần mở app đầu tiên. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục A.
///
/// Bốn bước, **bước 2 không được bỏ qua**: không có ví thì không ghi được gì.
///
/// Bước 2 cũng là điểm khác biệt lớn nhất so với MoneyNote — nó hỏi bạn **đang
/// có bao nhiêu tiền**, chứ không bắt đầu đếm từ 0 như thể bạn vừa sinh ra.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    _pageCtrl.nextPage(duration: Tokens.short, curve: Curves.easeInOutCubic);
  }

  Future<void> _finish() async {
    await ref
        .read(settingsRepositoryProvider)
        .write(SettingKeys.onboardingDone, 'true');

    // Đồng bộ cờ trong bộ nhớ TRƯỚC khi điều hướng. Thiếu dòng này thì
    // `redirect` của router vẫn thấy cờ cũ và đá ngược về đây ngay lập tức.
    setOnboardingCompleted(completed: true);

    if (mounted) context.go(AppRoutes.entry);
  }

  @override
  Widget build(BuildContext context) {
    final coVi = (ref.watch(walletListProvider()).value ?? const []).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                // Chặn vuốt qua bước 2 khi chưa có ví.
                physics: _page == 1 && !coVi
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  const _StepWelcome(),
                  _StepWallet(hasWallet: coVi),
                  const _StepCategories(),
                  const _StepPreferences(),
                ],
              ),
            ),
            _Footer(
              page: _page,
              canAdvance: _page != 1 || coVi,
              onNext: _next,
              onFinish: _finish,
              onSkip: _page == 1 ? null : _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepWelcome extends StatelessWidget {
  const _StepWelcome();

  @override
  Widget build(BuildContext context) {
    return const _StepFrame(
      icon: Icons.account_balance_wallet,
      title: 'Sổ thu chi',
      body: 'Offline hoàn toàn. Không quảng cáo.\n'
          'Dữ liệu nằm trên máy bạn, không gửi đi đâu cả.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bullet('Nhiều ví, có số dư gốc thật'),
          _Bullet('Bàn phím số có phép tính'),
          _Bullet('Báo cáo kèm câu diễn giải, không chỉ biểu đồ'),
          _Bullet('Xuất CSV, Excel, sao lưu — không khoá tính năng nào'),
        ],
      ),
    );
  }
}

class _StepWallet extends ConsumerWidget {
  const _StepWallet({required this.hasWallet});

  final bool hasWallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletListProvider()).value ?? const [];

    return _StepFrame(
      icon: Icons.savings_outlined,
      title: 'Ví đầu tiên',
      body: 'Khai số tiền bạn đang thực sự có. Mọi khoản thu chi sau này sẽ '
          'được cộng trừ từ con số đó.\n\n'
          'Đây là thứ MoneyNote không có — nó chỉ đếm từ 0, nên không bao giờ '
          'cho bạn biết mình đang có bao nhiêu.',
      child: Column(
        children: [
          for (final w in wallets)
            Card(
              margin: const EdgeInsets.only(bottom: Tokens.sm),
              child: ListTile(
                leading: Icon(
                  AppIcons.resolve(w.wallet.iconCode),
                  color: Color(w.wallet.colorValue),
                ),
                title: Text(w.wallet.name),
                subtitle: Text(formatMoney(w.balance)),
              ),
            ),
          const SizedBox(height: Tokens.md),
          SizedBox(
            width: double.infinity,
            height: Tokens.minTouchTarget,
            child: hasWallet
                ? OutlinedButton.icon(
                    onPressed: () => WalletFormSheet.show(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm ví nữa'),
                  )
                : FilledButton.icon(
                    onPressed: () => WalletFormSheet.show(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo ví đầu tiên'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepCategories extends ConsumerWidget {
  const _StepCategories();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepFrame(
      icon: Icons.category_outlined,
      title: 'Danh mục',
      body: 'App đã có sẵn 20 danh mục thông dụng — 14 khoản chi, 6 khoản thu. '
          'Dùng ngay được, sửa lúc nào cũng được trong tab Khác.',
      child: Wrap(
        spacing: Tokens.sm,
        runSpacing: Tokens.sm,
        children: [
          for (final c in [
            'Ăn uống',
            'Đi lại',
            'Tiền nhà',
            'Tiền điện nước',
            'Y tế',
            'Giải trí',
            'Tiền lương',
            'Đầu tư',
          ])
            Chip(label: Text(c)),
          const Chip(label: Text('và 12 mục nữa…')),
        ],
      ),
    );
  }
}

class _StepPreferences extends ConsumerWidget {
  const _StepPreferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);

    return _StepFrame(
      icon: Icons.tune,
      title: 'Vài tuỳ chọn',
      body: 'Đổi lại lúc nào cũng được trong tab Khác.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giao diện', style: context.textTheme.labelSmall),
          const SizedBox(height: Tokens.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Sáng')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Tối')),
              ButtonSegment(value: ThemeMode.system, label: Text('Hệ thống')),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(s.first),
          ),
          const SizedBox(height: Tokens.xl),
          const _MonthStartDayPicker(),
        ],
      ),
    );
  }
}

/// Ngày bắt đầu kỳ tài chính — cho người lĩnh lương giữa tháng.
class _MonthStartDayPicker extends ConsumerWidget {
  const _MonthStartDayPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ngay = ref.watch(monthStartDayProvider).value ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kỳ tài chính bắt đầu ngày', style: context.textTheme.labelSmall),
        const SizedBox(height: Tokens.sm),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: ngay.toDouble(),
                min: 1,
                max: 28,
                divisions: 27,
                label: '$ngay',
                onChanged: (v) => ref
                    .read(settingsRepositoryProvider)
                    .write(SettingKeys.monthStartDay, v.round().toString()),
              ),
            ),
            SizedBox(
              width: Tokens.xxl,
              child: Text('$ngay', style: context.textTheme.titleMedium),
            ),
          ],
        ),
        Text(
          ngay == 1
              ? 'Trùng tháng dương lịch.'
              : 'Kỳ chạy từ ngày $ngay tháng này tới ngày ${ngay - 1} tháng sau '
                  '— hợp với người lĩnh lương giữa tháng.',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Tokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Tokens.xl),
          Icon(icon, size: Tokens.xxxl, color: context.colorScheme.primary),
          const SizedBox(height: Tokens.xl),
          Text(title, style: context.textTheme.displaySmall),
          const SizedBox(height: Tokens.md),
          Text(
            body,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.xl),
          child,
          const SizedBox(height: Tokens.xxl),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 18, color: context.moneyColors.income),
          const SizedBox(width: Tokens.md),
          Expanded(
            child: Text(text, style: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.page,
    required this.canAdvance,
    required this.onNext,
    required this.onFinish,
    required this.onSkip,
  });

  final int page;
  final bool canAdvance;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  /// Null ở bước 2 — bước đó không được bỏ qua.
  final VoidCallback? onSkip;

  static const _lastPage = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.screenPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i <= _lastPage; i++)
                AnimatedContainer(
                  duration: Tokens.short,
                  margin: const EdgeInsets.symmetric(horizontal: Tokens.xs),
                  width: i == page ? Tokens.xl : Tokens.sm,
                  height: Tokens.sm,
                  decoration: BoxDecoration(
                    color: i == page
                        ? context.colorScheme.primary
                        : context.colorScheme.outlineVariant,
                    borderRadius: Tokens.brFull,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Tokens.lg),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                child: const Text('Bỏ qua'),
              ),
              const Spacer(),
              SizedBox(
                height: Tokens.minTouchTarget + Tokens.sm,
                child: FilledButton(
                  onPressed: canAdvance
                      ? (page == _lastPage ? onFinish : () {
                          HapticFeedback.selectionClick();
                          onNext();
                        })
                      : null,
                  child: Text(page == _lastPage ? 'Xong' : 'Tiếp tục'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
