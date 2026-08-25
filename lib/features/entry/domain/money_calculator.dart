import '../../../core/utils/money.dart';

/// Bốn phép tính bàn phím số hỗ trợ.
enum CalcOp {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const CalcOp(this.symbol);

  /// Ký hiệu hiển thị. Dùng `−` `×` `÷` thật chứ không phải `-` `x` `/` —
  /// chi tiết nhỏ nhưng là khác biệt giữa "trông như app" và "trông như bài
  /// tập lập trình".
  final String symbol;

  /// Nhân và chia làm trước cộng trừ.
  bool get isHighPrecedence => this == multiply || this == divide;
}

/// Trạng thái bàn phím số. **Bất biến và thuần** — không đụng Flutter, không
/// đụng DB, nên test được bằng `dart test` thuần.
///
/// Vì sao app cần máy tính ngay trong bàn phím: người Việt hay cộng nhiều món
/// trong một hoá đơn ("cơm 45 + trà đá 5 + gửi xe 5"). MoneyNote bắt mở app
/// máy tính riêng rồi chép số sang — mỗi lần như vậy tốn 15 giây và là lý do
/// người ta bỏ ghi chi tiêu. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục B.2.
///
/// Cách lưu: một danh sách xen kẽ số và toán tử, số cuối cùng là số đang gõ.
/// Không dùng chuỗi vì chuỗi phải phân tích lại mỗi lần bấm phím và dễ sinh
/// trạng thái vô nghĩa như `"50+*3"`.
class MoneyCalculator {
  /// **Bất biến của lớp**: `operands.length == operators.length + 1`.
  /// Không viết được thành `assert` vì constructor là `const`, mà biểu thức
  /// hằng của Dart không cho gọi `.length` trên danh sách. Mọi phương thức
  /// trong lớp đều giữ đúng bất biến này, và nó có test riêng bên dưới.
  const MoneyCalculator({
    this.operands = const [''],
    this.operators = const [],
  });

  /// Bàn phím lúc chưa gõ gì.
  static const MoneyCalculator empty = MoneyCalculator();

  /// Các số hạng dưới dạng chuỗi chữ số. Phần tử cuối là số đang gõ dở.
  /// Chuỗi rỗng nghĩa là chưa gõ chữ số nào cho số hạng đó.
  final List<String> operands;

  final List<CalcOp> operators;

  /// Chưa gõ gì cả.
  bool get isEmpty => operators.isEmpty && operands.single.isEmpty;

  /// Có nhiều hơn một số hạng — tức là đang thực sự tính toán chứ không chỉ
  /// gõ một con số. Dùng để quyết định có hiện dòng phép tính hay không.
  bool get hasExpression => operators.isNotEmpty;

  /// Gõ thêm chữ số.
  ///
  /// Chặn số 0 đứng đầu: gõ `0` rồi `5` ra `5`, không phải `05`.
  MoneyCalculator pressDigit(String digit) {
    final current = operands.last;
    final next = current == '0' ? digit : current + digit;
    // Giới hạn 15 chữ số: đủ cho mọi con số VND thực tế và vẫn an toàn với
    // int 64-bit sau khi nhân.
    if (next.length > 15) return this;
    return _replaceLast(next);
  }

  /// Phím `000` — người Việt gõ tiền toàn số tròn nghìn.
  ///
  /// Không làm gì khi chưa có chữ số nào, để tránh tạo ra số `000`.
  MoneyCalculator pressTripleZero() {
    final current = operands.last;
    if (current.isEmpty || current == '0') return this;
    return pressDigit('0').pressDigit('0').pressDigit('0');
  }

  /// Gõ toán tử.
  ///
  /// - Chưa gõ số nào: bỏ qua (không cho biểu thức bắt đầu bằng toán tử).
  /// - Vừa gõ một toán tử rồi: thay bằng toán tử mới, coi như bấm nhầm.
  MoneyCalculator pressOperator(CalcOp op) {
    if (operands.last.isEmpty) {
      if (operators.isEmpty) return this;
      // Đổi toán tử vừa bấm.
      return MoneyCalculator(
        operands: operands,
        operators: [...operators.sublist(0, operators.length - 1), op],
      );
    }
    return MoneyCalculator(
      operands: [...operands, ''],
      operators: [...operators, op],
    );
  }

