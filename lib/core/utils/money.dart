/// Xử lý tiền tệ. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 5.
///
/// **Quy ước sống còn của app này: tiền luôn là `int`, đơn vị đồng.**
/// Không bao giờ `double`. Lý do: `double` là số dấu phẩy động nhị phân,
/// `0.1 + 0.2 != 0.3`. Với hàng nghìn giao dịch, sai số tích luỹ làm số dư
/// lệch mà không truy được nguyên nhân. VND không có đơn vị nhỏ hơn đồng
/// nên `int` vừa đủ vừa đúng.
///
/// `int` của Dart trên Android là 64-bit → dư sức cho mọi con số VND.
library;

import 'package:intl/intl.dart';

/// Ký hiệu tiền tệ. v1 chỉ hỗ trợ một loại tiền cho toàn app.
const String kCurrencySymbol = 'đ';

/// Dấu trừ dùng để hiển thị là U+2212 MINUS SIGN, **không phải** dấu gạch nối
/// U+002D. Dấu gạch nối hẹp hơn dấu cộng nên cột số sẽ so le.
const String kMinusSign = '\u2212';
const String kPlusSign = '+';

final NumberFormat _currency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: kCurrencySymbol,
  decimalDigits: 0,
);

final NumberFormat _plain = NumberFormat.decimalPattern('vi_VN');

/// `intl` chèn khoảng trắng không ngắt (U+00A0) trước ký hiệu tiền tệ, và dùng
/// dấu gạch nối cho số âm. Chuẩn hoá lại để chuỗi luôn đoán trước được — cần
/// cho cả golden test lẫn khi so chuỗi trong unit test.
String _normalize(String s) =>
    s.replaceAll('\u00A0', ' ').replaceAll('-', kMinusSign).trim();

/// `50000` → `'50.000 đ'`. Số âm → `'−50.000 đ'`.
///
/// Chỉ giao dịch loại `adjustment` mới được mang số âm (xem file 02 mục 6).
String formatMoney(int amount) => _normalize(_currency.format(amount));

/// Luôn có dấu đứng trước: `'+50.000 đ'` / `'−50.000 đ'`. Số 0 không có dấu.
///
/// Dùng cho mọi số tiền trong danh sách giao dịch và báo cáo. Lý do ở file 07
/// mục 2.3: **không bao giờ chỉ dùng màu để truyền tin** — khoảng 8% nam giới
/// mù màu, xanh/đỏ với họ là một.
String formatSigned(int amount) {
  if (amount == 0) return formatMoney(0);
  final sign = amount > 0 ? kPlusSign : kMinusSign;
  return '$sign${formatMoney(amount.abs())}';
}

/// `50000` → `'50.000'`. Không có ký hiệu tiền tệ.
///
/// Dùng trong ô nhập liệu và bàn phím số, nơi ký hiệu `đ` được vẽ riêng.
String formatPlain(int amount) => _normalize(_plain.format(amount));

/// Rút gọn cho biểu đồ và nhãn chật: `8000000` → `'8,0tr'`.
///
/// **Chỉ dùng trong biểu đồ.** File 07 mục 1.1: không bao giờ làm tròn số tiền
/// ở màn hình chính — người dùng phải tin được con số. Chỗ nào dùng bản rút gọn
/// thì ghi kèm dấu `≈`.
String formatCompact(int amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? kMinusSign : '';
  String body;
  if (abs >= 1000000000) {
    body = '${_oneDecimal(abs / 1000000000)} tỷ';
  } else if (abs >= 1000000) {
    body = '${_oneDecimal(abs / 1000000)}tr';
  } else if (abs >= 1000) {
    body = '${_oneDecimal(abs / 1000)}k';
  } else {
    body = abs.toString();
  }
  return '$sign$body';
}

/// Một chữ số thập phân, dùng dấu phẩy kiểu Việt. Bỏ `,0` cho gọn: `8,0` → `8`.
String _oneDecimal(double v) {
  final s = v.toStringAsFixed(1);
  return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s)
      .replaceAll('.', ',');
}

/// Đọc chuỗi người dùng gõ thành `int` đồng. Trả `null` nếu không có chữ số nào.
///
/// Chấp nhận mọi dạng người ta hay gõ: `'50000'`, `'50.000'`, `'50,000'`,
/// `'50.000 đ'`, `' 50 000 '`. Cách làm: vứt hết ký tự không phải chữ số, chỉ
/// giữ dấu âm nếu nó đứng đầu.
///
/// An toàn vì VND không có phần thập phân — không sợ nhầm dấu phân cách nghìn
/// với dấu thập phân. Nếu sau này thêm USD thì hàm này phải viết lại.
int? parseMoney(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final negative = trimmed.startsWith('-') || trimmed.startsWith(kMinusSign);
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  final value = int.tryParse(digits);
  if (value == null) return null;
  return negative ? -value : value;
}
