#!/usr/bin/env python3
"""Build the HSK 2025 app datasets from pinned, attributed source lists."""

import argparse
import csv
import json
import re
import tempfile
import unicodedata
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent.parent
SOURCE_DIR = DATA_DIR / "sources" / "hsk-2025"
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
                        gloss.strip() for gloss in glosses.split("/") if gloss.strip()
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
    dictionary_readings = {normalize_pinyin(entry["pinyin"]) for entry in dictionary_entries}
    return next(
        (
            candidate
            for candidate in candidates
            if normalize_pinyin(str(candidate.get("pinyin", ""))) in dictionary_readings
        ),
        candidates[0] if len(candidates) == 1 else None,
    )


def _pick_dictionary_entry(
    candidates: list[dict[str, str]], legacy: dict | None
) -> dict[str, str] | None:
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


def build_datasets(dictionary_path: Path | None) -> dict[str, list[dict]]:
    cedict = load_cedict(_ensure_cedict(dictionary_path))
    legacy = load_legacy_words()
    datasets = {}

    for level, source_words in _load_source_words().items():
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
            dictionary_entry = _pick_dictionary_entry(dictionary_entries, legacy_entry)
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
                dictionary_entry["english"]
                if dictionary_entry
                else str(legacy_entry.get("english", "")) if legacy_entry else ""
            )
            polish = (
                str(legacy_entry.get("polish", "")).strip() if legacy_entry else ""
            )
            notes = str(legacy_entry.get("notes", "")) if legacy_entry else ""
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


def write_datasets(datasets: dict[str, list[dict]]) -> None:
    for level, words in datasets.items():
        number = level.removeprefix("HSK-").replace("-", "_")
        path = DATA_DIR / f"hsk2025_{number}_words.json"
        path.write_text(
            json.dumps(words, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )


def write_worklist(datasets: dict[str, list[dict]], output_path: Path) -> int:
    fields = [
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
    missing = [
        word
        for words in datasets.values()
        for word in words
        if not str(word.get("polish", "")).strip()
    ]
    with output_path.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for word in missing:
            writer.writerow(
                {
                    **{field: word.get(field, "") for field in fields[:8]},
                    "needs_pinyin": "yes" if not word["pinyin"] else "no",
                    "needs_english": "yes" if not word["english"] else "no",
                }
            )
    return len(missing)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cedict",
        type=Path,
        help="Path to a CC-CEDICT cedict_ts.u8 file; downloaded to the temp directory if omitted.",
    )
    args = parser.parse_args()

    datasets = build_datasets(args.cedict)
    write_datasets(datasets)
    worklist_path = DATA_DIR / "polish_translation_worklist.csv"
    missing = write_worklist(datasets, worklist_path)
    for level, words in datasets.items():
        missing_level = sum(not str(word["polish"]).strip() for word in words)
        missing_readings = sum(not word["pinyin"] or not word["english"] for word in words)
        print(
            f"{level}: {len(words)} words, {missing_level} missing Polish, "
            f"{missing_readings} missing pinyin/English"
        )
    print(f"Total: {sum(map(len, datasets.values()))} words")
    print(f"Polish worklist: {missing} words -> {worklist_path}")


if __name__ == "__main__":
    main()
