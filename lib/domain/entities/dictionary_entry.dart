class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.headword,
    required this.normalizedHeadword,
    required this.language,
    required this.direction,
    required this.sourceName,
    this.phonetic,
    this.pinyin,
    this.partOfSpeech,
    this.shortTranslation,
    this.definition,
    this.frequencyRank,
    this.tags,
    this.aliasMatched,
    this.aliasType,
    this.phrases = const [],
    this.examples = const [],
  });

  final int id;
  final String headword;
  final String normalizedHeadword;
  final String language;
  final String direction;
  final String sourceName;
  final String? phonetic;
  final String? pinyin;
  final String? partOfSpeech;
  final String? shortTranslation;
  final String? definition;
  final int? frequencyRank;
  final String? tags;
  final String? aliasMatched;
  final String? aliasType;
  final List<DictionaryPhrase> phrases;
  final List<DictionaryExample> examples;
}

class DictionaryPhrase {
  const DictionaryPhrase({
    required this.phrase,
    this.translation,
  });

  final String phrase;
  final String? translation;
}

class DictionaryExample {
  const DictionaryExample({
    required this.text,
    this.translation,
  });

  final String text;
  final String? translation;
}

class DictionarySuggestion {
  const DictionarySuggestion({
    required this.headword,
    this.shortTranslation,
  });

  final String headword;
  final String? shortTranslation;
}

class DictionaryLookupResult {
  const DictionaryLookupResult({
    this.entries = const [],
    this.suggestions = const [],
  });

  final List<DictionaryEntry> entries;
  final List<DictionarySuggestion> suggestions;

  bool get hasEntries => entries.isNotEmpty;
}
