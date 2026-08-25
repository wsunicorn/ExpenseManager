import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/features/settings/domain/lock_timing.dart';

void main() {
  final moc = DateTime(2026, 8, 25, 10);

  group('shouldRelock', () {
    test('app chưa từng xuống nền thì không khoá', () {
      expect(shouldRelock(leftAt: null, now: moc), isFalse);
    });

    test('rời đi trong khoảng ân hạn thì không bắt nhập lại PIN', () {
      // Đây chính là trường hợp hộp thoại vân tay: app xuống nền rồi lên lại
      // gần như tức thì. Khoá ở đây là tự khoá mình ra ngoài.
      expect(
        shouldRelock(
          leftAt: moc.subtract(const Duration(seconds: 2)),
          now: moc,
        ),
        isFalse,
      );
    });

    test('đúng mốc ân hạn vẫn chưa khoá — phải vượt qua mới khoá', () {
      expect(
        shouldRelock(leftAt: moc.subtract(kLockGracePeriod), now: moc),
        isFalse,
      );
    });

    test('vượt ân hạn một giây là khoá', () {
      expect(
        shouldRelock(
          leftAt: moc.subtract(kLockGracePeriod + const Duration(seconds: 1)),
          now: moc,
        ),
        isTrue,
      );
    });

    test('để máy qua đêm thì chắc chắn khoá', () {
      expect(
        shouldRelock(
          leftAt: moc.subtract(const Duration(hours: 9)),
          now: moc,
        ),
        isTrue,
      );
    });

    test('đồng hồ máy nhảy lùi thì không khoá, cũng không sập', () {
      // Người dùng đổi giờ hệ thống, hoặc múi giờ tự nhảy. Hiệu số âm — chỉ
      // cần đừng khoá bừa, đừng ném lỗi.
      expect(
        shouldRelock(leftAt: moc.add(const Duration(hours: 1)), now: moc),
        isFalse,
      );
    });
  });
}
