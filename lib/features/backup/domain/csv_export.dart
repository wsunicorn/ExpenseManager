/// Sinh nội dung CSV cho việc xuất giao dịch.
/// Đặc tả: `01_DAC_TA_TINH_NANG.md` mục G.1.
///
/// Tách khỏi phần ghi file để test được nội dung sinh ra mà không đụng đĩa.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../../core/db/daos/transaction_dao.dart';
import '../../../core/db/enums.dart';

/// Dấu hiệu thứ tự byte của UTF-8: `EF BB BF`.
///
/// **Bắt buộc phải có.** Excel trên Windows đoán mã hoá theo locale hệ thống,
/// không phải UTF-8, nên thiếu BOM thì mọi chữ tiếng Việt trong file sẽ hiện
/// thành ký tự rác. Đặc tả mục G.1 gọi đây là "lỗi kinh điển, đừng quên" —
/// và nó đúng là lỗi khiến người ta tưởng app hỏng.
const List<int> kUtf8Bom = [0xEF, 0xBB, 0xBF];

/// Tên cột, giữ nguyên như đặc tả để file mở ra khớp tài liệu.
const List<String> kCsvHeader = [
  'ngay',
  'loai',
  'so_tien',
  'tien_te',
  'vi',
  'danh_muc',
  'ghi_chu',
  'vi_dich',
  'id',
];

/// Nhãn loại giao dịch trong file xuất.
///
/// Dùng tên tiếng Anh của enum thay vì dịch sang tiếng Việt: file CSV còn để
/// nhập ngược lại, mà chuỗi tiếng Việt thì phụ thuộc cách viết hoa và dấu.
String csvTypeLabel(TransactionType type) => type.name;

/// Sinh các dòng CSV từ danh sách giao dịch.
///
/// Số tiền xuất ra dạng **số nguyên trần**, không có dấu phân cách nghìn và
/// không có ký hiệu tiền tệ — để Excel nhận ra đó là số chứ không phải chữ.
/// Định dạng đẹp là việc của màn hình, không phải việc của file dữ liệu.
List<List<String>> buildCsvRows(List<TransactionDetail> transactions) {
  final ngay = DateFormat('yyyy-MM-dd');

  return [
    kCsvHeader,
    for (final d in transactions)
      [
        ngay.format(d.transaction.date),
        csvTypeLabel(d.transaction.type),
        d.transaction.amount.toString(),
        d.wallet?.currency ?? 'VND',
        d.wallet?.name ?? '',
        d.category?.name ?? '',
        d.transaction.note,
        d.toWallet?.name ?? '',
        d.transaction.id.toString(),
      ],
  ];
}

/// Bộ mã hoá CSV.
///
/// **Dấu phân cách là dấu phẩy**, theo chuẩn RFC 4180 — cũng là mặc định của
/// `pandas.read_csv`. Gói `csv` có sẵn `Csv.excel()` dùng dấu chấm phẩy, hợp
/// locale tiếng Việt trên Windows hơn, nhưng lại làm pandas đọc sai. Chọn dấu
/// phẩy vì file này còn để phân tích bằng Python.
///
/// Hệ quả cần biết: mở thẳng bằng Excel trên máy locale Việt có thể dồn hết
/// vào một cột, vì Windows đặt "list separator" là dấu chấm phẩy. Cách xử lý:
/// Data → Text to Columns → Delimited → Comma.
///
/// BOM được thêm ở [buildCsvBytes] chứ không bật `addBom` ở đây, để
/// [buildCsvString] trả về chuỗi sạch.
final Csv _csv = Csv(lineDelimiter: '\r\n', autoDetect: false);

/// Chuỗi CSV hoàn chỉnh, **chưa có BOM**.
///
/// Dùng CRLF làm dấu xuống dòng: đó là thứ Excel trên Windows mong đợi, và
/// cũng là mặc định của chuẩn RFC 4180.
String buildCsvString(List<TransactionDetail> transactions) =>
    _csv.encode(buildCsvRows(transactions));

/// Byte của file CSV, **đã kèm BOM**.
///
/// Luôn dùng hàm này để ghi file. Ghi thẳng `utf8.encode(csv)` là quay lại
/// đúng cái lỗi vỡ chữ mà BOM sinh ra để tránh.
Uint8List buildCsvBytes(List<TransactionDetail> transactions) {
  final noiDung = utf8.encode(buildCsvString(transactions));
  return Uint8List.fromList([...kUtf8Bom, ...noiDung]);
}

/// Tên file xuất, kèm dấu thời gian để không ghi đè bản trước.
String csvFileName({DateTime? now}) {
  final t = now ?? DateTime.now();
  return 'sothuchi_${DateFormat('yyyyMMdd_HHmm').format(t)}.csv';
}
