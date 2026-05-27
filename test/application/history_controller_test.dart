import 'package:clear_translate/application/history/history_controller.dart';
import 'package:clear_translate/domain/entities/history_record.dart';
import 'package:clear_translate/domain/entities/translation_language.dart';
import 'package:clear_translate/domain/entities/translation_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_history_repository.dart';

void main() {
  test('loads and deletes local history records', () async {
    final repository = FakeHistoryRepository()
      ..records.add(
        HistoryRecord(
          id: '1',
          inputText: 'hello',
          outputText: '你好',
          mode: TranslationMode.translate,
          engine: 'llm_api',
          sourceLanguage: TranslationLanguage.en,
          targetLanguage: TranslationLanguage.zh,
          provider: 'fake',
          model: 'fake-model',
          createdAt: DateTime(2026, 5, 27),
        ),
      );
    final controller = HistoryController(repository);

    await controller.load();
    expect(controller.state.records, hasLength(1));

    await controller.delete('1');
    expect(controller.state.records, isEmpty);
  });
}
