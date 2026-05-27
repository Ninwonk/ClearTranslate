# Dictionary Builder

Phase 2 uses a prebuilt SQLite dictionary database at:

```text
assets/dictionaries/dictionary_v1.db
```

The Flutter app only queries SQLite at runtime. It does not parse MDict or StarDict files.

Current builder command:

```powershell
python tools/dictionary_builder/build_dictionary.py
```

This MVP seed database covers Phase 2 acceptance entries and establishes the schema. Later imports can replace the seed records with ECDICT and CC-CEDICT data.

