#!/usr/bin/env python3
"""Build the HSK 2025 app datasets from pinned, attributed source lists."""

import argparse
import csv
import hashlib
import io
import json
import os
import re
import shutil
import tempfile
import unicodedata
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent.parent
SOURCE_DIR = DATA_DIR / "sources" / "hsk-2025"
# Optional reviewed per-row overrides keyed "LEVEL|frequency" (e.g. "HSK-3|94"),
# used where one headword appears twice with different senses and the legacy
# data cannot carry two Polish translations. Each value must repeat the row's
# sourceWord and may set polish, notes, pinyin and english.
SENSE_OVERRIDES_PATH = SOURCE_DIR / "sense_overrides.json"
SENSE_OVERRIDE_FIELDS = frozenset({"sourceWord", "polish", "notes", "pinyin", "english"})
# Reviewed Polish translation shards, keyed "LEVEL|frequency". Each shard holds a
# fixed slice of the original translation worklist in source order; its keys are
# validated against the pinned source lists rather than a regenerated worklist.
TRANSLATION_SHARDS: tuple[tuple[int, int], ...] = tuple(
    (start, min(start + 399, 8280)) for start in range(1, 8281, 400)
)
TRANSLATION_SHARD_FIELDS = frozenset({"polish", "english", "pinyin", "review"})
# Reviewed pinyin/English for rows that CC-CEDICT and the legacy data cannot fill.
METADATA_COMPLETIONS_PATH = DATA_DIR / "hsk2025_metadata_completions.json"
METADATA_COMPLETION_FIELDS = frozenset({"pinyin", "english"})
REQUIRED_TEXT_FIELDS = ("pinyin", "english", "polish")
ROW_KEY = re.compile(r"(HSK-[1-6]|HSK-7-9)\|([1-9]\d*)")
SOURCE_COMMIT = "182692ce5a11bc30bdc771835d2f0f27491c25de"
CEDICT_URL = (
    "https://raw.githubusercontent.com/krmanik/cedict-json/"
    "63c2569948629323b515833930fdd10f285401b6/cedict_ts.u8"
)
LEVEL_FILES = {
    "HSK-1": "HSK_Level_1_words.txt",
    "HSK-2": "HSK_Level_2_words.txt",
    "HSK-3": "HSK_Level_3_words.txt",
    "HSK-4": "HSK_Level_4_words.txt",
    "HSK-5": "HSK_Level_5_words.txt",
    "HSK-6": "HSK_Level_6_words.txt",
    "HSK-7-9": "HSK_Level_7-9_words.txt",
}
EXPECTED_COUNTS = {
    "HSK-1": 300,
    "HSK-2": 204,
    "HSK-3": 507,
    "HSK-4": 1019,
    "HSK-5": 1638,
    "HSK-6": 1815,
    "HSK-7-9": 5622,
}
CEDICT_LINE = re.compile(r"^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.*)/$")
SURNAME_GLOSS = re.compile(r"^surname\s+\S", re.IGNORECASE)
VARIANT_GLOSS = re.compile(
    r"^(?:(?:old|archaic|ancient|obsolete|unofficial|erroneous|erhua|"
    r"Japanese|Korean|non-standard|traditional|literary)\s+)*"
    r"(?:variant|form) of\b|^see\s|^used in\b",
    re.IGNORECASE,
)
# Curated CC-CEDICT readings for HSK headwords (or numbered source words such as
# 喂1/喂2) whose homographs have several lexical readings that the legacy data
# cannot separate. Headwords listed twice in one level with different readings
# (e.g. 缝, 大意, 晃) are deliberately absent and reported as ambiguous by
# --sense-candidates instead.
PREFERRED_READINGS: dict[str, str] = {
    "喂1": "wei2", "喂2": "wei4",
    "吧": "ba5", "车": "che1", "给": "gei3", "好吃": "hao3 chi1",
    "见": "jian4", "要": "yao4", "雨": "yu3", "比": "bi3",
    "别": "bie2", "出来": "chu1 lai2", "从": "cong2", "告诉": "gao4 su5",
    "间": "jian1", "累": "lei4", "起来": "qi3 lai5", "远": "yuan3",
    "差": "cha4", "女人": "nu:3 ren2", "中": "zhong1", "嗯": "en5",
    "唉": "ai1", "哈": "ha1", "哦": "o4", "地道": "di4 dao4",
    "空地": "kong4 di4", "款式": "kuan3 shi4", "淋": "lin2", "漂": "piao1",
    "歪": "wai1", "粘": "zhan1", "熬": "ao2", "凹": "ao1",
    "剥": "bao1", "奔": "ben1", "绷": "beng1", "本色": "ben3 se4",
    "采": "cai3", "掺": "chan1", "澄清": "cheng2 qing1", "重重": "chong2 chong2",
    "仇": "chou2", "创": "chuang4", "出息": "chu1 xi5", "逮": "dai3",
    "担": "dan1", "倒数": "dao4 shu3", "得罪": "de2 zui5", "钉": "ding1",
    "斗": "dou4", "恶": "e4", "分量": "fen4 liang5", "搁": "ge1",
    "供": "gong1", "供养": "gong1 yang3", "哄": "hong3", "糊": "hu2",
    "劲": "jin4", "俊": "jun4", "扛": "kang2", "口音": "kou3 yin5",
    "搂": "lou3", "抡": "lun1", "眯": "mi1", "抹": "mo3",
    "刨": "pao2", "劈": "pi1", "片子": "pian1 zi5", "翘": "qiao4",
    "省事": "sheng3 shi4", "世故": "shi4 gu5", "驮": "tuo2", "唯": "wei2",
    "为人": "wei2 ren2", "削": "xiao1", "下调": "xia4 tiao2", "哑": "ya3",
    "涌": "yong3", "熨": "yun4", "攒": "zan3", "拽": "zhuai4",
    "幢": "zhuang4", "数": "shu3", "盛": "sheng4", "铺": "pu4",
    "精神": "jing1 shen2", "炸": "zha4",
}
# Readings for headwords listed more than once in one level, keyed by
# (level, frequency). The HSK 2025 source lists are sorted by toneless pinyin,
# so a duplicate's neighbours reveal its syllable (e.g. 重 between 吃惊 and 重新
# is chong2; 得 between 的话 and 灯 is dei3). Adjacent duplicates with the same
# toneless syllable cannot be ordered that way; they get distinct readings in
# tone order and are listed in POSITIONAL_READING_ORDER_ASSUMED for review.
POSITIONAL_READINGS: dict[tuple[str, int], str] = {
    ("HSK-2", 51): "guo4", ("HSK-2", 52): "guo5",
    ("HSK-3", 90): "de2", ("HSK-3", 94): "dei3",
    ("HSK-4", 105): "chong2", ("HSK-4", 977): "zhong4",
    ("HSK-4", 455): "kong1", ("HSK-4", 456): "kong4",
    ("HSK-5", 208): "chu3", ("HSK-5", 209): "chu4",
    ("HSK-5", 313): "diao4", ("HSK-5", 1156): "tiao2",
    ("HSK-5", 561): "ji4", ("HSK-5", 1260): "xi4",
    ("HSK-6", 758): "juan3", ("HSK-6", 759): "juan4",
    ("HSK-6", 875): "lou4", ("HSK-6", 878): "lu4",
    ("HSK-6", 1141): "san3", ("HSK-6", 1142): "san4",
    ("HSK-6", 1341): "tu3", ("HSK-6", 1342): "tu4",
    ("HSK-7-9", 769): "dan1", ("HSK-7-9", 770): "dan4",
    ("HSK-7-9", 831): "da4 yi4", ("HSK-7-9", 832): "da4 yi5",
    ("HSK-7-9", 1182): "feng2", ("HSK-7-9", 1183): "feng4",
    ("HSK-7-9", 1735): "huang3", ("HSK-7-9", 1736): "huang4",
    ("HSK-7-9", 2262): "juan1", ("HSK-7-9", 2263): "juan4",
    ("HSK-7-9", 2796): "men1", ("HSK-7-9", 2797): "men4",
    ("HSK-7-9", 2798): "meng1", ("HSK-7-9", 2800): "meng2",
    ("HSK-7-9", 2987): "ning2", ("HSK-7-9", 2988): "ning3",
    ("HSK-7-9", 3176): "qiang1", ("HSK-7-9", 3177): "qiang4",
}
POSITIONAL_READING_ORDER_ASSUMED: frozenset[tuple[str, int]] = frozenset(
    key
    for key in POSITIONAL_READINGS
    if key[0] != "HSK-3" and key not in {
        ("HSK-4", 105), ("HSK-4", 977), ("HSK-5", 313), ("HSK-5", 1156),
        ("HSK-5", 561), ("HSK-5", 1260), ("HSK-6", 875), ("HSK-6", 878),
    }
)
# Traditional forms for headwords whose same-reading CC-CEDICT homographs differ
# only by traditional character and where the legacy gloss is misleading.
PREFERRED_TRADITIONAL: dict[str, str] = {
    "台": "臺", "机制": "機制", "编制": "編制", "后": "後", "考": "考",
    "局": "局", "余": "餘", "筑": "築", "致": "致", "拟": "擬", "于": "於",
}
# Reviewed English for headwords whose CC-CEDICT entry is only a reference and
# that have no source shard override; authored by the corpus reviewer.
CURATED_ENGLISH: dict[str, str] = {
    "体检": "medical examination; health checkup",
    "纪录": "record; written account; record achievement",
}
GLOSS_STOPWORDS = {
    "abbr", "also", "and", "are", "but", "for", "from", "into", "one", "sb", "sth",
    "that", "the", "their", "this", "used", "with", "etc", "classifier", "variant",
    "old", "see", "word", "words",
}
TONE_MARKS = {
    "a": "āáǎà",
    "e": "ēéěè",
    "i": "īíǐì",
    "o": "ōóǒò",
    "u": "ūúǔù",
    "ü": "ǖǘǚǜ",
}


