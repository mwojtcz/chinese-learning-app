#!/usr/bin/env python3
"""Export untranslated HSK entries and safely merge reviewed Polish translation shards."""

import argparse
import csv
import json
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent.parent
SHARDS = {
    "HSK-5": [
        ("hsk5_polish_001_360.json", 1, 360),
        ("hsk5_polish_361_720.json", 361, 720),
        ("hsk5_polish_721_1071.json", 721, 1071),
    ],
    "HSK-6": [
        ("hsk6_polish_001_380.json", 1, 380),
        ("hsk6_polish_381_760.json", 381, 760),
        ("hsk6_polish_761_1140.json", 761, 1140),
    ],
}


def read_words(level: str) -> list[dict]:
    path = DATA_DIR / f"{level.lower().replace('-', '')}_words.json"
    with path.open(encoding="utf-8") as source:
        words = json.load(source)
    if not isinstance(words, list):
        raise ValueError(f"{path.name} must contain a JSON array")
    return words


def missing_words() -> list[dict]:
    missing = []
    for level in SHARDS:
        for word in read_words(level):
            if not str(word.get("polish", "")).strip():
                missing.append(word)
    return missing


def write_worklist(path: Path) -> int:
    words = missing_words()
    fields = ["level", "frequency", "hanzi", "traditional", "pinyin", "english", "polish"]
    with path.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for word in words:
            writer.writerow({field: word.get(field, "") for field in fields})
    return len(words)


def read_translation_shards() -> dict[str, dict[int, str]]:
    result: dict[str, dict[int, str]] = {}
    for level, shards in SHARDS.items():
        translations: dict[int, str] = {}
        expected = set()
        for filename, start, end in shards:
            expected.update(range(start, end + 1))
            path = DATA_DIR / filename
            if not path.exists():
                raise FileNotFoundError(f"Translation worker file is missing: {filename}")
            with path.open(encoding="utf-8") as source:
                shard = json.load(source)
            if not isinstance(shard, dict):
                raise ValueError(f"{filename} must map frequency numbers to Polish strings")
            shard_translations = {}
            for key, value in shard.items():
                try:
                    frequency = int(key)
                except ValueError as error:
                    raise ValueError(f"{filename} has a non-numeric frequency: {key}") from error
                if not isinstance(value, str) or not value.strip():
                    raise ValueError(f"{filename} has an empty translation for {frequency}")
                if frequency < start or frequency > end:
                    raise ValueError(f"{filename} contains out-of-range frequency {frequency}")
                if frequency in translations:
                    raise ValueError(f"{level} has duplicate translation for frequency {frequency}")
                shard_translations[frequency] = value.strip()
            if set(shard_translations) != set(range(start, end + 1)):
                missing = sorted(set(range(start, end + 1)) - set(shard_translations))
                raise ValueError(f"{filename} misses frequencies: {missing[:10]}")
            translations.update(shard_translations)

        words = read_words(level)
        word_frequencies = {word.get("frequency") for word in words}
        if word_frequencies != expected:
            raise ValueError(f"{level} source frequencies do not match the translation plan")
        result[level] = translations
    return result


def merge(translations: dict[str, dict[int, str]]) -> None:
    updates = {}
    for level, mapping in translations.items():
        words = read_words(level)
        for word in words:
            frequency = word.get("frequency")
            word["polish"] = mapping[frequency]
        updates[DATA_DIR / f"{level.lower().replace('-', '')}_words.json"] = words

    for path, words in updates.items():
        path.write_text(
            json.dumps(words, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--merge",
        action="store_true",
        help="Merge all complete worker translation files into the HSK5/6 source JSON.",
    )
    parser.add_argument(
        "--worklist",
        type=Path,
        default=DATA_DIR / "polish_translation_worklist_hsk2021.csv",
        help="Legacy HSK 2021 CSV output path (kept separate from the HSK 2025 worklist).",
    )
    args = parser.parse_args()

    count = write_worklist(args.worklist)
    print(f"Worklist: {count} untranslated HSK-5/6 entries -> {args.worklist}")
    if args.merge:
        translations = read_translation_shards()
        merge(translations)
        remaining = missing_words()
        if remaining:
            raise RuntimeError(f"Merge left {len(remaining)} untranslated HSK-5/6 entries")
        print("Merged and verified all HSK-5/6 Polish translations.")


if __name__ == "__main__":
    main()
