import 'package:clear_translate/application/translate/translate_controller.dart';
import 'package:clear_translate/domain/entities/translation_language.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_settings_repository.dart';
import '../fakes/fake_translation_provider.dart';

void main() {
  test('translates with configured provider and api key', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final fakeProvider = FakeTranslationProvider('你好');
    final controller = TranslateController(
      repository,
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
  });

  test('returns a clear error when api key is missing', () async {
    final repository = FakeSettingsRepository();
    final controller = TranslateController(
      repository,
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    await controller.translate('hello');

    expect(controller.state.outputText, isEmpty);
    expect(controller.state.errorMessage, '请先在设置中填写 API Key');
  });
}
