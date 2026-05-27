import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/history/history_controller.dart';
import '../../application/settings/settings_controller.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/history_record.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_mode.dart';
import '../../domain/entities/translation_request.dart';
import '../../domain/entities/translation_result.dart';
import '../../domain/providers/translation_provider.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/api/openai_compatible_client.dart';
import '../../infrastructure/api/openai_compatible_translation_provider.dart';
import '../../infrastructure/dictionary/sqlite_dictionary_repository.dart';
import '../../shared/errors/translation_error_mapper.dart';
import '../../shared/input/input_classifier.dart';

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

final dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => SqliteDictionaryRepository(),
);

final translateControllerProvider =
    StateNotifierProvider<TranslateController, TranslateState>((ref) {
  return TranslateController(
    ref.watch(settingsRepositoryProvider),
    ref.watch(historyRepositoryProvider),
    ref.watch(dictionaryRepositoryProvider),
    ref.watch(translationProviderFactoryProvider),
    onHistoryChanged: () => ref.read(historyControllerProvider.notifier).load(),
  );
});

class TranslateController extends StateNotifier<TranslateState> {
  TranslateController(
    this._settingsRepository,
    this._historyRepository,
    this._dictionaryRepository,
    this._providerFactory, {
    Future<void> Function()? onHistoryChanged,
  })  : _onHistoryChanged = onHistoryChanged,
        super(const TranslateState());

  final SettingsRepository _settingsRepository;
  final HistoryRepository _historyRepository;
  final DictionaryRepository _dictionaryRepository;
  final TranslationProviderFactory _providerFactory;
  final Future<void> Function()? _onHistoryChanged;
  TranslationProvider? _activeProvider;

  Future<void> translate(String input) async {
    final text = input.trim();
    if (text.isEmpty) {
      state = state.copyWith(errorMessage: '请输入要翻译的文本');
      return;
    }

    final classification = InputClassifier.classify(text);
    if (classification.mode == InputMode.localDictionary) {
      await _lookupDictionary(text);
      return;
    }

    if (!state.aiEnabled) {
      state = state.copyWith(
        currentMode: InputMode.aiTranslation,
        sourceLanguage: TranslationLanguage.detect(text),
        targetLanguage:
            TranslationLanguage.detect(text) == TranslationLanguage.zh
                ? TranslationLanguage.en
                : TranslationLanguage.zh,
        outputText: '本地词典无法可靠翻译完整句子，请开启 AI 翻译。',
        errorMessage: null,
        canUseAIExplanation: false,
      );
      return;
    }

    await _translateWithAI(text);
  }

  void setAiEnabled(bool value) {
    state = state.copyWith(aiEnabled: value);
  }

  Future<void> explainWithAI() async {
    final inputText = state.lastDictionaryInput;
    final dictionaryText = state.outputText.trim();
    if (inputText == null || dictionaryText.isEmpty) {
      state = state.copyWith(errorMessage: '请先查询本地词典结果');
      return;
    }
    if (!state.aiEnabled) {
      state = state.copyWith(errorMessage: '请先开启 AI');
      return;
    }

    await _explainDictionaryWithAI(inputText, dictionaryText);
  }

  Future<void> _lookupDictionary(String text) async {
    final sourceLanguage = TranslationLanguage.detect(text);
    final targetLanguage = sourceLanguage == TranslationLanguage.zh
        ? TranslationLanguage.en
        : TranslationLanguage.zh;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      outputText: '',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      currentMode: InputMode.localDictionary,
    );