def _pinyin_syllable(numbered: str) -> str:
    match = re.fullmatch(r"(.+?)([1-5])", numbered.lower())
    if not match:
        return numbered
    syllable, tone_text = match.groups()
    tone = int(tone_text)
    syllable = syllable.replace("u:", "ü").replace("v", "ü")
    if tone == 5:
        return syllable
    if "a" in syllable:
        index = syllable.index("a")
    elif "e" in syllable:
        index = syllable.index("e")
    elif "ou" in syllable:
        index = syllable.index("ou")
    else:
        vowels = [index for index, char in enumerate(syllable) if char in TONE_MARKS]
        if not vowels:
            return syllable
        index = vowels[-1]
    vowel = syllable[index]
    return syllable[:index] + TONE_MARKS[vowel][tone - 1] + syllable[index + 1 :]


def pinyin_with_tones(numbered: str) -> str:
    return " ".join(_pinyin_syllable(syllable) for syllable in numbered.split())


def normalize_pinyin(value: str) -> str:
    decomposed = unicodedata.normalize("NFD", value.lower())
    return "".join(
        char
        for char in decomposed
        if not unicodedata.combining(char) and not char.isspace() and not char.isdigit()
    ).replace("ü", "u").replace("v", "u")


def pinyin_reading_key(value: str) -> str:
    """Case-, spacing- and punctuation-insensitive reading key that keeps tones."""
    text = value.lower().replace("u:", "ü").replace("v", "ü")
    text = unicodedata.normalize("NFC", text)
    return "".join(char for char in text if char.isalpha())


def cedict_reading_key(numbered: str) -> str:
    return pinyin_reading_key(pinyin_with_tones(numbered))


def _glosses(entry: dict[str, str]) -> list[str]:
    return [gloss.strip() for gloss in entry.get("english", "").split("; ") if gloss.strip()]


def is_proper_entry(entry: dict[str, str]) -> bool:
    """CC-CEDICT capitalises the pinyin of proper nouns (names, places, surnames)."""
    return entry.get("pinyin", "")[:1].isupper()


def is_surname_only_entry(entry: dict[str, str]) -> bool:
    glosses = _glosses(entry)
    return bool(glosses) and all(SURNAME_GLOSS.match(gloss) for gloss in glosses)


def is_variant_only_entry(entry: dict[str, str]) -> bool:
    glosses = _glosses(entry)
    return bool(glosses) and all(VARIANT_GLOSS.match(gloss) for gloss in glosses)


def _primary_gloss_is_variant(entry: dict[str, str]) -> bool:
    glosses = _glosses(entry)
    return bool(glosses) and bool(VARIANT_GLOSS.match(glosses[0]))


