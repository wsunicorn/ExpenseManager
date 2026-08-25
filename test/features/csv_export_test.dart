import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/db/database.dart';
import 'package:so_thu_chi/core/db/enums.dart';
import 'package:so_thu_chi/features/backup/domain/csv_export.dart';
import 'package:so_thu_chi/features/entry/data/transaction_repository.dart';

/// Xuất CSV — `01_DAC_TA_TINH_NANG.md` mục G.1.
void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late int viTienMat;
  late int viMoMo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);

    Future<int> taoVi(String ten) => db.walletDao.insertWallet(
          WalletsCompanion.insert(
            name: ten,
            type: WalletType.cash,
            iconCode: 1,
            colorValue: 1,
            initialBalance: const Value(10000000),
          ),
        );
    viTienMat = await taoVi('Tiền mặt');
    viMoMo = await taoVi('MoMo');

    final dm = await (db.select(db.categories)
          ..where((c) => c.name.equals('Ăn uống')))
        .get();

    await repo.saveIncomeOrExpense(
      type: TransactionType.expense,
      amount: 50000,
      walletId: viTienMat,
      categoryId: dm.single.id,
      date: DateTime(2026, 8, 24),
      note: 'Cơm trưa văn phòng',
    );
  });

  tearDown(() async => db.close());

  Future<List<dynamic>> layGiaoDich() => db.transactionDao
      .watchBetween(DateTime(2026, 1, 1), DateTime(2026, 12, 31))
      .first;

  group('BOM UTF-8', () {
    /// Đặc tả gọi đây là "lỗi kinh điển": thiếu BOM thì Excel trên Windows
    /// đoán mã hoá theo locale và mọi chữ tiếng Việt hiện thành ký tự rác.
    test('file luôn bắt đầu bằng EF BB BF', () async {
      final bytes = buildCsvBytes(
        (await layGiaoDich()).cast(),
      );
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('bỏ BOM đi thì phần còn lại vẫn là UTF-8 hợp lệ', () async {
      final bytes = buildCsvBytes((await layGiaoDich()).cast());
      final text = utf8.decode(bytes.sublist(3));
      expect(text, contains('Cơm trưa văn phòng'));
    });
  });

  group('nội dung', () {
    test('dòng đầu là tên cột đúng đặc tả', () async {
      final rows = buildCsvRows((await layGiaoDich()).cast());
      expect(rows.first, [
        'ngay',
        'loai',
        'so_tien',
        'tien_te',
        'vi',
        'danh_muc',
        'ghi_chu',
        'vi_dich',
        'id',
      ]);
    });

    test('ghi đủ dữ liệu của một giao dịch', () async {
      final rows = buildCsvRows((await layGiaoDich()).cast());
      final r = rows[1];
      expect(r[0], '2026-08-24');
      expect(r[1], 'expense');
      expect(r[2], '50000');
      expect(r[3], 'VND');
      expect(r[4], 'Tiền mặt');
      expect(r[5], 'Ăn uống');
      expect(r[6], 'Cơm trưa văn phòng');
      expect(r[7], '');
    });

    /// Số phải là số trần để Excel nhận ra là số, không phải chuỗi.
    test('số tiền không có dấu phân cách nghìn hay ký hiệu tiền tệ', () async {
      final rows = buildCsvRows((await layGiaoDich()).cast());
      expect(rows[1][2], '50000');
      expect(rows[1][2], isNot(contains('.')));
      expect(rows[1][2], isNot(contains('đ')));
    });

    test('chuyển ví ghi cả ví nguồn và ví đích', () async {
      await repo.saveTransfer(
        amount: 500000,
        fromWalletId: viTienMat,
        toWalletId: viMoMo,
        date: DateTime(2026, 8, 25),
      );

      final rows = buildCsvRows((await layGiaoDich()).cast());
      final chuyen = rows.firstWhere((r) => r[1] == 'transfer');
      expect(chuyen[4], 'Tiền mặt');
      expect(chuyen[7], 'MoMo');
      expect(chuyen[5], '', reason: 'chuyển ví không có danh mục');
    });

    test('điều chỉnh giữ nguyên dấu âm', () async {
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.adjustment,
              amount: -23000,
              walletId: viTienMat,
              date: DateTime(2026, 8, 26),
            ),
          );

      final rows = buildCsvRows((await layGiaoDich()).cast());
      final dc = rows.firstWhere((r) => r[1] == 'adjustment');
      expect(dc[2], '-23000');
    });
  });

  group('định dạng file', () {
    test('dùng CRLF như Excel mong đợi', () async {
      final csv = buildCsvString((await layGiaoDich()).cast());
      expect(csv, contains('\r\n'));
    });

    /// Ghi chú chứa dấu phẩy mà không bọc ngoặc kép sẽ làm lệch cả bảng.
    test('ghi chú có dấu phẩy được bọc ngoặc kép', () async {
      final dm = await (db.select(db.categories)
            ..where((c) => c.name.equals('Ăn uống')))
          .get();
      await repo.saveIncomeOrExpense(
        type: TransactionType.expense,
        amount: 10000,
        walletId: viTienMat,
        categoryId: dm.single.id,
        date: DateTime(2026, 8, 27),
        note: 'Cà phê, bánh mì',
      );

      final csv = buildCsvString((await layGiaoDich()).cast());
      expect(csv, contains('"Cà phê, bánh mì"'));
    });

    test('tên file có dấu thời gian', () {
      final ten = csvFileName(now: DateTime(2026, 8, 24, 15, 42));
      expect(ten, 'sothuchi_20260824_1542.csv');
    });
  });
}
