import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/dictionary_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../../shared/utils/text_normalizer.dart';
import 'dictionary_asset_loader.dart';

class SqliteDictionaryRepository implements DictionaryRepository {
  SqliteDictionaryRepository({
    DictionaryAssetLoader assetLoader = const DictionaryAssetLoader(),
    Database? database,
  })  : _assetLoader = assetLoader,
        _database = database;

  final DictionaryAssetLoader _assetLoader;
  final Database? _database;

  @override
  Future<DictionaryLookupResult> lookup(String query) async {
    final normalized = TextNormalizer.normalize(query);
    if (normalized.isEmpty) {
      return const DictionaryLookupResult();
    }

    final database = await _openDatabase();
    final shouldDispose = _database == null;
    try {
      final phraseEntries = _lookupByPhrase(database, normalized);
      if (phraseEntries.isNotEmpty) {
        return DictionaryLookupResult(entries: phraseEntries);
      }

      final exactEntries = _lookupByHeadword(database, normalized);
      if (exactEntries.isNotEmpty) {
        return DictionaryLookupResult(entries: exactEntries);
      }

      final aliasEntries = _lookupByAlias(database, normalized);
      if (aliasEntries.isNotEmpty) {
        return DictionaryLookupResult(entries: aliasEntries);
      }

      return DictionaryLookupResult(
        suggestions: _suggest(database, normalized),
      );
    } finally {
      if (shouldDispose) {
        database.close();
      }
    }
  }

  @override
  Future<List<DictionarySuggestion>> suggest(String prefix) async {
    final normalized = TextNormalizer.normalize(prefix);
    if (normalized.length < 2) {
      return const [];
    }

    final database = await _openDatabase();
    final shouldDispose = _database == null;
    try {
      return _suggest(database, normalized);
    } finally {
      if (shouldDispose) {
        database.close();
      }
    }
  }

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database;
    }

    final file = await _assetLoader.ensureLoaded();
    return sqlite3.open(file.path);
  }

  List<DictionaryEntry> _lookupByHeadword(
      Database database, String normalized) {
    final rows = database.select(
      _entrySelectSql('normalized_headword = ?'),
      [normalized],
    );
    return rows.map((row) => _entryFromRow(database, row)).toList();
  }

  List<DictionaryEntry> _lookupByAlias(Database database, String normalized) {
    final rows = database.select(
      '''
      SELECT e.*, a.alias AS alias_matched, a.alias_type AS alias_type
      FROM dictionary_aliases a
      JOIN dictionary_entries e ON e.id = a.entry_id
      WHERE a.normalized_alias = ?
      ORDER BY e.frequency_rank IS NULL, e.frequency_rank ASC, e.headword ASC
      LIMIT 10
      ''',
      [normalized],
    );
    return rows.map((row) => _entryFromRow(database, row)).toList();
  }

  List<DictionaryEntry> _lookupByPhrase(Database database, String normalized) {
    final rows = database.select(
      '''
      SELECT e.*, p.phrase AS alias_matched, 'phrase' AS alias_type
      FROM dictionary_phrases p
      JOIN dictionary_entries e ON e.id = p.entry_id
      WHERE p.normalized_phrase = ?
      ORDER BY e.frequency_rank IS NULL, e.frequency_rank ASC, e.headword ASC
      LIMIT 10
      ''',
      [normalized],
    );
    return rows.map((row) => _entryFromRow(database, row)).toList();
  }

  List<DictionarySuggestion> _suggest(Database database, String normalized) {
    final rows = database.select(
      '''
      SELECT headword, short_translation
      FROM dictionary_entries
      WHERE normalized_headword LIKE ?
      ORDER BY frequency_rank IS NULL, frequency_rank ASC, headword ASC
      LIMIT 20
      ''',
      ['$normalized%'],
    );

    return rows
        .map(
          (row) => DictionarySuggestion(
            headword: row['headword'] as String,
            shortTranslation: row['short_translation'] as String?,
          ),
        )
        .toList();
  }

  String _entrySelectSql(String whereClause) {
    return '''
      SELECT *
      FROM dictionary_entries
      WHERE $whereClause
      ORDER BY frequency_rank IS NULL, frequency_rank ASC, headword ASC
      LIMIT 10
      ''';
  }

  DictionaryEntry _entryFromRow(Database database, Row row) {
    final id = row['id'] as int;
    return DictionaryEntry(
      id: id,
      headword: row['headword'] as String,
      normalizedHeadword: row['normalized_headword'] as String,
      language: row['language'] as String,
      direction: row['direction'] as String,
      phonetic: row['phonetic'] as String?,
      pinyin: row['pinyin'] as String?,
      partOfSpeech: row['part_of_speech'] as String?,
      shortTranslation: row['short_translation'] as String?,
      definition: row['definition'] as String?,
      sourceName: row['source_name'] as String,
      frequencyRank: row['frequency_rank'] as int?,
      tags: row['tags'] as String?,
      aliasMatched: _optionalString(row, 'alias_matched'),
      aliasType: _optionalString(row, 'alias_type'),
      phrases: _phrases(database, id),
      examples: _examples(database, id),
    );
  }

  List<DictionaryPhrase> _phrases(Database database, int entryId) {
    final rows = database.select(
      '''
      SELECT phrase, translation
      FROM dictionary_phrases
      WHERE entry_id = ?
      ORDER BY id ASC
      ''',
      [entryId],
    );

    return rows
        .map(
          (row) => DictionaryPhrase(
            phrase: row['phrase'] as String,
            translation: row['translation'] as String?,
          ),
        )
        .toList();
  }

  List<DictionaryExample> _examples(Database database, int entryId) {
    final rows = database.select(
      '''
      SELECT example_text, example_translation
      FROM dictionary_examples
      WHERE entry_id = ?
      ORDER BY id ASC
      ''',
      [entryId],
    );

    return rows
        .map(
          (row) => DictionaryExample(
            text: row['example_text'] as String,
            translation: row['example_translation'] as String?,
          ),
        )
        .toList();
  }

  String? _optionalString(Row row, String columnName) {
    if (!row.keys.contains(columnName)) {
      return null;
    }

    return row[columnName] as String?;
  }
}
