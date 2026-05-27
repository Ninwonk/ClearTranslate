class ProviderConfig {
  const ProviderConfig({
    required this.providerName,
    required this.baseUrl,
    required this.apiKeyStorageKey,
    required this.modelName,
    required this.isEnabled,
  });

  factory ProviderConfig.defaults() {
    return const ProviderConfig(
      providerName: 'OpenAI-compatible',
      baseUrl: 'https://api.openai.com/v1',
      apiKeyStorageKey: 'provider.openai_compatible.api_key',
      modelName: 'gpt-4o-mini',
      isEnabled: true,
    );
  }

  factory ProviderConfig.fromJson(Map<String, Object?> json) {
    return ProviderConfig(
      providerName: json['providerName'] as String? ?? 'OpenAI-compatible',
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKeyStorageKey: json['apiKeyStorageKey'] as String? ??
          'provider.openai_compatible.api_key',
      modelName: json['modelName'] as String? ?? 'gpt-4o-mini',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  final String providerName;
  final String baseUrl;
  final String apiKeyStorageKey;
  final String modelName;
  final bool isEnabled;

  ProviderConfig copyWith({
    String? providerName,
    String? baseUrl,
    String? apiKeyStorageKey,
    String? modelName,
    bool? isEnabled,
  }) {
    return ProviderConfig(
      providerName: providerName ?? this.providerName,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKeyStorageKey: apiKeyStorageKey ?? this.apiKeyStorageKey,
      modelName: modelName ?? this.modelName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'providerName': providerName,
      'baseUrl': baseUrl,
      'apiKeyStorageKey': apiKeyStorageKey,
      'modelName': modelName,
      'isEnabled': isEnabled,
    };
  }
}
