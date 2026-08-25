import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/router/app_router.dart';

/// Quyết định chuyển hướng onboarding.
///
/// **Đây là chỗ từng có bug chặn hoàn toàn app**: màn hình onboarding ghi
/// `onboarding_done=true` xuống database rồi điều hướng vào app, nhưng cờ
/// trong bộ nhớ vẫn `false` nên router đá ngược về onboarding ngay lập tức.
/// Bấm "Xong" hay "Bỏ qua" đều trông như không có tác dụng, và không có đường
/// nào vào được app.
///
/// Logic nhỏ nhưng sai thì app vô dụng — nên tách hàm thuần và test riêng.
void main() {
  group('chưa xong onboarding', () {
    test('ở màn hình khác thì bị ép về onboarding', () {
      for (final noi in [
        AppRoutes.entry,
        AppRoutes.calendar,
        AppRoutes.report,
        AppRoutes.budget,
        AppRoutes.settings,
        AppRoutes.wallets,
      ]) {
        expect(
          onboardingRedirect(completed: false, location: noi),
          AppRoutes.onboarding,
          reason: 'từ $noi phải bị đá về onboarding',
        );
      }
    });

    test('đang ở onboarding thì để yên, không lặp vô hạn', () {
      expect(
        onboardingRedirect(completed: false, location: AppRoutes.onboarding),
        isNull,
      );
    });
  });

  group('đã xong onboarding', () {
    test('vào thẳng màn hình được yêu cầu', () {
      for (final noi in [
        AppRoutes.entry,
        AppRoutes.calendar,
        AppRoutes.recurring,
        AppRoutes.categories,
      ]) {
        expect(
          onboardingRedirect(completed: true, location: noi),
          isNull,
          reason: 'không được chặn $noi',
        );
      }
    });

    /// Lưới an toàn: kể cả khi cờ bị lệch, người dùng vẫn thoát được khỏi
    /// onboarding thay vì kẹt vĩnh viễn.
    test('đang ở onboarding thì thả vào app', () {
      expect(
        onboardingRedirect(completed: true, location: AppRoutes.onboarding),
        AppRoutes.entry,
      );
    });
  });

  group('cờ trong bộ nhớ', () {
    /// Chính là bug đã gặp: ghi database mà quên cập nhật cờ.
    test('setter đổi được giá trị mà getter đọc ra', () {
      setOnboardingCompleted(completed: false);
      expect(onboardingCompleted, isFalse);

      setOnboardingCompleted(completed: true);
      expect(onboardingCompleted, isTrue);
    });

    test('bấm Xong rồi thì không còn bị đá về onboarding nữa', () {
      // Trạng thái lúc mở app lần đầu.
      setOnboardingCompleted(completed: false);
      expect(
        onboardingRedirect(
          completed: onboardingCompleted,
          location: AppRoutes.entry,
        ),
        AppRoutes.onboarding,
      );

      // Người dùng bấm "Xong" — màn hình gọi setter.
      setOnboardingCompleted(completed: true);

      expect(
        onboardingRedirect(
          completed: onboardingCompleted,
          location: AppRoutes.entry,
        ),
        isNull,
        reason: 'vào được app rồi',
      );
    });
  });

  // Trả về mặc định để không ảnh hưởng test khác chạy sau.
  tearDownAll(() => setOnboardingCompleted(completed: true));
}
