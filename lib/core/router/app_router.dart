import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/budget/presentation/budget_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/category/presentation/category_screen.dart';
import '../../features/dev_gallery/presentation/design_gallery_screen.dart';
import '../../features/entry/presentation/entry_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/recurring/presentation/recurring_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/background_guide_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/wallet/presentation/wallet_list_screen.dart';
import 'app_shell.dart';

/// Điều hướng của app. Đặc tả: `01_DAC_TA_TINH_NANG.md` — 5 tab dưới đáy,
/// giữ nguyên cấu trúc của MoneyNote vì đó là thứ MoneyNote làm đúng.
///
/// Dùng `StatefulShellRoute` chứ không phải `IndexedStack` tự viết: mỗi tab giữ
/// được ngăn xếp điều hướng riêng, nên mở màn hình con trong tab Khác rồi chuyển
/// sang tab Lịch và quay lại thì vẫn đúng chỗ cũ. Đây cũng là thứ cần cho deep
/// link từ widget màn hình chính ở Phase 8.
abstract final class AppRoutes {
  static const String onboarding = '/bat-dau';
  static const String entry = '/nhap-vao';
  static const String calendar = '/lich';
  static const String report = '/bao-cao';
  static const String budget = '/ngan-sach';
  static const String settings = '/khac';

  /// Tìm kiếm — nằm trong ngăn xếp của tab Lịch, mở từ nút kính lúp.
  static const String search = '/lich/tim-kiem';

  // Màn hình con, nằm trong ngăn xếp của tab Khác.
  static const String wallets = '/khac/vi';
  static const String designGallery = '/khac/he-thong-thiet-ke';
  static const String recurring = '/khac/dinh-ky';
  static const String categories = '/khac/danh-muc';
  static const String backgroundGuide = '/khac/chay-nen';
}

/// Cờ onboarding, đọc một lần lúc khởi động và giữ trong bộ nhớ.
///
/// Router của go_router không đọc provider được, nên giá trị được nạp ở
/// `main()` trước khi dựng app rồi gán vào đây. Đọc bất đồng bộ ngay trong
/// `redirect` sẽ khiến màn hình chớp một nhịp trước khi chuyển.
///
/// **Ghi database thôi là chưa đủ — phải gọi [setOnboardingCompleted].**
/// Đây từng là một bug chặn hoàn toàn: màn hình onboarding ghi
/// `onboarding_done=true` rồi `context.go(entry)`, nhưng biến này vẫn `false`
/// nên `redirect` đá ngược về onboarding ngay lập tức. Bấm "Xong" hay "Bỏ qua"
/// đều như không có tác dụng, và không có cách nào vào được app.
bool _onboardingCompleted = true;

bool get onboardingCompleted => _onboardingCompleted;

/// Cập nhật cờ trong bộ nhớ cho khớp với database.
///
/// Gọi **ngay sau** mỗi lần ghi `SettingKeys.onboardingDone`, trước khi điều
/// hướng. Có setter riêng thay vì gán thẳng biến để chỗ này dễ tìm và dễ nhớ.
void setOnboardingCompleted({required bool completed}) {
  _onboardingCompleted = completed;
}

/// Quyết định chuyển hướng. Tách thành hàm thuần để test được — logic này nhỏ
/// nhưng sai thì app không vào được, nên đáng có test riêng.
String? onboardingRedirect({
  required bool completed,
  required String location,
}) {
  final dangOOnboarding = location == AppRoutes.onboarding;

  // Chưa xong onboarding mà đang ở chỗ khác → ép về onboarding.
  if (!completed && !dangOOnboarding) return AppRoutes.onboarding;

  // Đã xong rồi mà vẫn ở onboarding → thả vào app.
  //
  // Nhánh này là lưới an toàn: thiếu nó thì mọi lỗi đồng bộ cờ đều biến thành
  // "kẹt ở onboarding, không thoát được".
  if (completed && dangOOnboarding) return AppRoutes.entry;

  return null;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.entry,
  redirect: (context, state) => onboardingRedirect(
    completed: _onboardingCompleted,
    location: state.matchedLocation,
  ),
  routes: [
    // Onboarding nằm ngoài khung 5 tab: nó chiếm trọn màn hình và không có
    // thanh điều hướng dưới đáy.
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.entry,
              builder: (_, _) => const EntryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (_, _) => const CalendarScreen(),
              routes: [
                GoRoute(
                  path: 'tim-kiem',
                  builder: (_, _) => const SearchScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.report,
              builder: (_, _) => const ReportScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.budget,
              builder: (_, _) => const BudgetScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'vi',
                  builder: (_, _) => const WalletListScreen(),
                ),
                GoRoute(
                  path: 'he-thong-thiet-ke',
                  builder: (_, _) => const DesignGalleryScreen(),
                ),
                GoRoute(
                  path: 'dinh-ky',
                  builder: (_, _) => const RecurringScreen(),
                ),
                GoRoute(
                  path: 'danh-muc',
                  builder: (_, _) => const CategoryScreen(),
                ),
                GoRoute(
                  path: 'chay-nen',
                  builder: (_, _) => const BackgroundGuideScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Không tìm thấy trang ${state.uri}')),
  ),
);
