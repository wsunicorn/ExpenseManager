import 'package:flutter/widgets.dart';

/// Design token của app — nguồn chân lý duy nhất cho khoảng cách, bo góc,
/// thời lượng animation. Đặc tả: `ke-hoach-app/07_UI_UX.md` mục 2.
///
/// Quy tắc: **không hardcode số trong widget**. Nếu cần một giá trị chưa có ở
/// đây, thêm token mới chứ đừng gõ số trực tiếp — nếu không, sau này đổi một
/// chỗ sẽ phải đi sửa 200 chỗ.
///
/// `abstract final class` là cú pháp Dart 3: lớp không thể tạo instance, cũng
/// không thể kế thừa. Dùng nó thay cho một đống biến toàn cục rời rạc.
abstract final class Tokens {
  // ── Khoảng cách — thang 4dp (file 07 mục 2.1) ─────────────────────────────
  /// 4dp — khe hở nhỏ nhất, giữa icon và nhãn.
  static const double xs = 4;

  /// 8dp — trong chip, giữa hai dòng chữ liên quan.
  static const double sm = 8;

  /// 12dp — giữa các thẻ trong danh sách.
  static const double md = 12;

  /// 16dp — lề màn hình, padding trong thẻ.
  static const double lg = 16;

  /// 24dp — giữa các nhóm nội dung khác nhau.
  static const double xl = 24;

  /// 32dp — trên/dưới một khối lớn.
  static const double xxl = 32;

  /// 48dp — khoảng trống lớn, trạng thái rỗng.
  static const double xxxl = 48;

  /// Lề trái/phải của mọi màn hình.
  static const double screenPadding = lg;

  // ── Bo góc (file 07 mục 2.2) ──────────────────────────────────────────────
  /// Chip, ô nhỏ.
  static const double radiusSm = 8;

  /// Thẻ, ô danh mục.
  static const double radiusMd = 16;

  /// Bottom sheet, nút lớn. M3 dùng bo góc lớn — đừng dùng 4px.
  static const double radiusLg = 28;

  /// Chip lọc, nút tròn.
  static const double radiusFull = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brFull =
      BorderRadius.all(Radius.circular(radiusFull));

  /// Bo góc chỉ ở hai mép trên — dùng cho bottom sheet.
  static const BorderRadius brSheetTop = BorderRadius.vertical(
    top: Radius.circular(radiusLg),
  );

  // ── Chuyển động (file 07 mục 4) ───────────────────────────────────────────
  // Quy tắc cứng: không animation nào vượt 400ms, trừ biểu đồ vẽ lần đầu.
  /// Phản hồi chạm: ripple, scale.
  static const Duration tap = Duration(milliseconds: 100);

  /// Chuyển tab, hiện/ẩn.
  static const Duration short = Duration(milliseconds: 200);

  /// Chuyển màn hình.
  static const Duration screen = Duration(milliseconds: 250);

  /// Bottom sheet trượt lên.
  static const Duration sheet = Duration(milliseconds: 300);

  /// Số đếm lên khi số dư thay đổi.
  static const Duration counter = Duration(milliseconds: 400);

  /// Ngoại lệ duy nhất được vượt 400ms: biểu đồ vẽ lần đầu. Chạy **một lần**.
  static const Duration chart = Duration(milliseconds: 700);

  // ── Khả năng tiếp cận (file 07 mục 5) ─────────────────────────────────────
  /// Vùng chạm tối thiểu. Ô nào nhỏ hơn phải bọc `SizedBox` cho đủ.
  static const double minTouchTarget = 48;

  /// Chiều cao ô danh mục trong lưới 4 cột.
  static const double categoryTileHeight = 72;
}