    try {
      final result = await _dictionaryRepository.lookup(text);
      final outputText = _formatDictionaryResult(result);
      final canUseAIExplanation =
          result.hasEntries || outputText.contains('本地词典没有找到结果');

      state = state.copyWith(
        isLoading: false,
        outputText: outputText,
        lastDictionaryInput: text,
        canUseAIExplanation: canUseAIExplanation,
      );

      if (result.hasEntries) {
        final settings = await _settingsRepository.load();
        if (settings.saveHistoryEnabled) {
          await _saveDictionaryHistory(text, outputText, result.entries.first);
          await _onHistoryChanged?.call();
        }
      }
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '本地词典查询失败，请稍后重试。',
      );
    }
  }

  Future<void> _translateWithAI(String text) async {
    final sourceLanguage = TranslationLanguage.detect(text);
    final targetLanguage = sourceLanguage == TranslationLanguage.zh
        ? TranslationLanguage.en
        : TranslationLanguage.zh;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      currentMode: InputMode.aiTranslation,
      canUseAIExplanation: false,
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

      if (settings.saveHistoryEnabled) {
        await _saveHistory(result);
        await _onHistoryChanged?.call();
      }
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: TranslationErrorMapper.message(error),
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

  Future<void> _explainDictionaryWithAI(
    String inputText,
    String dictionaryText,
  ) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentMode: InputMode.aiExplanation,
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
      final sourceLanguage = TranslationLanguage.detect(inputText);

      final result = await provider.translate(
        TranslationRequest(
          sourceText: '用户查询：$inputText\n\n本地词典结果：\n$dictionaryText',
          sourceLanguage: sourceLanguage,
          targetLanguage: TranslationLanguage.zh,
          mode: TranslationMode.dictionary,
          style: settings.translationStyle,
        ),
      );

      final outputText = 'AI 解释\n\n${result.translatedText}';
      state = state.copyWith(
        isLoading: false,
        outputText: outputText,
        canUseAIExplanation: false,
      );

      if (settings.saveHistoryEnabled) {
        await _historyRepository.add(
          HistoryRecord(
            id: const Uuid().v4(),
            inputText: inputText,
            outputText: outputText,
            mode: TranslationMode.dictionary,
            engine: 'llm_api',
            sourceLanguage: sourceLanguage,
            targetLanguage: TranslationLanguage.zh,
            provider: result.provider,
            model: result.model,
            createdAt: DateTime.now(),
          ),
        );
        await _onHistoryChanged?.call();
      }
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: TranslationErrorMapper.message(error),
      );
    }
  }

  Future<void> _saveHistory(TranslationResult result) async {
    await _historyRepository.add(
      HistoryRecord(
        id: const Uuid().v4(),
        inputText: result.sourceText,
        outputText: result.translatedText,
        mode: TranslationMode.translate,
        engine: 'llm_api',
        sourceLanguage: result.sourceLanguage,
        targetLanguage: result.targetLanguage,
        provider: result.provider,
        model: result.model,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _saveDictionaryHistory(
    String inputText,
    String outputText,
    DictionaryEntry entry,
  ) async {
    await _historyRepository.add(
      HistoryRecord(
        id: const Uuid().v4(),
        inputText: inputText,
        outputText: outputText,
        mode: TranslationMode.dictionary,
        engine: 'local_dictionary',
        sourceLanguage: entry.direction == 'zh_to_en'
            ? TranslationLanguage.zh
            : TranslationLanguage.en,
        targetLanguage: entry.direction == 'zh_to_en'
            ? TranslationLanguage.en
            : TranslationLanguage.zh,
        provider: entry.sourceName,
        model: null,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _formatDictionaryResult(DictionaryLookupResult result) {
    if (result.entries.isNotEmpty) {
      return result.entries.map(_formatEntry).join('\n\n---\n\n');
    }

    if (result.suggestions.isNotEmpty) {
      final suggestions = result.suggestions
          .map(
            (suggestion) => suggestion.shortTranslation == null
                ? '- ${suggestion.headword}'
                : '- ${suggestion.headword}: ${suggestion.shortTranslation}',
          )
          .join('\n');
      return '本地词典没有精确命中。\n\n候选词\n$suggestions';
    }

    return '本地词典没有找到结果。\n\n你可以使用 AI 查询。';
  }

  String _formatEntry(DictionaryEntry entry) {
    final buffer = StringBuffer()..writeln(entry.headword);

    if (entry.phonetic != null) {
      buffer.writeln('/ ${entry.phonetic} /');
    }
    if (entry.pinyin != null) {
      buffer.writeln('pinyin: ${entry.pinyin}');
    }
    if (entry.aliasMatched != null) {
      buffer
        ..writeln()
        ..writeln('${entry.aliasMatched} -> ${entry.headword}');
      if (entry.aliasType != null) {
        buffer.writeln('类型：${entry.aliasType}');
      }
    }
    if (entry.partOfSpeech != null) {
      buffer
        ..writeln()
        ..writeln(entry.partOfSpeech);
    }
    if (entry.definition != null) {
      buffer
        ..writeln()
        ..writeln(entry.definition);
    } else if (entry.shortTranslation != null) {
      buffer
        ..writeln()
        ..writeln(entry.shortTranslation);
    }
    if (entry.phrases.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('常见搭配');
      for (final phrase in entry.phrases) {
        if (phrase.translation == null) {
          buffer.writeln('- ${phrase.phrase}');
        } else {
          buffer.writeln('- ${phrase.phrase}: ${phrase.translation}');
        }
      }
    }
    if (entry.examples.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('例句');
      for (final example in entry.examples) {
        buffer.writeln('- ${example.text}');
        if (example.translation != null) {
          buffer.writeln('  ${example.translation}');
        }
      }
    }
    if (entry.tags != null) {
      buffer
        ..writeln()
        ..writeln('标签：${entry.tags}');
    }

    return buffer.toString().trim();
  }
}

class TranslateState {
  const TranslateState({
    this.sourceLanguage = TranslationLanguage.auto,
    this.targetLanguage = TranslationLanguage.zh,
    this.outputText = '',
    this.isLoading = false,
    this.currentMode = InputMode.aiTranslation,
    this.aiEnabled = true,
    this.canUseAIExplanation = false,
    this.lastDictionaryInput,
    this.errorMessage,
  });

  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final String outputText;
  final bool isLoading;
  final InputMode currentMode;
  final bool aiEnabled;
  final bool canUseAIExplanation;
  final String? lastDictionaryInput;
  final String? errorMessage;

  String get sourceLanguageLabel => sourceLanguage.label;

  String get targetLanguageLabel => targetLanguage.label;

  String get actionLabel => switch (currentMode) {
        InputMode.localDictionary => '查询',
        InputMode.aiExplanation => 'AI 解释',
        InputMode.aiTranslation => '翻译',
      };

  String get resultLabel => switch (currentMode) {
        InputMode.localDictionary => '词典结果',
        InputMode.aiExplanation => 'AI 解释',
        InputMode.aiTranslation => '译文',
      };

  TranslateState copyWith({
    TranslationLanguage? sourceLanguage,
    TranslationLanguage? targetLanguage,
    String? outputText,
    bool? isLoading,
    InputMode? currentMode,
    bool? aiEnabled,
    bool? canUseAIExplanation,
    Object? lastDictionaryInput = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return TranslateState(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      outputText: outputText ?? this.outputText,
      isLoading: isLoading ?? this.isLoading,
      currentMode: currentMode ?? this.currentMode,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      canUseAIExplanation: canUseAIExplanation ?? this.canUseAIExplanation,
      lastDictionaryInput: identical(lastDictionaryInput, _sentinel)
          ? this.lastDictionaryInput
          : lastDictionaryInput as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
