import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../../../core/db/daos/wallet_dao.dart';
import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';

/// Kết quả của một thao tác có thể bị nghiệp vụ từ chối.
///
/// Dùng kiểu trả về thay vì ném ngoại lệ cho các trường hợp *bình thường* như
/// "ví này còn giao dịch nên không xoá được". Ngoại lệ để dành cho lỗi thật sự
/// bất ngờ; lỗi nghiệp vụ đoán trước được thì nên nằm trong kiểu dữ liệu, để
/// người gọi buộc phải xử lý.
sealed class WalletActionResult {
  const WalletActionResult();
}

class WalletActionOk extends WalletActionResult {
  const WalletActionOk();
}

class WalletActionRejected extends WalletActionResult {
  const WalletActionRejected(this.reason);

  /// Câu tiếng Việt hiển thị thẳng cho người dùng.
  final String reason;
}

/// Tầng nghiệp vụ của ví. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục F.3 và mục K.
///
/// Repository là nơi **duy nhất** biết các quy tắc nghiệp vụ về ví. DAO chỉ
/// biết SQL, UI chỉ biết vẽ. Nhờ vậy quy tắc "ví có giao dịch thì không được
/// xoá" không thể bị lách bằng cách gọi thẳng DAO từ một màn hình khác.
class WalletRepository {
  WalletRepository(this._db);

  final AppDatabase _db;

  WalletDao get _dao => _db.walletDao;

  // ── Đọc ───────────────────────────────────────────────────────────────────
  // Dữ liệu hiển thị trả Stream để giao diện tự cập nhật khi DB đổi.

  Stream<List<WalletWithBalance>> watchWallets({bool includeArchived = false}) =>
      _dao.watchWalletsWithBalance(includeArchived: includeArchived);

  Stream<int> watchTotalBalance() => _dao.watchTotalBalance();

  Stream<int> watchBalance(int walletId) => _dao.watchBalance(walletId);

  // ── Ghi ───────────────────────────────────────────────────────────────────
  // Hành động trả Future.

  /// Tạo ví mới. `initialBalance` là số tiền đang có trong ví ngay lúc này —
  /// đây là thứ MoneyNote không có, và là lý do app này biết bạn thực sự có
  /// bao nhiêu tiền.
  Future<int> createWallet({
    required String name,
    required WalletType type,
    required int iconCode,
    required int colorValue,
    int initialBalance = 0,
    bool includeInTotal = true,
  }) {
    return _dao.insertWallet(
      WalletsCompanion.insert(
        name: name.trim(),
        type: type,
        iconCode: iconCode,
        colorValue: colorValue,
        initialBalance: Value(initialBalance),
        includeInTotal: Value(includeInTotal),
      ),
    );
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _dao.updateWallet(wallet);
  }

  /// Xoá ví. **Chỉ thành công khi ví chưa có giao dịch nào** — quy tắc số 5,
  /// file 01 mục K.
  ///
  /// Ví đã có lịch sử mà xoá cứng thì các giao dịch cũ sẽ trỏ vào ví không tồn
  /// tại, số dư và báo cáo hỏng vĩnh viễn. Trường hợp đó chỉ được lưu trữ.
  Future<WalletActionResult> deleteWallet(int walletId) async {
    final count = await _dao.countTransactions(walletId);
    if (count > 0) {
      return WalletActionRejected(
        'Ví này đang có $count giao dịch nên không xoá được. '
        'Hãy lưu trữ ví để ẩn khỏi danh sách mà vẫn giữ nguyên lịch sử.',
      );
    }
    await (_db.delete(_db.wallets)..where((w) => w.id.equals(walletId))).go();
    return const WalletActionOk();
  }

  Future<void> archiveWallet(int walletId) => _dao.archiveWallet(walletId);

  Future<void> unarchiveWallet(int walletId) => _dao.unarchiveWallet(walletId);

  /// Điều chỉnh số dư: người dùng đếm lại ví tiền mặt thấy lệch, nhập số thực
  /// tế, app tự tạo một giao dịch `adjustment` bằng đúng phần chênh.
  ///
  /// Cách này giữ được nguyên tắc "số dư luôn suy ra từ giao dịch" — không bao
  /// giờ sửa thẳng một con số số dư, vì làm thế thì lịch sử và số dư sẽ mâu
  /// thuẫn nhau mà không ai truy được nguyên nhân.
  ///
  /// Trả về `null` nếu không có gì chênh lệch (không tạo giao dịch rác).
  Future<int?> adjustBalance({
    required int walletId,
    required int actualBalance,
    String note = 'Điều chỉnh số dư',
  }) async {
    final current = await _dao.watchBalance(walletId).first;
    final delta = actualBalance - current;
    if (delta == 0) return null;

    // `adjustment` là loại **duy nhất** được mang amount âm.
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            type: TransactionType.adjustment,
            amount: delta,
            walletId: walletId,
            date: DateUtils.dateOnly(DateTime.now()),
            note: Value(note),
          ),
        );
  }

  /// Sắp xếp lại thứ tự ví sau khi người dùng kéo thả.
  ///
  /// Ghi trong một transaction: hoặc cả danh sách đổi thứ tự, hoặc không đổi gì.
  /// Ghi lẻ từng dòng mà đứt giữa chừng sẽ để lại thứ tự lộn xộn.
  Future<void> reorderWallets(List<int> orderedIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.wallets)
              ..where((w) => w.id.equals(orderedIds[i])))
            .write(WalletsCompanion(sortOrder: Value(i)));
      }
    });
  }
}
