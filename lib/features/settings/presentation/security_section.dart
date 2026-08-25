import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/money_colors.dart';
import 'app_lock_providers.dart';
import 'lock_screen.dart';
import 'notification_providers.dart';

/// Mục Bảo mật và Nhắc nhở trong tab Khác.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục J.
///
/// **Mọi công tắc ở đây đọc trạng thái qua provider phản ứng**, không dùng
/// `FutureBuilder`. Bài học từ lỗi thật: công tắc vân tay từng dùng
/// FutureBuilder nên bật xong phải thoát app vào lại mới thấy nó đổi.
class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daDatPin = ref.watch(pinIsSetProvider).value ?? false;

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          value: daDatPin,
          title: const Text('Khoá app bằng PIN'),
          subtitle: Text(
            daDatPin
                ? 'Phải nhập mã 4 số mỗi lần mở app'
                : 'Chặn người khác mở sổ khi cầm máy bạn',
          ),
          onChanged: (bat) async {
            if (bat) {
              await _datPin(context, ref);
            } else {
              await _goPin(context, ref);
            }
          },
        ),
        if (daDatPin) const _BiometricTile(),
        const _ReminderTile(),
      ],
    );
  }

  Future<void> _datPin(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => LockScreen(
          setupMode: true,
          onUnlocked: (pin) async {
            await ref.read(appLockProvider).setPin(pin);
            // Vừa gõ PIN xong ngay tại đây rồi, đừng để lớp khoá bật lên bắt
            // gõ lại lần nữa.
            ref.read(lockGateProvider.notifier).markUnlockedAfterSetup();
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  /// Gỡ khoá phải nhập đúng PIN hiện tại trước.
  ///
  /// Cho tắt khoá mà không cần xác thực thì cái khoá vô nghĩa: ai cầm được máy
  /// đang mở cũng tắt được nó.
  Future<void> _goPin(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => LockScreen(
          onUnlocked: (_) async {
            await ref.read(appLockProvider).removePin();
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }
}

class _BiometricTile extends ConsumerWidget {
  const _BiometricTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doCamBien = ref.watch(biometricAvailableProvider);
    final dangBat = ref.watch(biometricEnabledProvider).value ?? false;

    // Còn đang dò cảm biến — giữ chỗ, đừng để dòng nhảy vào rồi nhảy ra.
    if (doCamBien.isLoading) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Mở khoá bằng vân tay'),
        subtitle: Text('Đang kiểm tra cảm biến…'),
      );
    }

    final coCamBien = doCamBien.value ?? false;

    // Máy không dùng được vân tay thì vẫn hiện dòng này, chỉ làm mờ và nói rõ
    // vì sao. Bản trước ẩn hẳn nó đi — và đó chính là lỗi "bật vân tay không
    // được": không có gì để bấm, cũng không có câu nào giải thích.
    if (!coCamBien) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        enabled: false,
        title: Text('Mở khoá bằng vân tay'),
        subtitle: Text(
          'Máy chưa đăng ký vân tay hoặc khuôn mặt. Vào Cài đặt của điện '
          'thoại thêm vân tay rồi quay lại đây.',
        ),
      );
    }

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      value: dangBat,
      title: const Text('Mở khoá bằng vân tay'),
      subtitle: const Text('Vẫn nhập được PIN nếu vân tay hỏng'),
      // Không setState, không markNeedsBuild: ghi xuống settings rồi stream tự
      // đẩy giá trị mới về đây.
      onChanged: (v) =>
          ref.read(appLockProvider).setBiometricEnabled(enabled: v),
    );
  }
}

/// Nhắc ghi chi tiêu hằng ngày.
class _ReminderTile extends ConsumerWidget {
  const _ReminderTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Web không có thông báo cục bộ — ẩn hẳn thay vì hiện công tắc vô dụng.
    if (!NotificationService.isSupported) return const SizedBox.shrink();

    final bat = ref.watch(reminderEnabledProvider).value ?? false;
    final gio = ref.watch(reminderHourProvider).value ?? 21;
    final gioHienThi = gio.toString().padLeft(2, '0');

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          value: bat,
          title: const Text('Nhắc ghi chi tiêu hằng ngày'),
          subtitle: Text(
            bat ? 'Mỗi ngày lúc $gioHienThi:00' : 'Ghi đều mới có số liệu để nhìn',
          ),
          onChanged: (v) async {
            final xong = await ref
                .read(reminderControllerProvider.notifier)
                .setEnabled(enabled: v);
            if (!context.mounted || xong || !v) return;

            // Người dùng từ chối quyền thông báo. Im lặng sẽ khiến công tắc
            // bật lên rồi tự tắt mà không ai hiểu vì sao.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Chưa được cấp quyền thông báo. Vào Khác → Giữ app chạy nền '
                  'để bật lại.',
                ),
              ),
            );
          },
        ),
        if (bat)
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('Giờ nhắc'),
            trailing: Text(
              '$gioHienThi:00',
              style: context.textTheme.titleMedium,
            ),
            onTap: () async {
              final chon = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: gio, minute: 0),
              );
              if (chon != null) {
                await ref
                    .read(reminderControllerProvider.notifier)
                    .setHour(chon.hour);
              }
            },
          ),
      ],
    );
  }
}
