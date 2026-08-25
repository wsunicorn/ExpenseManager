// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chế độ sáng / tối / theo hệ thống.
///
/// Hiện giữ trong bộ nhớ. Phase 9 sẽ đọc–ghi vào bảng `settings` (khoá
/// `theme_mode`) để giữ lại sau khi tắt app — xem `01_DAC_TA_TINH_NANG.md` mục J.
///
/// Chú thích `@riverpod` sinh ra file `theme_mode_provider.g.dart` chứa
/// `themeModeControllerProvider`. Sau khi sửa file này phải chạy lại
/// `build_runner`, nếu không code sinh sẽ lệch với code tay.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// Chế độ sáng / tối / theo hệ thống.
///
/// Hiện giữ trong bộ nhớ. Phase 9 sẽ đọc–ghi vào bảng `settings` (khoá
/// `theme_mode`) để giữ lại sau khi tắt app — xem `01_DAC_TA_TINH_NANG.md` mục J.
///
/// Chú thích `@riverpod` sinh ra file `theme_mode_provider.g.dart` chứa
/// `themeModeControllerProvider`. Sau khi sửa file này phải chạy lại
/// `build_runner`, nếu không code sinh sẽ lệch với code tay.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// Chế độ sáng / tối / theo hệ thống.
  ///
  /// Hiện giữ trong bộ nhớ. Phase 9 sẽ đọc–ghi vào bảng `settings` (khoá
  /// `theme_mode`) để giữ lại sau khi tắt app — xem `01_DAC_TA_TINH_NANG.md` mục J.
  ///
  /// Chú thích `@riverpod` sinh ra file `theme_mode_provider.g.dart` chứa
  /// `themeModeControllerProvider`. Sau khi sửa file này phải chạy lại
  /// `build_runner`, nếu không code sinh sẽ lệch với code tay.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'94bd8f792b27b62a99041d379c582a508b8a09bb';

/// Chế độ sáng / tối / theo hệ thống.
///
/// Hiện giữ trong bộ nhớ. Phase 9 sẽ đọc–ghi vào bảng `settings` (khoá
/// `theme_mode`) để giữ lại sau khi tắt app — xem `01_DAC_TA_TINH_NANG.md` mục J.
///
/// Chú thích `@riverpod` sinh ra file `theme_mode_provider.g.dart` chứa
/// `themeModeControllerProvider`. Sau khi sửa file này phải chạy lại
/// `build_runner`, nếu không code sinh sẽ lệch với code tay.

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
