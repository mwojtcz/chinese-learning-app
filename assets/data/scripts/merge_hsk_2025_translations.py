#!/usr/bin/env python3
"""Validate and merge all reviewed HSK 2025 Polish translation shards."""

import csv
import json
import os
import tempfile
from pathlib import Path

from build_hsk_2025_data import DATA_DIR, LEVEL_FILES, write_worklist


WORKLIST_PATH = DATA_DIR / "polish_translation_worklist.csv"
METADATA_PATH = DATA_DIR / "hsk2025_metadata_completions.json"
EXPECTED_SHARDS = [
    (1, 400),
    (401, 800),
    (801, 1200),
    (1201, 1600),
    (1601, 2000),
    (2001, 2400),
    (2401, 2800),
    (2801, 3200),
    (3201, 3600),
    (3601, 4000),
    (4001, 4400),
    (4401, 4800),
    (4801, 5200),
    (5201, 5600),
    (5601, 6000),
    (6001, 6400),
    (6401, 6800),
    (6801, 7200),
    (7201, 7600),
    (7601, 8000),
    (8001, 8280),
]


def _row_key(row: dict[str, str]) -> str:
    return f"{row['level']}|{row['frequency']}"


def _read_worklist() -> list[dict[str, str]]:
    with WORKLIST_PATH.open(encoding="utf-8-sig", newline="") as source:
        return list(csv.DictReader(source))


def _load_shards(
    rows: list[dict[str, str]],
) -> dict[str, dict[str, str]]:
    if len(rows) != 8280:
        raise ValueError(
            f"Expected the original 8,280-row worklist; found {len(rows)}. "
            "Rebuild source data before merging, or all translations may already be merged."
        )

    merged: dict[str, dict[str, str]] = {}
    for start, end in EXPECTED_SHARDS:
        shard_path = DATA_DIR / f"hsk2025_polish_{start:04d}_{end:04d}.json"
        if not shard_path.is_file():
            raise FileNotFoundError(f"Missing translation shard: {shard_path.name}")
        with shard_path.open(encoding="utf-8") as source:
            shard = json.load(source)
        if not isinstance(shard, dict):
            raise ValueError(f"{shard_path.name} must contain a JSON object.")

        assigned_rows = rows[start - 1 : end]
        expected_keys = {_row_key(row) for row in assigned_rows}
        actual_keys = set(shard)
        if actual_keys != expected_keys:
            missing = sorted(expected_keys - actual_keys)
            unexpected = sorted(actual_keys - expected_keys)
            raise ValueError(
                f"{shard_path.name} has an invalid key set: "
                f"{len(missing)} missing, {len(unexpected)} unexpected."
            )

        for key, value in shard.items():
            if not isinstance(value, dict):
                raise ValueError(f"{shard_path.name}: {key} must map to an object.")
            polish = value.get("polish")
            if not isinstance(polish, str) or not polish.strip():
                raise ValueError(f"{shard_path.name}: {key} has no Polish translation.")
            for field in ("english", "pinyin"):
                if field in value and (
                    not isinstance(value[field], str) or not value[field].strip()
                ):
                    raise ValueError(f"{shard_path.name}: {key} has an empty {field}.")
            if "review" in value and (
                not isinstance(value["review"], str) or not value["review"].strip()
            ):
                raise ValueError(f"{shard_path.name}: {key} has an empty review note.")
            if key in merged:
                raise ValueError(f"Duplicate translation for {key}.")
            merged[key] = value

    if len(merged) != len(rows):
        raise ValueError(f"Expected {len(rows)} unique translations; found {len(merged)}.")
    return merged


def _load_metadata_completions(
    rows: list[dict[str, str]],
) -> dict[str, dict[str, str]]:
    expected = {
        _row_key(row): {
            field
            for field in ("pinyin", "english")
            if row[f"needs_{field}"] == "yes"
        }
        for row in rows
        if row["needs_pinyin"] == "yes" or row["needs_english"] == "yes"
    }
    if not expected:
        return {}
    if not METADATA_PATH.is_file():
        raise FileNotFoundError(f"Missing metadata completion file: {METADATA_PATH.name}")
    with METADATA_PATH.open(encoding="utf-8") as source:
        completions = json.load(source)
    if not isinstance(completions, dict):
        raise ValueError(f"{METADATA_PATH.name} must contain a JSON object.")
    if set(completions) != set(expected):
        missing = sorted(set(expected) - set(completions))
        unexpected = sorted(set(completions) - set(expected))
        raise ValueError(
            f"{METADATA_PATH.name} has an invalid key set: "
            f"{len(missing)} missing, {len(unexpected)} unexpected."
        )
    for key, fields in expected.items():
        value = completions[key]
        if not isinstance(value, dict):
            raise ValueError(f"{METADATA_PATH.name}: {key} must map to an object.")
        if set(value) != fields:
            raise ValueError(
                f"{METADATA_PATH.name}: {key} must contain exactly "
                f"{', '.join(sorted(fields))}."
            )
        if any(not isinstance(value[field], str) or not value[field].strip() for field in fields):
            raise ValueError(f"{METADATA_PATH.name}: {key} contains an empty field.")
    return completions


