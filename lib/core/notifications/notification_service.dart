import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/money.dart';

/// Thông báo cục bộ: cảnh báo ngân sách và nhắc nhập chi tiêu.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục E.3 và mục J.
///
/// **Chỉ chạy trên Android.** Trên web mọi hàm ở đây trở thành no-op thay vì
/// ném lỗi — app vẫn phải dùng được khi xem thử bằng trình duyệt, và một tính
/// năng không có sẵn thì nên im lặng vắng mặt chứ không nên làm sập màn hình.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _timezoneReady = false;

  /// Nền tảng có hỗ trợ thông báo cục bộ không.
  static bool get isSupported => !kIsWeb;

  /// Id cố định cho hai thông báo dùng lại nhiều lần. Đặt ở vùng số cao để
  /// không đụng id ngân sách (vốn lấy theo id dòng trong DB).
  static const int _idRecurringDue = 900001;
  static const int _idDailyReminder = 900002;

  static const _budgetChannel = AndroidNotificationDetails(
    'budget_alerts',
    'Cảnh báo ngân sách',
    channelDescription: 'Báo khi một danh mục chạm 80% và 100% hạn mức',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'daily_reminder',
    'Nhắc ghi chi tiêu',
    channelDescription: 'Nhắc nhập chi tiêu hằng ngày',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> init() async {
    if (!isSupported) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  /// Nạp cơ sở dữ liệu múi giờ và đặt múi giờ địa phương.
  ///
  /// `zonedSchedule` cần biết múi giờ thật của máy, nếu không lời nhắc 21:00
  /// sẽ nổ theo giờ UTC — lệch 7 tiếng ở Việt Nam.
  Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;

    tz_data.initializeTimeZones();
    try {
      // getLocalTimezone trả về TimezoneInfo, không phải String.
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception {
      // Không đọc được múi giờ máy — lùi về giờ Việt Nam, vì app chỉ có một
      // người dùng và người đó ở Việt Nam.
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
    _timezoneReady = true;
  }

  /// Xin quyền `POST_NOTIFICATIONS` — bắt buộc từ Android 13.
  ///
  /// Trả `false` khi người dùng từ chối. App vẫn phải chạy bình thường khi bị
  /// từ chối: thông báo là tiện ích, không phải điều kiện để dùng app.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Cảnh báo một danh mục vừa chạm ngưỡng ngân sách.
  ///
  /// `id` lấy theo id ngân sách để mỗi khoản chỉ chiếm một thông báo — bắn
  /// thông báo mới cho cùng một khoản sẽ thay thế cái cũ thay vì chất đống.
  Future<void> showBudgetAlert({
    required int budgetId,
    required String categoryName,
    required int spent,
    required int limit,
    required bool isOver,
  }) async {
    if (!isSupported) return;

    await _plugin.show(
      id: budgetId,
      title: isOver
          ? 'Vượt ngân sách $categoryName'
          : 'Sắp hết ngân sách $categoryName',
      body: isOver
          ? 'Đã chi ${formatMoney(spent)} / ${formatMoney(limit)}.'
          : 'Đã dùng ${(spent * 100 / limit).round()}% hạn mức '
              '(${formatMoney(spent)} / ${formatMoney(limit)}).',
      notificationDetails: const NotificationDetails(android: _budgetChannel),
    );
  }

  /// Thông báo khoản định kỳ đến hạn cần xác nhận.
  Future<void> showRecurringDue({required int count}) async {
    if (!isSupported) return;

    await _plugin.show(
      id: _idRecurringDue,
      title: 'Khoản định kỳ đến hạn',
      body: 'Có $count khoản chờ bạn xác nhận số tiền.',
      notificationDetails: const NotificationDetails(android: _reminderChannel),
    );
  }

  /// Nhắc nhập chi tiêu hằng ngày vào đúng giờ đã chọn.
  ///
  /// Dùng `zonedSchedule` + `DateTimeComponents.time`: hệ điều hành tự lặp lại
  /// vào đúng giờ đó mỗi ngày. Tự hẹn giờ trong app thì không chạy được, vì
  /// app không sống nền — trên MIUI thì giả định an toàn là app **không bao
  /// giờ** chạy nền.
  ///
  /// `inexactAllowWhileIdle` chứ không phải `exactAllowWhileIdle`: báo đúng
  /// giờ tuyệt đối cần quyền `SCHEDULE_EXACT_ALARM`, mà Android 14 đã siết rất
  /// chặt. Với một lời nhắc ghi chi tiêu thì lệch vài phút không hề gì — không
  /// đáng đánh đổi một quyền nhạy cảm.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!isSupported) return;
    await _ensureTimezone();
    await cancelDailyReminder();

    await _plugin.zonedSchedule(
      id: _idDailyReminder,
      scheduledDate: _nextInstanceOf(hour, minute),
      title: 'Ghi chi tiêu hôm nay',
      body: 'Vài giây thôi — ghi đều mới có số liệu để nhìn.',
      notificationDetails: const NotificationDetails(android: _reminderChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Lần kế tiếp mà đồng hồ chỉ đúng [hour]:[minute].
  ///
  /// Nếu hôm nay đã qua giờ đó rồi thì nhảy sang ngày mai — hẹn vào quá khứ
  /// sẽ khiến thông báo nổ ngay lập tức.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final bayGio = tz.TZDateTime.now(tz.local);
    var moc = tz.TZDateTime(
      tz.local,
      bayGio.year,
      bayGio.month,
      bayGio.day,
      hour,
      minute,
    );
    if (!moc.isAfter(bayGio)) {
      moc = moc.add(const Duration(days: 1));
    }
    return moc;
  }

  Future<void> cancelDailyReminder() async {
    if (!isSupported) return;
    await _plugin.cancel(id: _idDailyReminder);
  }
}
