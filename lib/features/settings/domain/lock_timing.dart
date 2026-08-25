/// Khoảng ân hạn: rời app dưới ngần này thì quay lại không phải nhập PIN.
///
/// Không thể khoá ngay khi vừa rời tiền cảnh, vì chính hộp thoại vân tay và
/// trình chọn tệp (lúc xuất/nhập dữ liệu) cũng đẩy app xuống nền — khoá ngay
/// sẽ thành vòng lặp không bao giờ mở khoá nổi. 30 giây đủ dài để đi qua các
/// hộp thoại đó, và đủ ngắn để người cầm được máy bạn không kịp làm gì.
const Duration kLockGracePeriod = Duration(seconds: 30);

/// Quay lại tiền cảnh thì có phải khoá lại không.
///
/// Tách khỏi `app.dart` để test được mà không cần dựng cả `MaterialApp` lẫn
/// vòng đời hệ điều hành — cùng lý do với `onboardingRedirect`.
///
/// [leftAt] là lúc app rời tiền cảnh, `null` khi app chưa từng xuống nền
/// (mở lần đầu, hoặc chỉ mới đổi hướng màn hình).
bool shouldRelock({
  required DateTime? leftAt,
  required DateTime now,
  Duration grace = kLockGracePeriod,
}) {
  if (leftAt == null) return false;
  return now.difference(leftAt) > grace;
}
