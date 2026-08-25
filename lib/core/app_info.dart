/// Thông tin phiên bản, hiện ở cuối tab Khác.
///
/// Viết tay chứ không đọc từ pubspec: đọc được số phiên bản lúc chạy cần thêm
/// gói `package_info_plus`, mà app này chỉ có một người dùng và một dòng hằng
/// số thì đủ. **Đổi ở đây thì phải đổi cả `version:` trong `pubspec.yaml`.**
///
/// Lý do phải hiện số này ra màn hình: đã có một lần mất công gỡ lỗi những thứ
/// đã sửa xong, chỉ vì không ai biết chắc máy đang chạy bản nào.
const String kAppVersion = '1.0.3';
