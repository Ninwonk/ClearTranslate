# ClearTranslate Risk Register

## Dictionary Licensing

Risk:

Dictionary datasets may have unclear or restrictive licenses. Commercial dictionary dumps are especially risky.

Mitigation:

- use only sources with explicit licenses
- keep `docs/dictionary_sources.md` current
- show attribution in the app before public release
- do not bundle Oxford, Longman, Collins, Cambridge, Merriam-Webster, or other commercial dictionary data unless licensing is explicitly cleared
- review licenses again before any public distribution

## CC-CEDICT Share-Alike

Risk:

CC-CEDICT is distributed under a Creative Commons Attribution-ShareAlike license. A bundled derived database may create attribution and share-alike obligations.

Mitigation:

- track source version, download date, and conversion script
- include attribution and license link
- publish derived dictionary metadata when distributing the app
- treat legal review as required before public release

## FTS5 Platform Support

Risk:

SQLite FTS5 may not be consistently available across every platform/runtime combination.

Mitigation:

- make exact lookup and prefix lookup work without FTS5
- use FTS5 only for enhanced full-text definition search
- isolate FTS5 migrations and queries
- add runtime capability checks if needed

## Dictionary Size

Risk:

Bundled dictionaries can increase app size, especially on mobile.

Mitigation:

- start with a practical `dictionary_v1.db`
- use indexes carefully
- consider desktop full dictionary and mobile lite dictionary later
- evaluate compressed asset size before mobile release

## Mode Classification Errors

Risk:

The app may classify short phrases or Chinese expressions incorrectly.

Mitigation:

- keep a visible `Use AI` / `AI Enhance` switch
- allow no-result fallback to AI
- avoid hiding user control
- keep classifier rules simple and testable

## API Cost

Risk:

Long text and repeated AI explanation can consume API quota quickly.

Mitigation:

- local dictionary handles common word lookup
- show clear AI mode state
- add long-text chunk count before translation
- support cancel

## API Key Leakage

Risk:

API keys could leak through logs, normal database storage, or error output.

Mitigation:

- store API keys through `flutter_secure_storage`
- normal settings store only secure-storage key names
- never log API keys
- mask API key inputs

## Product Scope Creep

Risk:

OCR, selected-text translation, account sync, and local models can distract from the core product.

Mitigation:

- keep current roadmap focused on dictionary plus LLM API
- explicitly exclude local translation models
- defer OCR and selected-text translation
- no account system or cloud sync in current plan

## Cross-Platform Build Limits

Risk:

Flutter cannot build every target on every OS.

Mitigation:

- validate Windows and Android on Windows
- validate macOS and iOS on macOS
- split CI by target platform later

