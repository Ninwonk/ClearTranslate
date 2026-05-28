# Dictionary Builder

ClearTranslate uses a compressed prebuilt SQLite dictionary asset at:

```text
assets/dictionaries/dictionary_v1.db.gz
```

The Flutter app only queries SQLite at runtime. It does not parse MDict or StarDict files.

Full builder command:

```powershell
python tools/dictionary_builder/build_dictionary.py --download
```

After the first download, rebuild from cached source files with:

```powershell
python tools/dictionary_builder/build_dictionary.py
```

The builder imports:

- ECDICT for English to Chinese entries.
- CC-CEDICT for Chinese to English entries.
- A tiny ClearTranslate seed set for acceptance-test fixtures and fallback coverage.

Source files are downloaded to `tools/dictionary_builder/sources/` and are
ignored by git. The builder leaves an uncompressed `dictionary_v1.db` locally
for inspection, but only `dictionary_v1.db.gz` is committed. The Flutter app
decompresses the asset to the application support directory and then queries the
normal SQLite DB; it does not parse CSV, MDict, or StarDict files at runtime.

For a tiny development fixture database:

```powershell
python tools/dictionary_builder/build_dictionary.py --profile seed
```
