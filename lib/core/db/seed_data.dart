import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../utils/text_search.dart';
import 'database.dart';
import 'enums.dart';
import 'tables/app_settings.dart';

/// Dữ liệu chèn sẵn khi DB được tạo lần đầu.
///
/// Bộ danh mục lấy đúng từ `ke-hoach-app/01_DAC_TA_TINH_NANG.md` mục F.1 —
/// bám theo MoneyNote, bổ sung "Giải trí" và "Phí ngân hàng".
///
/// "Phí ngân hàng" không phải danh mục trang trí: khi chuyển ví có phí, phần
/// phí được ghi thành một giao dịch chi thuộc danh mục này (file 01 mục B.3).
abstract final class SeedData {
  /// 14 danh mục chi.
  static const List<(String, IconData, int)> expenseCategories = [
    ('Ăn uống', Icons.restaurant, 0),
    ('Chi tiêu hàng ngày', Icons.shopping_basket_outlined, 1),
    ('Quần áo', Icons.checkroom, 2),
    ('Mỹ phẩm', Icons.face_retouching_natural, 3),
    ('Phí giao lưu', Icons.local_bar_outlined, 4),
    ('Y tế', Icons.medical_services_outlined, 5),
    ('Giáo dục', Icons.school_outlined, 6),
    ('Tiền điện nước', Icons.bolt_outlined, 9),
    ('Đi lại', Icons.directions_bus_outlined, 5),
    ('Phí liên lạc', Icons.phone_iphone, 4),
    ('Tiền nhà', Icons.home_outlined, 11),
    ('Giải trí', Icons.movie_outlined, 2),
    ('Phí ngân hàng', Icons.account_balance_outlined, 10),
    ('Khác', Icons.category_outlined, 11),
  ];

  /// 6 danh mục thu.
  static const List<(String, IconData, int)> incomeCategories = [
    ('Tiền lương', Icons.payments_outlined, 7),
    ('Tiền phụ cấp', Icons.card_giftcard_outlined, 8),
    ('Tiền thưởng', Icons.emoji_events_outlined, 9),
    ('Thu nhập phụ', Icons.work_outline, 6),
    ('Đầu tư', Icons.trending_up, 5),
    ('Thu nhập khác', Icons.savings_outlined, 11),
  ];

  /// Chèn toàn bộ danh mục mặc định. Gọi trong `onCreate` của migration.
  ///
  /// `sortOrder` được đánh theo đúng thứ tự trong đặc tả — người dùng kéo thả
  /// đổi lại sau cũng được, nhưng lần đầu mở app phải giống bản đặc tả để đối
  /// chiếu được với MoneyNote.
  static Future<void> insertDefaultCategories(AppDatabase db) async {
    await db.batch((batch) {
      var order = 0;
      for (final (name, icon, colorIndex) in expenseCategories) {
        batch.insert(
          db.categories,
          CategoriesCompanion.insert(
            name: name,
            nameAscii: Value(normalizeForSearch(name)),
            type: CategoryType.expense,
            iconCode: icon.codePoint,
            colorValue: AppPalette.at(colorIndex).toARGB32(),
            sortOrder: Value(order++),
          ),
        );
      }

      order = 0;
      for (final (name, icon, colorIndex) in incomeCategories) {
        batch.insert(
          db.categories,
          CategoriesCompanion.insert(
            name: name,
            nameAscii: Value(normalizeForSearch(name)),
            type: CategoryType.income,
            iconCode: icon.codePoint,
            colorValue: AppPalette.at(colorIndex).toARGB32(),
            sortOrder: Value(order++),
          ),
        );
      }
    });
  }

  /// Cài đặt mặc định. Ghi lúc tạo DB để phần còn lại của app luôn đọc được
  /// giá trị, không phải xử lý trường hợp "chưa có khoá này".
  static Future<void> insertDefaultSettings(AppDatabase db) async {
    await db.batch((batch) {
      batch.insertAll(db.appSettings, const [
        AppSettingsCompanion(
          key: Value(SettingKeys.onboardingDone),
          value: Value('false'),
        ),
        AppSettingsCompanion(
          key: Value(SettingKeys.themeMode),
          value: Value('system'),
        ),
        // Ngày 1: kỳ tài chính trùng tháng dương lịch. Ai lĩnh lương ngày 25
        // thì đổi trong Cài đặt (file 01 mục J).
        AppSettingsCompanion(
          key: Value(SettingKeys.monthStartDay),
          value: Value('1'),
        ),
        // Thứ 2 — tuần bắt đầu như lịch Việt Nam.
        AppSettingsCompanion(
          key: Value(SettingKeys.weekStartDay),
          value: Value('1'),
        ),
      ]);
    });
  }
}
