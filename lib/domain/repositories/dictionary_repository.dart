import '../entities/dictionary_entry.dart';

abstract interface class DictionaryRepository {
  Future<DictionaryLookupResult> lookup(String query);

  Future<List<DictionarySuggestion>> suggest(String prefix);
}
