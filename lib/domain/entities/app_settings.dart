import 'provider_config.dart';

class AppSettings {
  const AppSettings({
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
    required this.translationStyle,
    required this.saveHistoryEnabled,
    required this.themeMode,
    required this.chunkSize,
    required this.glossary,
    required this.providerConfig,
    this.showWindowHotKey,
    this.clearInputHotKey,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      defaultSourceLanguage: 'auto',
      defaultTargetLanguage: 'auto',
      translationStyle: 'natural',
      saveHistoryEnabled: true,
      themeMode: 'system',
      chunkSize: 3000,
      glossary: '',
      providerConfig: ProviderConfig.defaults(),
    );
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final providerJson = json['providerConfig'];

    return AppSettings(
      defaultSourceLanguage: json['defaultSourceLanguage'] as String? ?? 'auto',
      defaultTargetLanguage: json['defaultTargetLanguage'] as String? ?? 'auto',
      translationStyle: json['translationStyle'] as String? ?? 'natural',
      saveHistoryEnabled: json['saveHistoryEnabled'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'system',
      chunkSize: json['chunkSize'] as int? ?? 3000,
      glossary: json['glossary'] as String? ?? '',
      providerConfig: providerJson is Map<String, Object?>
          ? ProviderConfig.fromJson(providerJson)
          : ProviderConfig.defaults(),
      showWindowHotKey: _optionalMap(json['showWindowHotKey']),
      clearInputHotKey: _optionalMap(json['clearInputHotKey']),
    );
  }

  final String defaultSourceLanguage;
  final String defaultTargetLanguage;
  final String translationStyle;
  final bool saveHistoryEnabled;
  final String themeMode;
  final int chunkSize;
  final String glossary;
  final ProviderConfig providerConfig;
  final Map<String, Object?>? showWindowHotKey;
  final Map<String, Object?>? clearInputHotKey;

  AppSettings copyWith({
    String? defaultSourceLanguage,
    String? defaultTargetLanguage,
    String? translationStyle,
    bool? saveHistoryEnabled,
    String? themeMode,
    int? chunkSize,
    String? glossary,
    ProviderConfig? providerConfig,
    Map<String, Object?>? showWindowHotKey,
    Map<String, Object?>? clearInputHotKey,
  }) {
    return AppSettings(
      defaultSourceLanguage:
          defaultSourceLanguage ?? this.defaultSourceLanguage,
      defaultTargetLanguage:
          defaultTargetLanguage ?? this.defaultTargetLanguage,
      translationStyle: translationStyle ?? this.translationStyle,
      saveHistoryEnabled: saveHistoryEnabled ?? this.saveHistoryEnabled,
      themeMode: themeMode ?? this.themeMode,
      chunkSize: chunkSize ?? this.chunkSize,
      glossary: glossary ?? this.glossary,
      providerConfig: providerConfig ?? this.providerConfig,
      showWindowHotKey: showWindowHotKey ?? this.showWindowHotKey,
      clearInputHotKey: clearInputHotKey ?? this.clearInputHotKey,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'defaultSourceLanguage': defaultSourceLanguage,
      'defaultTargetLanguage': defaultTargetLanguage,
      'translationStyle': translationStyle,
      'saveHistoryEnabled': saveHistoryEnabled,
      'themeMode': themeMode,
      'chunkSize': chunkSize,
      'glossary': glossary,
      'providerConfig': providerConfig.toJson(),
      if (showWindowHotKey != null) 'showWindowHotKey': showWindowHotKey,
      if (clearInputHotKey != null) 'clearInputHotKey': clearInputHotKey,
    };
  }

  static Map<String, Object?>? _optionalMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return null;
  }
}