REFERENCE_GLOSS = re.compile(
    r"^(?:abbr\. for|(?:(?:old|archaic|ancient|obsolete|unofficial|erroneous|erhua|"
    r"non-standard|literary)\s+)*variant of|see(?: also)?)\s+"
    r"(?P<first>[^\s\[|,;()]+)(?:\|(?P<second>[^\s\[,;()]+))?"
    r"(?:\[(?P<pinyin>[^\]]+)\])?"
)


def _referenced_entry(
    gloss: str, cedict: dict[str, list[dict[str, str]]]
) -> tuple[re.Match, dict[str, str]] | None:
    match = REFERENCE_GLOSS.match(gloss)
    if not match:
        return None
    target = match.group("second") or match.group("first")
    candidates = [
        entry
        for entry in cedict.get(target, [])
        if not is_proper_entry(entry) and not _primary_gloss_is_variant(entry)
    ]
    if match.group("pinyin"):
        wanted = match.group("pinyin").lower()
        candidates = [e for e in candidates if e["pinyin"].lower() == wanted]
    return (match, candidates[0]) if candidates else None


def resolve_reference_english(
    entry: dict[str, str], cedict: dict[str, list[dict[str, str]]]
) -> str:
    """Replace a leading "see/variant of/abbr. for X" gloss with X's senses.

    Only entries whose first gloss is such a cross-reference are changed, and
    only references that resolve to a lexical CC-CEDICT entry are expanded.
    """
    glosses = _glosses(entry)
    if not glosses or not _referenced_entry(glosses[0], cedict):
        return entry["english"]
    result = []
    for gloss in glosses:
        reference = _referenced_entry(gloss, cedict)
        if reference is None:
            result.append(gloss)
            continue
        match, target = reference
        result.extend(_glosses(target))
        trailing = gloss[match.end():].strip()
        if trailing and not trailing.startswith("("):
            result.append(trailing)
    return "; ".join(_dedupe_glosses(result))


def _dedupe_glosses(glosses: list[str]) -> list[str]:
    seen = set()
    result = []
    for gloss in glosses:
        if gloss not in seen:
            seen.add(gloss)
            result.append(gloss)
    return result


def _ensure_cedict(dictionary_path: Path | None) -> Path:
    if dictionary_path:
        return dictionary_path
    cache_path = Path(tempfile.gettempdir()) / "chinese-learning-app-cedict.u8"
    if not cache_path.exists():
        request = urllib.request.Request(
            CEDICT_URL,
            headers={"User-Agent": "ChineseLearningApp vocabulary-data-builder"},
        )
        with urllib.request.urlopen(request, timeout=60) as response:
            cache_path.write_bytes(response.read())
    return cache_path


def load_cedict(path: Path) -> dict[str, list[dict[str, str]]]:
    entries: dict[str, list[dict[str, str]]] = defaultdict(list)
    with path.open(encoding="utf-8") as source:
        for line in source:
            if not line or line.startswith("#"):
                continue
            match = CEDICT_LINE.match(line.strip())
            if not match:
                continue
            traditional, simplified, pinyin, glosses = match.groups()
            entries[simplified].append(
                {
                    "traditional": traditional,
                    "pinyin": pinyin,
                    "english": "; ".join(
                        _dedupe_glosses(
                            [gloss.strip() for gloss in glosses.split("/") if gloss.strip()]
                        )
                    ),
                }
            )
    return entries


def load_legacy_words() -> dict[str, list[dict]]:
    legacy: dict[str, list[dict]] = defaultdict(list)
    for level in range(1, 7):
        path = DATA_DIR / f"hsk{level}_words.json"
        if not path.exists():
            continue
        with path.open(encoding="utf-8") as source:
            words = json.load(source)
        for word in words:
            hanzi = str(word.get("hanzi", "")).strip()
            if hanzi:
                legacy[hanzi].append(word)
    return legacy


def _pick_legacy_entry(
    candidates: list[dict], dictionary_entries: list[dict[str, str]]
) -> dict | None:
    if not candidates:
        return None
    return next(
        (
            candidate
            for candidate in candidates
            if str(candidate.get("pinyin", "")).strip()
            and any(
                _reading_match(entry, str(candidate.get("pinyin", ""))) <= 1
                for entry in dictionary_entries
            )
        ),
        candidates[0] if len(candidates) == 1 else None,
    )


def _reading_match(candidate: dict[str, str], legacy_pinyin: str) -> int:
    """0 = same reading incl. tones, 1 = same toneless reading, 2 = different.

    Legacy readings such as ``wèi/wéi`` list alternatives; the best one counts.
    """
    alternatives = [part for part in legacy_pinyin.split("/") if part.strip()]
    if not alternatives:
        return 0
    best = 2
    for alternative in alternatives:
        if cedict_reading_key(candidate["pinyin"]) == pinyin_reading_key(alternative):
            return 0
        if normalize_pinyin(candidate["pinyin"]) == normalize_pinyin(alternative):
            best = 1
    return best


def _has_neutral_syllable(legacy_pinyin: str, candidate: dict[str, str]) -> bool:
    """Whether the legacy reading leaves some syllable of the candidate toneless."""
    tone_marks = sum(
        1
        for char in unicodedata.normalize("NFD", legacy_pinyin.split("/")[0])
        if unicodedata.combining(char) and char != "\u0308"
    )
    return tone_marks < len(candidate["pinyin"].split())


def _gloss_tokens(text: str) -> set[str]:
    return {
        token
        for token in re.findall(r"[a-z]+", text.lower())
        if len(token) >= 3 and token not in GLOSS_STOPWORDS
    }


def _english_overlap(candidate: dict[str, str], legacy: dict | None) -> int:
    if not legacy:
        return 0
    return len(
        _gloss_tokens(str(legacy.get("english", ""))) & _gloss_tokens(candidate["english"])
    )


