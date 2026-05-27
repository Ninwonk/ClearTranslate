import 'package:clear_translate/domain/entities/dictionary_entry.dart';
import 'package:clear_translate/domain/entities/translation_request.dart';
import 'package:clear_translate/domain/entities/translation_result.dart';
import 'package:clear_translate/domain/providers/translation_provider.dart';

class FakeTranslationProvider implements TranslationProvider {
  FakeTranslationProvider(this.output);

  final String output;
  TranslationRequest? lastRequest;
  bool wasCancelled = false;

  @override
  Future<void> cancel(String requestId) async {
    wasCancelled = true;
  }

  @override
  Future<DictionaryEntry> lookup(String term) {
    throw UnimplementedError();
  }

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    lastRequest = request;

    return TranslationResult(
      sourceText: request.sourceText,
      translatedText: output,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      mode: request.mode,
      provider: 'fake',
      model: 'fake-model',
    );
  }
}
