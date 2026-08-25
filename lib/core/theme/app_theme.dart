import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'money_colors.dart';
import 'tokens.dart';

/// Nhà máy `ThemeData` của app. Đặc tả: `ke-hoach-app/06_RA_SOAT_CONG_NGHE.md`
/// mục 3.4 và `07_UI_UX.md`.
///
/// Không viết `ThemeData` bằng tay. `flex_color_scheme` sinh sẵn bản sáng/tối
/// khớp nhau và bảo đảm **mọi** widget của SDK nhận đúng màu — viết tay thì
/// luôn sót vài widget lạc màu (`DatePicker`, `SnackBar`, `Chip`… là những chỗ
/// hay quên nhất).
abstract final class AppTheme {
  /// Font nhúng tĩnh trong `assets/fonts/`, khai báo ở `pubspec.yaml`.
  ///
  /// Dùng font nhúng chứ không phải `google_fonts` tải runtime: app phải chạy
  /// offline hoàn toàn, không thể phụ thuộc mạng chỉ để hiển thị chữ.
  static const String fontFamily = 'BeVietnamPro';

  /// Màu chủ đề mặc định.
  ///
  /// File `01_DAC_TA_TINH_NANG.md` mục J chốt "mặc định đỏ giống MoneyNote".
  /// Ở đây dùng `redWine` — đỏ trầm ngả rượu vang — chứ không phải đỏ tươi, để
  /// nút chính không trùng sắc với màu chi tiêu (`MoneyColors.expense`).
  /// Nếu hai màu đó giống nhau thì tín hiệu "đây là khoản chi" bị loãng.
  static const FlexScheme defaultScheme = FlexScheme.redWine;

  static ThemeData light({FlexScheme scheme = defaultScheme}) =>
      FlexThemeData.light(
        scheme: scheme,
        // Nền phân tầng bằng màu, không bằng đổ bóng — nguyên tắc M3
        // (file 07 mục 2.5 và mục 8).
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 2,
        subThemesData: _subThemes,
        useMaterial3ErrorColors: true,
        visualDensity: VisualDensity.standard,
        fontFamily: fontFamily,
        extensions: const <ThemeExtension<dynamic>>{MoneyColors.light},
      );

  static ThemeData dark({FlexScheme scheme = defaultScheme}) =>
      FlexThemeData.dark(
        scheme: scheme,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 6,
        subThemesData: _subThemes,
        useMaterial3ErrorColors: true,
        visualDensity: VisualDensity.standard,
        fontFamily: fontFamily,
        extensions: const <ThemeExtension<dynamic>>{MoneyColors.dark},
      );

  /// Bo góc và tinh chỉnh component, lấy thẳng từ token — không gõ số ở đây.
  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    // Bo góc mặc định cho phần lớn component.
    defaultRadius: Tokens.radiusMd,

    // Nút lớn và bottom sheet dùng bo góc lớn hơn (file 07 mục 2.2).
    filledButtonRadius: Tokens.radiusLg,
    elevatedButtonRadius: Tokens.radiusLg,
    outlinedButtonRadius: Tokens.radiusLg,
    bottomSheetRadius: Tokens.radiusLg,
    dialogRadius: Tokens.radiusLg,
    fabRadius: Tokens.radiusLg,

    // Chip và nút lọc bo tròn hoàn toàn.
    chipRadius: Tokens.radiusFull,

    // Ô nhập và thẻ.
    inputDecoratorRadius: Tokens.radiusMd,
    cardRadius: Tokens.radiusMd,
    snackBarRadius: Tokens.radiusSm,

    // Thanh điều hướng 5 tab ở đáy.
    navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
    navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarHeight: 68,

    // Hiệu ứng chạm rõ ràng hơn mặc định — app dùng một tay, cần phản hồi chắc.
    interactionEffects: true,
    tintedDisabledControls: true,
  );
}
