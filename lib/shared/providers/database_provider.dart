import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/db/database.dart';

part 'database_provider.g.dart';

/// Kết nối DB dùng chung cho toàn app.
///
/// `keepAlive: true` vì đây là tài nguyên cấp app: mở lại kết nối SQLite mỗi
/// lần không còn màn hình nào nghe là vừa chậm vừa vô nghĩa. Mặc định của
/// Riverpod là tự huỷ khi hết người nghe — đúng cho dữ liệu màn hình, sai cho
/// thứ như thế này.
///
/// `ref.onDispose` đóng kết nối khi `ProviderScope` bị huỷ. Trong app thật điều
/// đó chỉ xảy ra lúc thoát, nhưng trong widget test thì xảy ra liên tục — không
/// đóng sẽ rò rỉ kết nối qua từng test.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
