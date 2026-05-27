# ClearTranslate Product Spec

## One-Sentence Definition

ClearTranslate is a local-dictionary-first, AI-translation-enhanced, minimalist cross-platform Chinese-English translation tool.

## Product Positioning

ClearTranslate serves personal high-frequency translation and dictionary lookup.

It should feel faster and cleaner than opening a web translator:

- no ads
- no membership prompts
- no account requirement
- no feed
- no cloud dependency for word lookup

## Core Product Model

```text
Single words / short phrases -> local dictionary
Sentences / paragraphs / long text -> LLM API
AI Enhance enabled -> LLM API
Local no-result -> offer AI query
```

## Local Dictionary

Local dictionary lookup is the default for:

- English words
- English inflections
- English short phrases
- short Chinese expressions
- Chinese-to-English lookup

Expected qualities:

- offline
- fast
- structured
- privacy-preserving
- no API cost

## LLM API

LLM API handles:

- sentence translation
- paragraph translation
- long text translation
- polishing
- deep word explanation
- examples
- synonym and confusing-word explanation
- English expression difference explanation

## Input Mode Classification

### English Word

Rule:

- only letters, hyphen, apostrophe
- one token
- no sentence punctuation

Default:

```text
local dictionary
```

### English Short Phrase

Rule:

- English tokens 2-5
- no complete sentence structure

Default:

```text
local dictionary first
```

### Chinese Term

Rule:

- mostly Chinese characters
- short length
- no full sentence punctuation

Default:

```text
local Chinese-to-English dictionary
```

### Sentence Or Paragraph

Rule:

- longer token count
- sentence punctuation
- multiple clauses
- multiline text

Default:

```text
AI translation
```

## AI Switch

Home page should add a lightweight switch:

```text
Use AI
```

Behavior:

- on word: AI explanation
- on phrase: AI phrase explanation
- on sentence: AI translation
- on long text: AI chunked translation

When AI is off:

- words and phrases use local dictionary only
- sentences show a clear prompt that local dictionary cannot reliably translate full sentences

## Button Labels

Primary action label changes by mode:

- local dictionary: Query
- AI translation: Translate
- AI explanation: AI Explain

## No-Result State

When local dictionary has no result:

```text
No local dictionary result found.

[Use AI Query]
```

Do not add web search in the first dictionary version.

