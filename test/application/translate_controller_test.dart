import 'package:clear_translate/application/translate/translate_controller.dart';
import 'package:clear_translate/domain/entities/app_settings.dart';
import 'package:clear_translate/domain/entities/translation_language.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_history_repository.dart';
import '../fakes/fake_settings_repository.dart';
import '../fakes/fake_translation_provider.dart';

void main() {
  test('translates with configured provider and api key', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final historyRepository = FakeHistoryRepository();
    final fakeProvider = FakeTranslationProvider('你好');
    final controller = TranslateController(
      repository,
      historyRepository,
      (config, apiKey) {
        expect(apiKey, 'secret-key');
        expect(config.modelName, 'gpt-4o-mini');
        return fakeProvider;
      },
    );

    await controller.translate('hello');

    expect(controller.state.outputText, '你好');
    expect(controller.state.sourceLanguage, TranslationLanguage.en);
    expect(controller.state.targetLanguage, TranslationLanguage.zh);
    expect(fakeProvider.lastRequest?.sourceText, 'hello');
    expect(historyRepository.records, hasLength(1));
    expect(historyRepository.records.single.inputText, 'hello');
    expect(historyRepository.records.single.outputText, '你好');
  });

  test('returns a clear error when api key is missing', () async {
    final repository = FakeSettingsRepository();
    final historyRepository = FakeHistoryRepository();
    final controller = TranslateController(
      repository,
      historyRepository,
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    await controller.translate('hello');

    expect(controller.state.outputText, isEmpty);
    expect(controller.state.errorMessage, '请先在设置中填写 API Key');
  });

  test('does not write history when history saving is disabled', () async {
    final repository = FakeSettingsRepository(
      initialSettings: AppSettings.defaults().copyWith(
        saveHistoryEnabled: false,
      ),
      initialApiKey: 'secret-key',
    );
    final historyRepository = FakeHistoryRepository();
    final controller = TranslateController(
      repository,
      historyRepository,
      (config, apiKey) => FakeTranslationProvider('你好'),
    );

    await controller.translate('hello');

    expect(controller.state.outputText, '你好');
    expect(historyRepository.records, isEmpty);
  });
}
