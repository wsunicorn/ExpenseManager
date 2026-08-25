/// Các kiểu liệt kê dùng chung cho toàn bộ tầng dữ liệu.
///
/// Drift lưu chúng bằng `textEnum()` — tức là ghi **tên** của giá trị vào cột
/// TEXT (`'income'`, `'expense'`…), không phải chỉ số. Chọn cách này vì:
///
/// - Mở file `.db` bằng DB Browser vẫn đọc hiểu được.
/// - Chèn thêm giá trị mới vào giữa `enum` không làm lệch dữ liệu cũ.
///
/// Đổi lại: **không bao giờ được đổi tên một giá trị enum** sau khi có dữ liệu
/// thật, vì tên chính là thứ đã nằm trong DB. Muốn đổi thì phải viết migration.
library;

/// Bốn loại giao dịch. Đặc tả: `ke-hoach-app/02_KIEN_TRUC_DATA.md` mục 4.3.
///
/// | loại | amount | categoryId | toWalletId | vào báo cáo thu/chi? |
/// |---|---|---|---|---|
/// | income | dương | bắt buộc | null | có |
/// | expense | dương | bắt buộc | null | có |
/// | transfer | dương | null | bắt buộc | **không** |
/// | adjustment | **có thể âm** | null | null | **không** |
enum TransactionType {
  /// Tiền vào.
  income,

  /// Tiền ra.
  expense,

  /// Chuyển giữa hai ví. Lưu **một dòng duy nhất** với `walletId` (ví nguồn)
  /// và `toWalletId` (ví đích) — không lưu cặp đối ứng hai dòng. Ưu điểm:
  /// xoá hoặc sửa không bao giờ làm lệch cặp.
  transfer,

  /// Điều chỉnh số dư khi đếm lại ví thấy lệch. **Ngoại lệ duy nhất của quy
  /// tắc "amount luôn dương"** — điều chỉnh giảm thì amount âm.
  adjustment;

  /// Hai loại được tính vào báo cáo thu/chi.
  ///
  /// Mọi truy vấn báo cáo phải lọc theo tập này. Quên mệnh đề lọc là bug phổ
  /// biến nhất của app kiểu này: chuyển tiền từ ví nọ sang ví kia bị đếm thành
  /// chi tiêu, làm báo cáo phồng lên vô lý.
  static const Set<TransactionType> reportable = {income, expense};

  bool get isReportable => reportable.contains(this);
}

/// Danh mục chỉ có thu hoặc chi — chuyển ví và điều chỉnh không có danh mục.
enum CategoryType { income, expense }

/// Loại ví. Đặc tả: `01_DAC_TA_TINH_NANG.md` bước 2 onboarding.
enum WalletType {
  cash,
  bank,
  ewallet,

  /// Thẻ tín dụng. **Số dư âm là bình thường**, không được cảnh báo
  /// (quy tắc nghiệp vụ số 7, file 01 mục K).
  credit,
  savings,
}

/// Chu kỳ lặp của khoản định kỳ. Đặc tả: file 02 mục 4.5.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }
