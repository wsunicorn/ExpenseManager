import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../domain/app_lock.dart';
import 'app_lock_providers.dart';

/// Màn hình nhập PIN để mở khoá app. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục J.
///
/// Bàn phím số tự vẽ chứ không dùng `TextField`: bàn phím hệ thống che mất
/// nửa màn hình, hiện gợi ý từ, và trên một số bộ gõ còn lưu lại thứ đã gõ.
/// Không thứ nào trong đó nên xảy ra với mã mở khoá.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({required this.onUnlocked, super.key, this.setupMode = false});

  /// Gọi khi mở khoá thành công, hoặc khi đặt PIN xong ở chế độ thiết lập.
  final void Function(String pin) onUnlocked;

  /// `true` khi đang **đặt PIN mới** — khi đó phải nhập hai lần để xác nhận.
  final bool setupMode;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';

  /// Lần nhập đầu ở chế độ thiết lập, để so với lần nhập lại.
  String? _firstEntry;

  String? _error;
  bool _daThuVanTay = false;

  @override
  void initState() {
    super.initState();
    if (!widget.setupMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _thuVanTay());
    }
  }

  /// Thử vân tay ngay khi mở, chỉ một lần.
  ///
  /// Thử lại tự động sau khi người dùng đã huỷ sẽ thành vòng lặp không thoát
  /// được — họ huỷ vì muốn gõ PIN.
  Future<void> _thuVanTay() async {
    if (_daThuVanTay) return;
    _daThuVanTay = true;

    final lock = ref.read(appLockProvider);
    if (!await lock.isBiometricEnabled) return;
    if (!await lock.canUseBiometrics()) return;

    if (await lock.authenticateBiometric() && mounted) {
      widget.onUnlocked('');
    }
  }

  Future<void> _them(String so) async {
    if (_pin.length >= kPinLength) return;

    HapticFeedback.selectionClick();
    setState(() {
      _pin += so;
      _error = null;
    });

    if (_pin.length == kPinLength) await _xuLyDayDu();
  }

  Future<void> _xuLyDayDu() async {
    // Chờ một nhịp để người dùng thấy chấm cuối cùng được tô.
    await Future<void>.delayed(Tokens.short);
    if (!mounted) return;

    if (widget.setupMode) {
      if (_firstEntry == null) {
        setState(() {
          _firstEntry = _pin;
          _pin = '';
        });
        return;
      }
      if (_firstEntry == _pin) {
        widget.onUnlocked(_pin);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _error = 'Hai lần nhập không khớp. Thử lại.';
          _firstEntry = null;
          _pin = '';
        });
      }
      return;
    }

    if (await ref.read(appLockProvider).verify(_pin)) {
      if (mounted) widget.onUnlocked(_pin);
    } else {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _error = 'Sai mã. Thử lại.';
          _pin = '';
        });
      }
    }
  }

  void _xoa() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final tieuDe = widget.setupMode
        ? (_firstEntry == null ? 'Đặt mã PIN' : 'Nhập lại để xác nhận')
        : 'Nhập mã PIN';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.lock_outline,
              size: Tokens.xxxl,
              color: context.colorScheme.primary,
            ),
            const SizedBox(height: Tokens.xl),
            Text(tieuDe, style: context.textTheme.headlineSmall),
            const SizedBox(height: Tokens.xl),

            // Bốn chấm thể hiện số chữ số đã nhập.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < kPinLength; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: Tokens.sm),
                    width: Tokens.md + 2,
                    height: Tokens.md + 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? context.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? context.moneyColors.expense
                            : context.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(
              height: Tokens.xxl,
              child: _error == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: Tokens.md),
                      child: Text(
                        _error!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.moneyColors.expense,
                        ),
                      ),
                    ),
            ),

            const Spacer(),
            // Bàn phím nằm ở nửa dưới — dùng một tay (file 07 mục 1.3).
            _Keypad(
              onDigit: _them,
              onBackspace: _xoa,
              onBiometric: widget.setupMode
                  ? null
                  : () {
                      _daThuVanTay = false;
                      _thuVanTay();
                    },
            ),
            const SizedBox(height: Tokens.xl),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.xxl),
      child: Column(
        children: [
          for (final hang in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final s in hang) _Key(label: s, onTap: () => onDigit(s))],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onBiometric != null)
                _Key(icon: Icons.fingerprint, onTap: onBiometric!)
              else
                const SizedBox(width: 72, height: 72),
              _Key(label: '0', onTap: () => onDigit('0')),
              _Key(icon: Icons.backspace_outlined, onTap: onBackspace),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.onTap, this.label, this.icon});

  final VoidCallback onTap;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.sm),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: context.colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: icon != null
                  ? Icon(icon)
                  : Text(label!, style: context.textTheme.headlineSmall),
            ),
          ),
        ),
      ),
    );
  }
}