def dictionary_entry_ranks(
    candidates: list[dict[str, str]],
    legacy: dict | None,
    preferred_reading: str | None = None,
    preferred_traditional: str | None = None,
) -> list[tuple[int, ...]]:
    """Sort keys for CC-CEDICT homographs of one headword; lower is better.

    CC-CEDICT lists capitalised proper-noun readings (``Quan2`` "surname Quan")
    before the everyday lowercase reading (``quan2`` "authority"), so the first
    entry is frequently a surname. Ordering, most significant first:

    0. a curated ``PREFERRED_READINGS`` reading and ``PREFERRED_TRADITIONAL``
       form, when given, win outright;
    1. surname-only entries never beat a lexical sense;
    2. bare cross-references ("variant of", "see", "used in") lose to real senses;
    3. the legacy reading must match ignoring tones (polyphone selection);
    4. an exact tone match wins (``ba5`` particle over ``ba1`` "bar"), unless it
       leaves a syllable toneless and shares no English with the legacy gloss
       while another reading does (``guò qu`` "go over" is ``guo4 qu4``);
    5. common words beat capitalised proper nouns (``quan2`` over ``Quan2``);
    6. entries whose first gloss is not "variant of" (``升`` over ``昇``);
    7. more English shared with the legacy gloss (``鐘`` clock over ``鍾`` cup);
    8. CC-CEDICT order, which keeps the first traditional form.

    Proper nouns stay selectable when they are the only appropriate option.
    """
    legacy_pinyin = str(legacy.get("pinyin", "")) if legacy else ""
    readings = [_reading_match(candidate, legacy_pinyin) for candidate in candidates]
    overlaps = [_english_overlap(candidate, legacy) for candidate in candidates]
    lexical_overlap = max(
        (
            overlap
            for candidate, reading, overlap in zip(candidates, readings, overlaps)
            if reading <= 1
            and not is_surname_only_entry(candidate)
            and not is_variant_only_entry(candidate)
        ),
        default=0,
    )
    ranks = []
    for index, (candidate, reading, overlap) in enumerate(
        zip(candidates, readings, overlaps)
    ):
        tone_exact = reading == 0 and (
            overlap > 0
            or lexical_overlap == 0
            or not _has_neutral_syllable(legacy_pinyin, candidate)
        )
        ranks.append(
            (
                int(
                    preferred_reading is not None
                    and candidate["pinyin"] != preferred_reading
                ),
                int(
                    preferred_traditional is not None
                    and candidate["traditional"] != preferred_traditional
                ),
                int(is_surname_only_entry(candidate)),
                int(is_variant_only_entry(candidate)),
                int(reading == 2),
                int(not tone_exact),
                int(is_proper_entry(candidate)),
                int(_primary_gloss_is_variant(candidate)),
                -overlap,
                index,
            )
        )
    return ranks


def _preferred_reading(
    source_word: str,
    base_word: str,
    level: str | None = None,
    frequency: int | None = None,
) -> str | None:
    positional = POSITIONAL_READINGS.get((level, frequency))
    if positional:
        return positional
    return PREFERRED_READINGS.get(source_word, PREFERRED_READINGS.get(base_word))


def _pick_dictionary_entry(
    candidates: list[dict[str, str]],
    legacy: dict | None,
    preferred_reading: str | None = None,
    preferred_traditional: str | None = None,
) -> dict[str, str] | None:
    if not candidates:
        return None
    ranks = dictionary_entry_ranks(
        candidates, legacy, preferred_reading, preferred_traditional
    )
    return candidates[min(range(len(candidates)), key=ranks.__getitem__)]


def _previous_pick_dictionary_entry(
    candidates: list[dict[str, str]], legacy: dict | None
) -> dict[str, str] | None:
    """Pre-2026-10 selection (first toneless match, else first entry); audit only."""
    if not candidates:
        return None
    if legacy:
        legacy_reading = normalize_pinyin(str(legacy.get("pinyin", "")))
        for candidate in candidates:
            if normalize_pinyin(candidate["pinyin"]) == legacy_reading:
                return candidate
    return candidates[0]


def _load_source_words() -> dict[str, list[str]]:
    result = {}
    for level, filename in LEVEL_FILES.items():
        path = SOURCE_DIR / filename
        with path.open(encoding="utf-8-sig") as source:
            words = [line.strip() for line in source if line.strip()]
        if len(words) != EXPECTED_COUNTS[level]:
            raise ValueError(
                f"{filename} contains {len(words)} entries; "
                f"expected {EXPECTED_COUNTS[level]}."
            )
        result[level] = words
    return result


def parse_row_key(
    key: str, source_words: dict[str, list[str]], label: str
) -> tuple[str, int]:
    """Validate a "LEVEL|frequency" key against the pinned source lists."""
    match = ROW_KEY.fullmatch(key) if isinstance(key, str) else None
    if not match:
        raise ValueError(f"{label}: invalid key {key!r}; expected 'HSK-n|frequency'.")
    level, frequency = match.group(1), int(match.group(2))
    if frequency > len(source_words.get(level, [])):
        raise ValueError(f"{label}: {key} is outside {level}.")
    return level, frequency


def load_sense_overrides(
    path: Path | None = None,
    source_words: dict[str, list[str]] | None = None,
) -> dict[tuple[str, int], dict[str, str]]:
    path = SENSE_OVERRIDES_PATH if path is None else path
    if not path.is_file():
        return {}
    with path.open(encoding="utf-8") as source:
        raw = json.load(source)
    if not isinstance(raw, dict):
        raise ValueError(f"{path.name} must contain a JSON object.")
    source_words = _load_source_words() if source_words is None else source_words
    overrides = {}
    for key, value in raw.items():
        level, frequency = parse_row_key(key, source_words, path.name)
        words = source_words[level]
        if not isinstance(value, dict) or set(value) - SENSE_OVERRIDE_FIELDS:
            raise ValueError(
                f"{path.name}: {key} must be an object with fields "
                f"{sorted(SENSE_OVERRIDE_FIELDS)}."
            )
        if value.get("sourceWord") != words[frequency - 1]:
            raise ValueError(
                f"{path.name}: {key} sourceWord {value.get('sourceWord')!r} "
                f"does not match {words[frequency - 1]!r}."
            )
        fields = {name: text for name, text in value.items() if name != "sourceWord"}
        if not fields or any(not isinstance(text, str) for text in fields.values()):
            raise ValueError(f"{path.name}: {key} needs string override fields.")
        if "polish" in fields and not fields["polish"].strip():
            raise ValueError(f"{path.name}: {key} has an empty Polish override.")
        overrides[(level, frequency)] = fields
    return overrides


