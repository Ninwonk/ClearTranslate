import 'translation_language.dart';
import 'translation_mode.dart';

class TranslationResult {
  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.mode,
    required this.provider,
    required this.model,
  });

  final String sourceText;
  final String translatedText;
  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final TranslationMode mode;
  final String provider;
  final String model;
}

