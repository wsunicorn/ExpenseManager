import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/utils/date_range.dart';
import '../domain/csv_export.dart';

/// Xuất dữ liệu và sao lưu. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục G.
///
/// Không ghi ra thư mục cố định rồi mới chia sẻ, mà đưa thẳng byte cho
/// `share_plus`. Lý do: trên Android 11+ quyền ghi vào bộ nhớ chung bị siết
/// rất chặt, còn hộp thoại chia sẻ thì để người dùng tự chọn đích — Drive,
/// Zalo, Gmail, hay lưu vào Files. Ít quyền hơn, ít đường hỏng hơn.
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  /// Xuất giao dịch trong khoảng ngày ra CSV rồi mở hộp thoại chia sẻ.
  Future<void> exportCsv({required DateRange range}) async {
    final rows = await _db.transactionDao
        .watchBetween(range.start, range.end)
        .first;

    await _share(
      bytes: buildCsvBytes(rows),
      fileName: csvFileName(),
      mimeType: 'text/csv',
      subject: 'Sổ thu chi — xuất CSV',
    );
  }

  /// Xuất Excel nhiều sheet. Đặc tả mục G.2.
  ///
  /// Bốn sheet: `GiaoDich`, `TheoDanhMuc`, `TheoVi`, `TongQuan`.
  Future<void> exportExcel({required DateRange range}) async {
    final excel = Excel.createExcel();

    final rows = await _db.transactionDao
        .watchBetween(range.start, range.end)
        .first;

    await _sheetGiaoDich(excel, rows);
    await _sheetTheoDanhMuc(excel, range);
    await _sheetTheoVi(excel, range);
    await _sheetTongQuan(excel, range, rows);

    // Excel.createExcel() tạo sẵn một sheet trống tên "Sheet1"; bỏ đi cho gọn.
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    final bytes = excel.encode();
    if (bytes == null) return;

    await _share(
      bytes: Uint8List.fromList(bytes),
      fileName:
          'sothuchi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'Sổ thu chi — xuất Excel',
    );
  }

  Future<void> _sheetGiaoDich(
    Excel excel,
    List<TransactionDetail> rows,
  ) async {
    final sheet = excel['GiaoDich'];
    final ngay = DateFormat('yyyy-MM-dd');

    sheet.appendRow(kCsvHeader.map(TextCellValue.new).toList());
    for (final d in rows) {
      sheet.appendRow([
        TextCellValue(ngay.format(d.transaction.date)),
        TextCellValue(csvTypeLabel(d.transaction.type)),
        // Ghi bằng IntCellValue chứ không phải chuỗi, để Excel cộng được.
        IntCellValue(d.transaction.amount),
        TextCellValue(d.wallet?.currency ?? 'VND'),
        TextCellValue(d.wallet?.name ?? ''),
        TextCellValue(d.category?.name ?? ''),
        TextCellValue(d.transaction.note),
        TextCellValue(d.toWallet?.name ?? ''),
        IntCellValue(d.transaction.id),
      ]);
    }
  }

  Future<void> _sheetTheoDanhMuc(Excel excel, DateRange range) async {
    final sheet = excel['TheoDanhMuc'];
    sheet.appendRow([
      TextCellValue('danh_muc'),
      TextCellValue('loai'),
      TextCellValue('tong_tien'),
      TextCellValue('so_giao_dich'),
    ]);

    for (final type in [TransactionType.expense, TransactionType.income]) {
      final totals = await _db.transactionDao
          .watchCategoryTotals(from: range.start, to: range.end, type: type)
          .first;
      for (final c in totals) {
        sheet.appendRow([
          TextCellValue(c.name),
          TextCellValue(type.name),
          IntCellValue(c.amount),
          IntCellValue(c.count),
        ]);
      }
    }
  }

  Future<void> _sheetTheoVi(Excel excel, DateRange range) async {
    final sheet = excel['TheoVi'];
    sheet.appendRow([
      TextCellValue('vi'),
      TextCellValue('so_du_goc'),
      TextCellValue('so_du_hien_tai'),
      TextCellValue('tinh_vao_tong'),
    ]);

    final wallets =
        await _db.walletDao.watchWalletsWithBalance(includeArchived: true).first;
    for (final w in wallets) {
      sheet.appendRow([
        TextCellValue(w.wallet.name),
        IntCellValue(w.wallet.initialBalance),
        IntCellValue(w.balance),
        TextCellValue(w.wallet.includeInTotal ? 'co' : 'khong'),
      ]);
    }
  }

  Future<void> _sheetTongQuan(
    Excel excel,
    DateRange range,
    List<TransactionDetail> rows,
  ) async {
    final sheet = excel['TongQuan'];
    final totals = await _db.transactionDao
        .watchTotals(range.start, range.end)
        .first;
    final ngay = DateFormat('yyyy-MM-dd');

    void dong(String nhan, CellValue giaTri) =>
        sheet.appendRow([TextCellValue(nhan), giaTri]);

    dong('tu_ngay', TextCellValue(ngay.format(range.start)));
    dong('den_ngay', TextCellValue(ngay.format(range.end)));
    dong('so_ngay', IntCellValue(range.dayCount));
    dong('tong_thu', IntCellValue(totals.income));
    dong('tong_chi', IntCellValue(totals.expense));
    dong('chenh_lech', IntCellValue(totals.income - totals.expense));
    dong('so_giao_dich', IntCellValue(rows.length));
    dong(
      'xuat_luc',
      TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
    );
  }

  /// Sao lưu toàn bộ dữ liệu ra file `.zip`. Đặc tả mục G.3.
  ///
  /// Nội dung là **JSON của từng bảng**, không phải copy thẳng file `.db`.
  /// Lý do: file SQLite chỉ khôi phục được bởi đúng phiên bản schema sinh ra
  /// nó, còn JSON thì đọc được bằng mắt và phục hồi được kể cả khi schema đã
  /// đổi. Với dữ liệu tài chính không thể tạo lại, đọc được bằng mắt là một
  /// tính năng.
  Future<void> backup() async {
    final duLieu = <String, dynamic>{
      'schema_version': _db.schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'wallets': await _rowsAsJson(_db.select(_db.wallets).get()),
      'categories': await _rowsAsJson(_db.select(_db.categories).get()),
      'transactions': await _rowsAsJson(_db.select(_db.transactions).get()),
      'budgets': await _rowsAsJson(_db.select(_db.budgets).get()),
      'recurring_rules':
          await _rowsAsJson(_db.select(_db.recurringRules).get()),
      'settings': await _rowsAsJson(_db.select(_db.appSettings).get()),
    };

    final json = const JsonEncoder.withIndent('  ').convert(duLieu);

    final noiDung = utf8.encode(json);
    // archive 3.6 nhận (tên, kích thước, nội dung) — chưa có API `bytes()`.
    final archive = Archive()
      ..addFile(ArchiveFile('sothuchi.json', noiDung.length, noiDung));

    final zip = ZipEncoder().encode(archive);
    if (zip == null) return;

    await _share(
      bytes: Uint8List.fromList(zip),
      fileName:
          'sothuchi_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.zip',
      mimeType: 'application/zip',
      subject: 'Sổ thu chi — sao lưu',
    );
  }

  Future<List<Map<String, dynamic>>> _rowsAsJson(
    Future<List<DataClass>> rows,
  ) async {
    return (await rows).map((r) => r.toJson()).toList();
  }

  Future<void> _share({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        files: [
          XFile.fromData(bytes, name: fileName, mimeType: mimeType),
        ],
        // Bắt buộc trên web: trình duyệt cần tên file để đặt cho bản tải về.
        fileNameOverrides: [fileName],
      ),
    );
  }
}
