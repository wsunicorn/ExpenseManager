import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../domain/money_calculator.dart';

/// Bàn phím số có phép tính. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục B.2 và
/// `07_UI_UX.md` mục 3.2.
///
/// Toàn bộ logic tính toán nằm ở [MoneyCalculator] — widget này chỉ vẽ và
/// chuyển phím bấm thành lời gọi hàm. Nhờ tách như vậy, phần dễ sai nhất
/// (thứ tự phép tính, xoá lùi, làm tròn) được test không cần dựng giao diện.
class MoneyKeypad extends StatefulWidget {
  const MoneyKeypad({
    required this.onSubmit,
    super.key,
    this.initialValue,
    this.submitLabel = 'Lưu',
  });

  /// Gọi khi bấm nút Lưu, kèm số tiền đã tính xong.
  final ValueChanged<int> onSubmit;

  /// Số tiền có sẵn khi mở bàn phím — dùng khi sửa giao dịch cũ.
  final int? initialValue;

  final String submitLabel;

  /// Mở bàn phím dạng bảng trượt và trả về số tiền, hoặc null nếu huỷ.
  static Future<int?> show(
    BuildContext context, {
    int? initialValue,
    String submitLabel = 'Lưu',
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => MoneyKeypad(
        initialValue: initialValue,
        submitLabel: submitLabel,
        onSubmit: (value) => Navigator.of(ctx).pop(value),
      ),
    );
  }

  @override
  State<MoneyKeypad> createState() => _MoneyKeypadState();
}

class _MoneyKeypadState extends State<MoneyKeypad> {
  late MoneyCalculator _calc;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _calc = initial == null || initial == 0
        ? MoneyCalculator.empty
        : MoneyCalculator(operands: [initial.toString()]);
  }

  /// Mỗi lần chạm phím rung nhẹ.
  ///
  /// `07_UI_UX.md` mục 3.2 gọi đây là "chi tiết nhỏ tạo cảm giác app xịn" —
  /// và nó thật sự quan trọng với bàn phím: ngón tay xác nhận được đã bấm
  /// trúng mà mắt không cần rời khỏi con số.
  void _apply(MoneyCalculator next, {bool heavy = false}) {
    if (heavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() => _calc = next);
  }

  void _submit() {
    final value = _calc.value;
    if (value == null || value <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value == null ? 'Phép tính chưa xong.' : 'Số tiền phải lớn hơn 0.',
          ),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final canSubmit = (_calc.value ?? 0) > 0;

    return SafeArea(
      // Bàn phím là lưới phím cao cố định (~376dp). Trên cửa sổ thấp hơn thế,
      // một Column trần sẽ tràn và hiện sọc vàng đen. Bọc scroll view để nó
      // cuộn thay vì vỡ — không đổi gì ở kích thước bình thường.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Vùng hiển thị ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Tokens.lg),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: Tokens.brMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Dòng phép tính, mờ hơn kết quả. Giữ chỗ cố định để bàn
                    // phím không nhảy lên xuống khi bắt đầu gõ phép tính.
                    SizedBox(
                      height: Tokens.xl,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _calc.expressionDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _calc.resultDisplay,
                              style: context.textTheme.displaySmall?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Tokens.sm),
                        Text(
                          kCurrencySymbol,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Tokens.md),

              // ── Lưới phím ────────────────────────────────────────────────
              // 4 cột phím + 1 cột bên phải cho Xoá và Lưu, đúng bố cục ở
              // file 07 mục 3.2.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _KeyRow(
                          children: [_digit('7'), _digit('8'), _digit('9')],
                        ),
                        _KeyRow(
                          children: [_digit('4'), _digit('5'), _digit('6')],
                        ),
                        _KeyRow(
                          children: [_digit('1'), _digit('2'), _digit('3')],
                        ),
                        _KeyRow(
                          children: [
                            _KeyButton(
                              label: '000',
                              onTap: () => _apply(_calc.pressTripleZero()),
                            ),
                            _digit('0'),
                            _KeyButton(
                              label: 'C',
                              tone: _KeyTone.muted,
                              onTap: () => _apply(_calc.clear()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Cột toán tử.
                  Expanded(
                    child: Column(
                      children: [
                        for (final op in CalcOp.values)
                          _KeyRow(
                            children: [
                              _KeyButton(
                                label: op.symbol,
                                tone: _KeyTone.operator,
                                onTap: () => _apply(_calc.pressOperator(op)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Cột Xoá + Lưu. Nút Lưu cao gấp đôi và là hành động chính.
                  Expanded(
                    child: Column(
                      children: [
                        _KeyRow(
                          children: [
                            _KeyButton(
                              icon: Icons.backspace_outlined,
                              tone: _KeyTone.muted,
                              onTap: () => _apply(_calc.backspace()),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(Tokens.xs),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: canSubmit ? _submit : null,
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: Tokens.brMd,
                                  ),
                                ),
                                child: Text(
                                  widget.submitLabel,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digit(String d) =>
      _KeyButton(label: d, onTap: () => _apply(_calc.pressDigit(d)));
}

/// Một hàng phím. Chiều cao cố định để mọi phím đạt vùng chạm ≥ 48dp.
class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.minTouchTarget + Tokens.md,
      child: Row(children: [for (final c in children) Expanded(child: c)]),
    );
  }
}

enum _KeyTone { normal, operator, muted }

/// Một phím, có hiệu ứng nhấn nảy.
///
/// `AnimatedScale` xuống 0.96 khi nhấn — một trong ba hiệu ứng "Expressive"
/// tự viết ở `07_UI_UX.md` mục 4, vì SDK Flutter chưa hỗ trợ M3 Expressive.
class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.onTap,
    this.label,
    this.icon,
    this.tone = _KeyTone.normal,
  });

  final VoidCallback onTap;
  final String? label;
  final IconData? icon;
  final _KeyTone tone;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final (bg, fg) = switch (widget.tone) {
      _KeyTone.normal => (cs.surfaceContainerHighest, cs.onSurface),
      _KeyTone.operator => (cs.secondaryContainer, cs.onSecondaryContainer),
      _KeyTone.muted => (cs.surfaceContainer, cs.onSurfaceVariant),
    };

    return Padding(
      padding: const EdgeInsets.all(Tokens.xs),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: Tokens.tap,
        curve: Curves.easeOut,
        child: Material(
          color: bg,
          borderRadius: Tokens.brMd,
          child: InkWell(
            borderRadius: Tokens.brMd,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Center(
              child: widget.icon != null
                  ? Icon(widget.icon, color: fg)
                  : Text(
                      widget.label!,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: fg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
