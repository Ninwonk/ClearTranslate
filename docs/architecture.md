# ClearTranslate Architecture

## Current Direction

ClearTranslate will evolve from the current layered Flutter prototype into a feature-oriented app.

Current code:

```text
lib/
├── application/
├── domain/
├── infrastructure/
├── presentation/
└── shared/
```

Target direction:

```text
lib/
├── features/
│   ├── dictionary/
│   ├── translation/
│   ├── history/
│   └── settings/
└── shared/
```

Migration should be incremental. Do not reorganize everything before Phase 2 needs it.

## Engine Split

```text
LocalDictionaryEngine
└── offline dictionary lookup, suggestions, aliases, phrases

LLMTranslationEngine
└── AI translation, explanation, long text, polishing
```

## Dictionary Feature Layout

```text
lib/features/dictionary/
├── data/
│   ├── dictionary_database.dart
│   ├── dictionary_repository_impl.dart
│   └── dictionary_asset_loader.dart
├── domain/
│   ├── dictionary_entry.dart
│   ├── dictionary_query.dart
│   └── dictionary_repository.dart
└── presentation/
    ├── dictionary_result_view.dart
    └── dictionary_suggestion_list.dart
```

## Build-Time Dictionary Pipeline

```text
ECDICT / CC-CEDICT
-> Python import scripts
-> normalized SQLite tables
-> dictionary_v1.db
-> Flutter asset
-> first-run copy
-> read-only lookup
```

The app must not parse `.mdx`, `.mdd`, `.ifo`, `.idx`, or `.dict` files at runtime.

## Data Ownership

### Secure Storage

Stores:

- API keys

### App Settings

Stores:

- provider name
- base URL
- model name
- translation style
- history setting
- dictionary display settings

### App Database

Stores:

- history records
- favorites
- local app metadata

### Dictionary Database

Stores:

- dictionary entries
- aliases
- phrases
- examples
- FTS index if available

Dictionary DB should be versioned separately from the app database.

