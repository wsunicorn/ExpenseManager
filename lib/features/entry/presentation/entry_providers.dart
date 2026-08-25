import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/enums.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../shared/providers/database_provider.dart';
import '../../budget/data/budget_alert_watcher.dart';
import '../../settings/presentation/notification_providers.dart';
import '../../widget_home/presentation/home_widget_providers.dart';
import '../data/transaction_repository.dart';

part 'entry_providers.g.dart';

@Riverpod(keepAlive: true)
BudgetAlertWatcher budgetAlertWatcher(Ref ref) => BudgetAlertWatcher(
      ref.watch(appDatabaseProvider),
      ref.watch(notificationServiceProvider),
    );

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) => TransactionRepository(
      ref.watch(appDatabaseProvider),
      // Sau mỗi khoản chi được ghi, kiểm xem có vừa vượt ngưỡng ngân sách
      // nào không. Truyền vào repository chứ không gọi từ màn hình: khoản
      // định kỳ và widget màn hình chính cũng ghi chi tiêu, cả ba đường đều
      // phải bắn cảnh báo như nhau.
      onExpenseRecorded: NotificationService.isSupported
          ? ref.watch(budgetAlertWatcherProvider).checkAfterExpense
          : null,
      // Đẩy số mới sang widget màn hình chính sau mỗi thay đổi dữ liệu.
      // Đặc tả mục I: cập nhật khi lưu/xoá/sửa giao dịch.
      onDataChanged: ref.watch(homeWidgetServiceProvider).update,
    );

/// Danh mục theo loại, danh mục dùng gần đây nằm đầu.
///
/// **Provider này viết tay, không dùng `@riverpod`** — ngoại lệ duy nhất trong
/// dự án, và có lý do kỹ thuật bắt buộc:
///
/// `riverpod_generator` 4.0.8 ném `InvalidTypeException` khi kiểu trả về của
/// provider có nhắc tới một lớp được khai báo trong file `part`. Mọi lớp dữ
/// liệu của drift (`Category`, `Wallet`, `Transaction`) đều nằm trong
/// `database.g.dart` — một `part` của `database.dart` — nên bộ sinh code không
/// phát ra được tham chiếu tới chúng. Đã thử `typedef` trung gian: không lách
/// được, vì typedef vẫn phân giải về đúng phần tử đó.
///
/// Hai cách sửa tận gốc đều đắt hơn: bật chế độ modular của drift (đổi cấu
/// trúc mọi file DB), hoặc bọc mỗi lớp drift trong một model domain riêng
/// (thêm tầng ánh xạ cho từng bảng). Với đúng một provider bị ảnh hưởng thì
/// viết tay là rẻ nhất — và bản viết tay dưới đây còn ngắn hơn code sinh ra.
///
/// **Quy tắc rút ra**: provider nào có kiểu trả về nhắc tới lớp drift thì viết
/// tay; còn lại vẫn dùng `@riverpod` như `CONVENTIONS.md` quy định.
final categoryListProvider =
    StreamProvider.family<List<Category>, CategoryType>(
  (ref, type) =>
      ref.watch(appDatabaseProvider).categoryDao.watchByType(type),
);

/// Ghi chú đã dùng, cho gợi ý ở ô Ghi chú.
@riverpod
Future<List<String>> recentNotes(Ref ref) =>
    ref.watch(transactionRepositoryProvider).recentNotes();

/// Ba tab của màn hình Nhập vào.
enum EntryTab {
  expense('Chi', TransactionType.expense),
  income('Thu', TransactionType.income),
  transfer('Chuyển ví', TransactionType.transfer);

  const EntryTab(this.label, this.transactionType);

  final String label;
  final TransactionType transactionType;

  /// Loại danh mục tương ứng. Null với chuyển ví — chuyển ví không có danh mục.
  CategoryType? get categoryType => switch (this) {
        EntryTab.expense => CategoryType.expense,
        EntryTab.income => CategoryType.income,
        EntryTab.transfer => null,
      };
}

/// Trạng thái đang nhập dở của màn hình Nhập vào.
class EntryFormState {
  const EntryFormState({
    required this.tab,
    required this.date,
    this.walletId,
    this.toWalletId,
    this.categoryId,
    this.amount = 0,
    this.fee = 0,
    this.note = '',
  });

  final EntryTab tab;

  /// Ngày thuần, không có giờ.
  final DateTime date;

  final int? walletId;

  /// Chỉ dùng ở tab Chuyển ví.
  final int? toWalletId;

  final int? categoryId;
  final int amount;

  /// Phí chuyển, chỉ dùng ở tab Chuyển ví.
  final int fee;

  final String note;

  /// Đủ điều kiện bấm Lưu chưa.
  bool get canSave => switch (tab) {
        EntryTab.transfer => amount > 0 &&
            walletId != null &&
            toWalletId != null &&
            walletId != toWalletId,
        _ => amount > 0 && walletId != null && categoryId != null,
      };

  EntryFormState copyWith({
    EntryTab? tab,
    DateTime? date,
    int? walletId,
    int? toWalletId,
    int? categoryId,
    int? amount,
    int? fee,
    String? note,
    bool clearCategory = false,
    bool clearToWallet = false,
  }) {
    return EntryFormState(
      tab: tab ?? this.tab,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      toWalletId: clearToWallet ? null : (toWalletId ?? this.toWalletId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      note: note ?? this.note,
    );
  }
}

/// Điều khiển form nhập.
///
/// Giữ `keepAlive` để trạng thái không mất khi chuyển sang tab Lịch rồi quay
/// lại — người dùng đang gõ dở một khoản mà mất hết là lỗi khó tha thứ.
@Riverpod(keepAlive: true)
class EntryForm extends _$EntryForm {
  @override
  EntryFormState build() {
    final now = DateTime.now();
    return EntryFormState(
      tab: EntryTab.expense,
      date: DateTime(now.year, now.month, now.day),
    );
  }

  /// Đổi tab. Danh mục bị xoá vì danh mục chi không dùng được cho khoản thu.
  void setTab(EntryTab tab) {
    if (tab == state.tab) return;
    state = state.copyWith(tab: tab, clearCategory: true);
  }

  void setDate(DateTime date) =>
      state = state.copyWith(date: DateTime(date.year, date.month, date.day));

  void shiftDate(int days) =>
      setDate(state.date.add(Duration(days: days)));

  void setWallet(int id) => state = state.copyWith(walletId: id);

  void setToWallet(int id) => state = state.copyWith(toWalletId: id);

  void setCategory(int id) => state = state.copyWith(categoryId: id);

  void setAmount(int amount) => state = state.copyWith(amount: amount);

  void setFee(int fee) => state = state.copyWith(fee: fee);

  void setNote(String note) => state = state.copyWith(note: note);

  /// Sau khi lưu: xoá số tiền và ghi chú, **giữ nguyên ngày và danh mục**.
  ///
  /// Đặc tả mục B.4. Lý do: người ta hay nhập liên tiếp vài khoản cùng loại
  /// trong một lần ngồi. Reset hết bắt chọn lại danh mục mỗi lần là thêm hai
  /// chạm cho mỗi khoản.
  void resetAfterSave() =>
      state = state.copyWith(amount: 0, fee: 0, note: '');
}
