import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings/settings_controller.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_request.dart';
import '../../domain/providers/translation_provider.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/api/openai_compatible_client.dart';
import '../../infrastructure/api/openai_compatible_translation_provider.dart';

typedef TranslationProviderFactory = TranslationProvider Function(
  ProviderConfig config,
  String apiKey,
);

final translationProviderFactoryProvider = Provider<TranslationProviderFactory>(
  (ref) {
    return (config, apiKey) {
      return OpenAICompatibleTranslationProvider(
        client: OpenAICompatibleClient(
          baseUrl: config.baseUrl,
          apiKey: apiKey,
        ),
        model: config.modelName,
        providerName: config.providerName,
      );
    };
  },
);

final translateControllerProvider =
    StateNotifierProvider<TranslateController, TranslateState>((ref) {
  return TranslateController(
    ref.watch(settingsRepositoryProvider),
    ref.watch(translationProviderFactoryProvider),
  );
});

class TranslateController extends StateNotifier<TranslateState> {
  TranslateController(this._settingsRepository, this._providerFactory)
      : super(const TranslateState());

  final SettingsRepository _settingsRepository;
  final TranslationProviderFactory _providerFactory;
  TranslationProvider? _activeProvider;

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
      final settings = await _settingsRepository.load();
      final config = settings.providerConfig;
      final apiKey =
          await _settingsRepository.readApiKey(config.apiKeyStorageKey);

      if (apiKey == null || apiKey.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '请先在设置中填写 API Key',
        );
        return;
      }

      final provider = _providerFactory(config, apiKey);
      _activeProvider = provider;

      final result = await provider.translate(
        TranslationRequest(
          sourceText: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          style: settings.translationStyle,
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
    _activeProvider?.cancel('active');
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
