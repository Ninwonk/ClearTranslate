# ClearTranslate Roadmap

## Strategy

ClearTranslate uses a staged roadmap:

```text
AI translation prototype -> AI text translation MVP -> local dictionary MVP -> AI dictionary enhancement -> long text -> mobile polish
```

The codebase should support Windows, macOS, Android, and iOS, but product validation starts on Windows/macOS desktop because copy, paste, keyboard input, and long text are easier to validate there.

## Phase 0: Prototype And Technical Validation

Status: completed for Windows desktop.

Goal:

- initialize Flutter project
- create desktop-first UI skeleton
- save API configuration locally
- store API Key outside normal settings data
- call an OpenAI-compatible API
- translate English to Chinese and Chinese to English
- build Windows release app

Delivered:

- Flutter project skeleton
- home, history, settings shells
- OpenAI-compatible translation provider
- settings persistence
- secure API key storage
- MiniMax-compatible output cleanup for `<think>` blocks
- Windows release build

Remaining optional validation:

- Android emulator smoke test
- macOS build on macOS

## Phase 1: AI Text Translation MVP

Status: completed.

Goal:

Make the current AI translation path reliable enough for daily desktop use.

Scope:

- text input
- automatic Chinese/English detection
- AI translation
- API Key settings
- one-click copy
- clear input/output
- better error messages
- local history records
- dark mode
- desktop basic layout

Acceptance:

- input English and get Chinese
- input Chinese and get English
- API Key is not hardcoded
- missing API Key gives a clear message
- provider errors are user-readable
- Windows or macOS desktop app runs

Delivered:

- OpenAI-compatible AI translation flow
- API Base URL, API Key, model, style, chunk-size settings
- secure API Key storage
- readable provider/network error mapping
- local history persistence
- dark desktop UI
- Windows release build

## Phase 2: Local Dictionary MVP

Status: completed.

Goal:

Add offline local dictionary lookup for words and short phrases.

Scope:

- build compressed `assets/dictionaries/dictionary_v1.db.gz`
- decompress bundled dictionary database to app support directory on first lookup
- English word to Chinese lookup
- English inflection lookup through aliases
- Chinese word or phrase to English lookup
- prefix suggestions
- local no-result state
- offer AI query when local lookup misses
- structured dictionary result UI
- dictionary lookup history

Delivered:

- ECDICT English-to-Chinese import
- CC-CEDICT Chinese-to-English import
- compressed SQLite dictionary asset, about 62 MB
- about 895k dictionary entries and 262k aliases in the generated DB
- offline exact lookup, alias lookup, phrase lookup, and prefix suggestions
- local no-result state with AI query fallback

Acceptance:

- `charge` shows local dictionary result
- `charged` shows a local dictionary result or an alias-derived result
- `负责` shows English expressions
- `char` shows suggestions
- dictionary lookup works offline
- local lookup is visibly faster than AI request

## Phase 3: AI Dictionary Enhancement

Status: completed.

Goal:

Combine local dictionary speed with AI explanation depth.

Scope:

- add a home-page `Use AI` / `AI Enhance` switch
- word result page has `AI deep explanation`
- Chinese-to-English result page has `AI explain differences`
- local no-result can trigger AI query
- AI explanation history
- visually separate local dictionary content from AI content
- Markdown preview for AI explanation output
- searchable split history view
- Windows/macOS tray integration
- close-to-tray behavior
- tray menu quit action
- customizable global desktop shortcuts

Acceptance:

- word and phrase inputs default to local dictionary
- clicking AI explanation calls LLM
- sentence input defaults to AI translation
- when AI is disabled, sentence input explains that local dictionary cannot reliably translate full sentences
- local no-result can be sent to AI
- AI Markdown output renders as readable content
- history supports keyword search and detail preview
- desktop hotkey can show/hide the app from tray

Delivered:

- `Use AI` switch on the home page
- AI explanation for dictionary/no-result states
- MiniMax `<think>` cleanup and Markdown rendering
- history page with left search/list pane and right detail preview pane
- system tray behavior for Windows/macOS
- customizable global hotkeys for show/hide and clear input
- modern generated app/tray icon

## Phase 4: Long Text Translation

Status: implemented, pending acceptance.

Goal:

Make longer translation reliable and cancellable.

Scope:

- paragraph-based chunking
- progress display
- cancel request
- retry failed chunk
- preserve Markdown
- terminology hints
- style setting

Implementation notes:

- Keep the existing normal translation path intact.
- Add a long-text controller path when input exceeds the configured chunk size.
- Split by paragraphs first, then merge small paragraphs up to the configured limit.
- Store per-chunk status so progress, cancellation, and retry are explicit.
- Preserve output order even if later parallel translation is introduced.
- Keep Phase 4 desktop-first; mobile-specific layout remains Phase 5.

Acceptance:

- long text does not freeze UI
- progress is visible
- request can be cancelled
- chunks merge in order
- Markdown structure is mostly preserved

Delivered:

- long input detection based on the configured chunk size
- paragraph-first chunking with long-paragraph fallback splitting
- sequential per-chunk translation with ordered merge
- visible progress text and progress bar on the home page
- cancel action for active long-text translation
- failed chunk retry action
- translation style and terminology hints passed into chunk prompts
- Markdown-oriented prompt requirements for structure preservation

## Phase 5: Mobile Adaptation

Goal:

Make Android and iOS usable, not just scaled-down desktop UI.

Scope:

- mobile vertical layout
- bottom navigation
- mobile copy/share behavior
- share text into app
- mobile dictionary result cards
- Android build
- iOS build

Acceptance:

- phone UI is usable one-handed
- copied text can be quickly queried or translated
- local dictionary lookup feels instant
- no cramped desktop layout on mobile

## Phase 6: Experience Polish

Goal:

Make the app feel like a refined daily tool.

Scope:

- desktop shortcuts
- small window mode
- restore last input
- favorites
- history search
- history export
- clear history
- dictionary source page
- custom prompts

Acceptance:

- copy, paste, query, copy result is fast
- visual design stays quiet and clean
- long-term use is not annoying

## Priority Table

| Priority | Feature | Phase |
| --- | --- | --- |
| P0 | AI text translation | Phase 1 |
| P0 | API Key settings | Phase 1 |
| P0 | one-click copy | Phase 1 |
| P0 | local history | Phase 1 |
| P0 | local English-to-Chinese dictionary | Phase 2 |
| P0 | local Chinese-to-English dictionary | Phase 2 |
| P0 | prebuilt dictionary database | Phase 2 |
| P1 | English inflection lookup | Phase 2 |
| P1 | prefix suggestions | Phase 2 |
| P1 | AI deep explanation | Phase 3 |
| P1 | Use AI switch | Phase 3 |
| P1 | long text chunked translation | Phase 4 |
| P2 | mobile adaptation | Phase 5 |
| P2 | favorites | Phase 6 |
| P2 | history search | completed in Phase 3 |
| P3 | voice input | deferred |
| P3 | OCR | out of scope |
| P3 | selected-text translation | out of scope |
| P3 | local translation model | out of scope |
| P3 | account system | out of scope |
| P3 | cloud sync | out of scope |
