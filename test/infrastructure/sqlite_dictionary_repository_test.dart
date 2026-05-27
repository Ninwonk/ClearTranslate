import 'package:clear_translate/infrastructure/dictionary/sqlite_dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database database;
  late SqliteDictionaryRepository repository;

  setUp(() {
    database = sqlite3.open('assets/dictionaries/dictionary_v1.db');
    repository = SqliteDictionaryRepository(database: database);
  });

  tearDown(() {
    database.close();
  });

  test('looks up English word locally', () async {
    final result = await repository.lookup('charge');

    expect(result.entries, isNotEmpty);
    expect(result.entries.first.headword, 'charge');
    expect(result.entries.first.shortTranslation, contains('收费'));
  });

  test('resolves English inflection through aliases', () async {
    final result = await repository.lookup('charged');

    expect(result.entries, isNotEmpty);
    expect(result.entries.first.headword, 'charge');
    expect(result.entries.first.aliasMatched, 'charged');
  });

  test('looks up Chinese expression locally', () async {
    final result = await repository.lookup('负责');

    expect(result.entries, isNotEmpty);
    expect(result.entries.first.direction, 'zh_to_en');
    expect(result.entries.first.shortTranslation, contains('responsible'));
  });

  test('suggests words by prefix', () async {
    final result = await repository.lookup('char');

    expect(result.entries, isEmpty);
    expect(result.suggestions.map((item) => item.headword), contains('charge'));
  });
}
