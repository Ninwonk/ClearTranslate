import 'translation_language.dart';
import 'translation_mode.dart';

class TranslationRequest {
  const TranslationRequest({
    required this.sourceText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.mode = TranslationMode.translate,
    this.style = 'natural',
  });

  final String sourceText;
  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final TranslationMode mode;
  final String style;
}

