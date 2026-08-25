import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/providers/database_provider.dart';
import '../data/recurring_repository.dart';

part 'recurring_providers.g.dart';

@Riverpod(keepAlive: true)
RecurringRepository recurringRepository(Ref ref) =>
    RecurringRepository(ref.watch(appDatabaseProvider));

/// Danh sách quy tắc định kỳ.
///
/// Viết tay vì kiểu trả về nhắc tới `RecurringRule` — lớp drift nằm trong file
/// `part`, mà `riverpod_generator` không sinh được tham chiếu tới đó.
final recurringRulesProvider = StreamProvider((ref) {
  return ref.watch(recurringRepositoryProvider).watchRules();
});

/// Kết quả lượt quét gần nhất, để giao diện biết có gì cần báo cho người dùng.
@Riverpod(keepAlive: true)
class RecurringScan extends _$RecurringScan {
  @override
  RecurringScanResult? build() => null;

  /// Quét khoản định kỳ đến hạn. Gọi mỗi lần mở app.
  ///
  /// Đây là **lớp đảm bảo** của đặc tả mục H.2 — luôn chạy, không phụ thuộc
  /// vào việc hệ điều hành có cho tiến trình nền sống hay không. Trên MIUI thì
  /// giả định an toàn là lớp nền **không bao giờ** chạy.
  Future<void> run() async {
    final ketQua = await ref.read(recurringRepositoryProvider).scanAndPost();
    state = ketQua;
  }

  /// Xoá kết quả sau khi người dùng đã xem xong.
  void clear() => state = null;

  Future<void> confirm(PendingOccurrence pending, {int? amountOverride}) async {
    await ref
        .read(recurringRepositoryProvider)
        .confirmOccurrence(pending, amountOverride: amountOverride);
    _remove(pending);
  }

  Future<void> skip(PendingOccurrence pending) async {
    await ref.read(recurringRepositoryProvider).skipOccurrence(pending);
    _remove(pending);
  }

  void _remove(PendingOccurrence pending) {
    final hienTai = state;
    if (hienTai == null) return;

    final conLai = hienTai.pendingConfirmation
        .where((p) => !(p.rule.id == pending.rule.id && p.date == pending.date))
        .toList();

    state = RecurringScanResult(
      postedCount: hienTai.postedCount,
      pendingConfirmation: conLai,
    );
  }
}
