import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/translation_request.dart';
import '../../domain/entities/translation_result.dart';
import '../../domain/providers/translation_provider.dart';

class MockTranslationProvider implements TranslationProvider {
  const MockTranslationProvider();

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return TranslationResult(
      sourceText: request.sourceText,
      translatedText:
          '[Mock] ${request.targetLanguage.label}: ${request.sourceText}',
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      mode: request.mode,
      provider: 'mock',
      model: 'mock-model',
    );
  }

  @override
  Future<DictionaryEntry> lookup(String term) async {
    throw UnimplementedError('Dictionary mode is handled by local repository.');
  }

  @override
  Future<void> cancel(String requestId) async {}
}
