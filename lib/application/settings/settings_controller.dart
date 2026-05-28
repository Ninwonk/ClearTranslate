import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/settings/local_settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(),
);

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final controller = SettingsController(ref.watch(settingsRepositoryProvider));
  controller.load();
  return controller;
});

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._repository) : super(SettingsState.initial());

  final SettingsRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final settings = await _repository.load();
      final apiKey = await _repository
          .readApiKey(settings.providerConfig.apiKeyStorageKey);

      state = state.copyWith(
        isLoading: false,
        settings: settings,
        apiKey: apiKey ?? '',
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '读取设置失败：$error',
      );
    }
  }

  Future<void> save({
    required String baseUrl,
    required String modelName,
    required String apiKey,
    required String translationStyle,
    required bool saveHistoryEnabled,
    required int chunkSize,
    required String glossary,
    Map<String, Object?>? showWindowHotKey,
    Map<String, Object?>? clearInputHotKey,
  }) async {
    final trimmedBaseUrl = baseUrl.trim();
    final trimmedModelName = modelName.trim();
    final trimmedApiKey = apiKey.trim();

    if (trimmedBaseUrl.isEmpty) {
      state = state.copyWith(errorMessage: 'API Base URL 不能为空');
      return;
    }
    if (trimmedModelName.isEmpty) {
      state = state.copyWith(errorMessage: '模型名称不能为空');
      return;
    }

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final currentSettings = state.settings;
      final providerConfig = currentSettings.providerConfig.copyWith(
        baseUrl: _normalizeBaseUrl(trimmedBaseUrl),
        modelName: trimmedModelName,
      );
      final nextSettings = currentSettings.copyWith(
        translationStyle: translationStyle,
        saveHistoryEnabled: saveHistoryEnabled,
        chunkSize: chunkSize,
        glossary: glossary.trim(),
        providerConfig: providerConfig,
        showWindowHotKey: showWindowHotKey,
        clearInputHotKey: clearInputHotKey,
      );

      await _repository.save(nextSettings);
      await _repository.writeApiKey(
        providerConfig.apiKeyStorageKey,
        trimmedApiKey,
      );

      state = state.copyWith(
        isSaving: false,
        settings: nextSettings,
        apiKey: trimmedApiKey,
        successMessage: '设置已保存',
      );
    } on Object catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '保存设置失败：$error',
      );
    }
  }

  String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

class SettingsState {
  const SettingsState({
    required this.settings,
    required this.apiKey,
    required this.isLoading,
    required this.isSaving,
    this.errorMessage,
    this.successMessage,
  });

  factory SettingsState.initial() {
    return SettingsState(
      settings: AppSettings.defaults(),
      apiKey: '',
      isLoading: true,
      isSaving: false,
    );
  }

  final AppSettings settings;
  final String apiKey;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  ProviderConfig get providerConfig => settings.providerConfig;

  SettingsState copyWith({
    AppSettings? settings,
    String? apiKey,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      apiKey: apiKey ?? this.apiKey,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
    );
  }
}

const _sentinel = Object();
