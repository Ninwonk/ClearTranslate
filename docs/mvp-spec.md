# ClearTranslate MVP Spec

## Current MVP Definition

ClearTranslate MVP is split into two practical milestones:

1. AI text translation MVP
2. local dictionary MVP

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

Still needed for Phase 1:

- local history persistence
- error message mapping
- desktop shortcut polish
- UI state polish

## Phase 2 MVP: Local Dictionary

Goal:

Add instant offline lookup for common word and phrase cases.

Required:

- `dictionary_v1.db` asset
- dictionary asset copy on first launch
- English-to-Chinese lookup
- Chinese-to-English lookup
- alias-based inflection lookup
- prefix suggestions
- structured dictionary result UI
- no-result state with AI query action

Dictionary source candidates:

- ECDICT for English-to-Chinese
- CC-CEDICT for Chinese-to-English

Dictionary runtime format:

```text
SQLite database only
```

Do not parse MDict or StarDict at runtime.

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

