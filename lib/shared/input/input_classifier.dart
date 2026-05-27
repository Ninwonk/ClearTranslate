import '../utils/text_normalizer.dart';

enum InputMode {
  localDictionary,
  aiTranslation,
  aiExplanation,
}

class InputClassification {
  const InputClassification({
    required this.mode,
    required this.canUseLocalDictionary,
    required this.shouldUseAI,
    required this.reason,
  });

  final InputMode mode;
  final bool canUseLocalDictionary;
  final bool shouldUseAI;
  final String reason;
}

class InputClassifier {
  const InputClassifier._();

  static InputClassification classify(String input) {
    final normalized = TextNormalizer.normalize(input);
    if (normalized.isEmpty) {
      return const InputClassification(
        mode: InputMode.aiTranslation,
        canUseLocalDictionary: false,
        shouldUseAI: false,
        reason: 'empty',
      );
    }

    if (_looksLikeSentence(input)) {
      return const InputClassification(
        mode: InputMode.aiTranslation,
        canUseLocalDictionary: false,
        shouldUseAI: true,
        reason: 'sentence_or_paragraph',
      );
    }

    if (_isEnglishWord(normalized) || _isShortEnglishPhrase(normalized)) {
      return const InputClassification(
        mode: InputMode.localDictionary,
        canUseLocalDictionary: true,
        shouldUseAI: false,
        reason: 'english_word_or_phrase',
      );
    }

    if (_isShortChineseTerm(normalized)) {
      return const InputClassification(
        mode: InputMode.localDictionary,
        canUseLocalDictionary: true,
        shouldUseAI: false,
        reason: 'short_chinese_term',
      );
    }

    return const InputClassification(
      mode: InputMode.aiTranslation,
      canUseLocalDictionary: false,
      shouldUseAI: true,
      reason: 'fallback_ai_translation',
    );
  }

  static bool _looksLikeSentence(String input) {
    if (input.contains('\n')) {
      return true;
    }

    if (RegExp(r'[。！？!?；;]').hasMatch(input)) {
      return true;
    }

    final tokens = TextNormalizer.normalize(input).split(' ');
    if (tokens.length > 5) {
      return true;
    }

    final chineseCount = RegExp(r'[\u4e00-\u9fff]').allMatches(input).length;
    return chineseCount > 6;
  }

  static bool _isEnglishWord(String input) {
    return RegExp(r"^[a-z][a-z'-]*$").hasMatch(input);
  }

  static bool _isShortEnglishPhrase(String input) {
    final tokens = input.split(' ');
    if (tokens.length < 2 || tokens.length > 5) {
      return false;
    }

    return tokens.every((token) => RegExp(r"^[a-z][a-z'-]*$").hasMatch(token));
  }

  static bool _isShortChineseTerm(String input) {
    return RegExp(r'^[\u4e00-\u9fff]{1,6}$').hasMatch(input);
  }
}
