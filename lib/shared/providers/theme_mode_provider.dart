import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Chế độ sáng / tối / theo hệ thống.
///
/// Hiện giữ trong bộ nhớ. Phase 9 sẽ đọc–ghi vào bảng `settings` (khoá
/// `theme_mode`) để giữ lại sau khi tắt app — xem `01_DAC_TA_TINH_NANG.md` mục J.
///
/// Chú thích `@riverpod` sinh ra file `theme_mode_provider.g.dart` chứa
/// `themeModeControllerProvider`. Sau khi sửa file này phải chạy lại
/// `build_runner`, nếu không code sinh sẽ lệch với code tay.
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;

  /// Xoay vòng Hệ thống → Sáng → Tối → Hệ thống.
  void cycle() => state = switch (state) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
}
