import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/desktop/desktop_integration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopIntegration.instance.initialize();
  runApp(const ProviderScope(child: ClearTranslateApp()));
}
