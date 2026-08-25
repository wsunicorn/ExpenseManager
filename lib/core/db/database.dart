import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
// `visibleForTesting` lấy từ foundation thay vì thêm `meta` làm dependency
// trực tiếp — file này vốn đã phụ thuộc Flutter qua drift_flutter.
import 'package:flutter/foundation.dart';

import '../utils/text_search.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/wallet_dao.dart';
// enums.dart được dùng bởi database.g.dart. File `part` chỉ nhìn thấy import
// của file cha, nên phải khai ở đây dù code trong file này không gọi tới.
import 'enums.dart';
import 'seed_data.dart';
import 'tables/app_settings.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/recurring_rules.dart';
import 'tables/transactions.dart';
import 'tables/wallets.dart';

part 'database.g.dart';

/// Cơ sở dữ liệu của app. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.
///
/// **Quy tắc migration tuyệt đối**: mỗi lần đổi schema phải tăng
/// [schemaVersion] và viết nhánh `onUpgrade` tương ứng. Không bao giờ được xử
/// lý lỗi DB bằng cách gỡ app cài lại — trong đó có dữ liệu tài chính thật,
/// không khôi phục được.
@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Budgets,
    RecurringRules,
    AppSettings,
  ],
  daos: [WalletDao, CategoryDao, TransactionDao, BudgetDao],
)
class AppDatabase extends _$AppDatabase {
  /// Mở DB thật trên máy.
  AppDatabase() : super(_openConnection());

  /// Dùng trong test: truyền một `QueryExecutor` chạy hoàn toàn trong RAM.
  ///
  /// Nhờ constructor này mà test công thức số dư chạy được mà không cần thiết
  /// bị, không cần file, và không đụng vào dữ liệu thật.
  AppDatabase.forTesting(super.executor);

  /// Lịch sử schema:
  /// - **1** — sáu bảng ban đầu.
  /// - **2** — thêm `transactions.note_ascii` và `categories.name_ascii` cho
  ///   tìm kiếm không dấu.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Danh mục mặc định phải có ngay từ lần mở đầu tiên, nếu không màn
          // hình Nhập vào sẽ trống trơn và người dùng không biết bắt đầu từ đâu.
          await SeedData.insertDefaultCategories(this);
          await SeedData.insertDefaultSettings(this);
        },
        onUpgrade: (m, from, to) async {
          // Mỗi nhánh chỉ thêm, không bao giờ xoá dữ liệu. Người dùng có giao
          // dịch thật trong đây.
          if (from < 2) {
            await m.addColumn(transactions, transactions.noteAscii);
            await m.addColumn(categories, categories.nameAscii);
            // Cột mới rỗng với mọi dòng cũ — phải điền lại, nếu không mọi
            // giao dịch đã nhập trước bản này sẽ vĩnh viễn không tìm ra.
            await _backfillSearchColumns();
          }
        },
        beforeOpen: (details) async {
          // SQLite **tắt kiểm tra khoá ngoại theo mặc định**. Không bật thì mọi
          // `references(...)` khai trong bảng chỉ là tài liệu, không có hiệu
          // lực, và app sẽ vui vẻ tạo giao dịch trỏ vào ví đã bị xoá.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Cho test gọi được [_backfillSearchColumns].
  ///
  /// Đây là bước dễ quên nhất của migration này, và quên thì hậu quả âm thầm:
  /// dữ liệu cũ vẫn còn nhưng vĩnh viễn không tìm ra. Đáng để lộ ra cho test.
  @visibleForTesting
  Future<void> backfillSearchColumnsForTest() => _backfillSearchColumns();

  /// Điền cột tìm kiếm cho dữ liệu đã có sẵn.
  ///
  /// Chạy trong một transaction: hoặc điền xong hết, hoặc không đổi gì. Nửa
  /// vời sẽ để lại một phần dữ liệu không tìm được mà không có dấu hiệu nào.
  Future<void> _backfillSearchColumns() async {
    await transaction(() async {
      for (final row in await select(transactions).get()) {
        await (update(transactions)..where((t) => t.id.equals(row.id))).write(
          TransactionsCompanion(
            noteAscii: Value(normalizeForSearch(row.note)),
          ),
        );
      }
      for (final row in await select(categories).get()) {
        await (update(categories)..where((c) => c.id.equals(row.id))).write(
          CategoriesCompanion(
            nameAscii: Value(normalizeForSearch(row.name)),
          ),
        );
      }
    });
  }
}

/// Mở kết nối phù hợp với nền tảng đang chạy.
///
/// - Trên Android: file SQLite trong thư mục riêng của app.
/// - Trên web: WebAssembly. Hai file `web/sqlite3.wasm` và `web/drift_worker.js`
///   phải có sẵn trong thư mục `web/` — chúng được tải về từ bản phát hành
///   drift đúng phiên bản, không sinh ra bởi `flutter create`.
///
/// Web ở đây chỉ để **xem nhanh giao diện lúc phát triển**. Bản dùng thật là
/// Android; dữ liệu trên web nằm trong OPFS/IndexedDB của trình duyệt và không
/// liên quan gì tới dữ liệu trên điện thoại.
DatabaseConnection _openConnection() {
  return driftDatabase(
    name: 'so_thu_chi',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
