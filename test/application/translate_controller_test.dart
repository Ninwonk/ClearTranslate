import 'package:clear_translate/application/translate/translate_controller.dart';
import 'package:clear_translate/domain/entities/app_settings.dart';
import 'package:clear_translate/domain/entities/dictionary_entry.dart';
import 'package:clear_translate/domain/entities/translation_language.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_dictionary_repository.dart';
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
      FakeDictionaryRepository(),
      (config, apiKey) {
        expect(apiKey, 'secret-key');
        expect(config.modelName, 'gpt-4o-mini');
        return fakeProvider;
      },
    );

    await controller.translate('hello, how are you?');

    expect(controller.state.outputText, '你好');
    expect(controller.state.sourceLanguage, TranslationLanguage.en);
    expect(controller.state.targetLanguage, TranslationLanguage.zh);
    expect(fakeProvider.lastRequest?.sourceText, 'hello, how are you?');
    expect(historyRepository.records, hasLength(1));
    expect(historyRepository.records.single.inputText, 'hello, how are you?');
    expect(historyRepository.records.single.outputText, '你好');
  });

  test('returns a clear error when api key is missing', () async {
    final repository = FakeSettingsRepository();
    final historyRepository = FakeHistoryRepository();
    final controller = TranslateController(
      repository,
      historyRepository,
      FakeDictionaryRepository(),
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    await controller.translate('hello, how are you?');

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
      FakeDictionaryRepository(),
      (config, apiKey) => FakeTranslationProvider('你好'),
    );

    await controller.translate('hello, how are you?');

    expect(controller.state.outputText, '你好');
    expect(historyRepository.records, isEmpty);
  });

  test('uses local dictionary for short word input', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final historyRepository = FakeHistoryRepository();
    final dictionaryRepository = FakeDictionaryRepository(
      result: const DictionaryLookupResult(
        entries: [
          DictionaryEntry(
            id: 1,
            headword: 'charge',
            normalizedHeadword: 'charge',
            language: 'en',
            direction: 'en_to_zh',
            sourceName: 'test',
            shortTranslation: '收费；指控',
          ),
        ],
      ),
    );
    final controller = TranslateController(
      repository,
      historyRepository,
      dictionaryRepository,
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    await controller.translate('charge');

    expect(dictionaryRepository.lastQuery, 'charge');
    expect(controller.state.outputText, contains('charge'));
    expect(controller.state.outputText, contains('收费'));
    expect(historyRepository.records.single.engine, 'local_dictionary');
  });

  test('explains local dictionary result with ai on demand', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final historyRepository = FakeHistoryRepository();
    final dictionaryRepository = FakeDictionaryRepository(
      result: const DictionaryLookupResult(
        entries: [
          DictionaryEntry(
            id: 1,
            headword: 'charge',
            normalizedHeadword: 'charge',
            language: 'en',
            direction: 'en_to_zh',
            sourceName: 'test',
            shortTranslation: '收费；指控',
          ),
        ],
      ),
    );
    final fakeProvider = FakeTranslationProvider('charge 的核心含义是施加。');
    final controller = TranslateController(
      repository,
      historyRepository,
      dictionaryRepository,
      (config, apiKey) => fakeProvider,
    );

    await controller.translate('charge');
    await controller.explainWithAI();

    expect(fakeProvider.lastRequest?.mode.name, 'dictionary');
    expect(controller.state.outputText, contains('核心含义'));
    expect(historyRepository.records.first.engine, 'llm_api');
  });

  test('offers ai query when local dictionary has no exact hit', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final historyRepository = FakeHistoryRepository();
    final dictionaryRepository = FakeDictionaryRepository(
      result: const DictionaryLookupResult(
        suggestions: [
          DictionarySuggestion(
            headword: 'personal',
            shortTranslation: '个人的；私人的',
          ),
        ],
      ),
    );
    final controller = TranslateController(
      repository,
      historyRepository,
      dictionaryRepository,
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    await controller.translate('person');

    expect(controller.state.canUseAIExplanation, isTrue);
    expect(controller.state.aiAssistLabel, '使用 AI 查询');
  });

  test('offers ai query when local dictionary has no result', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final historyRepository = FakeHistoryRepository();
    final controller = TranslateController(
      repository,
      historyRepository,
      FakeDictionaryRepository(result: const DictionaryLookupResult()),
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    await controller.translate('unknownword');

    expect(controller.state.canUseAIExplanation, isTrue);
    expect(controller.state.aiAssistLabel, '使用 AI 查询');
  });

  test('does not translate sentences when ai is disabled', () async {
    final repository = FakeSettingsRepository(initialApiKey: 'secret-key');
    final historyRepository = FakeHistoryRepository();
    final controller = TranslateController(
      repository,
      historyRepository,
      FakeDictionaryRepository(),
      (config, apiKey) => FakeTranslationProvider('unused'),
    );

    controller.setAiEnabled(false);
    await controller.translate('hello, how are you?');

    expect(controller.state.outputText, contains('请开启 AI 翻译'));
    expect(historyRepository.records, isEmpty);
  });
}