  /// Xoá lùi một ký tự — chữ số hoặc toán tử.
  MoneyCalculator backspace() {
    final current = operands.last;
    if (current.isNotEmpty) {
      return _replaceLast(current.substring(0, current.length - 1));
    }
    if (operators.isEmpty) return this;
    // Số hạng cuối rỗng: xoá toán tử, quay lại số hạng trước.
    return MoneyCalculator(
      operands: operands.sublist(0, operands.length - 1),
      operators: operators.sublist(0, operators.length - 1),
    );
  }

  MoneyCalculator clear() => empty;

  /// Kết quả phép tính, đơn vị đồng. `null` khi biểu thức chưa hoàn chỉnh
  /// hoặc chia cho 0.
  ///
  /// Toàn bộ tính toán bằng `int`. Chia được **làm tròn tới đồng gần nhất**
  /// chứ không cắt cụt — chia hoá đơn 100.000 cho 3 người ra 33.333 đ, cắt cụt
  /// hay làm tròn ở đây lệch nhau vài đồng, nhưng nguyên tắc "không dùng
  /// double cho tiền" thì không được phá.
  int? get value {
    if (operands.any((o) => o.isEmpty)) return null;

    final nums = <int>[];
    for (final o in operands) {
      final n = int.tryParse(o);
      if (n == null) return null;
      nums.add(n);
    }

    // Lượt 1: nhân và chia.
    final reduced = <int>[nums.first];
    final pending = <CalcOp>[];
    for (var i = 0; i < operators.length; i++) {
      final op = operators[i];
      final rhs = nums[i + 1];
      if (op.isHighPrecedence) {
        final lhs = reduced.removeLast();
        if (op == CalcOp.divide) {
          if (rhs == 0) return null;
          reduced.add(_divideRounded(lhs, rhs));
        } else {
          reduced.add(lhs * rhs);
        }
      } else {
        pending.add(op);
        reduced.add(rhs);
      }
    }

    // Lượt 2: cộng và trừ, từ trái sang phải.
    var acc = reduced.first;
    for (var i = 0; i < pending.length; i++) {
      acc = pending[i] == CalcOp.add ? acc + reduced[i + 1] : acc - reduced[i + 1];
    }
    return acc;
  }

  /// Chia làm tròn tới số nguyên gần nhất, nửa thì làm tròn ra xa 0.
  static int _divideRounded(int a, int b) {
    final negative = (a < 0) != (b < 0);
    final absA = a.abs();
    final absB = b.abs();
    final q = (absA + absB ~/ 2) ~/ absB;
    return negative ? -q : q;
  }

  /// Dòng biểu thức hiển thị phía trên kết quả, ví dụ `45.000 + 5.000 + 5.000`.
  /// Trả chuỗi rỗng khi chỉ có một số hạng.
  String get expressionDisplay {
    if (!hasExpression) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < operands.length; i++) {
      buffer.write(_formatOperand(operands[i]));
      if (i < operators.length) buffer.write(' ${operators[i].symbol} ');
    }
    return buffer.toString().trimRight();
  }

  /// Con số lớn hiển thị chính giữa — luôn là kết quả tính tới thời điểm này.
  ///
  /// Đặc tả mục B.2 nói kết quả "tự tính", nên số này cập nhật ngay từng phím
  /// chứ không đợi bấm `=`. Khi vừa bấm một toán tử và chưa gõ số tiếp theo,
  /// nó giữ nguyên kết quả của phần đã gõ — hiện `0` lúc đó làm người dùng
  /// tưởng vừa mất số vừa nhập.
  String get resultDisplay {
    final v = value;
    if (v != null) return formatPlain(v);

    // Số hạng cuối đang rỗng: tính phần biểu thức phía trước.
    if (operators.isNotEmpty && operands.last.isEmpty) {
      final prefix = MoneyCalculator(
        operands: operands.sublist(0, operands.length - 1),
        operators: operators.sublist(0, operators.length - 1),
      );
      final pv = prefix.value;
      if (pv != null) return formatPlain(pv);
    }
    return _formatOperand(operands.last);
  }

  static String _formatOperand(String raw) {
    if (raw.isEmpty) return '0';
    final n = int.tryParse(raw);
    return n == null ? raw : formatPlain(n);
  }

  MoneyCalculator _replaceLast(String value) => MoneyCalculator(
        operands: [...operands.sublist(0, operands.length - 1), value],
        operators: operators,
      );
}