def _reading_legacy_entry(
    candidates: list[dict], dictionary_entry: dict[str, str] | None, fallback: dict | None
) -> dict | None:
    """Prefer the legacy row whose tone-exact reading matches the chosen entry."""
    if dictionary_entry is None:
        return fallback
    for candidate in candidates:
        if _reading_match(dictionary_entry, str(candidate.get("pinyin", ""))) == 0:
            return candidate
    return fallback


def build_datasets(
    dictionary_path: Path | None,
    sense_overrides_path: Path | None = None,
    *,
    apply_sense_overrides: bool = True,
) -> dict[str, list[dict]]:
    """Build rows from source lists, CC-CEDICT and legacy data only.

    This raw build does not apply the reviewed translation shards or metadata
    completions; use build_final_datasets for publishable data.
    """
    cedict = load_cedict(_ensure_cedict(dictionary_path))
    legacy = load_legacy_words()
    all_source_words = _load_source_words()
    overrides = (
        load_sense_overrides(sense_overrides_path, all_source_words)
        if apply_sense_overrides
        else {}
    )
    datasets = {}

    for level, source_words in all_source_words.items():
        base_words = [re.sub(r"\d+$", "", source_word) for source_word in source_words]
        base_word_counts = Counter(base_words)
        duplicate_bases = {
            word for word, count in base_word_counts.items() if count > 1
        }
        output = []

        for frequency, (source_word, base_word) in enumerate(
            zip(source_words, base_words, strict=True), start=1
        ):
            dictionary_entries = cedict.get(base_word, [])
            legacy_entry = _pick_legacy_entry(legacy.get(base_word, []), dictionary_entries)
            dictionary_entry = _pick_dictionary_entry(
                dictionary_entries,
                legacy_entry,
                _preferred_reading(source_word, base_word, level, frequency),
                PREFERRED_TRADITIONAL.get(base_word),
            )
            if (level, frequency) in POSITIONAL_READINGS:
                legacy_entry = _reading_legacy_entry(
                    legacy.get(base_word, []), dictionary_entry, legacy_entry
                )
            display_key = (
                f"{base_word}#{frequency}"
                if base_word in duplicate_bases
                else source_word
            )

            traditional = (
                dictionary_entry["traditional"]
                if dictionary_entry
                else str(legacy_entry.get("traditional", base_word)) if legacy_entry else base_word
            )
            pinyin = (
                pinyin_with_tones(dictionary_entry["pinyin"])
                if dictionary_entry
                else str(legacy_entry.get("pinyin", "")) if legacy_entry else ""
            )
            english = (
                resolve_reference_english(dictionary_entry, cedict)
                if dictionary_entry
                else str(legacy_entry.get("english", "")) if legacy_entry else ""
            )
            english = CURATED_ENGLISH.get(source_word, english)
            polish = (
                str(legacy_entry.get("polish", "")).strip() if legacy_entry else ""
            )
            notes = str(legacy_entry.get("notes", "")) if legacy_entry else ""
            override = overrides.get((level, frequency), {})
            pinyin = override.get("pinyin", pinyin)
            english = override.get("english", english)
            polish = override.get("polish", polish).strip()
            notes = override.get("notes", notes)
            output.append(
                {
                    "hanzi": display_key,
                    "traditional": traditional,
                    "pinyin": pinyin,
                    "english": english,
                    "polish": polish,
                    "level": level,
                    "notes": notes,
                    "tags": list(legacy_entry.get("tags", [])) if legacy_entry else [],
                    "partOfSpeech": legacy_entry.get("partOfSpeech") if legacy_entry else None,
                    "frequency": frequency,
                    "sourceWord": source_word,
                    "sourceEdition": "HSK 2025",
                }
            )
        datasets[level] = output
    return datasets


def _load_json_object(path: Path) -> dict:
    with path.open(encoding="utf-8") as source:
        data = json.load(source)
    if not isinstance(data, dict):
        raise ValueError(f"{path.name} must contain a JSON object.")
    return data


