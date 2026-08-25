import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/db/tables/app_settings.dart';
import 'core/router/app_router.dart';
import 'features/onboarding/presentation/onboarding_providers.dart';

Future<void> main() async {
  // Bắt buộc khi có việc async trước runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp dữ liệu ngày tháng cho locale 'vi'. Khác với NumberFormat (dữ liệu số
  // đã biên dịch sẵn trong intl), DateFormat theo locale phải nạp lúc chạy —
  // quên bước này thì mọi DateFormat(..., 'vi') sẽ ném LocaleDataException.
  await initializeDateFormatting('vi');

  // Dựng container trước runApp để đọc được cờ onboarding, rồi dùng lại chính
  // container đó cho app. Tạo hai container khác nhau sẽ có hai kết nối DB.
  final container = ProviderContainer();
  setOnboardingCompleted(
    completed: await container.read(settingsRepositoryProvider).read(
              SettingKeys.onboardingDone,
            ) ==
        'true',
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SoThuChiApp(),
    ),
  );
}
