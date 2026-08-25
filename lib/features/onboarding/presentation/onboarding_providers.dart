import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/tables/app_settings.dart';
import '../../../shared/providers/database_provider.dart';

part 'onboarding_providers.g.dart';

/// Đọc và ghi bảng cài đặt khoá–giá trị.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(appDatabaseProvider));

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> read(String key) async {
    final row = await (_db.select(_db.appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Stream<String?> watch(String key) {
    return (_db.select(_db.appSettings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }
}

/// Đã chạy xong onboarding chưa.
///
/// Trả `null` khi còn đang đọc — giao diện phải chờ, không được đoán. Đoán sai
/// sẽ chớp màn hình onboarding một nhịp rồi nhảy vào app, hoặc tệ hơn là bắt
/// người dùng làm lại onboarding mỗi lần mở.
@riverpod
Stream<bool?> onboardingDone(Ref ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.onboardingDone)
      .map((v) => v == null ? false : v == 'true');
}

/// Ngày bắt đầu kỳ tài chính, 1–28.
@riverpod
Stream<int> monthStartDay(Ref ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.monthStartDay)
      .map((v) => int.tryParse(v ?? '1')?.clamp(1, 28) ?? 1);
}
