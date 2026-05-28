import 'package:clear_translate/domain/entities/translation_language.dart';
import 'package:clear_translate/domain/entities/translation_request.dart';
import 'package:clear_translate/shared/prompts/translation_prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds glossary block to long text chunk prompt', () {
    final messages = TranslationPrompts.translate(
      const TranslationRequest(
        sourceText: 'ClearTranslate is fast.',
        sourceLanguage: TranslationLanguage.en,
        targetLanguage: TranslationLanguage.zh,
        glossary: 'ClearTranslate = ClearTranslate',
        currentChunk: 1,
        totalChunks: 2,
      ),
    );

    final userMessage = messages.last['content']!;

    expect(userMessage, contains('术语参考'));
    expect(userMessage, contains('ClearTranslate = ClearTranslate'));
    expect(userMessage, contains('第 1 / 2 段'));
  });
}
