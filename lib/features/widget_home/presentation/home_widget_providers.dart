import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/providers/database_provider.dart';
import '../data/home_widget_service.dart';

part 'home_widget_providers.g.dart';

@Riverpod(keepAlive: true)
HomeWidgetService homeWidgetService(Ref ref) =>
    HomeWidgetService(ref.watch(appDatabaseProvider));
