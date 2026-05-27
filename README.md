# ClearTranslate

ClearTranslate is a Flutter-based cross-platform Chinese-English translation tool.

The product direction is now:

```text
Local dictionary first. LLM API when context gets complex.
```

For short word and phrase lookup, ClearTranslate should prefer a prebuilt local SQLite dictionary. For sentences, paragraphs, long text, polishing, and deeper explanations, it should use an OpenAI-compatible LLM API configured by the user.

## Current Stage

Phase 0 has validated the Windows desktop prototype and OpenAI-compatible translation chain.

Next major stages:

- Phase 1: AI text translation MVP
- Phase 2: local dictionary MVP
- Phase 3: AI-enhanced dictionary explanations

## Planned Platforms

- Windows
- macOS
- Android
- iOS

Linux and Web are not current product targets.

## Getting Started

Install Flutter, then run:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

If Flutter is not in PATH on this machine:

```powershell
C:\Users\ning.wang\Downloads\flutter\bin\flutter.bat run -d windows
```

## Documentation

Project planning documents live in `docs/`.

Recommended reading order:

1. `docs/overview.md`
2. `docs/product_spec.md`
3. `docs/architecture.md`
4. `docs/roadmap.md`
5. `docs/dictionary_sources.md`