def _nonblank_text(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def load_translation_shards(
    source_words: dict[str, list[str]],
    shard_dir: Path = DATA_DIR,
    shard_ranges: tuple[tuple[int, int], ...] = TRANSLATION_SHARDS,
) -> dict[tuple[str, int], dict[str, str]]:
    """Load every reviewed Polish shard, validated against source row identities.

    Shards must exist, hold exactly their slice size, use only known fields with
    non-blank text, and list valid source keys in strictly increasing source order
    across all shards (so keys are unique and slices cannot overlap).
    """
    level_order = {level: index for index, level in enumerate(LEVEL_FILES)}
    translations: dict[tuple[str, int], dict[str, str]] = {}
    previous: tuple[int, int] | None = None
    for start, end in shard_ranges:
        path = shard_dir / f"hsk2025_polish_{start:04d}_{end:04d}.json"
        if not path.is_file():
            raise FileNotFoundError(f"Missing translation shard: {path.name}")
        shard = _load_json_object(path)
        if len(shard) != end - start + 1:
            raise ValueError(
                f"{path.name} has {len(shard)} entries; expected {end - start + 1}."
            )
        for key, value in shard.items():
            level, frequency = parse_row_key(key, source_words, path.name)
            position = (level_order[level], frequency)
            if previous is not None and position <= previous:
                raise ValueError(f"{path.name}: {key} is duplicated or out of source order.")
            previous = position
            if not isinstance(value, dict):
                raise ValueError(f"{path.name}: {key} must map to an object.")
            unknown = set(value) - TRANSLATION_SHARD_FIELDS
            if unknown:
                raise ValueError(f"{path.name}: {key} has unknown fields {sorted(unknown)}.")
            if not _nonblank_text(value.get("polish")):
                raise ValueError(f"{path.name}: {key} has no Polish translation.")
            for field, text in value.items():
                if not _nonblank_text(text):
                    raise ValueError(f"{path.name}: {key} has an empty {field}.")
            translations[(level, frequency)] = {
                field: text.strip() for field, text in value.items()
            }
    return translations


def load_metadata_completions(
    source_words: dict[str, list[str]], path: Path = METADATA_COMPLETIONS_PATH
) -> dict[tuple[str, int], dict[str, str]]:
    """Load reviewed pinyin/English completions keyed by source row."""
    if not path.is_file():
        raise FileNotFoundError(f"Missing metadata completion file: {path.name}")
    completions = {}
    for key, value in _load_json_object(path).items():
        row = parse_row_key(key, source_words, path.name)
        if not isinstance(value, dict) or not value:
            raise ValueError(f"{path.name}: {key} must map to a non-empty object.")
        unknown = set(value) - METADATA_COMPLETION_FIELDS
        if unknown:
            raise ValueError(f"{path.name}: {key} has unknown fields {sorted(unknown)}.")
        if any(not _nonblank_text(text) for text in value.values()):
            raise ValueError(f"{path.name}: {key} contains an empty field.")
        completions[row] = {field: text.strip() for field, text in value.items()}
    return completions


def apply_reviewed_sources(
    raw_datasets: dict[str, list[dict]],
    translations: dict[tuple[str, int], dict[str, str]],
    completions: dict[tuple[str, int], dict[str, str]],
    overrides: dict[tuple[str, int], dict[str, str]],
) -> tuple[dict[str, list[dict]], dict]:
    """Layer reviewed data over a raw build without mutating it.

    Order: translation shards replace Polish (and any English/pinyin they carry)
    and append review notes; metadata completions fill only fields that are still
    blank; explicit sense overrides are applied last and always win.
    """
    datasets = {
        level: [dict(row, tags=list(row.get("tags", []))) for row in rows]
        for level, rows in raw_datasets.items()
    }
    index = {
        (row["level"], row["frequency"]): row
        for rows in datasets.values()
        for row in rows
    }
    for name, layer in (
        ("translation shard", translations),
        ("metadata completion", completions),
        ("sense override", overrides),
    ):
        absent = sorted(set(layer) - set(index))
        if absent:
            raise ValueError(f"{len(absent)} {name} keys are absent from the build: {absent[:5]}")

    for key, translation in translations.items():
        row = index[key]
        row["polish"] = translation["polish"]
        for field in ("english", "pinyin"):
            if field in translation:
                row[field] = translation[field]
        if "review" in translation:
            existing_notes = str(row.get("notes", "")).strip()
            review_note = f"Review: {translation['review']}"
            row["notes"] = f"{existing_notes}; {review_note}" if existing_notes else review_note

    superseded_completions = []
    for key, completion in completions.items():
        row = index[key]
        for field, value in completion.items():
            if str(row.get(field, "")).strip():
                superseded_completions.append(f"{key[0]}|{key[1]}:{field}")
            else:
                row[field] = value

    for key, override in overrides.items():
        row = index[key]
        for field in ("pinyin", "english", "polish", "notes"):
            if field in override:
                row[field] = override[field].strip() if field == "polish" else override[field]

    report = {
        "translationShardRows": len(translations),
        "metadataCompletionRows": len(completions),
        "senseOverrideRows": len(overrides),
        "supersededCompletionFields": sorted(superseded_completions),
    }
    return datasets, report


def validate_final_datasets(
    datasets: dict[str, list[dict]], source_words: dict[str, list[str]]
) -> None:
    """Refuse to publish data with missing rows, wrong identities or blank text."""
    if list(datasets) != list(LEVEL_FILES):
        raise ValueError(f"Expected levels {list(LEVEL_FILES)}; found {list(datasets)}.")
    problems = []
    for level, rows in datasets.items():
        words = source_words[level]
        if len(rows) != len(words):
            problems.append(f"{level} has {len(rows)} rows; expected {len(words)}")
            continue
        if len({row.get("hanzi") for row in rows}) != len(rows):
            problems.append(f"{level} has duplicate hanzi display keys")
        for frequency, (row, source_word) in enumerate(zip(rows, words), start=1):
            key = f"{level}|{frequency}"
            if (row.get("level"), row.get("frequency"), row.get("sourceWord")) != (
                level,
                frequency,
                source_word,
            ):
                problems.append(f"{key} does not match source word {source_word!r}")
            for field in REQUIRED_TEXT_FIELDS:
                if not _nonblank_text(row.get(field)):
                    problems.append(f"{key} has blank {field}")
    if problems:
        raise ValueError(
            f"{len(problems)} final dataset problems; first: {'; '.join(problems[:10])}"
        )


def build_final_datasets(
    dictionary_path: Path | None,
    *,
    shard_dir: Path = DATA_DIR,
    metadata_completions_path: Path = METADATA_COMPLETIONS_PATH,
    sense_overrides_path: Path | None = None,
) -> tuple[dict[str, list[dict]], dict]:
    """Build publishable datasets entirely from pinned and reviewed sources.

    Never reads the generated hsk2025_*_words.json files, so rebuilding is
    idempotent and cannot silently keep stale generated values.
    """
    source_words = _load_source_words()
    translations = load_translation_shards(source_words, shard_dir)
    completions = load_metadata_completions(source_words, metadata_completions_path)
    overrides = load_sense_overrides(sense_overrides_path, source_words)
    raw = build_datasets(dictionary_path, apply_sense_overrides=False)
    datasets, report = apply_reviewed_sources(raw, translations, completions, overrides)
    validate_final_datasets(datasets, source_words)
    return datasets, report


def dataset_path(level: str, output_dir: Path = DATA_DIR) -> Path:
    number = level.removeprefix("HSK-").replace("-", "_")
    return output_dir / f"hsk2025_{number}_words.json"


def serialize_dataset(words: list[dict]) -> str:
    return json.dumps(words, ensure_ascii=False, indent=2) + "\n"


class RollbackError(OSError):
    """A failed batch write could not be fully rolled back.

    ``retained_backups`` maps each target whose previous content could not be
    restored to the backup file holding that content; those files are kept.
    """

    def __init__(self, message: str, retained_backups: dict[Path, Path]):
        super().__init__(message)
        self.retained_backups = retained_backups


def _staged_file(path: Path, kind: str) -> Path:
    handle, name = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.", suffix=f".{kind}")
    os.close(handle)
    return Path(name)


def replace_files_transactionally(contents: dict[Path, str]) -> None:
    """Replace a batch of files with best-effort all-or-nothing semantics.

    New content and a backup copy of every existing target are staged next to
    each target before anything is replaced; each target is then swapped in with
    os.replace. If any step fails, targets already replaced are restored from
    their backups (or removed if they did not exist) and the original error is
    raised. If restoring fails, RollbackError is raised and the backups needed
    for manual recovery are kept. This is not crash-atomic across files: a
    process or OS crash mid-batch can still leave a mix of old and new files,
    with recovery backups left beside them.
    """
    staged: list[tuple[Path, Path, Path | None]] = []
    replaced: list[tuple[Path, Path | None]] = []
    retained: dict[Path, Path] = {}
    try:
        for path, content in contents.items():
            new_file = _staged_file(path, "tmp")
            backup = None
            staged.append((path, new_file, None))
            new_file.write_text(content, encoding="utf-8", newline="")
            if path.exists():
                backup = _staged_file(path, "bak")
                staged[-1] = (path, new_file, backup)
                shutil.copy2(path, backup)
        for path, new_file, backup in staged:
            os.replace(new_file, path)
            replaced.append((path, backup))
    except BaseException as error:
        failures = []
        for path, backup in reversed(replaced):
            try:
                if backup is None:
                    path.unlink(missing_ok=True)
                else:
                    os.replace(backup, path)
            except OSError as restore_error:
                failures.append(f"{path.name}: {restore_error}")
                if backup is not None:
                    retained[path] = backup
        if failures:
            recovery = ", ".join(f"{path} <- {backup}" for path, backup in retained.items())
            raise RollbackError(
                f"Write failed ({error}) and rollback failed for {len(failures)} file(s): "
                f"{'; '.join(failures)}. Recover previous content from: {recovery or 'none'}",
                retained,
            ) from error
        raise
    finally:
        for _, new_file, backup in staged:
            new_file.unlink(missing_ok=True)
            if backup is not None and backup not in retained.values():
                backup.unlink(missing_ok=True)


def write_datasets(
    datasets: dict[str, list[dict]],
    output_dir: Path = DATA_DIR,
    source_words: dict[str, list[str]] | None = None,
) -> None:
    """Validate the complete datasets, then replace all level files as one batch."""
    validate_final_datasets(
        datasets, _load_source_words() if source_words is None else source_words
    )
    replace_files_transactionally(
        {dataset_path(level, output_dir): serialize_dataset(words) for level, words in datasets.items()}
    )


def write_outputs(
    datasets: dict[str, list[dict]],
    output_dir: Path = DATA_DIR,
    worklist_path: Path | None = None,
    source_words: dict[str, list[str]] | None = None,
) -> int:
    """Validate, then replace all level files and the worklist as one batch."""
    validate_final_datasets(
        datasets, _load_source_words() if source_words is None else source_words
    )
    worklist, missing = render_worklist(datasets)
    contents = {
        dataset_path(level, output_dir): serialize_dataset(words)
        for level, words in datasets.items()
    }
    contents[worklist_path or output_dir / "polish_translation_worklist.csv"] = worklist
    replace_files_transactionally(contents)
    return missing


WORKLIST_FIELDS = [
    "level",
    "frequency",
    "hanzi",
    "sourceWord",
    "traditional",
    "pinyin",
    "english",
    "polish",
    "needs_pinyin",
    "needs_english",
]


def render_worklist(datasets: dict[str, list[dict]]) -> tuple[str, int]:
    missing = [
        word
        for words in datasets.values()
        for word in words
        if not str(word.get("polish", "")).strip()
    ]
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=WORKLIST_FIELDS)
    writer.writeheader()
    for word in missing:
        writer.writerow(
            {
                **{field: word.get(field, "") for field in WORKLIST_FIELDS[:8]},
                "needs_pinyin": "yes" if not word["pinyin"] else "no",
                "needs_english": "yes" if not word["english"] else "no",
            }
        )
    return "\ufeff" + output.getvalue(), len(missing)


