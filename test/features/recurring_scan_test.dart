import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/recurring/data/recurring_repository.dart';

/// Quét và ghi bù khoản định kỳ — `01_DAC_TA_TINH_NANG.md` mục H.2.
void main() {
  late AppDatabase db;
  late RecurringRepository repo;
  late int viId;
  late int dmId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecurringRepository(db);

    viId = await db.walletDao.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        type: WalletType.cash,
        iconCode: 1,
        colorValue: 1,
        initialBalance: const Value(50000000),
      ),
    );
    final rows = await (db.select(db.categories)
          ..where((c) => c.name.equals('Tiền nhà')))
        .get();
    dmId = rows.single.id;
  });

  tearDown(() async => db.close());

  Future<int> taoQuyTac({
    bool autoPost = true,
    required DateTime startDate,
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  }) =>
      repo.createRule(
        type: TransactionType.expense,
        amount: 4000000,
        walletId: viId,
        categoryId: dmId,
        frequency: frequency,
        startDate: startDate,
        autoPost: autoPost,
        note: 'Tiền nhà',
      );

  Future<List<Transaction>> giaoDich() => db.select(db.transactions).get();

  group('tự động ghi', () {
    test('ghi kỳ đầu tiên đúng ngày bắt đầu', () async {
      await taoQuyTac(startDate: DateTime(2026, 8, 1));
      final r = await repo.scanAndPost(now: DateTime(2026, 8, 5));

      expect(r.postedCount, 1);
      final tx = (await giaoDich()).single;
      expect(tx.date, DateTime(2026, 8, 1));
      expect(tx.amount, 4000000);
      expect(tx.recurringRuleId, isNotNull);
    });

    /// Đây là lý do lớp quét-khi-mở-app tồn tại: MIUI giết tiến trình nền, nên
    /// app có thể không chạy nền suốt ba tháng.
    test('bù đủ mọi kỳ đã lỡ, không phải chỉ một', () async {
      await taoQuyTac(startDate: DateTime(2026, 5, 1));
      final r = await repo.scanAndPost(now: DateTime(2026, 8, 24));

      expect(r.postedCount, 4, reason: 'tháng 5, 6, 7, 8');
      final list = await giaoDich();
      expect(list.map((t) => t.date), [
        DateTime(2026, 5, 1),
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
      ]);
    });

    /// Quét hai lần liên tiếp không được sinh giao dịch trùng.
    test('quét lại không ghi trùng', () async {
      await taoQuyTac(startDate: DateTime(2026, 8, 1));
      await repo.scanAndPost(now: DateTime(2026, 8, 24));
      final lan2 = await repo.scanAndPost(now: DateTime(2026, 8, 24));

      expect(lan2.postedCount, 0);
      expect(await giaoDich(), hasLength(1));
    });

    test('số dư ví bị trừ đúng sau khi ghi bù', () async {
      await taoQuyTac(startDate: DateTime(2026, 6, 1));
      await repo.scanAndPost(now: DateTime(2026, 8, 24));

      // 3 kỳ × 4 triệu
      expect(await db.walletDao.watchBalance(viId).first, 50000000 - 12000000);
    });

    test('quy tắc đã tắt thì không ghi gì', () async {
      final id = await taoQuyTac(startDate: DateTime(2026, 5, 1));
      await repo.setActive(id, active: false);

      final r = await repo.scanAndPost(now: DateTime(2026, 8, 24));
      expect(r.postedCount, 0);
      expect(await giaoDich(), isEmpty);
    });

    test('chưa tới ngày bắt đầu thì chưa ghi', () async {
      await taoQuyTac(startDate: DateTime(2026, 12, 1));
      final r = await repo.scanAndPost(now: DateTime(2026, 8, 24));
      expect(r.postedCount, 0);
    });
  });

  group('nhắc xác nhận', () {
    test('không tự ghi, chỉ báo lên chờ duyệt', () async {
      await taoQuyTac(startDate: DateTime(2026, 8, 1), autoPost: false);
      final r = await repo.scanAndPost(now: DateTime(2026, 8, 24));

      expect(r.postedCount, 0);
      expect(r.pendingConfirmation, hasLength(1));
      expect(await giaoDich(), isEmpty);
    });

    /// Tiền điện tháng nào cũng khác — sửa được số tiền lúc xác nhận là điểm
    /// mấu chốt, không có nó thì chế độ này vô dụng.
    test('xác nhận với số tiền khác thì ghi theo số mới', () async {
      await taoQuyTac(startDate: DateTime(2026, 8, 1), autoPost: false);
      final r = await repo.scanAndPost(now: DateTime(2026, 8, 24));

      await repo.confirmOccurrence(
        r.pendingConfirmation.single,
        amountOverride: 850000,
      );

      final tx = (await giaoDich()).single;
      expect(tx.amount, 850000);
    });

    test('bỏ qua một kỳ thì không ghi nhưng cũng không hỏi lại', () async {
      await taoQuyTac(startDate: DateTime(2026, 8, 1), autoPost: false);
      final r1 = await repo.scanAndPost(now: DateTime(2026, 8, 24));
      await repo.skipOccurrence(r1.pendingConfirmation.first);

      final r2 = await repo.scanAndPost(now: DateTime(2026, 8, 24));
      expect(r2.pendingConfirmation, isEmpty);
      expect(await giaoDich(), isEmpty);
    });
  });

  group('quy tắc hết hạn', () {
    test('tự tắt sau kỳ cuối cùng', () async {
      final id = await repo.createRule(
        type: TransactionType.expense,
        amount: 100000,
        walletId: viId,
        categoryId: dmId,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 15),
      );

      final r = await repo.scanAndPost(now: DateTime(2026, 8, 24));
      expect(r.postedCount, 2, reason: 'tháng 6 và tháng 7');

      final rule = await (db.select(db.recurringRules)
            ..where((x) => x.id.equals(id)))
          .getSingle();
      expect(rule.isActive, isFalse);
    });
  });

  group('ngày 31 hằng tháng', () {
    /// Bài kiểm tra thật của nextOccurrence trên dữ liệu thật.
    test('lùi về ngày cuối tháng ngắn nhưng không trôi ngày', () async {
      await taoQuyTac(startDate: DateTime(2026, 1, 31));
      await repo.scanAndPost(now: DateTime(2026, 5, 15));

      final list = await giaoDich();
      expect(list.map((t) => t.date), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });
  });
}
