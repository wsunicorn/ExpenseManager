import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/money.dart';

/// Cầu nối dữ liệu sang widget màn hình chính.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục I.
///
/// **Widget không đọc SQLite.** Tiến trình widget chạy trong launcher, tách
/// biệt với app; mở database từ đó vừa chậm vừa dễ tranh khoá file. Thay vào
/// đó phía Dart tính sẵn vài chuỗi rồi ghi vào SharedPreferences dùng chung,
/// Kotlin chỉ đọc ra và vẽ.
///
/// Đổi lại: widget hiển thị số của lần cập nhật gần nhất. Với một widget xem
/// nhanh thì đó là đánh đổi đúng — và [update] được gọi sau mỗi lần dữ liệu
/// đổi nên độ trễ gần như không thấy được.
class HomeWidgetService {
  HomeWidgetService(this._db);

  final AppDatabase _db;

  /// Widget chỉ có trên Android.
  static bool get isSupported => !kIsWeb;

  /// Tên lớp `AppWidgetProvider` bên Kotlin.
  static const String _androidProvider = 'BalanceWidgetProvider';

  /// Tính lại các con số và đẩy sang widget.
  ///
  /// Gọi sau mỗi lần lưu, sửa, xoá giao dịch và mỗi khi app vào nền.
  Future<void> update() async {
    if (!isSupported) return;

    try {
      final tongTaiSan = await _db.walletDao.watchTotalBalance().first;

      final homNay = dateOnly(DateTime.now());
      final ngayNay = await _db.transactionDao
          .watchTotals(homNay, homNay)
          .first;

      final thang = calendarMonthOf(homNay);
      final thangNay = await _db.transactionDao
          .watchTotals(thang.start, thang.end)
          .first;

      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        formatMoney(tongTaiSan),
      );
      await HomeWidget.saveWidgetData<String>(
        'today_expense',
        'Hôm nay $kMinusSign${formatCompact(ngayNay.expense)} đ',
      );
      await HomeWidget.saveWidgetData<String>(
        'month_summary',
        'Tháng này  +${formatCompact(thangNay.income)}  '
        '$kMinusSign${formatCompact(thangNay.expense)}',
      );

      await HomeWidget.updateWidget(name: _androidProvider);
    } on Exception {
      // Widget hỏng không được làm sập app. Người dùng vẫn ghi chi tiêu được
      // kể cả khi launcher từ chối cập nhật.
    }
  }
}
