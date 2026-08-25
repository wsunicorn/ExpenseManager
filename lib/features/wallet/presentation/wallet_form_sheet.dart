import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import 'wallet_providers.dart';

/// Nhãn tiếng Việt cho từng loại ví.
String walletTypeLabel(WalletType type) => switch (type) {
  WalletType.cash => 'Tiền mặt',
  WalletType.bank => 'Ngân hàng',
  WalletType.ewallet => 'Ví điện tử',
  WalletType.credit => 'Thẻ tín dụng',
  WalletType.savings => 'Tiết kiệm',
};

/// Bảng trượt tạo hoặc sửa ví.
///
/// Các trường bám đúng bước 2 onboarding trong `01_DAC_TA_TINH_NANG.md`:
/// tên, loại, icon + màu, số dư hiện có, và cờ tính vào tổng.
///
/// Dùng bottom sheet thay vì màn hình riêng vì `07_UI_UX.md` mục 1.3: app được
/// dùng một tay khi đang đứng, mọi thao tác chính nên nằm ở nửa dưới màn hình.
class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  /// Null nghĩa là tạo mới.
  final Wallet? existing;

  /// Mở sheet và trả về `true` nếu có thay đổi được lưu.
  static Future<bool?> show(BuildContext context, {Wallet? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WalletFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;

  late WalletType _type;
  late int _iconCode;
  late int _colorValue;
  late bool _includeInTotal;

  /// Lỗi hiện ngay dưới ô Tên ví.
  ///
  /// Trước đây dùng SnackBar, nhưng SnackBar thuộc `ScaffoldMessenger` của màn
  /// hình phía sau nên nó hiện **bên dưới** bảng trượt và bị che hoàn toàn —
  /// người dùng bấm Lưu mà tưởng nút hỏng.
  String? _nameError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    // Khi sửa, số dư gốc hiển thị dạng đã format cho dễ đọc.
    _balanceCtrl = TextEditingController(
      text: w == null ? '' : formatPlain(w.initialBalance),
    );
    _type = w?.type ?? WalletType.cash;
    _iconCode = w?.iconCode ?? AppIcons.wallet.first.codePoint;
    _colorValue = w?.colorValue ?? AppPalette.colors.first.toARGB32();
    _includeInTotal = w?.includeInTotal ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Ví cần có tên.');
      return;
    }
    setState(() => _nameError = null);

    final repo = ref.read(walletRepositoryProvider);
    // parseMoney trả null khi ô trống — số dư gốc để trống nghĩa là 0.
    final initial = parseMoney(_balanceCtrl.text) ?? 0;

    if (_isEditing) {
      await repo.updateWallet(
        widget.existing!.copyWith(
          name: name,
          type: _type,
          iconCode: _iconCode,
          colorValue: _colorValue,
          initialBalance: initial,
          includeInTotal: _includeInTotal,
        ),
      );
    } else {
      await repo.createWallet(
        name: name,
        type: _type,
        iconCode: _iconCode,
        colorValue: _colorValue,
        initialBalance: initial,
        includeInTotal: _includeInTotal,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Padding(
      // Đẩy nội dung lên trên bàn phím khi nó hiện ra.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phần cuộn được: mọi trường nhập.
          //
          // `Flexible` chứ không phải `Expanded`: bảng trượt phải co lại vừa
          // nội dung khi form ngắn, nhưng khi form dài hơn màn hình thì vùng
          // này nhường chỗ cho nút ở đáy thay vì đẩy nút ra ngoài tầm nhìn.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Tokens.screenPadding,
                Tokens.screenPadding,
                Tokens.screenPadding,
                Tokens.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: Tokens.xxl,
                      height: Tokens.xs,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: Tokens.brFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: Tokens.lg),
                  Text(
                    _isEditing ? 'Sửa ví' : 'Ví mới',
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Tokens.xl),

                  TextField(
                    controller: _nameCtrl,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Tên ví',
                      hintText: 'Tiền mặt, MoMo, Vietcombank…',
                      errorText: _nameError,
                    ),
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: Tokens.md),

                  Text('Loại ví', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    children: [
                      for (final t in WalletType.values)
                        ChoiceChip(
                          label: Text(walletTypeLabel(t)),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.lg),

                  TextField(
                    controller: _balanceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Số tiền bạn đang có trong ví này',
                      suffixText: kCurrencySymbol,
                      // Câu này lấy nguyên văn từ đặc tả bước 2 onboarding — nó giải
                      // thích điều mà MoneyNote không bao giờ nói rõ.
                      helperText: 'Mọi khoản thu chi sau này sẽ được cộng/trừ từ con số này.',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Icon', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      for (final icon in AppIcons.wallet)
                        _PickTile(
                          selected: _iconCode == icon.codePoint,
                          onTap: () =>
                              setState(() => _iconCode = icon.codePoint),
                          child: Icon(icon, size: 22),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.lg),

                  Text('Màu', style: context.textTheme.labelSmall),
                  const SizedBox(height: Tokens.sm),
                  Wrap(
                    spacing: Tokens.sm,
                    runSpacing: Tokens.sm,
                    children: [
                      for (final color in AppPalette.colors)
                        _PickTile(
                          selected: _colorValue == color.toARGB32(),
                          onTap: () =>
                              setState(() => _colorValue = color.toARGB32()),
                          child: Container(
                            width: Tokens.xl,
                            height: Tokens.xl,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: Tokens.brFull,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.md),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _includeInTotal,
                    onChanged: (v) => setState(() => _includeInTotal = v),
                    title: const Text('Tính vào Tổng tài sản'),
                    subtitle: const Text(
                      'Tắt với sổ tiết kiệm dài hạn bạn không muốn thấy trong số dư '
                      'hằng ngày.',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hành động chính **ghim cố định ở đáy**, luôn nhìn thấy dù form dài
          // bao nhiêu (file 07 mục 1.3 — quy tắc cứng).
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.screenPadding,
              Tokens.sm,
              Tokens.screenPadding,
              Tokens.lg,
            ),
            child: SizedBox(
              width: double.infinity,
              height: Tokens.minTouchTarget + Tokens.sm,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Lưu thay đổi' : 'Tạo ví'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô chọn vuông trong lưới icon / màu. Bọc `SizedBox` để đạt vùng chạm 48dp
/// dù nội dung bên trong nhỏ hơn (file 07 mục 5).
class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return SizedBox(
      width: Tokens.minTouchTarget,
      height: Tokens.minTouchTarget,
      child: Material(
        color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
        borderRadius: Tokens.brSm,
        child: InkWell(
          borderRadius: Tokens.brSm,
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
