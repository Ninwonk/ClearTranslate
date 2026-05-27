import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/translation_request.dart';
import '../../domain/entities/translation_result.dart';
import '../../domain/providers/translation_provider.dart';
import '../../shared/prompts/translation_prompts.dart';
import '../../shared/utils/translation_output_cleaner.dart';
import 'openai_compatible_client.dart';

class OpenAICompatibleTranslationProvider implements TranslationProvider {
  OpenAICompatibleTranslationProvider({
    required OpenAICompatibleClient client,
    required this.model,
    this.providerName = 'OpenAI-compatible',
  }) : _client = client;

  final OpenAICompatibleClient _client;
  final String model;
  final String providerName;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    final translatedText = await _client.createChatCompletion(
      model: model,
      messages: TranslationPrompts.translate(request),
    );

    return TranslationResult(
      sourceText: request.sourceText,
      translatedText: TranslationOutputCleaner.clean(translatedText),
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      mode: request.mode,
      provider: providerName,
      model: model,
    );
  }

  @override
  Future<DictionaryEntry> lookup(String term) {
    throw UnimplementedError('Dictionary mode is not part of Phase 0.');
  }

  @override
  Future<void> cancel(String requestId) async {}
}
