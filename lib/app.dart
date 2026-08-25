import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/recurring/presentation/pending_occurrences_sheet.dart';
import 'features/recurring/presentation/recurring_providers.dart';
import 'features/widget_home/presentation/home_widget_providers.dart';
import 'shared/providers/color_scheme_provider.dart';
import 'shared/providers/theme_mode_provider.dart';

/// Gốc của cây widget: `MaterialApp.router` + theme + điều hướng.
class SoThuChiApp extends ConsumerStatefulWidget {
  const SoThuChiApp({super.key});

  @override
  ConsumerState<SoThuChiApp> createState() => _SoThuChiAppState();
}

class _SoThuChiAppState extends ConsumerState<SoThuChiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _quetDinhKy());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quét lại khi app quay lại tiền cảnh: người dùng có thể để app mở qua đêm,
    // và sáng hôm sau đã sang kỳ mới.
    if (state == AppLifecycleState.resumed) _quetDinhKy();

    // Cập nhật widget mỗi khi app vào nền — đó là lúc người dùng sắp nhìn
    // màn hình chính (đặc tả mục I).
    if (state == AppLifecycleState.paused) {
      ref.read(homeWidgetServiceProvider).update();
    }
  }

  /// Quét khoản định kỳ đến hạn.
  ///
  /// Đây là **lớp đảm bảo** của đặc tả mục H.2 — luôn chạy mỗi lần mở app,
  /// không phụ thuộc vào việc hệ điều hành có cho tiến trình nền sống hay
  /// không. Trên MIUI, giả định an toàn duy nhất là lớp nền **không bao giờ**
  /// chạy, nên toàn bộ tính đúng đắn phải nằm ở đây.
  Future<void> _quetDinhKy() async {
    await ref.read(recurringScanProvider.notifier).run();
    if (!mounted) return;

    // Quét có thể vừa sinh giao dịch — đẩy số mới sang widget.
    await ref.read(homeWidgetServiceProvider).update();
    if (!mounted) return;

    final ketQua = ref.read(recurringScanProvider);
    if (ketQua == null || ketQua.isEmpty) return;

    // Có kỳ chờ xác nhận thì mở bảng duyệt ngay.
    if (ketQua.pendingConfirmation.isNotEmpty) {
      final ctx = appRouter.configuration.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await PendingOccurrencesSheet.show(ctx);
      }
      return;
    }

    // Chỉ có khoản tự ghi thì báo nhẹ, không chặn đường người dùng.
    final messenger = _messengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Đã ghi ${ketQua.postedCount} khoản định kỳ đến hạn.',
        ),
      ),
    );
  }

  /// Khoá riêng cho `ScaffoldMessenger` ở cấp app: SnackBar phải hiện được kể
  /// cả khi việc quét kết thúc trước lúc màn hình đầu tiên dựng xong.
  static final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final scheme = ref.watch(colorSchemeControllerProvider);

    return MaterialApp.router(
      title: 'Sổ thu chi',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light(scheme: scheme),
      darkTheme: AppTheme.dark(scheme: scheme),
      themeMode: themeMode,

      // App chỉ phục vụ một người dùng Việt Nam nên khoá cứng tiếng Việt,
      // không theo ngôn ngữ hệ thống.
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: appRouter,
    );
  }
}
