import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/features/settings/domain/app_lock.dart';

/// Khoá app bằng PIN — `01_DAC_TA_TINH_NANG.md` mục J.
void main() {
  group('kiểm tra định dạng PIN', () {
    test('chấp nhận đúng 4 chữ số', () {
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin('0000'), isTrue);
    });

    test('từ chối độ dài sai và ký tự không phải số', () {
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('12345'), isFalse);
      expect(isValidPin('12a4'), isFalse);
      expect(isValidPin(''), isFalse);
      expect(isValidPin('    '), isFalse);
    });
  });

  group('băm và xác minh', () {
    test('PIN đúng thì xác minh thành công', () {
      final luu = hashPin('1234');
      expect(verifyPin('1234', luu), isTrue);
    });

    test('PIN sai thì thất bại', () {
      final luu = hashPin('1234');
      expect(verifyPin('1235', luu), isFalse);
      expect(verifyPin('0000', luu), isFalse);
    });

    /// Muối ngẫu nhiên: cùng một PIN nhưng hai lần băm phải ra hai chuỗi khác
    /// nhau. Không có muối thì nhìn hai người cùng đặt PIN 1234 là biết ngay.
    test('cùng PIN nhưng hai lần băm ra hai chuỗi khác nhau', () {
      expect(hashPin('1234'), isNot(hashPin('1234')));
    });

    /// Bản lưu không được chứa PIN dạng chữ ở bất kỳ đâu.
    test('bản lưu không lộ PIN', () {
      final luu = hashPin('1234');
      expect(luu.split(':').last, isNot(contains('1234')));
      expect(luu.length, greaterThan(40));
    });

    test('dữ liệu lưu hỏng thì từ chối, không nổ', () {
      expect(verifyPin('1234', ''), isFalse);
      expect(verifyPin('1234', 'rac'), isFalse);
      expect(verifyPin('1234', 'a:b:c'), isFalse);
    });

    test('băm lại với cùng muối cho cùng kết quả', () {
      final luu = hashPin('9876');
      final muoi = luu.split(':').first;
      expect(hashPin('9876', salt: muoi), luu);
    });
  });
}
