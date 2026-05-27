import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from normalize import normalize_text


ROOT = Path(__file__).resolve().parents[2]
ASSET_DB = ROOT / "assets" / "dictionaries" / "dictionary_v1.db"
SCHEMA = Path(__file__).with_name("schema.sql")


ENTRIES = [
    {
        "headword": "charge",
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": "tʃɑːrdʒ",
        "part_of_speech": "v.; n.",
        "short_translation": "收费；指控；充电；负责；费用",
        "definition": """v.
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
        "source_name": "ClearTranslate Seed",
        "frequency_rank": 1200,
        "tags": "CET4,CET6,high-frequency",
        "aliases": [
            ("charges", "third_person_singular"),
            ("charged", "past_tense_or_past_participle"),
            ("charging", "present_participle"),
        ],
        "phrases": [
            ("in charge of", "负责；掌管"),
            ("charge for", "为某物收费"),
            ("be charged with", "被指控"),
            ("charge a battery", "给电池充电"),
        ],
        "examples": [
            ("The hotel charged me 100 dollars.", "酒店收了我 100 美元。"),
            ("He was charged with theft.", "他被指控盗窃。"),
        ],
    },
    {
        "headword": "character",
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": "ˈkærəktər",
        "part_of_speech": "n.",
        "short_translation": "性格；人物；字符",
        "definition": "n.\n1. 性格；品质\n2. 人物；角色\n3. 字符；文字",
        "source_name": "ClearTranslate Seed",
        "frequency_rank": 1500,
        "tags": "CET4,CET6",
        "aliases": [("characters", "plural")],
        "phrases": [],
        "examples": [],
    },
    {
        "headword": "charity",
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": "ˈtʃærəti",
        "part_of_speech": "n.",
        "short_translation": "慈善；慈善机构",
        "definition": "n.\n1. 慈善；施舍\n2. 慈善机构",
        "source_name": "ClearTranslate Seed",
        "frequency_rank": 3600,
        "tags": "CET4,CET6",
        "aliases": [("charities", "plural")],
        "phrases": [],
        "examples": [],
    },
    {
        "headword": "chart",
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": "tʃɑːrt",
        "part_of_speech": "n.; v.",
        "short_translation": "图表；海图；记录",
        "definition": "n.\n1. 图表\n2. 海图\nv.\n1. 记录；绘制图表",
        "source_name": "ClearTranslate Seed",
        "frequency_rank": 2800,
        "tags": "CET4",
        "aliases": [("charts", "plural_or_third_person_singular")],
        "phrases": [],
        "examples": [],
    },
    {
        "headword": "charm",
        "language": "en",
        "direction": "en_to_zh",
        "phonetic": "tʃɑːrm",
        "part_of_speech": "n.; v.",
        "short_translation": "魅力；吸引；迷住",
        "definition": "n.\n1. 魅力\n2. 护身符\nv.\n1. 迷住；吸引",
        "source_name": "ClearTranslate Seed",
        "frequency_rank": 4200,
        "tags": "CET6",
        "aliases": [("charms", "plural_or_third_person_singular")],
        "phrases": [],
        "examples": [],
    },
    {
        "headword": "负责",
        "language": "zh",
        "direction": "zh_to_en",
        "pinyin": "fu4 ze2",
        "part_of_speech": "v.",
        "short_translation": "be responsible for; be in charge of; take responsibility for",
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
        "examples": [
            ("我负责这个项目。", "I am responsible for this project."),
        ],
    },
]


def main() -> None:
    ASSET_DB.parent.mkdir(parents=True, exist_ok=True)
    if ASSET_DB.exists():
        ASSET_DB.unlink()

    connection = sqlite3.connect(ASSET_DB)
    try:
        connection.executescript(SCHEMA.read_text(encoding="utf-8"))
        insert_meta(connection)
        for entry in ENTRIES:
            insert_entry(connection, entry)
        connection.commit()
    finally:
        connection.close()


def insert_meta(connection: sqlite3.Connection) -> None:
    values = {
        "dictionary_version": "v1-seed",
        "schema_version": "1",
        "build_time": datetime.now(timezone.utc).isoformat(),
        "source_ecdict_version": "not-imported-phase2-seed",
        "source_cc_cedict_version": "not-imported-phase2-seed",
    }
    connection.executemany(
        "INSERT INTO dictionary_meta(key, value) VALUES(?, ?)",
        values.items(),
    )


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
            json.dumps(entry, ensure_ascii=False),
            entry["source_name"],
            entry.get("frequency_rank"),
            entry.get("tags"),
            datetime.now(timezone.utc).isoformat(),
        ),
    )
    entry_id = cursor.lastrowid

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
            for alias, alias_type in entry.get("aliases", [])
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


if __name__ == "__main__":
    main()

