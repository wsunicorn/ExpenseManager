import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/daos/wallet_dao.dart';
import '../../../shared/providers/database_provider.dart';
import '../data/wallet_repository.dart';

part 'wallet_providers.g.dart';

/// Repository ví. Giao diện không bao giờ chạm tới DAO hay `AppDatabase` —
/// nó đi qua đây.
@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) =>
    WalletRepository(ref.watch(appDatabaseProvider));

/// Danh sách ví kèm số dư, tự cập nhật khi có giao dịch mới.
///
/// Trả `Stream` nên Riverpod bọc thành `AsyncValue`: giao diện xử lý ba trạng
/// thái loading / error / data mà không phải tự quản cờ `isLoading`.
@riverpod
Stream<List<WalletWithBalance>> walletList(
  Ref ref, {
  bool includeArchived = false,
}) {
  return ref
      .watch(walletRepositoryProvider)
      .watchWallets(includeArchived: includeArchived);
}

/// Tổng tài sản — chỉ gồm ví có `includeInTotal` và chưa lưu trữ.
@riverpod
Stream<int> totalBalance(Ref ref) =>
    ref.watch(walletRepositoryProvider).watchTotalBalance();
