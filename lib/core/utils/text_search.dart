/// Chuẩn hoá chữ tiếng Việt để tìm kiếm không dấu.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C.4.
///
/// **Vì sao cần**: `LIKE` của SQLite chỉ bỏ qua hoa/thường với ký tự ASCII.
/// Với tiếng Việt, `'com trua'` không bao giờ khớp `'Cơm trưa'`, mà gõ đủ dấu
/// trên điện thoại thì chậm — nên người ta sẽ không dùng ô tìm kiếm.
///
/// **Cách làm**: lưu sẵn một bản đã bỏ dấu và viết thường vào cột riêng trong
/// DB, rồi tìm trên cột đó. Không tính lúc truy vấn được vì SQLite không có
/// hàm bỏ dấu Unicode.
///
/// Toàn bộ file là hàm thuần — test được bằng `dart test`.
library;

/// Bảng tra: mỗi chuỗi là các biến thể có dấu của một chữ cái ASCII.
///
/// Viết dạng chuỗi thay vì `Map` từng ký tự cho gọn và dễ soát bằng mắt.
const Map<String, String> _vietnameseMap = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

/// Bảng tra ngược, dựng một lần lúc khởi động: ký tự có dấu → ký tự ASCII.
final Map<int, String> _foldTable = () {
  final table = <int, String>{};
  for (final entry in _vietnameseMap.entries) {
    final plain = entry.key;
    for (final ch in entry.value.split('')) {
      table[ch.codeUnitAt(0)] = plain;
      table[ch.toUpperCase().codeUnitAt(0)] = plain.toUpperCase();
    }
  }
  return table;
}();

/// Bỏ dấu tiếng Việt, **giữ nguyên hoa/thường**.
///
/// `'Cơm trưa'` → `'Com trua'`, `'Đầu tư'` → `'Dau tu'`.
///
/// Ký tự không phải tiếng Việt được giữ nguyên, kể cả emoji và chữ Hán — hàm
/// này không cố gắng chuẩn hoá mọi ngôn ngữ, chỉ lo tiếng Việt.
String removeDiacritics(String input) {
  if (input.isEmpty) return input;

  final buffer = StringBuffer();
  for (final unit in input.codeUnits) {
    buffer.write(_foldTable[unit] ?? String.fromCharCode(unit));
  }
  return buffer.toString();
}

/// Dạng chuẩn hoá dùng để **lưu vào DB và để so khớp**: bỏ dấu, viết thường,
/// gom nhiều khoảng trắng thành một, cắt hai đầu.
///
/// Cả lúc ghi lẫn lúc tìm đều phải đi qua hàm này. Dùng hai cách chuẩn hoá
/// khác nhau ở hai đầu là kiểu bug âm thầm nhất: tìm không ra mà không hiểu vì
/// sao.
String normalizeForSearch(String input) {
  return removeDiacritics(input)
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
