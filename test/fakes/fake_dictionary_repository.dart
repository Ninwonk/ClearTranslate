import 'package:clear_translate/domain/entities/dictionary_entry.dart';
import 'package:clear_translate/domain/repositories/dictionary_repository.dart';

class FakeDictionaryRepository implements DictionaryRepository {
  FakeDictionaryRepository({DictionaryLookupResult? result})
      : result = result ?? const DictionaryLookupResult();

  DictionaryLookupResult result;
  String? lastQuery;

  @override
  Future<DictionaryLookupResult> lookup(String query) async {
    lastQuery = query;
    return result;
  }

  @override
  Future<List<DictionarySuggestion>> suggest(String prefix) async {
    return result.suggestions;
  }
}
