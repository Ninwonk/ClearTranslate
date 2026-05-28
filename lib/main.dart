import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'infrastructure/settings/local_settings_repository.dart';
import 'shared/desktop/desktop_integration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await LocalSettingsRepository().load();
  await DesktopIntegration.instance.initialize(settings);
  runApp(const ProviderScope(child: ClearTranslateApp()));
}
