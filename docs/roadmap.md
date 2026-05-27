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

## Phase 2: Local Dictionary MVP

Goal:

Add offline local dictionary lookup for words and short phrases.

Scope:

- build `assets/dictionaries/dictionary_v1.db`
- copy bundled dictionary database to app support directory on first launch
- English word to Chinese lookup
- English inflection lookup through aliases
- Chinese word or phrase to English lookup
- prefix suggestions
- local no-result state
- offer AI query when local lookup misses
- structured dictionary result UI
- dictionary lookup history

Acceptance:

- `charge` shows local dictionary result
- `charged` resolves to `charge`
- `负责` shows English expressions
- `char` shows suggestions
- dictionary lookup works offline
- local lookup is visibly faster than AI request

## Phase 3: AI Dictionary Enhancement

Goal:

Combine local dictionary speed with AI explanation depth.

Scope:

- add a home-page `Use AI` / `AI Enhance` switch
- word result page has `AI deep explanation`
- Chinese-to-English result page has `AI explain differences`
- local no-result can trigger AI query
- AI explanation history
- visually separate local dictionary content from AI content

Acceptance:

- word and phrase inputs default to local dictionary
- clicking AI explanation calls LLM
- sentence input defaults to AI translation
- when AI is disabled, sentence input explains that local dictionary cannot reliably translate full sentences

## Phase 4: Long Text Translation

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

Acceptance:

- long text does not freeze UI
- progress is visible
- request can be cancelled
- chunks merge in order
- Markdown structure is mostly preserved

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
| P2 | history search | Phase 6 |
| P3 | voice input | deferred |
| P3 | OCR | out of scope |
| P3 | selected-text translation | out of scope |
| P3 | local translation model | out of scope |
| P3 | account system | out of scope |
| P3 | cloud sync | out of scope |

