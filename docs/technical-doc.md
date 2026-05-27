# ClearTranslate Technical Design

## Technical Direction

ClearTranslate should be implemented as a hybrid local dictionary and LLM API app.

Runtime principles:

- Flutter handles four-platform UI.
- Local dictionary lookup reads a prebuilt SQLite database.
- LLM translation uses an OpenAI-compatible HTTP API.
- API keys are stored through secure storage.
- User history and settings stay local.

## Technology Stack

| Area | Choice |
| --- | --- |
| App framework | Flutter |
| Language | Dart |
| State management | Riverpod |
| HTTP | Dio |
| Local app database | Drift / SQLite |
| Dictionary database | prebuilt SQLite asset |
| Secure storage | flutter_secure_storage |
| Dictionary build scripts | Python |

## High-Level Architecture

```text
Flutter App
├── features
│   ├── dictionary
│   │   ├── LocalDictionaryEngine
│   │   ├── DictionaryRepository
│   │   ├── DictionaryDatabase
│   │   └── DictionaryResultView
│   │
│   ├── translation
│   │   ├── LLMTranslationEngine
│   │   ├── OpenAICompatibleProvider
│   │   └── LongTextTranslator
│   │
│   ├── history
│   │   ├── HistoryRepository
│   │   └── HistoryDatabase
│   │
│   └── settings
│       ├── SettingsRepository
│       └── SecureApiKeyStorage
│
├── shared
│   ├── input_classifier
│   ├── language_detector
│   ├── text_normalizer
│   ├── app_theme
│   └── error_handling
```

The current codebase still uses a simpler `application/domain/infrastructure/presentation` structure. It can be evolved toward `features/` when dictionary work starts, but Phase 1 does not require a disruptive migration.

## Dictionary Runtime Strategy

Do not parse MDict or StarDict inside the Flutter app.

Use this pipeline:

```text
dictionary source data
-> offline builder scripts
-> dictionary_v1.db
-> Flutter asset
-> first launch copy to app support directory
-> Drift / sqlite3 query
```

Benefits:

- predictable runtime format
- simple Flutter integration
- fast exact lookup and prefix lookup
- optional FTS5 full-text search
- easier versioning and updates
- UI does not depend on source dictionary formats

## Dictionary Builder Structure

```text
assets/
└── dictionaries/
    └── dictionary_v1.db

tools/
└── dictionary_builder/
    ├── README.md
    ├── build_dictionary.py
    ├── import_ecdict.py
    ├── import_cc_cedict.py
    ├── normalize.py
    └── schema.sql
```

## Dictionary SQLite Schema

### dictionary_meta

```sql
CREATE TABLE dictionary_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

Stores dictionary version, schema version, source versions, and build time.

### dictionary_entries

```sql
CREATE TABLE dictionary_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  headword TEXT NOT NULL,
  normalized_headword TEXT NOT NULL,
  language TEXT NOT NULL,
  direction TEXT NOT NULL,
  phonetic TEXT,
  pinyin TEXT,
  part_of_speech TEXT,
  short_translation TEXT,
  definition TEXT,
  raw_source TEXT,
  source_name TEXT NOT NULL,
  frequency_rank INTEGER,
  tags TEXT,
  created_at TEXT
);
```

### dictionary_aliases

```sql
CREATE TABLE dictionary_aliases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  alias TEXT NOT NULL,
  normalized_alias TEXT NOT NULL,
  alias_type TEXT NOT NULL,
  FOREIGN KEY(entry_id) REFERENCES dictionary_entries(id)
);
```

Used for inflections, spelling variants, simplified/traditional aliases, and common redirects.

### dictionary_examples

```sql
CREATE TABLE dictionary_examples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  example_text TEXT NOT NULL,
  example_translation TEXT,
  source_name TEXT,
  FOREIGN KEY(entry_id) REFERENCES dictionary_entries(id)
);
```

### dictionary_phrases

```sql
CREATE TABLE dictionary_phrases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  phrase TEXT NOT NULL,
  normalized_phrase TEXT NOT NULL,
  translation TEXT,
  FOREIGN KEY(entry_id) REFERENCES dictionary_entries(id)
);
```

### dictionary_fts

If the runtime SQLite build supports FTS5, add a virtual table:

```sql
CREATE VIRTUAL TABLE dictionary_fts USING fts5(
  headword,
  normalized_headword,
  short_translation,
  definition,
  content='dictionary_entries',
  content_rowid='id'
);
```

SQLite documents FTS5 as a virtual table module for full-text search. Drift supports custom SQL and `.drift` files, so FTS5 migration SQL should live there instead of being forced into pure Dart table declarations.

FTS5 is an enhancement. Exact lookup, alias lookup, phrase lookup, and prefix suggestions must work without FTS5.

## Indexes

```sql
CREATE INDEX idx_dictionary_entries_normalized_headword
ON dictionary_entries(normalized_headword);

CREATE INDEX idx_dictionary_entries_direction
ON dictionary_entries(direction);

CREATE INDEX idx_dictionary_aliases_normalized_alias
ON dictionary_aliases(normalized_alias);

CREATE INDEX idx_dictionary_phrases_normalized_phrase
ON dictionary_phrases(normalized_phrase);
```

## Query Strategy

Normalize input before lookup:

```text
trim
lowercase for English
collapse whitespace
full-width to half-width where possible
simplified/traditional conversion later
inflection resolution through aliases
```

English word lookup:

```text
dictionary_entries.normalized_headword
-> dictionary_aliases.normalized_alias
-> prefix suggestions
-> offer AI query
```

Chinese lookup:

```text
dictionary_entries.headword / normalized_headword
-> aliases
-> FTS if available
-> offer AI query
```

Phrase lookup:

```text
dictionary_phrases
-> dictionary_entries
-> FTS if available
-> offer AI query
```

Prefix suggestions can start with `LIKE :query || '%'` and later be optimized with range queries.

## Input Classifier

```dart
enum InputMode {
  localDictionary,
  aiTranslation,
  aiExplanation,
}

class InputClassification {
  final InputMode mode;
  final bool canUseLocalDictionary;
  final bool shouldUseAI;
  final String reason;
}
```

Default classification:

- English single word: local dictionary
- English short phrase, 2-5 tokens: local dictionary first
- short Chinese term: local dictionary first
- sentence, paragraph, multiline text: AI translation
- user enables AI: force AI path

## Core Interfaces

```dart
abstract class DictionaryRepository {
  Future<List<DictionaryEntry>> lookup(String query);
  Future<List<DictionarySuggestion>> suggest(String prefix);
  Future<List<DictionaryEntry>> lookupPhrase(String phrase);
}
```

```dart
abstract class TranslationEngine {
  Future<TranslationResult> translate(TranslationRequest request);
}
```

```dart
abstract class AIExplanationEngine {
  Future<AIExplanationResult> explainWord({
    required String query,
    required DictionaryEntry? localEntry,
  });
}
```

## History Schema Direction

History must record source engine:

```sql
CREATE TABLE history_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  input_text TEXT NOT NULL,
  output_text TEXT NOT NULL,
  mode TEXT NOT NULL,
  engine TEXT NOT NULL,
  source_language TEXT,
  target_language TEXT,
  provider TEXT,
  model TEXT,
  dictionary_entry_id INTEGER,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
```

Values:

```text
mode: dictionary / translation / explanation
engine: local_dictionary / llm_api
```

