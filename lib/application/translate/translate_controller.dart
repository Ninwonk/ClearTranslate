import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_request.dart';
import '../../domain/providers/translation_provider.dart';
import '../../infrastructure/api/mock_translation_provider.dart';

final translationProvider = Provider<TranslationProvider>(
  (ref) => const MockTranslationProvider(),
);

final translateControllerProvider =
    StateNotifierProvider<TranslateController, TranslateState>((ref) {
  return TranslateController(ref.watch(translationProvider));
});

class TranslateController extends StateNotifier<TranslateState> {
  TranslateController(this._provider) : super(const TranslateState());

  final TranslationProvider _provider;

  Future<void> translate(String input) async {
    final text = input.trim();
    if (text.isEmpty) {
      state = state.copyWith(errorMessage: '请输入要翻译的文本');
      return;
    }

    final sourceLanguage = TranslationLanguage.detect(text);
    final targetLanguage = sourceLanguage == TranslationLanguage.zh
        ? TranslationLanguage.en
        : TranslationLanguage.zh;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    try {
      final result = await _provider.translate(
        TranslationRequest(
          sourceText: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        outputText: result.translatedText,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '翻译失败：$error',
      );
    }
  }

  void cancel() {
    state = state.copyWith(isLoading: false, errorMessage: '已取消翻译');
  }

  void clear() {
    state = const TranslateState();
  }
}

class TranslateState {
  const TranslateState({
    this.sourceLanguage = TranslationLanguage.auto,
    this.targetLanguage = TranslationLanguage.zh,
    this.outputText = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final String outputText;
  final bool isLoading;
  final String? errorMessage;

  String get sourceLanguageLabel => sourceLanguage.label;

  String get targetLanguageLabel => targetLanguage.label;

  TranslateState copyWith({
    TranslationLanguage? sourceLanguage,
    TranslationLanguage? targetLanguage,
    String? outputText,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return TranslateState(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      outputText: outputText ?? this.outputText,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
