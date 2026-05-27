import '../entities/dictionary_entry.dart';
import '../entities/translation_request.dart';
import '../entities/translation_result.dart';

abstract interface class TranslationProvider {
  Future<TranslationResult> translate(TranslationRequest request);

  Future<DictionaryEntry> lookup(String term);

  Future<void> cancel(String requestId);
}