def write_worklist(datasets: dict[str, list[dict]], output_path: Path) -> int:
    content, missing = render_worklist(datasets)
    replace_files_transactionally({output_path: content})
    return missing


def compare_with_current(
    datasets: dict[str, list[dict]], output_dir: Path = DATA_DIR
) -> dict:
    """Read-only diff of a final build against the generated files on disk."""
    differences = []
    for level, words in datasets.items():
        path = dataset_path(level, output_dir)
        current = json.loads(path.read_text(encoding="utf-8")) if path.is_file() else []
        current_rows = {row.get("frequency"): row for row in current if isinstance(row, dict)}
        for row in words:
            existing = current_rows.get(row["frequency"], {})
            changed = {
                field: {"current": existing.get(field), "built": row[field]}
                for field in row
                if existing.get(field) != row[field]
            }
            if changed:
                differences.append(
                    {
                        "key": f"{level}|{row['frequency']}",
                        "sourceWord": row["sourceWord"],
                        "fields": changed,
                    }
                )
        if len(current_rows) != len(words):
            differences.append({"key": level, "rowCount": [len(current_rows), len(words)]})
    field_counts = Counter(
        field for difference in differences for field in difference.get("fields", {})
    )
    return {
        "differingRows": len(differences),
        "fieldCounts": dict(sorted(field_counts.items())),
        "rows": differences,
    }


def _entry_summary(entry: dict[str, str] | None) -> dict | None:
    if not entry:
        return None
    return {
        "traditional": entry["traditional"],
        "cedictPinyin": entry["pinyin"],
        "pinyin": pinyin_with_tones(entry["pinyin"]),
        "english": entry["english"],
        "proper": is_proper_entry(entry),
        "surnameOnly": is_surname_only_entry(entry),
        "variantOnly": is_variant_only_entry(entry),
    }


def _load_current_datasets() -> dict[str, list[dict]]:
    current = {}
    for level in LEVEL_FILES:
        number = level.removeprefix("HSK-").replace("-", "_")
        path = DATA_DIR / f"hsk2025_{number}_words.json"
        current[level] = (
            json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
        )
    return current


