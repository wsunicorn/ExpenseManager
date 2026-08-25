import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/utils/text_search.dart';

/// Kết quả ghi giao dịch.
sealed class SaveResult {
  const SaveResult();
}

/// Ghi thành công. [ids] gồm mọi dòng đã tạo — chuyển ví có phí sinh hai dòng,
/// nên hoàn tác phải xoá cả hai.
class SaveOk extends SaveResult {
  const SaveOk(this.ids);

  final List<int> ids;
}

/// Bị nghiệp vụ từ chối. [reason] là câu tiếng Việt hiện thẳng cho người dùng.
class SaveRejected extends SaveResult {
  const SaveRejected(this.reason);

  final String reason;
}

/// Tên danh mục nhận phí chuyển ví. Có sẵn trong bộ seed mặc định.
const String kBankFeeCategoryName = 'Phí ngân hàng';

/// Tầng nghiệp vụ của giao dịch.
///
/// Đây là nơi **duy nhất** kiểm tra các quy tắc ở `01_DAC_TA_TINH_NANG.md`
/// mục K. Đặt ở đây chứ không phải ở màn hình, vì sau này còn khoản định kỳ và
/// nhập từ widget cùng ghi giao dịch — cả ba đường đều phải qua cùng một cửa.
/// Gọi lại sau khi một khoản chi được ghi, để kiểm ngưỡng ngân sách.
typedef ExpenseRecordedCallback = Future<void> Function({
  required DateTime date,
  required int categoryId,
  required int spentDelta,
});

class TransactionRepository {
  TransactionRepository(this._db, {this.onExpenseRecorded, this.onDataChanged});

  final AppDatabase _db;

  /// Null trên nền không có thông báo (web) — khi đó bỏ qua hoàn toàn.
  final ExpenseRecordedCallback? onExpenseRecorded;

  /// Gọi sau mỗi thay đổi dữ liệu, để cập nhật widget màn hình chính.
  final Future<void> Function()? onDataChanged;

  TransactionDao get _dao => _db.transactionDao;

  // ── Đọc ───────────────────────────────────────────────────────────────────

  Stream<List<TransactionDetail>> watchBetween(DateTime from, DateTime to) =>
      _dao.watchBetween(DateUtils.dateOnly(from), DateUtils.dateOnly(to));

  Stream<({int income, int expense})> watchTotals(DateTime from, DateTime to) =>
      _dao.watchTotals(DateUtils.dateOnly(from), DateUtils.dateOnly(to));

  Future<List<String>> recentNotes() => _dao.recentNotes();

  // ── Ghi ───────────────────────────────────────────────────────────────────

  /// Ghi một khoản thu hoặc chi.
  ///
  /// Quy tắc số 8 (file 01 mục K): **không cho nhập số tiền ≤ 0.** Số 0 không
  /// mang thông tin gì, số âm thì đã có loại `expense` để diễn đạt.
  Future<SaveResult> saveIncomeOrExpense({
    required TransactionType type,
    required int amount,
    required int walletId,
    required int categoryId,
    required DateTime date,
    String note = '',
  }) async {
    assert(
      type == TransactionType.income || type == TransactionType.expense,
      'Hàm này chỉ dành cho thu và chi',
    );

    if (amount <= 0) {
      return const SaveRejected('Số tiền phải lớn hơn 0.');
    }

    final id = await _dao.insertTransaction(
      TransactionsCompanion.insert(
        type: type,
        amount: amount,
        walletId: walletId,
        categoryId: Value(categoryId),
        date: DateUtils.dateOnly(date),
        note: Value(note.trim()),
        noteAscii: Value(normalizeForSearch(note)),
      ),
    );

    // Hai viec duoi day KHONG duoc chan nut Luu.
    //
    // Kiem nguong ngan sach doc them tu DB, con cap nhat widget man hinh chinh
    // thi ba truy van cong mot luot goi qua kenh platform. Await ca hai lam
    // moi lan bam Luu kho gan nua giay - du de cam thay giat.
    //
    // Ca hai deu la viec phu: giao dich da ghi xong roi, va neu chung that bai
    // thi cung khong anh huong so lieu.
    if (type == TransactionType.expense) {
      unawaited(
        onExpenseRecorded?.call(
          date: date,
          categoryId: categoryId,
          spentDelta: amount,
        ) ??
            Future<void>.value(),
      );
    }
    unawaited(onDataChanged?.call() ?? Future<void>.value());

    return SaveOk([id]);
  }

