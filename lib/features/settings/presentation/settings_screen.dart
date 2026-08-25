import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/tables/app_settings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/providers/color_scheme_provider.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../../shared/widgets/money_text.dart';
import '../../backup/presentation/backup_section.dart';
import '../../onboarding/presentation/onboarding_providers.dart';
import '../../wallet/presentation/wallet_providers.dart';
import 'security_section.dart';

/// Tab "Khác". Đặc tả: `01_DAC_TA_TINH_NANG.md` mục J.
///
/// MoneyNote nhét 9 mục quảng cáo app khác vào đây. Tab này chỉ có cài đặt thật.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    final total = ref.watch(totalBalanceProvider);
    final wallets = ref.watch(walletListProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('Khác')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(Tokens.screenPadding),
            child: Card(
              margin: EdgeInsets.zero,
              color: context.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(Tokens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng tài sản',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: Tokens.xs),
                    MoneyText(
                      total.value ?? 0,
                      style: context.textTheme.displaySmall?.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: Tokens.xs),
                    Text(
                      '${wallets.value?.length ?? 0} ví đang hoạt động',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const _SectionHeader('Quản lý'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ví'),
            subtitle: const Text('Thêm, sửa, điều chỉnh số dư, lưu trữ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.wallets),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Danh mục'),
            subtitle: const Text('Thêm, sửa, đổi icon, kéo thả sắp xếp'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.categories),
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat_outlined),
            title: const Text('Khoản định kỳ'),
            subtitle: const Text('Tiền nhà, tiền điện, phí Internet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.recurring),
          ),

          const _SectionHeader('Giao diện'),
          ListTile(
            leading: Icon(switch (mode) {
              ThemeMode.system => Icons.brightness_auto_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
            }),
            title: const Text('Chế độ hiển thị'),
            subtitle: Text(switch (mode) {
              ThemeMode.system => 'Theo hệ thống',
              ThemeMode.light => 'Sáng',
              ThemeMode.dark => 'Tối',
            }),
            onTap: () => ref.read(themeModeControllerProvider.notifier).cycle(),
          ),
          const _ColorSchemePicker(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Hệ thống thiết kế'),
            subtitle: const Text(
              'Bảng tra cứu nội bộ: màu, chữ, component ở cả hai chế độ',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.designGallery),
          ),

          const _SectionHeader('Bảo mật & nhắc nhở'),
          const SecuritySection(),

          ListTile(
            leading: const Icon(Icons.battery_saver_outlined),
            title: const Text('Giữ app chạy nền'),
            subtitle: const Text(
              'Cần cho MIUI/Xiaomi — nếu lời nhắc không đến thì vào đây',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.backgroundGuide),
          ),

          const _SectionHeader('Dữ liệu'),
          const BackupSection(),

          const _SectionHeader('Khác'),
          ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: const Text('Chạy lại hướng dẫn'),
            subtitle: const Text('Xem lại 4 bước giới thiệu'),
            onTap: () async {
              await ref
                  .read(settingsRepositoryProvider)
                  .write(SettingKeys.onboardingDone, 'false');
              if (context.mounted) context.go(AppRoutes.onboarding);
            },
          ),

          const SizedBox(height: Tokens.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.screenPadding,
            ),
            child: Text(
              'Sổ thu chi · offline hoàn toàn · không quảng cáo\n'
              'Dữ liệu nằm trên máy bạn, không gửi đi đâu cả.',
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: Tokens.xxl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.screenPadding,
        Tokens.lg,
        Tokens.screenPadding,
        Tokens.sm,
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Sáu màu chủ đề. Đặc tả `01_DAC_TA_TINH_NANG.md` mục J.
///
/// Giới hạn sáu lựa chọn chứ không cho chọn màu tự do: `07_UI_UX.md` mục 6
/// bước 2 nói thẳng — "mọi giao diện xấu đều xấu vì quá nhiều màu". Sáu bảng
/// màu dựng sẵn của flex_color_scheme đều đã được phối tử tế và có sẵn bản
/// tối khớp.
class _ColorSchemePicker extends ConsumerWidget {
  const _ColorSchemePicker();

  static const _luaChon = <(String, FlexScheme)>[
    ('Đỏ rượu vang', FlexScheme.redWine),
    ('Đỏ tươi', FlexScheme.red),
    ('Xanh dương', FlexScheme.brandBlue),
    ('Xanh lục', FlexScheme.money),
    ('Tím', FlexScheme.deepPurple),
    ('Cam', FlexScheme.mango),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hienTai = ref.watch(colorSchemeControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.screenPadding,
        Tokens.sm,
        Tokens.screenPadding,
        Tokens.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Màu chủ đề', style: context.textTheme.labelSmall),
          const SizedBox(height: Tokens.sm),
          Wrap(
            spacing: Tokens.sm,
            runSpacing: Tokens.sm,
            children: [
              for (final (ten, scheme) in _luaChon)
                ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor:
                        FlexColor.schemesWithCustom[scheme]!.light.primary,
                    radius: 10,
                  ),
                  label: Text(ten),
                  selected: hienTai == scheme,
                  onSelected: (_) => ref
                      .read(colorSchemeControllerProvider.notifier)
                      .setScheme(scheme),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
