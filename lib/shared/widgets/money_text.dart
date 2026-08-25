import 'package:flutter/material.dart';

import '../../core/theme/money_colors.dart';
import '../../core/utils/money.dart';

/// Cách hiển thị số tiền. Quyết định dấu và màu.
enum MoneySignStyle {
  /// Không thêm dấu. Dùng cho số dư ví, tổng tài sản.
  none,

  /// Luôn có `+` hoặc `−`, màu theo dấu. Dùng cho giao dịch, báo cáo.
  signed,
}

/// Hiển thị một số tiền. **Mọi số tiền trong app phải đi qua widget này.**
///
/// Nó lo hai việc mà gõ `Text(formatMoney(x))` sẽ quên:
///
/// 1. Bật `FontFeature.tabularFigures()` — chữ số cùng bề rộng. Không có nó,
///    các cột số trong danh sách so le và trông nghiệp dư ngay lập tức
///    (file 07 mục 2.4 và mục 8).
/// 2. Gắn `Semantics` đọc được — trình đọc màn hình phát âm "âm năm mươi nghìn
///    đồng" thay vì đọc rời từng ký tự.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.signStyle = MoneySignStyle.none,
    this.style,
    this.color,
    this.compact = false,
  });

  /// Số tiền, đơn vị đồng. Luôn là `int` — xem `core/utils/money.dart`.
  final int amount;

  final MoneySignStyle signStyle;

  /// Kiểu chữ nền. `tabularFigures` sẽ được ghép thêm, không cần tự thêm.
  final TextStyle? style;

  /// Ghi đè màu. Bỏ trống thì tự suy theo dấu khi `signStyle` là `signed`.
  final Color? color;

  /// Rút gọn `8.000.000 đ` → `8tr`. **Chỉ dùng trong biểu đồ** và nhớ ghi `≈`
  /// bên cạnh (file 07 mục 1.1: không làm tròn tiền ở màn hình chính).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final signed = signStyle == MoneySignStyle.signed;

    final String text;
    if (compact) {
      text = signed && amount > 0
          ? '$kPlusSign${formatCompact(amount)}'
          : formatCompact(amount);
    } else {
      text = signed ? formatSigned(amount) : formatMoney(amount);
    }

    final money = context.moneyColors;
    final Color? resolved = color ??
        (signed
            ? (amount > 0
                ? money.income
                : amount < 0
                    ? money.expense
                    : null)
            : null);

    final base = style ?? DefaultTextStyle.of(context).style;

    return Semantics(
      label: signed ? formatSigned(amount) : formatMoney(amount),
      excludeSemantics: true,
      child: Text(
        text,
        style: base.copyWith(
          color: resolved,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
