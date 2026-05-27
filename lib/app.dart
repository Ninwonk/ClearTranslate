import 'package:flutter/material.dart';

import 'presentation/app_shell.dart';
import 'shared/theme/app_theme.dart';

class ClearTranslateApp extends StatelessWidget {
  const ClearTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearTranslate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
