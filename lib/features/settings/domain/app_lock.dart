/// Khoá app bằng PIN. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục J.
///
/// **Không lưu PIN dạng chữ.** Lưu bản băm kèm muối, để ai mở được file DB
/// cũng không đọc ra mã. Với một app cá nhân thì đây không phải phòng thủ
/// nghiêm ngặt, nhưng lưu mã trần thì không có lý do gì để biện minh.
///
/// Hàm thuần, test được không cần Flutter.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Độ dài PIN. Bốn chữ số như đặc tả.
const int kPinLength = 4;

/// Băm PIN kèm muối ngẫu nhiên.
///
/// Trả về chuỗi `muối:băm` để lưu một ô duy nhất trong bảng settings.
///
/// Dùng SHA-256 lặp nhiều vòng thay vì băm một lần: PIN chỉ có 10.000 khả
/// năng, băm một vòng thì dò hết mất chưa tới một giây. Lặp 10.000 vòng đưa
/// chi phí dò lên mức khó chịu mà vẫn không làm người dùng chờ khi mở app.
String hashPin(String pin, {String? salt}) {
  final muoi = salt ?? _randomSalt();
  var bytes = utf8.encode('$muoi:$pin');

  for (var i = 0; i < 10000; i++) {
    bytes = utf8.encode(sha256.convert(bytes).toString());
  }

  return '$muoi:${sha256.convert(bytes)}';
}

/// Kiểm tra PIN có khớp bản đã lưu không.
///
/// Trả `false` với mọi đầu vào dị dạng thay vì ném lỗi — dữ liệu hỏng thì
/// người dùng bị khoá ngoài, chứ không được cho vào.
bool verifyPin(String pin, String stored) {
  final phan = stored.split(':');
  if (phan.length != 2) return false;

  return hashPin(pin, salt: phan.first) == stored;
}

/// PIN hợp lệ: đúng [kPinLength] chữ số.
bool isValidPin(String pin) =>
    pin.length == kPinLength && RegExp(r'^\d+$').hasMatch(pin);

String _randomSalt() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return base64Url.encode(bytes);
}
