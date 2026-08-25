import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/money_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_range.dart';
import 'backup_providers.dart';

/// Các mục xuất dữ liệu và sao lưu trong tab Khác.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục G.
///
/// MoneyNote khoá toàn bộ phần này sau vương miện Premium. Ở đây không giới
/// hạn gì — đó là một trong những lý do dựng app này.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.ios_share_outlined),
          title: const Text('Xuất CSV'),
          subtitle: const Text(
            'UTF-8 có BOM, dấu phẩy — mở được bằng Excel và pandas',
          ),
          onTap: () => _xuat(context, ref, ExportFormat.csv),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('Xuất Excel'),
          subtitle: const Text(
            '4 sheet: GiaoDich, TheoDanhMuc, TheoVi, TongQuan',
          ),
          onTap: () => _xuat(context, ref, ExportFormat.excel),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Sao lưu toàn bộ'),
          subtitle: const Text('Nén thành file .zip để cất giữ hoặc chuyển máy'),
          onTap: () => ref.read(exportServiceProvider).backup(),
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('Khôi phục từ file sao lưu'),
          subtitle: const Text('Thay thế toàn bộ dữ liệu hiện tại'),
          onTap: () => _khoiPhuc(context, ref),
        ),
      ],
    );
  }

  Future<void> _xuat(
    BuildContext context,
    WidgetRef ref,
    ExportFormat format,
  ) async {
    final khoang = await _chonKhoang(context);
    if (khoang == null || !context.mounted) return;

    final service = ref.read(exportServiceProvider);
    if (format == ExportFormat.csv) {
      await service.exportCsv(range: khoang);
    } else {
      await service.exportExcel(range: khoang);
    }
  }

  /// Chọn khoảng thời gian trước khi xuất (đặc tả mục G.1).
  Future<DateRange?> _chonKhoang(BuildContext context) async {
    final now = DateTime.now();

    return showModalBottomSheet<DateRange>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.screenPadding),
              child: Text(
                'Xuất khoảng nào?',
                style: ctx.textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: const Text('Tháng này'),
              onTap: () => Navigator.pop(ctx, calendarMonthOf(now)),
            ),
            ListTile(
              title: const Text('Tháng trước'),
              onTap: () => Navigator.pop(
                ctx,
                calendarMonthOf(DateTime(now.year, now.month - 1)),
              ),
            ),
            ListTile(
              title: const Text('Năm nay'),
              onTap: () => Navigator.pop(ctx, calendarYearOf(now)),
            ),
            ListTile(
              title: const Text('Toàn bộ'),
              onTap: () => Navigator.pop(
                ctx,
                DateRange(DateTime(2000), DateTime(2100, 12, 31)),
              ),
            ),
            ListTile(
              title: const Text('Chọn khoảng ngày…'),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  locale: const Locale('vi'),
                );
                if (ctx.mounted) {
                  Navigator.pop(
                    ctx,
                    picked == null
                        ? null
                        : DateRange(picked.start, picked.end),
                  );
                }
              },
            ),
            const SizedBox(height: Tokens.md),
          ],
        ),
      ),
    );
  }

  /// Khôi phục — **hai lớp xác nhận** vì không có đường lùi.
  Future<void> _khoiPhuc(BuildContext context, WidgetRef ref) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thay thế toàn bộ dữ liệu?'),
        content: const Text(
          'Mọi ví, giao dịch, danh mục, ngân sách và khoản định kỳ hiện tại '
          'sẽ bị xoá và thay bằng nội dung file sao lưu.\n\n'
          'Không hoàn tác được. Nếu chưa chắc, hãy Sao lưu toàn bộ trước đã.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tôi hiểu, chọn file'),
          ),
        ],
      ),
    );
    if (!(dongY ?? false) || !context.mounted) return;

    final ketQua = await ref.read(restoreServiceProvider).restoreFromFile();
    if (!context.mounted) return;

    switch (ketQua) {
      case RestoreFailed(:final reason):
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Không khôi phục được'),
            content: Text(reason),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      case RestoreOk(:final counts, :final total):
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Đã khôi phục'),
            content: Text(
              'Nạp lại $total dòng:\n'
              '${counts.entries.map((e) => '· ${e.key}: ${e.value}').join('\n')}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Xong'),
              ),
            ],
          ),
        );
    }
  }
}

enum ExportFormat { csv, excel }
