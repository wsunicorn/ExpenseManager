// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

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

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
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
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';
