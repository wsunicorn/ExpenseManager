import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/db/tables/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../features/onboarding/presentation/onboarding_providers.dart';

part 'color_scheme_provider.g.dart';

/// Màu chủ đề đang chọn, lưu bền trong bảng `settings`.
///
/// Khác với `themeModeControllerProvider` (còn giữ trong bộ nhớ), giá trị này
/// ghi xuống DB ngay: đổi màu rồi tắt app mà mở lại thấy màu cũ là kiểu lỗi
/// khiến người dùng tưởng app không lưu được gì.
@Riverpod(keepAlive: true)
class ColorSchemeController extends _$ColorSchemeController {
  @override
  FlexScheme build() {
    // Nạp bất đồng bộ rồi cập nhật state khi có kết quả.
    _load();
    return AppTheme.defaultScheme;
  }

  Future<void> _load() async {
    final ten = await ref
        .read(settingsRepositoryProvider)
        .read(SettingKeys.colorScheme);
    if (ten == null) return;

    final tim = FlexScheme.values.where((s) => s.name == ten);
    if (tim.isNotEmpty) state = tim.first;
  }

  Future<void> setScheme(FlexScheme scheme) async {
    state = scheme;
    await ref
        .read(settingsRepositoryProvider)
        .write(SettingKeys.colorScheme, scheme.name);
  }
}
