import 'package:flutter/material.dart';

import '../../core/theme/money_colors.dart';
import '../../core/theme/tokens.dart';

/// Trạng thái rỗng dùng chung.
///
/// `07_UI_UX.md` mục 3.5 đặt ra yêu cầu cứng: mọi màn hình phải có một trạng
/// thái rỗng tử tế gồm **icon nhạt + câu giải thích + nút hành động**. Không
/// bao giờ để màn hình trắng trơn với chữ "Không có dữ liệu" như MoneyNote.
///
/// Lý do không chỉ là thẩm mỹ: màn hình rỗng là lần đầu người dùng gặp một tính
/// năng. Nếu nó không nói được "chỗ này để làm gì" và "bấm đâu để bắt đầu" thì
/// tính năng coi như không tồn tại.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;

  /// Câu tiếng Việt giải thích vì sao trống và điều gì sẽ lấp đầy nó.
  final String message;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: Tokens.xxxl,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Tokens.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Tokens.xl),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
