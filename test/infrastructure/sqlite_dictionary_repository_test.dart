import 'dart:io';

import 'package:clear_translate/infrastructure/dictionary/sqlite_dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDirectory;
  late File dictionaryFile;
  late Database database;
  late SqliteDictionaryRepository repository;

  setUpAll(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'clear_translate_dictionary_test_',
    );
    dictionaryFile = File('${tempDirectory.path}/dictionary_v1.db');
    final compressedBytes =
        File('assets/dictionaries/dictionary_v1.db.gz').readAsBytesSync();
    dictionaryFile.writeAsBytesSync(
      GZipCodec().decode(compressedBytes),
      flush: true,
    );
  });

  setUp(() {
    database = sqlite3.open(dictionaryFile.path);
    repository = SqliteDictionaryRepository(database: database);
  });

  tearDown(() {
    database.close();
  });

  tearDownAll(() {
    tempDirectory.deleteSync(recursive: true);
  });

  test('looks up English word locally', () async {
    final result = await repository.lookup('charge');

    expect(result.entries, isNotEmpty);
    expect(result.entries.first.headword, 'charge');
    expect(result.entries.first.shortTranslation, contains('费用'));
  });

  test('looks up common seed words locally', () async {
    final personal = await repository.lookup('Personal');
    final hello = await repository.lookup('hello');

    expect(personal.entries, isNotEmpty);
    expect(personal.entries.first.headword, 'personal');
    expect(personal.entries.first.shortTranslation, contains('私人'));
    expect(hello.entries, isNotEmpty);
    expect(hello.entries.first.shortTranslation, contains('喂'));
  });

  test('resolves English inflection through aliases', () async {
    final result = await repository.lookup('charged');

    expect(result.entries, isNotEmpty);
    expect(result.entries.first.headword, 'charged');
    expect(result.entries.first.shortTranslation, contains('带电'));
  });

  test('looks up Chinese expression locally', () async {
    final result = await repository.lookup('负责');

    expect(result.entries, isNotEmpty);
    expect(result.entries.first.direction, 'zh_to_en');
    expect(result.entries.first.shortTranslation, contains('responsible'));
  });

  test('suggests words by prefix', () async {
    final suggestions = await repository.suggest('char');

    expect(suggestions.map((item) => item.headword), contains('charge'));
  });
}
