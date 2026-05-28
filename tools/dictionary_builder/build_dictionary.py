import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from normalize import normalize_text


ROOT = Path(__file__).resolve().parents[2]
ASSET_DB = ROOT / "assets" / "dictionaries" / "dictionary_v1.db"
SCHEMA = Path(__file__).with_name("schema.sql")


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
    }


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

ENTRIES.extend(
    [
        english_entry(
            "hello",
            "həˈloʊ",
            "interj.; n.",
            "你好；喂；问候",
            "interj.\n1. 你好；您好\n2. 喂，用于打招呼或接电话\nn.\n1. 问候；招呼",
            300,
            aliases=[("hi", "informal_greeting")],
            examples=[("Hello, nice to meet you.", "你好，很高兴见到你。")],
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
                (
                    "Please do not share personal information.",
                    "请不要分享个人信息。",
                ),
            ],
        ),
        english_entry(
            "world",
            "wɜːrld",
            "n.",
            "世界；领域；世人",
            "n.\n1. 世界；地球\n2. 某个领域或圈子\n3. 世人；人类社会",
            500,
            aliases=[("worlds", "plural")],
            examples=[("The world is changing fast.", "世界正在快速变化。")],
        ),
        english_entry(
            "good",
            "ɡʊd",
            "adj.; n.",
            "好的；有益的；善良的",
            "adj.\n1. 好的；令人满意的\n2. 有益的；有效的\n3. 善良的\nn.\n1. 好处；益处",
            200,
            aliases=[("better", "comparative"), ("best", "superlative")],
        ),
        english_entry(
            "morning",
            "ˈmɔːrnɪŋ",
            "n.",
            "早晨；上午",
            "n.\n1. 早晨；上午\n2. 一天的开始阶段",
            850,
            aliases=[("mornings", "plural")],
            phrases=[("good morning", "早上好")],
        ),
        english_entry(
            "afternoon",
            "ˌæftərˈnuːn",
            "n.",
            "下午",
            "n.\n1. 下午；午后",
            1100,
            aliases=[("afternoons", "plural")],
        ),
        english_entry(
            "available",
            "əˈveɪləbl",
            "adj.",
            "可用的；有空的；可获得的",
            "adj.\n1. 可用的；可获得的\n2. 有空的；可见面的\n3. 可购得的",
            950,
            phrases=[("available for", "可用于；有时间参加")],
            examples=[
                (
                    "I am available tomorrow afternoon.",
                    "我明天下午有空。",
                ),
            ],
        ),
        english_entry(
            "tomorrow",
            "təˈmɑːroʊ",
            "n.; adv.",
            "明天；在明天",
            "n.\n1. 明天\nadv.\n1. 在明天",
            700,
        ),
        english_entry(
            "today",
            "təˈdeɪ",
            "n.; adv.",
            "今天；在今天",
            "n.\n1. 今天；当今\nadv.\n1. 在今天；现在",
            650,
        ),
        english_entry(
            "translate",
            "trænsˈleɪt",
            "v.",
            "翻译；转化；解释",
            "v.\n1. 翻译\n2. 转化为另一种形式\n3. 解释；说明",
            1700,
            aliases=[
                ("translates", "third_person_singular"),
                ("translated", "past_tense_or_past_participle"),
                ("translating", "present_participle"),
            ],
        ),
        english_entry(
            "translation",
            "trænsˈleɪʃn",
            "n.",
            "翻译；译文；转化",
            "n.\n1. 翻译行为\n2. 译文\n3. 转化；转换",
            1600,
            aliases=[("translations", "plural")],
        ),
        english_entry(
            "dictionary",
            "ˈdɪkʃəneri",
            "n.",
            "词典；字典",
            "n.\n1. 词典；字典\n2. 专门术语表",
            2500,
            aliases=[("dictionaries", "plural")],
        ),
        english_entry(
            "history",
            "ˈhɪstri",
            "n.",
            "历史；历史记录",
            "n.\n1. 历史\n2. 过去经历\n3. 应用中的历史记录",
            1900,
            aliases=[("histories", "plural")],
        ),
        english_entry(
            "setting",
            "ˈsetɪŋ",
            "n.",
            "设置；环境；背景",
            "n.\n1. 设置；配置\n2. 环境；场景\n3. 背景",
            2300,
            aliases=[("settings", "plural")],
        ),
        english_entry(
            "model",
            "ˈmɑːdl",
            "n.; v.",
            "模型；型号；模范；建模",
            "n.\n1. 模型；样式\n2. 型号\n3. 模范\nv.\n1. 建模；模拟",
            1800,
            aliases=[
                ("models", "plural_or_third_person_singular"),
                ("modeled", "past_tense_or_past_participle"),
                ("modelling", "present_participle"),
                ("modeling", "present_participle"),
            ],
        ),
        english_entry(
            "input",
            "ˈɪnpʊt",
            "n.; v.",
            "输入；投入；输入内容",
            "n.\n1. 输入；输入内容\n2. 投入；意见\nv.\n1. 输入数据",
            2100,
            aliases=[
                ("inputs", "plural_or_third_person_singular"),
                ("inputted", "past_tense_or_past_participle"),
                ("inputting", "present_participle"),
            ],
        ),
        english_entry(
            "output",
            "ˈaʊtpʊt",
            "n.; v.",
            "输出；产出；输出内容",
            "n.\n1. 输出；输出内容\n2. 产量；产出\nv.\n1. 输出数据",
            2200,
            aliases=[
                ("outputs", "plural_or_third_person_singular"),
                ("outputted", "past_tense_or_past_participle"),
                ("outputting", "present_participle"),
            ],
        ),
        english_entry(
            "copy",
            "ˈkɑːpi",
            "n.; v.",
            "复制；副本；文案",
            "n.\n1. 副本；复制件\n2. 文案\nv.\n1. 复制\n2. 抄写；模仿",
            1300,
            aliases=[
                ("copies", "plural_or_third_person_singular"),
                ("copied", "past_tense_or_past_participle"),
                ("copying", "present_participle"),
            ],
        ),
        english_entry(
            "clear",
            "klɪr",
            "adj.; v.",
            "清楚的；清除；明确的",
            "adj.\n1. 清楚的；明确的\n2. 透明的\nv.\n1. 清除；清空\n2. 通过；批准",
            1000,
            aliases=[
                ("clears", "third_person_singular"),
                ("cleared", "past_tense_or_past_participle"),
                ("clearing", "present_participle"),
            ],
        ),
        english_entry(
            "simple",
            "ˈsɪmpl",
            "adj.",
            "简单的；朴素的；易懂的",
            "adj.\n1. 简单的；容易理解的\n2. 朴素的；不复杂的",
            800,
            aliases=[("simpler", "comparative"), ("simplest", "superlative")],
        ),
        english_entry(
            "fast",
            "fæst",
            "adj.; adv.",
            "快的；快速地",
            "adj.\n1. 快的；迅速的\nadv.\n1. 快速地",
            750,
            aliases=[("faster", "comparative"), ("fastest", "superlative")],
        ),
        english_entry(
            "responsible",
            "rɪˈspɑːnsəbl",
            "adj.",
            "负责的；有责任的；可靠的",
            "adj.\n1. 负责的；承担责任的\n2. 可靠的；可信赖的\n3. 是原因的",
            1000,
            phrases=[("be responsible for", "负责；对某事承担责任")],
        ),
    ]
)


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