def _load_datasets() -> dict[str, list[dict]]:
    datasets = {}
    for level in LEVEL_FILES:
        number = level.removeprefix("HSK-").replace("-", "_")
        path = DATA_DIR / f"hsk2025_{number}_words.json"
        with path.open(encoding="utf-8") as source:
            data = json.load(source)
        if not isinstance(data, list):
            raise ValueError(f"{path.name} must contain a JSON list.")
        keys = [
            f"{word.get('level')}|{word.get('frequency')}"
            for word in data
            if isinstance(word, dict)
        ]
        if len(keys) != len(data) or len(keys) != len(set(keys)):
            raise ValueError(f"{path.name} contains invalid or duplicate word keys.")
        datasets[level] = data
    return datasets


def _write_atomic(path: Path, content: str) -> Path:
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        newline="",
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
        delete=False,
    ) as target:
        target.write(content)
        return Path(target.name)


def merge() -> int:
    rows = _read_worklist()
    if not rows:
        print("No untranslated Polish entries remain.")
        return 0
    translations = _load_shards(rows)
    metadata_completions = _load_metadata_completions(rows)
    datasets = _load_datasets()
    indexed_words = {
        f"{word['level']}|{word['frequency']}": word
        for words in datasets.values()
        for word in words
    }
    if not translations.keys() <= indexed_words.keys():
        raise ValueError("Translation shard contains words absent from the HSK datasets.")

    metadata_gaps: list[str] = []
    for key, translation in translations.items():
        word = indexed_words[key]
        word["polish"] = translation["polish"].strip()
        for field in ("english", "pinyin"):
            if field in translation:
                word[field] = translation[field].strip()
        if "review" in translation:
            existing_notes = str(word.get("notes", "")).strip()
            review_note = f"Review: {translation['review'].strip()}"
            word["notes"] = (
                f"{existing_notes}; {review_note}"
                if existing_notes
                else review_note
            )
    for key, completion in metadata_completions.items():
        word = indexed_words[key]
        for field, value in completion.items():
            current_value = str(word.get(field, "")).strip()
            if not current_value:
                word[field] = value.strip()

    for key, word in indexed_words.items():
        if not str(word.get("pinyin", "")).strip() or not str(
            word.get("english", "")
        ).strip():
            metadata_gaps.append(key)
    if metadata_gaps:
        raise ValueError(
            f"{len(metadata_gaps)} translated entries still lack pinyin or English; "
            f"first keys: {', '.join(metadata_gaps[:10])}"
        )
    remaining_polish = [
        f"{word['level']}|{word['frequency']}"
        for words in datasets.values()
        for word in words
        if not str(word.get("polish", "")).strip()
    ]
    if remaining_polish:
        raise ValueError(
            f"{len(remaining_polish)} Polish translations remain; "
            f"first keys: {', '.join(remaining_polish[:10])}"
        )

    temporary_files: list[tuple[Path, Path]] = []
    try:
        for level, words in datasets.items():
            number = level.removeprefix("HSK-").replace("-", "_")
            path = DATA_DIR / f"hsk2025_{number}_words.json"
            content = json.dumps(words, ensure_ascii=False, indent=2) + "\n"
            temporary_files.append((path, _write_atomic(path, content)))
        for path, temporary_path in temporary_files:
            os.replace(temporary_path, path)
    finally:
        for _, temporary_path in temporary_files:
            temporary_path.unlink(missing_ok=True)

    missing = write_worklist(datasets, WORKLIST_PATH)
    if missing:
        raise ValueError(f"{missing} Polish translations remain after merge.")
    print(f"Merged {len(translations)} Polish translations into seven HSK 2025 datasets.")
    return len(translations)


if __name__ == "__main__":
    merge()
