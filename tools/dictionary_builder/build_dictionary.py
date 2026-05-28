import argparse
import csv
import gzip
import json
import re
import shutil
import sqlite3
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from normalize import normalize_text


ROOT = Path(__file__).resolve().parents[2]
ASSET_DB = ROOT / "assets" / "dictionaries" / "dictionary_v1.db"
ASSET_DB_GZ = ROOT / "assets" / "dictionaries" / "dictionary_v1.db.gz"
SCHEMA = Path(__file__).with_name("schema.sql")
SOURCE_DIR = Path(__file__).with_name("sources")
ECDICT_CSV = SOURCE_DIR / "ecdict.csv"
CC_CEDICT_GZ = SOURCE_DIR / "cedict_1_0_ts_utf-8_mdbg.txt.gz"

ECDICT_URL = (
    "https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv"
)
CC_CEDICT_URL = (
    "https://www.mdbg.net/chinese/export/cedict/"
    "cedict_1_0_ts_utf-8_mdbg.txt.gz"
)

EXCHANGE_TYPES = {
    "p": "past_tense",
    "d": "past_participle",
    "i": "present_participle",
    "3": "third_person_singular",
    "r": "comparative",
    "t": "superlative",
    "s": "plural",
    "0": "lemma",
    "1": "exchange_marker",
}

CC_CEDICT_PATTERN = re.compile(r"^(\S+) (\S+) \[(.*?)\] /(.*)/$")


def main() -> None:
    args = parse_args()
    if args.download:
        download_sources()

    if args.profile == "full":
        require_source(ECDICT_CSV, ECDICT_URL)
        require_source(CC_CEDICT_GZ, CC_CEDICT_URL)

    ASSET_DB.parent.mkdir(parents=True, exist_ok=True)
    if ASSET_DB.exists():
        ASSET_DB.unlink()

    connection = sqlite3.connect(ASSET_DB)
    try:
        connection.execute("PRAGMA journal_mode = OFF")
        connection.execute("PRAGMA synchronous = OFF")
        connection.execute("PRAGMA temp_store = MEMORY")
        connection.executescript(SCHEMA.read_text(encoding="utf-8"))
        insert_meta(connection, args.profile)

        stats = {"seed": 0, "ecdict": 0, "cc_cedict": 0}
        for entry in seed_entries():
            insert_entry(connection, entry)
            stats["seed"] += 1

        if args.profile == "full":
            stats["ecdict"] = import_ecdict(connection)
            stats["cc_cedict"] = import_cc_cedict(connection)

        for key, value in stats.items():
            upsert_meta(connection, f"entry_count_{key}", str(value))

        connection.commit()
        connection.execute("VACUUM")
    finally:
        connection.close()

    compress_database()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build the bundled ClearTranslate SQLite dictionary.",
    )
    parser.add_argument(
        "--profile",
        choices=("full", "seed"),
        default="full",
        help="Build full ECDICT/CC-CEDICT database or the tiny seed database.",
    )
    parser.add_argument(
        "--download",
        action="store_true",
        help="Download ECDICT and CC-CEDICT sources before building.",
    )
    return parser.parse_args()


def download_sources() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    download_file(ECDICT_URL, ECDICT_CSV)
    download_file(CC_CEDICT_URL, CC_CEDICT_GZ)


def download_file(url: str, target: Path) -> None:
    print(f"Downloading {url}")
    with urllib.request.urlopen(url) as response:
        target.write_bytes(response.read())


def compress_database() -> None:
    with ASSET_DB.open("rb") as source, gzip.open(
        ASSET_DB_GZ,
        "wb",
        compresslevel=9,
    ) as target:
        shutil.copyfileobj(source, target)


def require_source(path: Path, url: str) -> None:
    if path.exists():
        return
    raise FileNotFoundError(
        f"Missing dictionary source: {path}. "
        f"Run `python tools/dictionary_builder/build_dictionary.py --download` "
        f"or download it from {url}."
    )


def insert_meta(connection: sqlite3.Connection, profile: str) -> None:
    values = {
        "dictionary_version": f"v1-{profile}",
        "schema_version": "1",
        "build_time": datetime.now(timezone.utc).isoformat(),
        "build_profile": profile,
        "source_ecdict_url": ECDICT_URL,
        "source_ecdict_license": "MIT",
        "source_cc_cedict_url": CC_CEDICT_URL,
        "source_cc_cedict_license": "CC BY-SA 4.0",
        "builder": "tools/dictionary_builder/build_dictionary.py",
    }
    connection.executemany(
        "INSERT INTO dictionary_meta(key, value) VALUES(?, ?)",
        values.items(),
    )


def upsert_meta(connection: sqlite3.Connection, key: str, value: str) -> None:
    connection.execute(
        """
        INSERT INTO dictionary_meta(key, value) VALUES(?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        """,
        (key, value),
    )


