import 'package:flutter/material.dart';

/// Màu theo **vai trò ngữ nghĩa**, không theo tên màu.
/// Đặc tả: `ke-hoach-app/07_UI_UX.md` mục 2.3.
///
/// Trong widget không bao giờ gọi `Colors.red`. Gọi `context.moneyColors.expense`.
/// Lý do: đổi bảng màu hoặc bật dark mode chỉ phải sửa ở đây, không phải đi
/// lùng 200 chỗ.
///
/// `ThemeExtension` là cơ chế chính thức của Flutter để gắn thêm token màu của
/// riêng app vào `ThemeData`, và nó tự nội suy khi chuyển sáng↔tối.
///
/// **Quy ước Việt Nam**: trong chứng khoán Việt đỏ = tăng, xanh = giảm — ngược
/// phương Tây. Nhưng trong app sổ thu chi, quy ước phổ biến (và MoneyNote đang
/// dùng) là **đỏ = chi, xanh = thu**. Giữ nguyên để không phải học lại.
///
/// Dù vậy, **màu không bao giờ là phương tiện truyền tin duy nhất** — số tiền
/// luôn kèm dấu `+` / `−` (xem `formatSigned` trong `core/utils/money.dart`).
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.adjustment,
    required this.incomeSurface,
    required this.expenseSurface,
    required this.budgetSafe,
    required this.budgetWarn,
    required this.budgetOver,
  });

  /// Thu nhập. Dùng cho số tiền, biểu đồ, chấm trên ô lịch.
  final Color income;

  /// Chi tiêu.
  final Color expense;

  /// Chuyển ví — trung tính, vì không phải thu cũng không phải chi.
  final Color transfer;

  /// Điều chỉnh số dư. Cũng trung tính nhưng khác sắc với chuyển ví.
  final Color adjustment;

  /// Nền nhạt cho chip / huy hiệu thu nhập.
  final Color incomeSurface;

  /// Nền nhạt cho chip / huy hiệu chi tiêu.
  final Color expenseSurface;

  /// Ngân sách dùng dưới 80%.
  final Color budgetSafe;

  /// Ngân sách dùng 80–100%.
  final Color budgetWarn;

  /// Ngân sách vượt 100%.
  final Color budgetOver;

  /// Bảng màu chế độ sáng. Mọi màu đã kiểm tương phản ≥ 4.5:1 trên nền sáng
  /// của Material 3 (yêu cầu ở file 07 mục 5).
  static const MoneyColors light = MoneyColors(
    // Xanh duong chu khong phai xanh luc: `07_UI_UX.md` muc 2.3 cho phep ca
    // hai, va MoneyNote dung xanh duong. Chu du an dung MoneyNote nhieu nam
    // nen giu mau quen mat, khong bat hoc lai.
    income: Color(0xFF1565C0),
    expense: Color(0xFFC62828),
    transfer: Color(0xFF5F6368),
    adjustment: Color(0xFF6A4C93),
    incomeSurface: Color(0xFFE3F0FB),
    expenseSurface: Color(0xFFFCE4E4),
    budgetSafe: Color(0xFF0F7B3F),
    budgetWarn: Color(0xFF9A6700),
    budgetOver: Color(0xFFC62828),
  );

  /// Bảng màu chế độ tối. Không phải bản sáng bị làm tối — là bộ màu riêng,
  /// sáng hơn và bớt bão hoà, để đọc được trên nền tối thật sự của M3.
  static const MoneyColors dark = MoneyColors(
    income: Color(0xFF7FB8F0),
    expense: Color(0xFFFF897D),
    transfer: Color(0xFFA9A5B0),
    adjustment: Color(0xFFC4A7F0),
    incomeSurface: Color(0xFF16283A),
    expenseSurface: Color(0xFF3A1D1B),
    budgetSafe: Color(0xFF6BD08E),
    budgetWarn: Color(0xFFF5C451),
    budgetOver: Color(0xFFFF897D),
  );

  @override
  MoneyColors copyWith({
    Color? income,
    Color? expense,
    Color? transfer,
    Color? adjustment,
    Color? incomeSurface,
    Color? expenseSurface,
    Color? budgetSafe,
    Color? budgetWarn,
    Color? budgetOver,
  }) {
    return MoneyColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      adjustment: adjustment ?? this.adjustment,
      incomeSurface: incomeSurface ?? this.incomeSurface,
      expenseSurface: expenseSurface ?? this.expenseSurface,
      budgetSafe: budgetSafe ?? this.budgetSafe,
      budgetWarn: budgetWarn ?? this.budgetWarn,
      budgetOver: budgetOver ?? this.budgetOver,
    );
  }

  /// Nội suy giữa hai bảng màu khi theme đổi. Flutter gọi hàm này để animation
  /// sáng↔tối mượt thay vì nhảy giật.
  @override
  MoneyColors lerp(covariant MoneyColors? other, double t) {
    if (other == null) return this;
    return MoneyColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      adjustment: Color.lerp(adjustment, other.adjustment, t)!,
      incomeSurface: Color.lerp(incomeSurface, other.incomeSurface, t)!,
      expenseSurface: Color.lerp(expenseSurface, other.expenseSurface, t)!,
      budgetSafe: Color.lerp(budgetSafe, other.budgetSafe, t)!,
      budgetWarn: Color.lerp(budgetWarn, other.budgetWarn, t)!,
      budgetOver: Color.lerp(budgetOver, other.budgetOver, t)!,
    );
  }
}

/// Lối tắt đọc theme, để widget không phải viết `Theme.of(context).colorScheme`
/// dài dòng ở mọi dòng.
extension ThemeShortcuts on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Màu ngữ nghĩa của app. Luôn có mặt vì `AppTheme` đăng ký nó ở cả hai chế độ.
  MoneyColors get moneyColors => Theme.of(this).extension<MoneyColors>()!;
}
