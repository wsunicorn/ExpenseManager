import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/money_colors.dart';
import 'app_lock_providers.dart';
import 'lock_screen.dart';

/// Lớp chặn đặt giữa `MaterialApp` và toàn bộ màn hình của app.
///
/// **Vì sao cần widget này:** trước đây `LockScreen` chỉ được mở từ tab Khác để
/// *đặt* PIN. Không có chỗ nào hỏi PIN lúc mở app, nên đặt PIN xong vẫn vào
/// thẳng — cái khoá không khoá gì cả. Đây là chỗ biến nó thành khoá thật.
///
/// Dùng `Stack` chứ không thay thế `child`: nếu bỏ `child` ra khỏi cây widget
/// thì `Router` bị huỷ và dựng lại sau mỗi lần mở khoá, mất luôn tab đang đứng
/// và chạy lại việc quét khoản định kỳ. Chồng lên trên rẻ hơn và không mất gì.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khoa = ref.watch(lockGateProvider);

    // Đã biết chắc là không khoá — đường đi thường ngày, không tốn gì thêm.
    if (khoa == false) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          // `HitTestBehavior.opaque` để mọi cú chạm rơi vào khoảng trống của
          // màn hình khoá đều bị nuốt, không lọt xuống app bên dưới. Thiếu dòng
          // này thì người ta vẫn bấm mù được vào nút Lưu nằm sau lớp khoá.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: khoa == null
                ? const _Man()
                : LockScreen(
                    onUnlocked: (_) =>
                        ref.read(lockGateProvider.notifier).unlock(),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Tấm che lúc còn đang hỏi DB xem có đặt PIN không.
///
/// Chỉ kéo dài vài khung hình, nhưng bắt buộc phải có: coi "chưa biết" là
/// "không khoá" đồng nghĩa số dư loé lên trước khi màn hình khoá kịp hiện.
class _Man extends StatelessWidget {
  const _Man();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.colorScheme.surface,
        child: const SizedBox.expand(),
      );
}
