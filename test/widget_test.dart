import 'package:clear_translate/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
