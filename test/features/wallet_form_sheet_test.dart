import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/wallet/presentation/wallet_form_sheet.dart';

/// Test bố cục cho bảng trượt tạo ví — **khoá lại hai lỗi thật đã gặp**.
///
/// Cố ý **không đụng database**: cả hai lỗi đều thuần giao diện, và
/// `WalletFormSheet` chỉ gọi tới repository ở nhánh lưu thành công. Nhờ vậy
/// test chạy trong một giây và không dính hai cái bẫy của widget test có DB
/// (`pumpAndSettle` gặp vòng xoay vô hạn, và I/O thật không chạy được trong
/// vùng `FakeAsync`).
///
/// Phần nghiệp vụ ghi ví đã có `balance_test.dart` phủ trên DB thật.
void main() {
  /// Dựng riêng bảng trượt ở một kích thước màn hình cho trước.
  Future<void> moSheet(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: WalletFormSheet()),
        ),
      ),
    );
    await tester.pump();
  }

  group('bố cục', () {
    /// Đây là lỗi đã làm chủ dự án không tạo được ví: nút "Tạo ví" nằm cuối một
    /// cột cuộn cao khoảng 870dp, trong khi cửa sổ Chrome chỉ cao chừng 700dp.
    /// Nút bị đẩy ra ngoài tầm nhìn nên trông như nút hỏng.
    ///
    /// Bản sửa ghim nút xuống đáy, tách khỏi vùng cuộn.
    testWidgets('nút Tạo ví nằm trong khung nhìn trên màn hình thấp',
        (tester) async {
      await moSheet(tester, const Size(400, 640));

      final nut = find.widgetWithText(FilledButton, 'Tạo ví');
      expect(nut, findsOneWidget);

      final hop = tester.getRect(nut);
      expect(
        hop.bottom,
        lessThanOrEqualTo(640.0),
        reason: 'đáy nút ở ${hop.bottom}, màn hình cao 640',
      );
      expect(hop.top, greaterThanOrEqualTo(0.0));
    });

    testWidgets('nút vẫn ở đáy trên màn hình rất thấp', (tester) async {
      await moSheet(tester, const Size(400, 420));

      final hop = tester.getRect(find.widgetWithText(FilledButton, 'Tạo ví'));
      expect(hop.bottom, lessThanOrEqualTo(420.0));
    });

    testWidgets('nút nằm ở một phần ba dưới màn hình', (tester) async {
      await moSheet(tester, const Size(400, 900));

      final hop = tester.getRect(find.widgetWithText(FilledButton, 'Tạo ví'));
      // Quy tắc cứng của 07_UI_UX.md mục 1.3: hành động chính phải nằm trong
      // 1/3 dưới, tầm với của ngón cái khi cầm một tay.
      expect(hop.top, greaterThan(900 * 2 / 3));
    });

    testWidgets('không tràn bố cục ở màn hình hẹp', (tester) async {
      await moSheet(tester, const Size(320, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('vùng nhập cuộn được, nút thì không cuộn theo', (tester) async {
      await moSheet(tester, const Size(400, 640));

      final truoc = tester.getRect(find.widgetWithText(FilledButton, 'Tạo ví'));

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      final sau = tester.getRect(find.widgetWithText(FilledButton, 'Tạo ví'));
      expect(sau, truoc, reason: 'nút phải đứng yên khi cuộn nội dung');
    });
  });

  group('phản hồi khi thiếu tên', () {
    /// Lỗi thứ hai: báo lỗi bằng SnackBar thì nó thuộc `ScaffoldMessenger` của
    /// màn hình phía sau, hiện **bên dưới** bảng trượt và bị che hoàn toàn.
    testWidgets('tên rỗng hiện lỗi ngay dưới ô nhập, không dùng SnackBar',
        (tester) async {
      await moSheet(tester, const Size(400, 900));

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo ví'));
      await tester.pump();

      expect(find.text('Ví cần có tên.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('lỗi biến mất ngay khi bắt đầu gõ tên', (tester) async {
      await moSheet(tester, const Size(400, 900));

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo ví'));
      await tester.pump();
      expect(find.text('Ví cần có tên.'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Tên ví'), 'M');
      await tester.pump();
      expect(find.text('Ví cần có tên.'), findsNothing);
    });

    testWidgets('tên chỉ toàn khoảng trắng cũng bị từ chối', (tester) async {
      await moSheet(tester, const Size(400, 900));

      await tester.enterText(find.widgetWithText(TextField, 'Tên ví'), '    ');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo ví'));
      await tester.pump();

      expect(find.text('Ví cần có tên.'), findsOneWidget);
    });
  });

  group('các trường của form', () {
    testWidgets('có đủ trường theo bước 2 onboarding', (tester) async {
      await moSheet(tester, const Size(400, 900));

      expect(find.text('Ví mới'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Tên ví'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Số tiền bạn đang có trong ví này'),
        findsOneWidget,
      );
      expect(find.text('Loại ví'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);
      expect(find.text('Màu'), findsOneWidget);
      expect(find.text('Tính vào Tổng tài sản'), findsOneWidget);
    });

    testWidgets('có đủ 5 loại ví', (tester) async {
      await moSheet(tester, const Size(400, 900));

      for (final ten in [
        'Tiền mặt',
        'Ngân hàng',
        'Ví điện tử',
        'Thẻ tín dụng',
        'Tiết kiệm',
      ]) {
        expect(find.widgetWithText(ChoiceChip, ten), findsOneWidget);
      }
    });

    testWidgets('giải thích rõ ý nghĩa của số dư gốc', (tester) async {
      await moSheet(tester, const Size(400, 900));

      // Câu này là điểm khác biệt lớn nhất so với MoneyNote — phải luôn có mặt.
      expect(
        find.text(
          'Mọi khoản thu chi sau này sẽ được cộng/trừ từ con số này.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('đổi được loại ví', (tester) async {
      await moSheet(tester, const Size(400, 900));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Ngân hàng'));
      await tester.pump();

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Ngân hàng'),
      );
      expect(chip.selected, isTrue);
    });
  });
}
