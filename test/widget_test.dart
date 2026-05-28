import 'package:clear_translate/app.dart';
import 'package:clear_translate/application/history/history_controller.dart';
import 'package:clear_translate/domain/entities/history_record.dart';
import 'package:clear_translate/domain/entities/translation_language.dart';
import 'package:clear_translate/domain/entities/translation_mode.dart';
import 'package:clear_translate/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fakes/fake_history_repository.dart';

void main() {
  testWidgets('renders app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClearTranslateApp()));

    expect(find.text('ClearTranslate'), findsOneWidget);
    expect(find.text('翻译'), findsWidgets);
    expect(find.text('历史'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
  });

  testWidgets('renders phone-sized shell with bottom navigation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ClearTranslateApp()));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ClearTranslate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history detail fits in a short desktop window', (tester) async {
    tester.view.physicalSize = const Size(960, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyRepository = FakeHistoryRepository()
      ..records.add(
        HistoryRecord(
          id: 'history-1',
          inputText: 'personal',
          outputText: 'personal\n\n/ personal /',
          mode: TranslationMode.dictionary,
          engine: 'local',
          sourceLanguage: TranslationLanguage.en,
          targetLanguage: TranslationLanguage.zh,
          provider: 'ECDICT',
          model: 'dictionary',
          createdAt: DateTime(2026, 5, 28, 15, 16),
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();

    expect(find.text('ECDICT / dictionary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
