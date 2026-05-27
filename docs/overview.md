# ClearTranslate Overview

## Product Direction

ClearTranslate is a clean cross-platform Chinese-English translation tool built with Flutter for Windows, macOS, Android, and iOS.

The product is no longer planned as a pure LLM translation client. The new direction is a hybrid tool:

```text
Local dictionary for speed.
LLM API for depth and context.
```

## Positioning

ClearTranslate should be a fast, private, no-ad, no-membership personal translation tool.

It should not try to copy large translation platforms. It should focus on a smaller and more controllable experience:

- word lookup should be instant and local
- sentence and paragraph translation should be high quality
- long text translation should preserve structure
- API keys and history should stay local
- no account system, cloud sync, ads, or membership flow

## Core Principles

### Local First

Single words, short phrases, and Chinese-to-English expression lookup should prefer the local dictionary database.

Local dictionary lookup should be:

- offline
- fast
- structured
- privacy-preserving
- free from API cost

### AI For Complex Work

LLM API should handle tasks where context matters:

- sentence translation
- paragraph translation
- long text translation
- translation polishing
- deep word explanation
- examples and usage differences
- confusing synonym explanation

### Minimal Interaction

The home page still revolves around one flow:

```text
input -> classify mode -> show result -> copy / favorite / AI enhance
```

No feed, ads, learning community, account system, or membership prompts.

## Engine Model

```text
LocalDictionaryEngine
└── words, phrases, Chinese expression lookup, suggestions, offline search

LLMTranslationEngine
└── sentences, paragraphs, long text, AI explanation, polishing
```

Default behavior:

- word or short phrase: local dictionary first
- sentence, paragraph, or long text: LLM API
- user enables AI: force AI translation or AI explanation
- local dictionary has no result: offer AI query

## Non-Goals

Current planning excludes:

- local LLM
- local machine translation model
- runtime MDict parsing
- runtime StarDict parsing
- OCR
- screenshot translation
- selected-text translation
- browser extension
- account system
- cloud sync
- membership system
- ads
- learning community

