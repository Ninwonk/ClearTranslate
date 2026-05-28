# ClearTranslate MVP Spec

## Current MVP Definition

The initial MVP milestones are complete:

1. AI text translation MVP
2. local dictionary MVP
3. AI dictionary enhancement

This avoids blocking usable translation on dictionary data preparation, while keeping the final product direction local-dictionary-first.

## Phase 1 MVP: AI Text Translation

Goal:

Make the current Windows/macOS desktop app reliable for sentence and paragraph translation.

Required:

- text input
- automatic Chinese/English detection
- OpenAI-compatible translation provider
- API Base URL setting
- API Key secure storage
- model setting
- one-click copy
- clear input/output
- readable error messages
- basic local history
- dark mode

Done from Phase 0:

- Windows app runs
- OpenAI-compatible provider works
- MiniMax response cleanup works
- API Key is not hardcoded

Phase 1 status: completed.

## Phase 2 MVP: Local Dictionary

Status: completed.

Goal:

Add instant offline lookup for common word and phrase cases.

Required:

- compressed `dictionary_v1.db.gz` asset
- dictionary asset decompression into the app support directory
- English-to-Chinese lookup
- Chinese-to-English lookup
- alias-based inflection lookup
- prefix suggestions
- structured dictionary result UI
- no-result state with AI query action

Dictionary source candidates:

- ECDICT for English-to-Chinese
- CC-CEDICT for Chinese-to-English

Implemented sources:

- ECDICT
- CC-CEDICT
- ClearTranslate seed entries for acceptance fixtures

Dictionary runtime format:

```text
SQLite database only
```

Do not parse MDict or StarDict at runtime.

## Phase 3 MVP: AI Dictionary Enhancement

Status: completed.

Delivered:

- local dictionary first for words and short phrases
- AI switch and AI query fallback
- AI deep explanation for dictionary/no-result states
- Markdown preview for AI explanation output
- local history with searchable split detail view
- Windows/macOS tray integration
- close-to-tray behavior and tray quit menu
- customizable global shortcuts

## Phase 4 Next MVP: Long Text Translation

Goal:

Translate long passages without freezing the UI or losing structure.

Required:

- detect long input by configured chunk size
- split by paragraphs and chunk length
- translate chunks in order
- show progress
- support cancel
- support retry for failed chunks
- merge translated chunks into a single output
- preserve Markdown/list/paragraph structure where possible

## Home Behavior

Default mode:

- word: local dictionary
- short phrase: local dictionary first
- sentence: AI translation
- paragraph: AI translation

Controls:

- Translate / Query button label changes with mode
- `Use AI` or `AI Enhance` switch can force AI behavior
- local no-result can offer AI query

## Dictionary Result UI

English-to-Chinese example:

```text
charge
/ tʃɑːrdʒ /

v.
1. 收费；要价
2. 指控；控告
3. 充电

n.
1. 费用
2. 指控

Common phrases
- in charge of
- charge for
- be charged with

Inflections
- charges
- charged
- charging
```

Chinese-to-English example:

```text
负责
pinyin: fu4 ze2

English expressions
1. be responsible for
2. be in charge of
3. take responsibility for
4. handle
5. manage
```

## Settings

### AI Settings

- API Provider
- API Base URL
- API Key
- Model
- default AI enabled
- translation style

### Local Dictionary Settings

- dictionary version
- dictionary sources
- enable English-to-Chinese
- enable Chinese-to-English
- show frequency
- show tags
- show inflections

### Privacy Settings

- save history
- clear history
- clear favorites
- allow sending text to AI API

### Appearance

- follow system
- light mode
- dark mode
- font size
- compact mode
