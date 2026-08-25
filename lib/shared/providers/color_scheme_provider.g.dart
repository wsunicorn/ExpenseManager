// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_scheme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Màu chủ đề đang chọn, lưu bền trong bảng `settings`.
///
/// Khác với `themeModeControllerProvider` (còn giữ trong bộ nhớ), giá trị này
/// ghi xuống DB ngay: đổi màu rồi tắt app mà mở lại thấy màu cũ là kiểu lỗi
/// khiến người dùng tưởng app không lưu được gì.

@ProviderFor(ColorSchemeController)
final colorSchemeControllerProvider = ColorSchemeControllerProvider._();

/// Màu chủ đề đang chọn, lưu bền trong bảng `settings`.
///
/// Khác với `themeModeControllerProvider` (còn giữ trong bộ nhớ), giá trị này
/// ghi xuống DB ngay: đổi màu rồi tắt app mà mở lại thấy màu cũ là kiểu lỗi
/// khiến người dùng tưởng app không lưu được gì.
final class ColorSchemeControllerProvider
    extends $NotifierProvider<ColorSchemeController, FlexScheme> {
  /// Màu chủ đề đang chọn, lưu bền trong bảng `settings`.
  ///
  /// Khác với `themeModeControllerProvider` (còn giữ trong bộ nhớ), giá trị này
  /// ghi xuống DB ngay: đổi màu rồi tắt app mà mở lại thấy màu cũ là kiểu lỗi
  /// khiến người dùng tưởng app không lưu được gì.
  ColorSchemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorSchemeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorSchemeControllerHash();

  @$internal
  @override
  ColorSchemeController create() => ColorSchemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlexScheme value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlexScheme>(value),
    );
  }
}

String _$colorSchemeControllerHash() =>
    r'd50a986cd94d79dc81b27c6ab51803b08070c587';

/// Màu chủ đề đang chọn, lưu bền trong bảng `settings`.
///
/// Khác với `themeModeControllerProvider` (còn giữ trong bộ nhớ), giá trị này
/// ghi xuống DB ngay: đổi màu rồi tắt app mà mở lại thấy màu cũ là kiểu lỗi
/// khiến người dùng tưởng app không lưu được gì.

abstract class _$ColorSchemeController extends $Notifier<FlexScheme> {
  FlexScheme build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FlexScheme, FlexScheme>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FlexScheme, FlexScheme>,
              FlexScheme,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
