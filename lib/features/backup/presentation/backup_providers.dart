import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../shared/providers/database_provider.dart';
import '../data/export_service.dart';

part 'backup_providers.g.dart';

@Riverpod(keepAlive: true)
ExportService exportService(Ref ref) =>
    ExportService(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
RestoreService restoreService(Ref ref) =>
    RestoreService(ref.watch(appDatabaseProvider));

/// Kết quả khôi phục.
sealed class RestoreResult {
  const RestoreResult();
}

class RestoreOk extends RestoreResult {
  const RestoreOk(this.counts);

  /// Số dòng đã nạp cho từng bảng.
  final Map<String, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);
}

class RestoreFailed extends RestoreResult {
  const RestoreFailed(this.reason);

  final String reason;
}

/// Khôi phục dữ liệu từ file sao lưu `.zip`. Đặc tả mục G.3.
class RestoreService {
  RestoreService(this._db);

  final AppDatabase _db;

  /// Đọc file zip người dùng chọn và nạp đè toàn bộ dữ liệu.
  ///
  /// **Thay thế toàn bộ dữ liệu hiện tại.** Màn hình phải cảnh báo rõ trước
  /// khi gọi hàm này — không có đường lùi.
  ///
  /// Toàn bộ việc xoá và nạp nằm trong một transaction: nếu file hỏng giữa
  /// chừng, dữ liệu cũ còn nguyên. Xoá trước rồi nạp ngoài transaction là cách
  /// chắc chắn để mất sạch dữ liệu khi gặp file lỗi.
  Future<RestoreResult> restoreFromFile() async {
    // file_picker 12 dùng API tĩnh `pickFile`, trả thẳng `PlatformFile?` —
    // không còn `FilePicker.platform` hay `FilePickerResult` như bản cũ.
    final chon = await FilePicker.pickFile(
      dialogTitle: 'Chọn file sao lưu',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (chon == null) {
      return const RestoreFailed('Chưa chọn file nào.');
    }

    try {
      // `readAsBytes()` thay cho cờ `withData` đã bị khai tử; nó chạy được
      // trên cả web lẫn native.
      final bytes = await chon.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.files.where((f) => f.name == 'sothuchi.json');
      if (file.isEmpty) {
        return const RestoreFailed(
          'File này không phải bản sao lưu của Sổ thu chi '
          '(thiếu sothuchi.json).',
        );
      }

      final json = jsonDecode(
        utf8.decode(file.first.content as List<int>),
      ) as Map<String, dynamic>;

      return await _apply(json);
    } on Exception catch (e) {
      return RestoreFailed('File sao lưu hỏng hoặc sai định dạng.\n$e');
    }
  }

  Future<RestoreResult> _apply(Map<String, dynamic> json) async {
    final counts = <String, int>{};

    await _db.transaction(() async {
      // Xoá theo thứ tự ngược với phụ thuộc khoá ngoại: bảng con trước.
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.wallets).go();
      await _db.delete(_db.appSettings).go();

      // Rồi nạp theo thứ tự xuôi: bảng cha trước.
      counts['wallets'] = await _insertAll(
        json['wallets'],
        (m) => _db.into(_db.wallets).insert(Wallet.fromJson(m)),
      );
      counts['categories'] = await _insertAll(
        json['categories'],
        (m) => _db.into(_db.categories).insert(Category.fromJson(m)),
      );
      counts['recurring_rules'] = await _insertAll(
        json['recurring_rules'],
        (m) => _db.into(_db.recurringRules).insert(RecurringRule.fromJson(m)),
      );
      counts['transactions'] = await _insertAll(
        json['transactions'],
        (m) => _db.into(_db.transactions).insert(Transaction.fromJson(m)),
      );
      counts['budgets'] = await _insertAll(
        json['budgets'],
        (m) => _db.into(_db.budgets).insert(Budget.fromJson(m)),
      );
      counts['settings'] = await _insertAll(
        json['settings'],
        (m) => _db.into(_db.appSettings).insert(AppSetting.fromJson(m)),
      );
    });

    return RestoreOk(counts);
  }

  Future<int> _insertAll(
    dynamic raw,
    Future<void> Function(Map<String, dynamic>) insert,
  ) async {
    if (raw is! List) return 0;
    for (final item in raw) {
      await insert(item as Map<String, dynamic>);
    }
    return raw.length;
  }
}
