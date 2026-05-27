import 'translation_language.dart';
import 'translation_mode.dart';

class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.inputText,
    required this.outputText,
    required this.mode,
    required this.engine,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.provider,
    required this.model,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory HistoryRecord.fromJson(Map<String, Object?> json) {
    return HistoryRecord(
      id: json['id'] as String,
      inputText: json['inputText'] as String,
      outputText: json['outputText'] as String,
      mode: TranslationMode.values.byName(json['mode'] as String),
      engine: json['engine'] as String,
      sourceLanguage:
          TranslationLanguage.values.byName(json['sourceLanguage'] as String),
      targetLanguage:
          TranslationLanguage.values.byName(json['targetLanguage'] as String),
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  final String id;
  final String inputText;
  final String outputText;
  final TranslationMode mode;
  final String engine;
  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final String? provider;
  final String? model;
  final DateTime createdAt;
  final bool isFavorite;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'inputText': inputText,
      'outputText': outputText,
      'mode': mode.name,
      'engine': engine,
      'sourceLanguage': sourceLanguage.name,
      'targetLanguage': targetLanguage.name,
      'provider': provider,
      'model': model,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }
}
