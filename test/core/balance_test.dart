// `Value` — bọc giá trị cho các cột tuỳ chọn của Companion. Nó ở drift.dart,
// không phải drift/native.dart.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';

/// Test bắt buộc số 2 trong `CONVENTIONS.md`: công thức tính số dư ví.
///
/// Chạy trên DB SQLite **hoàn toàn trong RAM** — không đụng file, không cần
/// thiết bị, không ảnh hưởng dữ liệu thật. Mỗi test có DB riêng tinh khôi.
///
/// Đây là test đáng giá nhất trong toàn dự án: sai công thức số dư thì mọi con
/// số app hiển thị đều sai, mà lại rất khó nhận ra bằng mắt.
void main() {
  late AppDatabase db;

  /// Ngày cố định để test không phụ thuộc lúc chạy.
  final ngay = DateTime(2026, 8, 24);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Tạo ví, trả về id.
  Future<int> taoVi({
    required String ten,
    required int soDuGoc,
    bool tinhVaoTong = true,
  }) {
    return db.walletDao.insertWallet(
      WalletsCompanion.insert(
        name: ten,
        type: WalletType.cash,
        iconCode: 0xe263,
        colorValue: 0xFF43A047,
        initialBalance: Value(soDuGoc),
        includeInTotal: Value(tinhVaoTong),
      ),
    );
  }

  Future<void> ghiGiaoDich({
    required TransactionType loai,
    required int soTien,
    required int viId,
    int? viDichId,
    int? danhMucId,
  }) async {
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            type: loai,
            amount: soTien,
            walletId: viId,
            toWalletId: Value(viDichId),
            categoryId: Value(danhMucId),
            date: ngay,
          ),
        );
  }

  /// Lấy id một danh mục chi bất kỳ trong bộ seed.
  Future<int> motDanhMucChi() async {
    final rows = await (db.select(db.categories)
          ..where((c) => c.type.equalsValue(CategoryType.expense))
          ..limit(1))
        .get();
    return rows.single.id;
  }

  group('seed dữ liệu ban đầu', () {
    test('DB mới có sẵn 20 danh mục mặc định — 14 chi, 6 thu', () async {
      final all = await db.select(db.categories).get();
      expect(all.length, 20);
      expect(
        all.where((c) => c.type == CategoryType.expense).length,
        14,
      );
      expect(
        all.where((c) => c.type == CategoryType.income).length,
        6,
      );
    });

    test('có "Phí ngân hàng" — danh mục nhận phí khi chuyển ví', () async {
      final all = await db.select(db.categories).get();
      expect(all.map((c) => c.name), contains('Phí ngân hàng'));
    });

    test('cài đặt mặc định được ghi sẵn', () async {
      final settings = await db.select(db.appSettings).get();
      final map = {for (final s in settings) s.key: s.value};
      expect(map['onboarding_done'], 'false');
      expect(map['month_start_day'], '1');
    });
  });

  group('số dư một ví', () {
    test('ví mới chưa có giao dịch trả về đúng số dư gốc', () async {
      final id = await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      expect(await db.walletDao.watchBalance(id).first, 5000000);
    });

    /// Đây chính là tiêu chí "Xong khi" của Phase 2 trong `04_LO_TRINH.md`.
    test('5.000.000 gốc trừ một khoản chi 50.000 còn 4.950.000', () async {
      final id = await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      await ghiGiaoDich(
        loai: TransactionType.expense,
        soTien: 50000,
        viId: id,
        danhMucId: await motDanhMucChi(),
      );
      expect(await db.walletDao.watchBalance(id).first, 4950000);
    });

    test('thu cộng vào, chi trừ ra', () async {
      final id = await taoVi(ten: 'Tiền mặt', soDuGoc: 1000000);
      final dm = await motDanhMucChi();
      await ghiGiaoDich(
        loai: TransactionType.income,
        soTien: 200000,
        viId: id,
        danhMucId: dm,
      );
      await ghiGiaoDich(
        loai: TransactionType.expense,
        soTien: 50000,
        viId: id,
        danhMucId: dm,
      );
      expect(await db.walletDao.watchBalance(id).first, 1150000);
    });

    test('điều chỉnh được phép âm — ngoại lệ duy nhất của quy tắc dương',
        () async {
      final id = await taoVi(ten: 'Tiền mặt', soDuGoc: 1000000);
      await ghiGiaoDich(
        loai: TransactionType.adjustment,
        soTien: -23000,
        viId: id,
      );
      expect(await db.walletDao.watchBalance(id).first, 977000);
    });

    test('thẻ tín dụng để số dư âm là bình thường', () async {
      final id = await taoVi(ten: 'Thẻ tín dụng', soDuGoc: 0);
      await ghiGiaoDich(
        loai: TransactionType.expense,
        soTien: 2000000,
        viId: id,
        danhMucId: await motDanhMucChi(),
      );
      expect(await db.walletDao.watchBalance(id).first, -2000000);
    });
  });

  group('chuyển ví', () {
    test('trừ ví nguồn, cộng ví đích, chỉ bằng một dòng dữ liệu', () async {
      final nguon = await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      final dich = await taoVi(ten: 'MoMo', soDuGoc: 0);

      await ghiGiaoDich(
        loai: TransactionType.transfer,
        soTien: 500000,
        viId: nguon,
        viDichId: dich,
      );

      expect(await db.walletDao.watchBalance(nguon).first, 4500000);
      expect(await db.walletDao.watchBalance(dich).first, 500000);

      // Đúng một bản ghi, không phải cặp đối ứng — quyết định thiết kế ở
      // file 02 mục 4.3.
      final all = await db.select(db.transactions).get();
      expect(all.length, 1);
    });

    test('không làm đổi tổng tài sản — tiền chỉ đi từ túi này sang túi kia',
        () async {
      final nguon = await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      final dich = await taoVi(ten: 'MoMo', soDuGoc: 1000000);
      final truoc = await db.walletDao.watchTotalBalance().first;

      await ghiGiaoDich(
        loai: TransactionType.transfer,
        soTien: 500000,
        viId: nguon,
        viDichId: dich,
      );

      expect(await db.walletDao.watchTotalBalance().first, truoc);
      expect(truoc, 6000000);
    });
  });

  group('tổng tài sản', () {
    test('chỉ cộng ví có includeInTotal = true', () async {
      await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      await taoVi(ten: 'Sổ tiết kiệm', soDuGoc: 50000000, tinhVaoTong: false);
      expect(await db.walletDao.watchTotalBalance().first, 5000000);
    });

    test('bỏ qua ví đã lưu trữ', () async {
      await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      final cu = await taoVi(ten: 'Ví cũ', soDuGoc: 300000);
      expect(await db.walletDao.watchTotalBalance().first, 5300000);

      await db.walletDao.archiveWallet(cu);
      expect(await db.walletDao.watchTotalBalance().first, 5000000);
    });

    test('không có ví nào thì trả 0, không phải null', () async {
      expect(await db.walletDao.watchTotalBalance().first, 0);
    });
  });

  group('danh sách ví kèm số dư', () {
    test('sắp theo sortOrder và loại ví đã lưu trữ ra khỏi danh sách', () async {
      final a = await taoVi(ten: 'Tiền mặt', soDuGoc: 1000000);
      await taoVi(ten: 'MoMo', soDuGoc: 2000000);
      await db.walletDao.archiveWallet(a);

      final list = await db.walletDao.watchWalletsWithBalance().first;
      expect(list.length, 1);
      expect(list.single.wallet.name, 'MoMo');
      expect(list.single.balance, 2000000);

      final all = await db.walletDao
          .watchWalletsWithBalance(includeArchived: true)
          .first;
      expect(all.length, 2);
    });

    test('số dư tính đúng cho từng ví trong danh sách', () async {
      final tienMat = await taoVi(ten: 'Tiền mặt', soDuGoc: 5000000);
      final momo = await taoVi(ten: 'MoMo', soDuGoc: 0);
      final dm = await motDanhMucChi();

      await ghiGiaoDich(
        loai: TransactionType.expense,
        soTien: 50000,
        viId: tienMat,
        danhMucId: dm,
      );
      await ghiGiaoDich(
        loai: TransactionType.transfer,
        soTien: 500000,
        viId: tienMat,
        viDichId: momo,
      );

      final list = await db.walletDao.watchWalletsWithBalance().first;
      final byName = {for (final w in list) w.wallet.name: w.balance};
      expect(byName['Tiền mặt'], 4450000);
      expect(byName['MoMo'], 500000);
    });
  });

  group('ràng buộc dữ liệu', () {
    test('khoá ngoại được bật — không tạo được giao dịch vào ví không tồn tại',
        () async {
      expect(
        () => ghiGiaoDich(
          loai: TransactionType.expense,
          soTien: 50000,
          viId: 9999,
          danhMucId: 1,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('đếm được số giao dịch của một ví, kể cả vế nhận của chuyển ví',
        () async {
      final nguon = await taoVi(ten: 'Tiền mặt', soDuGoc: 1000000);
      final dich = await taoVi(ten: 'MoMo', soDuGoc: 0);

      expect(await db.walletDao.countTransactions(dich), 0);

      await ghiGiaoDich(
        loai: TransactionType.transfer,
        soTien: 100000,
        viId: nguon,
        viDichId: dich,
      );

      expect(await db.walletDao.countTransactions(nguon), 1);
      expect(await db.walletDao.countTransactions(dich), 1);
    });
  });

  group('stream tự cập nhật', () {
    test('thêm giao dịch thì stream số dư phát giá trị mới', () async {
      final id = await taoVi(ten: 'Tiền mặt', soDuGoc: 1000000);
      final stream = db.walletDao.watchBalance(id);

      final future = stream.take(2).toList();
      // Chờ giá trị đầu được phát trước khi ghi, nếu không hai giá trị có thể
      // bị gộp làm một và test sẽ treo.
      await Future<void>.delayed(Duration.zero);
      await ghiGiaoDich(
        loai: TransactionType.expense,
        soTien: 50000,
        viId: id,
        danhMucId: await motDanhMucChi(),
      );

      expect(await future, [1000000, 950000]);
    });
  });
}
