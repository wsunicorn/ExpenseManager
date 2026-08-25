import '../../../core/db/enums.dart';

/// Bộ lọc tìm kiếm giao dịch. Đặc tả: `01_DAC_TA_TINH_NANG.md` mục C.4.
///
/// Lớp thuần, bất biến — không phụ thuộc Flutter hay drift, nên test được và
/// dùng lại được ở màn hình Báo cáo (Phase 5) lẫn lúc xuất CSV (Phase 8).
///
/// Mọi trường đều tuỳ chọn. Trường bỏ trống nghĩa là **không lọc theo tiêu chí
/// đó**, chứ không phải "lọc ra rỗng".
class TransactionFilter {
  const TransactionFilter({
    this.keyword = '',
    this.from,
    this.to,
    this.walletIds = const {},
    this.categoryIds = const {},
    this.types = const {},
    this.minAmount,
    this.maxAmount,
  });

  /// Tìm trong ghi chú và tên danh mục.
  final String keyword;

  /// Khoảng ngày, đóng ở cả hai đầu.
  final DateTime? from;
  final DateTime? to;

  /// Rỗng = mọi ví.
  final Set<int> walletIds;

  /// Rỗng = mọi danh mục.
  final Set<int> categoryIds;

  /// Rỗng = mọi loại giao dịch.
  final Set<TransactionType> types;

  /// Khoảng tiền, so trên trị tuyệt đối của `amount`.
  ///
  /// Dùng trị tuyệt đối vì `adjustment` được phép âm — người dùng gõ "từ 10.000
  /// đến 50.000" thì họ nghĩ về độ lớn khoản tiền, không nghĩ về dấu.
  final int? minAmount;
  final int? maxAmount;

  /// Không có tiêu chí nào được đặt.
  bool get isEmpty =>
      keyword.trim().isEmpty &&
      from == null &&
      to == null &&
      walletIds.isEmpty &&
      categoryIds.isEmpty &&
      types.isEmpty &&
      minAmount == null &&
      maxAmount == null;

  /// Số tiêu chí đang bật — hiện trên huy hiệu nút Lọc.
  int get activeCount {
    var n = 0;
    if (keyword.trim().isNotEmpty) n++;
    if (from != null || to != null) n++;
    if (walletIds.isNotEmpty) n++;
    if (categoryIds.isNotEmpty) n++;
    if (types.isNotEmpty) n++;
    if (minAmount != null || maxAmount != null) n++;
    return n;
  }

  TransactionFilter copyWith({
    String? keyword,
    DateTime? from,
    DateTime? to,
    Set<int>? walletIds,
    Set<int>? categoryIds,
    Set<TransactionType>? types,
    int? minAmount,
    int? maxAmount,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return TransactionFilter(
      keyword: keyword ?? this.keyword,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      walletIds: walletIds ?? this.walletIds,
      categoryIds: categoryIds ?? this.categoryIds,
      types: types ?? this.types,
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
    );
  }

  /// Cần `==` và `hashCode` vì bộ lọc được dùng làm tham số của provider
  /// family — Riverpod so sánh tham số để quyết định có tạo lại provider hay
  /// không. Thiếu chúng thì mỗi lần gõ một ký tự sẽ dựng một provider mới và
  /// truy vấn lại từ đầu.
  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.keyword == keyword &&
      other.from == from &&
      other.to == to &&
      _setEquals(other.walletIds, walletIds) &&
      _setEquals(other.categoryIds, categoryIds) &&
      _setEquals(other.types, types) &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount;

  @override
  int get hashCode => Object.hash(
        keyword,
        from,
        to,
        Object.hashAllUnordered(walletIds),
        Object.hashAllUnordered(categoryIds),
        Object.hashAllUnordered(types),
        minAmount,
        maxAmount,
      );

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
