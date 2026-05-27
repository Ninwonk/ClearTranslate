import 'provider_config.dart';

class AppSettings {
  const AppSettings({
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
    required this.translationStyle,
    required this.saveHistoryEnabled,
    required this.themeMode,
    required this.chunkSize,
    required this.providerConfig,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      defaultSourceLanguage: 'auto',
      defaultTargetLanguage: 'auto',
      translationStyle: 'natural',
      saveHistoryEnabled: true,
      themeMode: 'system',
      chunkSize: 3000,
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
      providerConfig: providerJson is Map<String, Object?>
          ? ProviderConfig.fromJson(providerJson)
          : ProviderConfig.defaults(),
    );
  }

  final String defaultSourceLanguage;
  final String defaultTargetLanguage;
  final String translationStyle;
  final bool saveHistoryEnabled;
  final String themeMode;
  final int chunkSize;
  final ProviderConfig providerConfig;

  AppSettings copyWith({
    String? defaultSourceLanguage,
    String? defaultTargetLanguage,
    String? translationStyle,
    bool? saveHistoryEnabled,
    String? themeMode,
    int? chunkSize,
    ProviderConfig? providerConfig,
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
      providerConfig: providerConfig ?? this.providerConfig,
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
      'providerConfig': providerConfig.toJson(),
    };
  }
}
