# Dictionary Sources

This document tracks planned dictionary data sources and licensing obligations.

It is planning documentation, not legal advice. Before public distribution, review source licenses again and verify attribution and share-alike requirements.

## Runtime Format

ClearTranslate should ship a prebuilt SQLite database:

```text
assets/dictionaries/dictionary_v1.db
```

The app should not parse MDict or StarDict at runtime.

## Planned Sources

| Source | Direction | URL | License | Notes |
| --- | --- | --- | --- | --- |
| ECDICT | English to Chinese | https://github.com/skywind3000/ECDICT | MIT | GitHub repository identifies the project as MIT licensed. |
| CC-CEDICT | Chinese to English | https://cc-cedict.org/editor/editor.php?handler=Download | CC BY-SA 4.0 on the current download page | Requires attribution and share-alike handling when distributed. |

## Source Metadata To Record Per Build

Every dictionary build should record:

- source name
- source URL
- license
- source version or commit
- download date
- conversion script version
- dictionary schema version
- whether commercial distribution is allowed
- whether attribution is required
- whether share-alike is required

## Do Not Bundle

Do not bundle dictionary data from unclear or commercial sources, including:

- Oxford
- Longman
- Collins
- Cambridge
- Merriam-Webster
- random MDX/MDict packs without explicit redistribution rights

## FTS5 Reference

SQLite FTS5 is a virtual-table module for full-text search:

https://www.sqlite.org/fts5.html

Use FTS5 as an enhancement only. Exact lookup, alias lookup, and prefix suggestions must work without it.

