import 'package:flutter/material.dart';

import '../../../core/platform/system_settings.dart';
import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';

/// Hướng dẫn giữ app chạy nền. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục H.2.
///
/// **Vì sao màn hình này tồn tại:** MIUI (và ColorOS, Funtouch, EMUI) giết
/// tiến trình nền rất mạnh. Nếu app bị giết, khoản định kỳ không tự ghi được
/// và lời nhắc hằng ngày không bao giờ đến — mà người dùng sẽ nghĩ app hỏng
/// chứ không nghĩ do hệ điều hành.
///
/// App đã thiết kế để **sống được kể cả khi lớp nền không bao giờ chạy**: mỗi
/// lần mở app đều quét và ghi bù các kỳ đã lỡ. Nhưng lời nhắc thì không có
/// đường lùi nào — nó buộc phải chạy nền.
class BackgroundGuideScreen extends StatefulWidget {
  const BackgroundGuideScreen({super.key});

  @override
  State<BackgroundGuideScreen> createState() => _BackgroundGuideScreenState();
}

class _BackgroundGuideScreenState extends State<BackgroundGuideScreen> {
  bool _laMiui = false;

  @override
  void initState() {
    super.initState();
    SystemSettings.isMiui().then((v) {
      if (mounted) setState(() => _laMiui = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giữ app chạy nền')),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.screenPadding),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: context.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: Tokens.md),
                      Expanded(
                        child: Text(
                          _laMiui
                              ? 'Máy của bạn dùng MIUI'
                              : 'Nếu lời nhắc không đến',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.md),
                  Text(
                    _laMiui
                        ? 'MIUI giết tiến trình nền rất mạnh. Bật hai mục dưới '
                            'đây thì lời nhắc hằng ngày mới đến đúng giờ.'
                        : 'Một số hãng giới hạn tiến trình nền. Bật hai mục '
                            'dưới đây nếu lời nhắc không đến.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.xl),

          const _Buoc(
            so: 1,
            tieuDe: 'Bật Tự khởi động',
            moTa: 'Cho phép app tự chạy lại sau khi bị hệ thống đóng. '
                'Không có nó, khoản định kỳ chỉ được ghi khi bạn mở app.',
            nhanNut: 'Mở trang Tự khởi động',
            hanhDong: SystemSettings.openAutoStartSettings,
          ),
          const _Buoc(
            so: 2,
            tieuDe: 'Bỏ giới hạn pin',
            moTa: 'Đặt app ở chế độ "Không giới hạn" trong mục tiết kiệm pin. '
                'Đây là thứ hay chặn lời nhắc hằng ngày nhất.',
            nhanNut: 'Mở cài đặt pin',
            hanhDong: SystemSettings.openBatterySettings,
          ),
          const _Buoc(
            so: 3,
            tieuDe: 'Cho phép thông báo',
            moTa: 'Từ Android 13, app phải xin quyền thông báo. Nếu bạn từng '
                'bấm Từ chối, phải bật lại ở trang thông tin app.',
            nhanNut: 'Mở thông tin app',
            hanhDong: SystemSettings.openAppSettings,
          ),

          const SizedBox(height: Tokens.xl),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Không bật cũng không mất dữ liệu',
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Tokens.sm),
                  Text(
                    'App được thiết kế để sống được kể cả khi hệ điều hành '
                    'không bao giờ cho chạy nền: mỗi lần bạn mở app, nó tự quét '
                    'và ghi bù mọi khoản định kỳ đã đến hạn — kể cả khi bạn '
                    'không mở app suốt ba tháng.\n\n'
                    'Chỉ riêng lời nhắc hằng ngày là buộc phải chạy nền, vì '
                    'không có cách nào nhắc bạn khi app đang đóng.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.xxl),
        ],
      ),
    );
  }
}

class _Buoc extends StatelessWidget {
  const _Buoc({
    required this.so,
    required this.tieuDe,
    required this.moTa,
    required this.nhanNut,
    required this.hanhDong,
  });

  final int so;
  final String tieuDe;
  final String moTa;
  final String nhanNut;
  final Future<bool> Function() hanhDong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.lg),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: Tokens.lg,
                    backgroundColor: context.colorScheme.primaryContainer,
                    child: Text(
                      '$so',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: Tokens.md),
                  Expanded(
                    child: Text(tieuDe, style: context.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.md),
              Text(
                moTa,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Tokens.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(nhanNut),
                  onPressed: () async {
                    final moDuoc = await hanhDong();
                    if (!context.mounted || moDuoc) return;

                    // Không mở được trang nào — nói thật thay vì im lặng.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Máy này không có trang cài đặt đó. '
                          'Tìm trong Cài đặt → Ứng dụng → Sổ thu chi.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