def build_sense_candidates(dictionary_path: Path | None) -> dict:
    """Audit every source row for CC-CEDICT homograph selections.

    Read-only: compares the previous first-match selection, the ranked selection
    and the committed JSON so data fixes can be applied by a separate pass.
    """
    resolved_path = _ensure_cedict(dictionary_path)
    cedict = load_cedict(resolved_path)
    legacy = load_legacy_words()
    current = _load_current_datasets()
    rows = []
    proper_only = []
    total = 0

    for level, source_words in _load_source_words().items():
        current_rows = {
            (row.get("frequency"), row.get("sourceWord")): row for row in current[level]
        }
        for frequency, source_word in enumerate(source_words, start=1):
            total += 1
            base_word = re.sub(r"\d+$", "", source_word)
            entries = cedict.get(base_word, [])
            legacy_entry = _pick_legacy_entry(legacy.get(base_word, []), entries)
            previous = _previous_pick_dictionary_entry(entries, legacy_entry)
            candidate = _pick_dictionary_entry(
                entries,
                legacy_entry,
                _preferred_reading(source_word, base_word, level, frequency),
                PREFERRED_TRADITIONAL.get(base_word),
            )
            current_row = current_rows.get((frequency, source_word))
            if entries and all(is_proper_entry(entry) for entry in entries):
                proper_only.append(
                    {
                        "level": level,
                        "frequency": frequency,
                        "sourceWord": source_word,
                        "english": candidate["english"],
                    }
                )

            reasons = []
            if previous is not candidate:
                if is_surname_only_entry(previous):
                    reasons.append("previous_surname_only")
                elif is_proper_entry(previous):
                    reasons.append("previous_proper_noun")
                if is_variant_only_entry(previous):
                    reasons.append("previous_variant_only")
                if pinyin_with_tones(previous["pinyin"]) != pinyin_with_tones(
                    candidate["pinyin"]
                ):
                    reasons.append("tone_or_reading_changed")
                if not reasons:
                    reasons.append("ranking_changed")
            lexical_readings = {
                pinyin_reading_key(pinyin_with_tones(entry["pinyin"]))
                for entry in entries
                if not is_proper_entry(entry)
                and not is_surname_only_entry(entry)
                and not is_variant_only_entry(entry)
            }
            if (
                len(lexical_readings) > 1
                and not (legacy_entry and str(legacy_entry.get("pinyin", "")).strip())
                and _preferred_reading(source_word, base_word, level, frequency) is None
            ):
                reasons.append("ambiguous_polyphone_without_legacy")
            if (level, frequency) in POSITIONAL_READING_ORDER_ASSUMED:
                reasons.append("duplicate_order_assumed")
            current_english = str(current_row.get("english", "")) if current_row else None
            proper_glosses = {
                entry["english"]
                for entry in entries
                if is_proper_entry(entry) or is_surname_only_entry(entry)
            }
            if (
                candidate
                and not is_proper_entry(candidate)
                and current_english in proper_glosses
                and "current_json_proper_gloss" not in reasons
            ):
                reasons.append("current_json_proper_gloss")
            if not reasons:
                continue

            if current_row is None:
                status = "missing_row"
            elif current_english == candidate["english"]:
                status = "already_candidate"
            elif current_english == previous["english"]:
                status = "matches_previous_pick"
            else:
                status = "custom_english"
            rows.append(
                {
                    "level": level,
                    "frequency": frequency,
                    "sourceWord": source_word,
                    "hanzi": current_row.get("hanzi") if current_row else base_word,
                    "legacyPinyin": legacy_entry.get("pinyin") if legacy_entry else None,
                    "reasons": reasons,
                    "currentJsonStatus": status,
                    "current": {
                        "traditional": current_row.get("traditional"),
                        "pinyin": current_row.get("pinyin"),
                        "english": current_english,
                        "polish": current_row.get("polish"),
                    }
                    if current_row
                    else None,
                    "previousPick": _entry_summary(previous),
                    "candidate": _entry_summary(candidate),
                    "alternatives": [_entry_summary(entry) for entry in entries],
                }
            )

    needs_fix = [row for row in rows if row["currentJsonStatus"] != "already_candidate"]
    return {
        "schema": "chinese-learning-app/dictionary-sense-candidates@1",
        "generator": "assets/data/scripts/build_hsk_2025_data.py --sense-candidates",
        "cedictSha256": hashlib.sha256(resolved_path.read_bytes()).hexdigest(),
        "sourceRows": total,
        "summary": {
            "flaggedRows": len(rows),
            "needsJsonFix": len(needs_fix),
            "byReason": dict(
                sorted(Counter(reason for row in rows for reason in row["reasons"]).items())
            ),
            "byCurrentJsonStatus": dict(
                sorted(Counter(row["currentJsonStatus"] for row in rows).items())
            ),
            "properOnlyRowsRetained": len(proper_only),
        },
        "rows": rows,
        "properOnlyRowsRetained": proper_only,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cedict",
        type=Path,
        help="Path to a CC-CEDICT cedict_ts.u8 file; downloaded to the temp directory if omitted.",
    )
    parser.add_argument(
        "--sense-candidates",
        type=Path,
        help="Write a read-only homograph audit JSON to this path instead of rebuilding data.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Build the final datasets in memory and report differences from the "
        "generated files without writing anything; exits 1 if they differ.",
    )
    parser.add_argument(
        "--check-report",
        type=Path,
        help="With --check, also write the full difference report JSON to this path.",
    )
    args = parser.parse_args()

    if args.sense_candidates:
        report = build_sense_candidates(args.cedict)
        args.sense_candidates.parent.mkdir(parents=True, exist_ok=True)
        args.sense_candidates.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print(json.dumps(report["summary"], ensure_ascii=False))
        print(f"Sense candidates -> {args.sense_candidates}")
        return

    datasets, report = build_final_datasets(args.cedict)
    if args.check:
        comparison = compare_with_current(datasets)
        if args.check_report:
            args.check_report.parent.mkdir(parents=True, exist_ok=True)
            args.check_report.write_text(
                json.dumps({**report, **comparison}, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        print(
            json.dumps(
                {
                    "differingRows": comparison["differingRows"],
                    "fieldCounts": comparison["fieldCounts"],
                    "supersededCompletionFields": len(report["supersededCompletionFields"]),
                },
                ensure_ascii=False,
            )
        )
        raise SystemExit(1 if comparison["differingRows"] else 0)

    worklist_path = DATA_DIR / "polish_translation_worklist.csv"
    missing = write_outputs(datasets, worklist_path=worklist_path)
    for level, words in datasets.items():
        print(f"{level}: {len(words)} words")
    print(f"Total: {sum(map(len, datasets.values()))} words")
    print(
        f"Applied {report['translationShardRows']} shard rows, "
        f"{report['metadataCompletionRows']} metadata completions, "
        f"{report['senseOverrideRows']} sense overrides."
    )
    print(f"Polish worklist: {missing} words -> {worklist_path}")


if __name__ == "__main__":
    main()
