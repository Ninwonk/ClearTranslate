CREATE TABLE dictionary_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE dictionary_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  headword TEXT NOT NULL,
  normalized_headword TEXT NOT NULL,
  language TEXT NOT NULL,
  direction TEXT NOT NULL,
  phonetic TEXT,
  pinyin TEXT,
  part_of_speech TEXT,
  short_translation TEXT,
  definition TEXT,
  raw_source TEXT,
  source_name TEXT NOT NULL,
  frequency_rank INTEGER,
  tags TEXT,
  created_at TEXT
);

CREATE TABLE dictionary_aliases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  alias TEXT NOT NULL,
  normalized_alias TEXT NOT NULL,
  alias_type TEXT NOT NULL,
  FOREIGN KEY(entry_id) REFERENCES dictionary_entries(id)
);

CREATE TABLE dictionary_examples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  example_text TEXT NOT NULL,
  example_translation TEXT,
  source_name TEXT,
  FOREIGN KEY(entry_id) REFERENCES dictionary_entries(id)
);

CREATE TABLE dictionary_phrases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  phrase TEXT NOT NULL,
  normalized_phrase TEXT NOT NULL,
  translation TEXT,
  FOREIGN KEY(entry_id) REFERENCES dictionary_entries(id)
);

CREATE INDEX idx_dictionary_entries_normalized_headword
ON dictionary_entries(normalized_headword);

CREATE INDEX idx_dictionary_entries_direction
ON dictionary_entries(direction);

CREATE INDEX idx_dictionary_aliases_normalized_alias
ON dictionary_aliases(normalized_alias);

CREATE INDEX idx_dictionary_phrases_normalized_phrase
ON dictionary_phrases(normalized_phrase);

