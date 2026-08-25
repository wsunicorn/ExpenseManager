import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/enums.dart';
import '../../../shared/providers/database_provider.dart';
import '../domain/transaction_filter.dart';

part 'search_providers.g.dart';

/// Bộ lọc đang áp dụng ở màn hình Tìm kiếm.
@riverpod
class SearchFilter extends _$SearchFilter {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setKeyword(String keyword) =>
      state = state.copyWith(keyword: keyword);

  void setDateRange(DateTime? from, DateTime? to) => from == null && to == null
      ? state = state.copyWith(clearDates: true)
      : state = state.copyWith(from: from, to: to);

  void toggleWallet(int id) => state = state.copyWith(
        walletIds: _toggle(state.walletIds, id),
      );

  void toggleCategory(int id) => state = state.copyWith(
        categoryIds: _toggle(state.categoryIds, id),
      );

  void toggleType(TransactionType type) => state = state.copyWith(
        types: _toggle(state.types, type),
      );

  void setAmountRange(int? min, int? max) => min == null && max == null
      ? state = state.copyWith(clearAmounts: true)
      : state = state.copyWith(minAmount: min, maxAmount: max);

  void clear() => state = const TransactionFilter();

  static Set<T> _toggle<T>(Set<T> current, T value) {
    final next = {...current};
    if (!next.remove(value)) next.add(value);
    return next;
  }
}

/// Kết quả tìm kiếm, tự cập nhật khi dữ liệu đổi.
@riverpod
Stream<List<TransactionDetail>> searchResults(Ref ref) {
  final filter = ref.watch(searchFilterProvider);
  return ref.watch(appDatabaseProvider).transactionDao.watchFiltered(filter);
}

/// Tóm tắt kết quả cho dòng đầu danh sách: "38 giao dịch · −4.520.000 đ".
///
/// Chênh lệch chỉ cộng thu và chi — chuyển ví và điều chỉnh bị loại, đúng quy
/// tắc số 3. Nếu cộng cả chúng vào thì con số tổng sẽ vô nghĩa.
typedef SearchSummary = ({int count, int net});

@riverpod
SearchSummary searchSummary(Ref ref) {
  final results = ref.watch(searchResultsProvider).value ?? const [];
  var net = 0;
  for (final d in results) {
    switch (d.transaction.type) {
      case TransactionType.income:
        net += d.transaction.amount;
      case TransactionType.expense:
        net -= d.transaction.amount;
      case TransactionType.transfer:
      case TransactionType.adjustment:
        break;
    }
  }
  return (count: results.length, net: net);
}
