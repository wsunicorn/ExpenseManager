import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/utils/money.dart';

/// Test bắt buộc số 3 trong `CONVENTIONS.md`: `parseMoney()` / `formatMoney()`.
///
/// Đây là hàm thuần, không cần Flutter engine — chạy nhanh, không cần thiết bị.
void main() {
  group('formatMoney', () {
    test('chèn dấu chấm ngăn cách hàng nghìn kiểu Việt', () {
      expect(formatMoney(0), '0 đ');
      expect(formatMoney(999), '999 đ');
      expect(formatMoney(1000), '1.000 đ');
      expect(formatMoney(50000), '50.000 đ');
      expect(formatMoney(1250000), '1.250.000 đ');
    });

    test('số âm dùng dấu trừ U+2212, không phải gạch nối U+002D', () {
      expect(formatMoney(-350000), '−350.000 đ');
      expect(formatMoney(-350000).contains('-'), isFalse);
    });

    test('không còn khoảng trắng không ngắt của intl', () {
      expect(formatMoney(50000).contains(' '), isFalse);
    });

    test('chịu được số lớn — int 64-bit dư sức cho mọi con số VND', () {
      expect(formatMoney(999999999999), '999.999.999.999 đ');
    });
  });

  group('formatSigned', () {
    test('luôn có dấu đứng trước — không dựa vào màu để phân biệt thu/chi', () {
      expect(formatSigned(50000), '+50.000 đ');
      expect(formatSigned(-50000), '−50.000 đ');
    });

    test('số 0 không mang dấu', () {
      expect(formatSigned(0), '0 đ');
    });
  });

  group('formatPlain', () {
    test('không kèm ký hiệu tiền tệ', () {
      expect(formatPlain(1250000), '1.250.000');
      expect(formatPlain(1250000).contains('đ'), isFalse);
    });
  });

  group('formatCompact', () {
    test('rút gọn theo bậc nghìn / triệu / tỷ', () {
      expect(formatCompact(999), '999');
      expect(formatCompact(50000), '50k');
      expect(formatCompact(8000000), '8tr');
      expect(formatCompact(1200000000), '1,2 tỷ');
    });

    test('dùng dấu phẩy thập phân kiểu Việt', () {
      expect(formatCompact(3200000), '3,2tr');
    });

    test('giữ dấu âm', () {
      expect(formatCompact(-350000), '−350k');
    });
  });

  group('parseMoney', () {
    test('đọc được mọi dạng người dùng hay gõ', () {
      expect(parseMoney('50000'), 50000);
      expect(parseMoney('50.000'), 50000);
      expect(parseMoney('50,000'), 50000);
      expect(parseMoney('50.000 đ'), 50000);
      expect(parseMoney('  50 000  '), 50000);
    });

    test('trả null khi không có chữ số nào', () {
      expect(parseMoney(''), isNull);
      expect(parseMoney('   '), isNull);
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('đ'), isNull);
    });

    test('giữ dấu âm chỉ khi nó đứng đầu chuỗi', () {
      expect(parseMoney('−350.000'), -350000);
      expect(parseMoney('-350000'), -350000);
      // Dấu trừ ở giữa không phải số âm — đó là người dùng gõ nhầm.
      expect(parseMoney('350-000'), 350000);
    });

    test('khứ hồi: parse(format(x)) == x', () {
      for (final v in [0, 1, 999, 50000, 1250000, -350000, 999999999]) {
        expect(parseMoney(formatMoney(v)), v, reason: 'thất bại với $v');
      }
    });
  });
}