  /// Chuyển tiền giữa hai ví.
  ///
  /// Lưu **một dòng duy nhất** với `walletId` (đi) và `toWalletId` (đến), không
  /// lưu cặp đối ứng — quyết định thiết kế ở `02_KIEN_TRUC_DATA.md` mục 4.3.
  ///
  /// Phí chuyển, nếu có, **không** gộp vào dòng chuyển mà được ghi thành một
  /// giao dịch chi riêng thuộc danh mục "Phí ngân hàng" (đặc tả mục B.3). Lý
  /// do: bản thân việc chuyển tiền không làm bạn nghèo đi, nhưng phí thì có —
  /// và bạn cần thấy tổng phí ngân hàng đã trả trong báo cáo.
  ///
  /// Cả hai dòng ghi trong một transaction: hoặc có đủ, hoặc không có gì.
  Future<SaveResult> saveTransfer({
    required int amount,
    required int fromWalletId,
    required int toWalletId,
    required DateTime date,
    int fee = 0,
    String note = '',
  }) async {
    if (amount <= 0) {
      return const SaveRejected('Số tiền phải lớn hơn 0.');
    }
    if (fromWalletId == toWalletId) {
      return const SaveRejected('Ví nguồn và ví đích phải khác nhau.');
    }
    if (fee < 0) {
      return const SaveRejected('Phí chuyển không được âm.');
    }

    final day = DateUtils.dateOnly(date);
    final ids = <int>[];

    await _db.transaction(() async {
      ids.add(
        await _dao.insertTransaction(
          TransactionsCompanion.insert(
            type: TransactionType.transfer,
            amount: amount,
            walletId: fromWalletId,
            toWalletId: Value(toWalletId),
            date: day,
            note: Value(note.trim()),
            noteAscii: Value(normalizeForSearch(note)),
          ),
        ),
      );

      if (fee > 0) {
        final feeCategory = await _db.categoryDao
            .findByName(kBankFeeCategoryName, CategoryType.expense);
        ids.add(
          await _dao.insertTransaction(
            TransactionsCompanion.insert(
              type: TransactionType.expense,
              amount: fee,
              walletId: fromWalletId,
              categoryId: Value(feeCategory?.id),
              date: day,
              note: const Value('Phí chuyển tiền'),
              noteAscii: Value(normalizeForSearch('Phí chuyển tiền')),
            ),
          ),
        );
      }
    });

    unawaited(onDataChanged?.call() ?? Future<void>.value());
    return SaveOk(ids);
  }

  /// Sửa một khoản thu hoặc chi đã ghi.
  ///
  /// Đi qua **cùng bộ quy tắc** với lúc tạo. Nếu để màn hình sửa ghi thẳng
  /// xuống DAO thì quy tắc "số tiền phải lớn hơn 0" sẽ bị lách mất — đây là
  /// kiểu lỗ hổng chỉ lộ ra sau vài tháng, khi trong DB đã có dòng amount = 0
  /// mà không ai biết từ đâu ra.
  Future<SaveResult> editIncomeOrExpense({
    required Transaction original,
    required int amount,
    required int walletId,
    required int categoryId,
    required DateTime date,
    String note = '',
  }) async {
    if (amount <= 0) {
      return const SaveRejected('Số tiền phải lớn hơn 0.');
    }

    await _dao.updateTransaction(
      original.copyWith(
        amount: amount,
        walletId: walletId,
        categoryId: Value(categoryId),
        date: DateUtils.dateOnly(date),
        note: note.trim(),
        noteAscii: normalizeForSearch(note),
        updatedAt: DateTime.now(),
      ),
    );
    return SaveOk([original.id]);
  }

  /// Sửa một giao dịch chuyển ví.
  ///
  /// Không đụng tới dòng phí đi kèm (nếu có): phí là một giao dịch chi độc
  /// lập, sửa hay xoá riêng. Gộp hai thứ vào một thao tác sẽ khiến người dùng
  /// sửa số tiền chuyển mà vô tình đổi cả khoản phí.
  Future<SaveResult> editTransfer({
    required Transaction original,
    required int amount,
    required int fromWalletId,
    required int toWalletId,
    required DateTime date,
    String note = '',
  }) async {
    if (amount <= 0) {
      return const SaveRejected('Số tiền phải lớn hơn 0.');
    }
    if (fromWalletId == toWalletId) {
      return const SaveRejected('Ví nguồn và ví đích phải khác nhau.');
    }

    await _dao.updateTransaction(
      original.copyWith(
        amount: amount,
        walletId: fromWalletId,
        toWalletId: Value(toWalletId),
        date: DateUtils.dateOnly(date),
        note: note.trim(),
        noteAscii: normalizeForSearch(note),
        updatedAt: DateTime.now(),
      ),
    );
    return SaveOk([original.id]);
  }

  /// Sửa ngày và ghi chú của một giao dịch điều chỉnh số dư.
  ///
  /// **Không cho sửa số tiền.** Số tiền của một điều chỉnh là phần chênh lệch
  /// đã tính ra tại thời điểm đếm lại ví; sửa nó bằng tay sẽ làm số dư nói dối
  /// mà không còn dấu vết nào truy ngược. Muốn đổi thì xoá rồi điều chỉnh lại.
  Future<SaveResult> editAdjustmentMeta({
    required Transaction original,
    required DateTime date,
    String note = '',
  }) async {
    await _dao.updateTransaction(
      original.copyWith(
        date: DateUtils.dateOnly(date),
        note: note.trim(),
        noteAscii: normalizeForSearch(note),
        updatedAt: DateTime.now(),
      ),
    );
    return SaveOk([original.id]);
  }

  /// Xoá giao dịch. Dùng cho cả nút Hoàn tác lẫn thao tác vuốt xoá.
  ///
  /// Với chuyển ví chỉ có một dòng nên xoá một lần là sạch — đây chính là ưu
  /// điểm của việc không lưu cặp đối ứng.
  Future<void> deleteTransactions(List<int> ids) async {
    await _db.transaction(() async {
      for (final id in ids) {
        await _dao.deleteById(id);
      }
    });
    unawaited(onDataChanged?.call() ?? Future<void>.value());
  }
}
