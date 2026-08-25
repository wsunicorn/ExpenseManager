import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/features/entry/domain/money_calculator.dart';

/// Bàn phím số là hàm thuần nên test được trực tiếp, không cần dựng widget.
///
/// Đây là chỗ đáng test kỹ: người dùng gõ số tiền sai thì mọi báo cáo sau đó
/// đều sai, mà lại không có cách nào phát hiện ngoài trí nhớ.
void main() {
  /// Gõ một chuỗi phím cho gọn: chữ số gõ thẳng, toán tử dùng ký hiệu.
  MoneyCalculator go(String keys) {
    var c = MoneyCalculator.empty;
    for (final k in keys.split('')) {
      c = switch (k) {
        '+' => c.pressOperator(CalcOp.add),
        '-' => c.pressOperator(CalcOp.subtract),
        '*' => c.pressOperator(CalcOp.multiply),
        '/' => c.pressOperator(CalcOp.divide),
        '<' => c.backspace(),
        _ => c.pressDigit(k),
      };
    }
    return c;
  }

  group('gõ số', () {
    test('bàn phím mới thì rỗng và chưa có giá trị', () {
      expect(MoneyCalculator.empty.isEmpty, isTrue);
      expect(MoneyCalculator.empty.value, isNull);
    });

    test('gõ chữ số ra đúng số', () {
      expect(go('50000').value, 50000);
    });

    test('không cho số 0 đứng đầu', () {
      expect(go('05').value, 5);
      expect(go('000').value, 0);
    });

    test('phím 000 thêm ba số 0', () {
      final c = go('50').pressTripleZero();
      expect(c.value, 50000);
    });

    test('phím 000 không làm gì khi chưa gõ chữ số nào', () {
      expect(MoneyCalculator.empty.pressTripleZero().isEmpty, isTrue);
    });

    test('chặn số quá dài', () {
      final c = go('123456789012345');
      expect(c.value, 123456789012345);
      expect(c.pressDigit('6').value, 123456789012345, reason: 'bị chặn');
    });
  });

  group('phép tính', () {
    /// Đúng tình huống trong đặc tả: cộng nhiều món trong một hoá đơn.
    test('cộng nhiều số hạng', () {
      expect(go('45000+5000+5000').value, 55000);
    });

    test('trừ', () {
      expect(go('100000-30000').value, 70000);
    });

    test('nhân — ví dụ 3 suất cơm 45.000', () {
      expect(go('45000*3').value, 135000);
    });

    test('chia — chia đôi hoá đơn', () {
      expect(go('100000/2').value, 50000);
    });

    test('nhân chia làm trước cộng trừ', () {
      expect(go('10000+2000*3').value, 16000);
      expect(go('10000-6000/2').value, 7000);
    });

    test('cộng trừ tính từ trái sang phải', () {
      expect(go('100-30-20').value, 50);
    });

    test('chia làm tròn tới đồng gần nhất, không cắt cụt', () {
      // 100.000 / 3 = 33.333,33… → 33.333
      expect(go('100000/3').value, 33333);
      // 100.000 / 8 = 12.500 chẵn
      expect(go('100000/8').value, 12500);
      // 5 / 2 = 2,5 → làm tròn ra xa 0 thành 3
      expect(go('5/2').value, 3);
    });

    test('chia cho 0 trả null chứ không nổ', () {
      expect(go('100/0').value, isNull);
    });

    test('biểu thức chưa hoàn chỉnh thì chưa có giá trị', () {
      expect(go('100+').value, isNull);
    });
  });

  group('sửa khi bấm nhầm', () {
    test('bấm toán tử hai lần thì thay toán tử, không tạo biểu thức hỏng', () {
      expect(go('100+*3').value, 300);
      expect(go('100+-30').value, 70);
    });

    test('không cho biểu thức bắt đầu bằng toán tử', () {
      expect(MoneyCalculator.empty.pressOperator(CalcOp.add).isEmpty, isTrue);
    });

    test('xoá lùi bỏ từng chữ số', () {
      expect(go('50000<').value, 5000);
      expect(go('50000<<').value, 500);
    });

    test('xoá lùi qua toán tử thì quay lại số hạng trước', () {
      final c = go('100+<');
      expect(c.hasExpression, isFalse);
      expect(c.value, 100);
    });

    test('xoá hết thì về trạng thái rỗng', () {
      expect(go('123<<<').isEmpty, isTrue);
    });

    test('clear xoá sạch', () {
      expect(go('45000+5000').clear().isEmpty, isTrue);
    });
  });

  group('hiển thị', () {
    test('số hạng có dấu chấm ngăn cách hàng nghìn', () {
      expect(go('45000+5000').expressionDisplay, '45.000 + 5.000');
    });

    test('không hiện dòng biểu thức khi chỉ có một số', () {
      expect(go('50000').expressionDisplay, '');
      expect(go('50000').resultDisplay, '50.000');
    });

    test('dùng ký hiệu toán học thật, không phải - x /', () {
      expect(go('100-30').expressionDisplay, contains('−'));
      expect(go('100*3').expressionDisplay, contains('×'));
      expect(go('100/2').expressionDisplay, contains('÷'));
    });

    test('vừa bấm toán tử thì giữ kết quả phần đã gõ, không nhảy về 0', () {
      expect(go('45000+').resultDisplay, '45.000');
      expect(go('45000+5000+').resultDisplay, '50.000');
    });

    test('kết quả cập nhật ngay từng phím, không đợi bấm =', () {
      expect(go('45000+5').resultDisplay, '45.005');
      expect(go('45000+50').resultDisplay, '45.050');
      expect(go('45000+5000').resultDisplay, '50.000');
    });

    test('gõ xong thì hiện kết quả đã tính', () {
      expect(go('45000+5000').resultDisplay, '50.000');
    });
  });
}
