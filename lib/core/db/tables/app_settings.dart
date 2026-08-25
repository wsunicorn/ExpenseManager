import 'package:drift/drift.dart';

/// Bảng khoá–giá trị cho mọi cài đặt.
/// Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.6.
///
/// Đặt tên lớp là `AppSettings` chứ không phải `Settings` để tên bảng sinh ra
/// không đụng từ khoá nào của SQLite.
///
/// Vì sao dùng bảng thay vì `shared_preferences`: cài đặt nằm cùng file DB nên
/// backup `.zip` chỉ cần một file là đủ, restore không bao giờ lệch pha giữa
/// dữ liệu và cấu hình. `shared_preferences` chỉ dùng làm cầu nối sang widget
/// màn hình chính (Phase 8).
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 64)();

  /// Mọi giá trị lưu dạng chuỗi. Bên gọi tự ép kiểu — số ít và đơn giản nên
  /// không đáng dựng cơ chế kiểu tổng quát.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Khoá cài đặt đã dùng. Gom vào một chỗ để không gõ sai chuỗi rải rác.
abstract final class SettingKeys {
  /// `'true'` sau khi chạy xong onboarding (file 01 mục A).
  static const String onboardingDone = 'onboarding_done';

  /// Tên của `ThemeMode`: `'system'` / `'light'` / `'dark'`.
  static const String themeMode = 'theme_mode';

  /// Ngày bắt đầu kỳ tài chính, 1–28. Mặc định `'1'`.
  ///
  /// Người lĩnh lương ngày 25 có thể đổi để báo cáo tính đúng chu kỳ của họ
  /// (file 01 mục J). Giới hạn 28 để tháng nào cũng tồn tại ngày đó.
  static const String monthStartDay = 'month_start_day';

  /// `'1'` = Thứ 2, `'7'` = Chủ nhật.
  static const String weekStartDay = 'week_start_day';

  /// Ví được chọn ở lần nhập gần nhất, để mặc định sẵn cho lần sau.
  static const String lastUsedWalletId = 'last_used_wallet_id';

  /// Màu chủ đề đang chọn (tên của `FlexScheme`).
  static const String colorScheme = 'color_scheme';
}