def import_ecdict(connection: sqlite3.Connection) -> int:
    count = 0
    with ECDICT_CSV.open("r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)
        for row in reader:
            entry = ecdict_row_to_entry(row)
            if entry is None:
                continue
            insert_entry(connection, entry)
            count += 1
            if count % 10000 == 0:
                connection.commit()
                print(f"Imported ECDICT rows: {count}")
    return count


def ecdict_row_to_entry(row: dict[str, str]) -> dict | None:
    word = (row.get("word") or "").strip()
    if not word:
        return None

    translation = clean_multiline(row.get("translation"))
    definition = clean_multiline(row.get("definition"))
    if not translation and not definition:
        return None

    tags = ",".join(
        item
        for item in [
            row.get("tag", "").strip(),
            "collins" if row.get("collins", "").strip() not in ("", "0") else "",
            "oxford" if row.get("oxford", "").strip() not in ("", "0") else "",
        ]
        if item
    )
    frequency_rank = first_int(row.get("frq")) or first_int(row.get("bnc"))

    return {
        "headword": word,
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": empty_to_none(row.get("phonetic")),
        "part_of_speech": empty_to_none(row.get("pos")),
        "short_translation": first_translation_line(translation or definition),
        "definition": combine_definition(translation, definition),
        "source_name": "ECDICT",
        "frequency_rank": frequency_rank,
        "tags": tags or None,
        "aliases": parse_exchange(row.get("exchange")),
        "phrases": [],
        "examples": [],
        "raw_source": None,
    }


def import_cc_cedict(connection: sqlite3.Connection) -> int:
    count = 0
    with gzip.open(CC_CEDICT_GZ, "rt", encoding="utf-8") as file:
        for line in file:
            entry = cc_cedict_line_to_entry(line)
            if entry is None:
                continue
            insert_entry(connection, entry)
            count += 1
            if count % 10000 == 0:
                connection.commit()
                print(f"Imported CC-CEDICT rows: {count}")
    return count


def cc_cedict_line_to_entry(line: str) -> dict | None:
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    match = CC_CEDICT_PATTERN.match(line)
    if match is None:
        return None

    traditional, simplified, pinyin, definition_text = match.groups()
    definitions = [
        item.strip()
        for item in definition_text.split("/")
        if item.strip()
    ]
    if not definitions:
        return None

    aliases = []
    if traditional != simplified:
        aliases.append((traditional, "traditional"))

    return {
        "headword": simplified,
        "language": "zh",
        "direction": "zh_to_en",
        "pinyin": pinyin,
        "part_of_speech": None,
        "short_translation": "; ".join(definitions[:3]),
        "definition": format_english_definitions(definitions),
        "source_name": "CC-CEDICT",
        "frequency_rank": None,
        "tags": "cc-cedict",
        "aliases": aliases,
        "phrases": [],
        "examples": [],
        "raw_source": None,
    }


def insert_entry(connection: sqlite3.Connection, entry: dict) -> None:
    cursor = connection.execute(
        """
        INSERT INTO dictionary_entries(
          headword,
          normalized_headword,
          language,
          direction,
          phonetic,
          pinyin,
          part_of_speech,
          short_translation,
          definition,
          raw_source,
          source_name,
          frequency_rank,
          tags,
          created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            entry["headword"],
            normalize_text(entry["headword"]),
            entry["language"],
            entry["direction"],
            entry.get("phonetic"),
            entry.get("pinyin"),
            entry.get("part_of_speech"),
            entry.get("short_translation"),
            entry.get("definition"),
            entry.get("raw_source"),
            entry["source_name"],
            entry.get("frequency_rank"),
            entry.get("tags"),
            datetime.now(timezone.utc).isoformat(),
        ),
    )
    entry_id = cursor.lastrowid

    aliases = dedupe_pairs(entry.get("aliases", []))
    connection.executemany(
        """
        INSERT INTO dictionary_aliases(
          entry_id,
          alias,
          normalized_alias,
          alias_type
        )
        VALUES (?, ?, ?, ?)
        """,
        [
            (entry_id, alias, normalize_text(alias), alias_type)
            for alias, alias_type in aliases
            if alias and normalize_text(alias) != normalize_text(entry["headword"])
        ],
    )

    connection.executemany(
        """
        INSERT INTO dictionary_phrases(
          entry_id,
          phrase,
          normalized_phrase,
          translation
        )
        VALUES (?, ?, ?, ?)
        """,
        [
            (entry_id, phrase, normalize_text(phrase), translation)
            for phrase, translation in entry.get("phrases", [])
        ],
    )

    connection.executemany(
        """
        INSERT INTO dictionary_examples(
          entry_id,
          example_text,
          example_translation,
          source_name
        )
        VALUES (?, ?, ?, ?)
        """,
        [
            (entry_id, example_text, example_translation, entry["source_name"])
            for example_text, example_translation in entry.get("examples", [])
        ],
    )


def parse_exchange(value: str | None) -> list[tuple[str, str]]:
    if not value:
        return []

    aliases = []
    for segment in value.split("/"):
        if ":" not in segment:
            continue
        code, alias = segment.split(":", 1)
        alias = alias.strip()
        if not alias:
            continue
        aliases.append((alias, EXCHANGE_TYPES.get(code, code)))
    return aliases


def dedupe_pairs(values: list[tuple[str, str]]) -> list[tuple[str, str]]:
    seen = set()
    result = []
    for value in values:
        key = (normalize_text(value[0]), value[1])
        if key in seen:
            continue
        seen.add(key)
        result.append(value)
    return result


def clean_multiline(value: str | None) -> str | None:
    if value is None:
        return None
    text = value.replace("\\n", "\n").strip()
    return text or None


def empty_to_none(value: str | None) -> str | None:
    if value is None:
        return None
    text = value.strip()
    return text or None


def first_int(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        number = int(value)
    except ValueError:
        return None
    return number if number > 0 else None


def first_translation_line(value: str | None) -> str | None:
    if not value:
        return None
    for line in value.splitlines():
        text = line.strip()
        if not text:
            continue
        if len(text) > 160:
            return f"{text[:157]}..."
        return text
    return None


def combine_definition(translation: str | None, definition: str | None) -> str | None:
    sections = []
    if translation:
        sections.append(translation)
    if definition:
        sections.append(f"English definition\n{definition}")
    return "\n\n".join(sections) if sections else None


def format_english_definitions(definitions: list[str]) -> str:
    if len(definitions) == 1:
        return definitions[0]
    return "\n".join(
        f"{index}. {definition}"
        for index, definition in enumerate(definitions, start=1)
    )


def seed_entries() -> list[dict]:
    return [
        english_entry(
            "charge",
            "tʃɑːrdʒ",
            "v.; n.",
            "收费；指控；充电；负责；费用",
            """v.
1. 收费；要价
2. 指控；控告
3. 充电
4. 负责；掌管
5. 冲锋

n.
1. 费用
2. 指控
3. 主管；负责
4. 电荷""",
            1200,
            aliases=[
                ("charges", "third_person_singular"),
                ("charged", "past_tense_or_past_participle"),
                ("charging", "present_participle"),
            ],
            phrases=[
                ("in charge of", "负责；掌管"),
                ("charge for", "为某物收费"),
                ("be charged with", "被指控"),
                ("charge a battery", "给电池充电"),
            ],
            examples=[
                ("The hotel charged me 100 dollars.", "酒店收了我 100 美元。"),
                ("He was charged with theft.", "他被指控盗窃。"),
            ],
        ),
        english_entry(
            "personal",
            "ˈpɜːrsənl",
            "adj.",
            "个人的；私人的；亲自的",
            "adj.\n1. 个人的；与个人有关的\n2. 私人的；隐私的\n3. 亲自的；本人做出的",
            900,
            aliases=[("personally", "adverb"), ("personals", "plural")],
            phrases=[
                ("personal information", "个人信息"),
                ("personal opinion", "个人观点"),
                ("personal computer", "个人电脑"),
            ],
            examples=[
                ("This is my personal opinion.", "这是我的个人观点。"),
                ("Please do not share personal information.", "请不要分享个人信息。"),
            ],
        ),
        {
            "headword": "负责",
            "language": "zh",
            "direction": "zh_to_en",
            "pinyin": "fu4 ze2",
            "part_of_speech": "v.",
            "short_translation": (
                "be responsible for; be in charge of; take responsibility for"
            ),
            "definition": """英文表达
1. be responsible for
2. be in charge of
3. take responsibility for
4. handle
5. manage""",
            "source_name": "ClearTranslate Seed",
            "frequency_rank": 800,
            "tags": "common-expression",
            "aliases": [("負責", "traditional")],
            "phrases": [
                ("负责人", "person in charge"),
                ("负责某事", "be responsible for something"),
                ("对结果负责", "be responsible for the result"),
            ],
            "examples": [("我负责这个项目。", "I am responsible for this project.")],
            "raw_source": json.dumps({"source": "seed"}, ensure_ascii=False),
        },
    ]


def english_entry(
    headword: str,
    phonetic: str,
    part_of_speech: str,
    short_translation: str,
    definition: str,
    frequency_rank: int,
    aliases: list[tuple[str, str]] | None = None,
    phrases: list[tuple[str, str]] | None = None,
    examples: list[tuple[str, str]] | None = None,
    tags: str = "seed,common",
) -> dict:
    return {
        "headword": headword,
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": phonetic,
        "part_of_speech": part_of_speech,
        "short_translation": short_translation,
        "definition": definition,
        "source_name": "ClearTranslate Seed",
        "frequency_rank": frequency_rank,
        "tags": tags,
        "aliases": aliases or [],
        "phrases": phrases or [],
        "examples": examples or [],
        "raw_source": json.dumps({"source": "seed"}, ensure_ascii=False),
    }


if __name__ == "__main__":
    main()
