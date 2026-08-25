import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/transactions.dart';
import '../tables/wallets.dart';

part 'wallet_dao.g.dart';

/// Một ví kèm số dư đã tính. Số dư **không** được lưu trong bảng — nó luôn
/// được tính lại từ giao dịch, nên không bao giờ có chuyện số dư "lệch" khỏi
/// lịch sử.
class WalletWithBalance {
  const WalletWithBalance({required this.wallet, required this.balance});

  final Wallet wallet;

  /// Số dư hiện tại, đơn vị đồng. Có thể âm — với thẻ tín dụng đó là bình
  /// thường, không được cảnh báo (quy tắc số 7, file 01 mục K).
  final int balance;
}

/// Mảnh SQL tính chênh lệch số dư của một ví từ bảng giao dịch.
///
/// Tách ra hằng số để dùng lại ở nhiều truy vấn mà không sợ chép sai một
/// nhánh — chép sai một dòng ở đây là số dư sai toàn app, và rất khó nhận ra.
///
/// Đọc theo công thức ở `02_KIEN_TRUC_DATA.md` mục 6:
/// số dư = số dư gốc + thu − chi − chuyển đi + chuyển đến + điều chỉnh.
const String _balanceDeltaSql = '''
COALESCE(SUM(CASE
  WHEN t.type = 'income'     AND t.wallet_id    = w.id THEN  t.amount
  WHEN t.type = 'expense'    AND t.wallet_id    = w.id THEN -t.amount
  WHEN t.type = 'transfer'   AND t.wallet_id    = w.id THEN -t.amount
  WHEN t.type = 'transfer'   AND t.to_wallet_id = w.id THEN  t.amount
  WHEN t.type = 'adjustment' AND t.wallet_id    = w.id THEN  t.amount
  ELSE 0 END), 0)
''';

/// Truy vấn liên quan tới ví và số dư.
///
/// `DatabaseAccessor` là cách drift gom truy vấn theo nhóm thay vì nhét hết
/// vào một lớp `AppDatabase` khổng lồ.
@DriftAccessor(tables: [Wallets, Transactions])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  /// Mọi ví chưa lưu trữ, kèm số dư, sắp theo thứ tự người dùng đặt.
  ///
  /// Trả `Stream` chứ không phải `Future`: khi thêm một giao dịch, drift phát
  /// hiện bảng `transactions` đổi và tự đẩy giá trị mới xuống — giao diện cập
  /// nhật mà không cần ai gọi "refresh". Đây là lý do chính chọn drift thay vì
  /// sqflite thuần.
  ///
  /// `readsFrom` là thứ bắt buộc phải khai đúng với `customSelect`: drift không
  /// tự đọc được câu SQL viết tay, nên phải nói cho nó biết truy vấn này phụ
  /// thuộc bảng nào. Khai thiếu thì stream sẽ **không** cập nhật.
  Stream<List<WalletWithBalance>> watchWalletsWithBalance({
    bool includeArchived = false,
  }) {
    final query = db.customSelect(
      '''
      SELECT w.*, w.initial_balance + $_balanceDeltaSql AS balance
      FROM wallets w
      LEFT JOIN transactions t
        ON t.wallet_id = w.id OR t.to_wallet_id = w.id
      ${includeArchived ? '' : 'WHERE w.archived_at IS NULL'}
      GROUP BY w.id
      ORDER BY w.sort_order ASC, w.id ASC
      ''',
      readsFrom: {wallets, transactions},
    );

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => WalletWithBalance(
                  wallet: wallets.map(row.data),
                  balance: row.read<int>('balance'),
                ),
              )
              .toList(),
        );
  }

  /// Số dư của một ví.
  Stream<int> watchBalance(int walletId) {
    final query = db.customSelect(
      '''
      SELECT w.initial_balance + $_balanceDeltaSql AS balance
      FROM wallets w
      LEFT JOIN transactions t
        ON t.wallet_id = w.id OR t.to_wallet_id = w.id
      WHERE w.id = ?1
      GROUP BY w.id
      ''',
      variables: [Variable<int>(walletId)],
      readsFrom: {wallets, transactions},
    );

    return query.watchSingle().map((row) => row.read<int>('balance'));
  }

  /// **Tổng tài sản** — chỉ cộng ví có `includeInTotal = true` và chưa lưu trữ
  /// (quy tắc số 2, file 01 mục K).
  ///
  /// Dùng truy vấn con thay vì `SUM` lồng nhau: gộp theo ví trước, cộng lại
  /// sau. Viết thẳng một tầng sẽ nhân đôi số dòng khi một giao dịch chuyển ví
  /// khớp cả hai vế của `ON`.
  Stream<int> watchTotalBalance() {
    final query = db.customSelect(
      '''
      SELECT COALESCE(SUM(b.balance), 0) AS total FROM (
        SELECT w.initial_balance + $_balanceDeltaSql AS balance
        FROM wallets w
        LEFT JOIN transactions t
          ON t.wallet_id = w.id OR t.to_wallet_id = w.id
        WHERE w.include_in_total = 1 AND w.archived_at IS NULL
        GROUP BY w.id
      ) b
      ''',
      readsFrom: {wallets, transactions},
    );

    return query.watchSingle().map((row) => row.read<int>('total'));
  }

  /// Đếm giao dịch đang trỏ vào một ví — kể cả vế nhận của giao dịch chuyển.
  ///
  /// Dùng để quyết định được xoá cứng hay chỉ được lưu trữ (quy tắc số 5,
  /// file 01 mục K).
  Future<int> countTransactions(int walletId) async {
    final row = await db.customSelect(
      '''
      SELECT COUNT(*) AS c FROM transactions
      WHERE wallet_id = ?1 OR to_wallet_id = ?1
      ''',
      variables: [Variable<int>(walletId)],
      readsFrom: {transactions},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<int> insertWallet(WalletsCompanion wallet) =>
      into(wallets).insert(wallet);

  Future<bool> updateWallet(Wallet wallet) => update(wallets).replace(wallet);

  /// Lưu trữ thay vì xoá. Ví đã có giao dịch không bao giờ được xoá cứng.
  Future<int> archiveWallet(int walletId) =>
      (update(wallets)..where((w) => w.id.equals(walletId))).write(
        WalletsCompanion(archivedAt: Value(DateTime.now())),
      );

  Future<int> unarchiveWallet(int walletId) =>
      (update(wallets)..where((w) => w.id.equals(walletId))).write(
        const WalletsCompanion(archivedAt: Value(null)),
      );
}
