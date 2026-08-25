import 'package:flutter/material.dart';

/// Bảng tra icon dùng được trong app.
///
/// **Vì sao phải có file này thay vì gọi thẳng `IconData(codePoint)`:**
///
/// Schema lưu icon dưới dạng `codePoint` (số nguyên) để không phụ thuộc tên
/// icon — tên có thể đổi giữa các phiên bản Flutter, số thì không. Nhưng nếu
/// dựng `IconData(code, fontFamily: 'MaterialIcons')` lúc chạy thì Flutter mất
/// khả năng tree-shake font icon: nó không biết icon nào thực sự được dùng nên
/// `flutter build apk` sẽ dừng với lỗi *"This application cannot tree shake
/// icons fonts. It has non-constant instances of IconData"*. Cách chữa duy nhất
/// khi đó là `--no-tree-shake-icons`, khiến APK phồng thêm ~1MB font.
///
/// Giải pháp: giữ một danh sách `const` cố định. Mọi icon đều là hằng số nên
/// tree-shaking hoạt động, và việc giới hạn bộ icon cũng đúng với đặc tả —
/// `01_DAC_TA_TINH_NANG.md` bước 2 onboarding nói rõ "lưới 24 icon".
abstract final class AppIcons {
  /// Icon cho danh mục thu / chi.
  static const List<IconData> category = [
    Icons.restaurant,
    Icons.shopping_basket_outlined,
    Icons.checkroom,
    Icons.face_retouching_natural,
    Icons.local_bar_outlined,
    Icons.medical_services_outlined,
    Icons.school_outlined,
    Icons.bolt_outlined,
    Icons.directions_bus_outlined,
    Icons.phone_iphone,
    Icons.home_outlined,
    Icons.movie_outlined,
    Icons.account_balance_outlined,
    Icons.category_outlined,
    Icons.payments_outlined,
    Icons.card_giftcard_outlined,
    Icons.emoji_events_outlined,
    Icons.work_outline,
    Icons.trending_up,
    Icons.savings_outlined,
    Icons.pets_outlined,
    Icons.fitness_center_outlined,
    Icons.local_cafe_outlined,
    Icons.child_care_outlined,
  ];

  /// Icon cho ví.
  static const List<IconData> wallet = [
    Icons.payments_outlined,
    Icons.account_balance_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.credit_card_outlined,
    Icons.savings_outlined,
    Icons.phone_android_outlined,
    Icons.currency_exchange,
    Icons.wallet_outlined,
  ];

  /// Icon thay thế khi `codePoint` trong DB không nằm trong bảng tra — xảy ra
  /// nếu bản cũ của app từng lưu icon nay đã bỏ.
  static const IconData fallback = Icons.help_outline;

  /// `codePoint` → `IconData`. Dựng một lần lúc khởi động.
  static final Map<int, IconData> _byCodePoint = {
    for (final i in [...category, ...wallet]) i.codePoint: i,
  };

  /// Tra icon từ số lưu trong DB. Không bao giờ ném lỗi — icon sai chỉ là
  /// phiền mắt, không đáng làm sập màn hình.
  static IconData resolve(int codePoint) =>
      _byCodePoint[codePoint] ?? fallback;
}

/// Bảng màu dành cho danh mục và ví.
///
/// Cố định 12 màu thay vì cho chọn tự do: file `07_UI_UX.md` mục 6 bước 2 nói
/// thẳng — "mọi giao diện xấu đều xấu vì quá nhiều màu". Giới hạn bộ chọn là
/// cách rẻ nhất để giữ app trông có gu.
abstract final class AppPalette {
  static const List<Color> colors = [
    Color(0xFFE53935), // đỏ
    Color(0xFFD81B60), // hồng
    Color(0xFF8E24AA), // tím
    Color(0xFF5E35B1), // tím đậm
    Color(0xFF3949AB), // chàm
    Color(0xFF1E88E5), // xanh dương
    Color(0xFF00897B), // ngọc
    Color(0xFF43A047), // lục
    Color(0xFF7CB342), // lục nhạt
    Color(0xFFF9A825), // vàng
    Color(0xFFFB8C00), // cam
    Color(0xFF6D4C41), // nâu
  ];

  static Color at(int index) => colors[index % colors.length];
}
