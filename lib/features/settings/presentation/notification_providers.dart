import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_service.dart';
import '../../onboarding/presentation/onboarding_providers.dart';
import 'app_lock_providers.dart';

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) =>
    NotificationService(FlutterLocalNotificationsPlugin());

/// Đã bật nhắc hằng ngày chưa.
@riverpod
Stream<bool> reminderEnabled(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(LockKeys.reminderEnabled)
    .map((v) => v == 'true');

/// Giờ nhắc, mặc định 21:00 như đặc tả mục A bước 4.
@riverpod
Stream<int> reminderHour(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(LockKeys.reminderHour)
    .map((v) => int.tryParse(v ?? '21')?.clamp(0, 23) ?? 21);

/// Bật/tắt và đặt giờ nhắc.
@riverpod
class ReminderController extends _$ReminderController {
  @override
  void build() {}

  Future<void> setEnabled(bool enabled) async {
    final settings = ref.read(settingsRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);

    if (enabled) {
      // Xin quyền trước khi ghi cờ: người dùng từ chối mà cờ vẫn bật thì công
      // tắc nói dối — nó bật nhưng chẳng bao giờ có thông báo nào.
      final duocPhep = await notif.requestPermission();
      if (!duocPhep) return;

      final gio = int.tryParse(
            await settings.read(LockKeys.reminderHour) ?? '21',
          ) ??
          21;
      await notif.scheduleDailyReminder(hour: gio, minute: 0);
    } else {
      await notif.cancelDailyReminder();
    }

    await settings.write(LockKeys.reminderEnabled, enabled.toString());
  }

  Future<void> setHour(int hour) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.write(LockKeys.reminderHour, hour.toString());

    // Đặt lại lịch ngay nếu đang bật.
    if (await settings.read(LockKeys.reminderEnabled) == 'true') {
      await ref
          .read(notificationServiceProvider)
          .scheduleDailyReminder(hour: hour, minute: 0);
    }
  }
}
