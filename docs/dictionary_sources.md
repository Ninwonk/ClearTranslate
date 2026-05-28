# Dictionary Sources

This document tracks planned dictionary data sources and licensing obligations.

It is planning documentation, not legal advice. Before public distribution, review source licenses again and verify attribution and share-alike requirements.

## Runtime Format

ClearTranslate should ship a compressed prebuilt SQLite database asset:

```text
assets/dictionaries/dictionary_v1.db.gz
```

The app should decompress this asset to its application support directory, then
query normal SQLite. It should not parse MDict or StarDict at runtime.

## Bundled Sources

| Source | Direction | URL | License | Notes |
| --- | --- | --- | --- | --- |
| ECDICT | English to Chinese | https://github.com/skywind3000/ECDICT | MIT | Imported into `dictionary_v1.db` by the dictionary builder. |
| CC-CEDICT | Chinese to English | https://cc-cedict.org/editor/editor.php?handler=Download | CC BY-SA 4.0 on the current download page | Imported into `dictionary_v1.db`; requires attribution and share-alike handling when distributed. |
| ClearTranslate Seed | English/Chinese smoke-test entries | local builder data | Project license | Kept small and used for tests/fallback fixtures. |

## Current Build Notes

The full dictionary build is generated with:

```powershell
python tools/dictionary_builder/build_dictionary.py --download
```

Downloaded source files live under `tools/dictionary_builder/sources/` and are
not committed. The generated compressed app asset is committed at:

```text
assets/dictionaries/dictionary_v1.db.gz
```

The uncompressed SQLite database is generated locally as
`assets/dictionaries/dictionary_v1.db` and ignored by git. Current full-build
size on Windows is roughly:

- ECDICT source CSV: 66 MB
- CC-CEDICT source gzip: 3.8 MB
- uncompressed SQLite DB: 220 MB
- compressed Flutter dictionary asset: 61 MB

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
