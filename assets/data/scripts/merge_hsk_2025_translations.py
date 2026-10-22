#!/usr/bin/env python3
"""Validate and merge all reviewed HSK 2025 Polish translation shards.

The merge is a full, source-backed rebuild: it never patches the generated
hsk2025_*_words.json files in place and never depends on the mutable
polish_translation_worklist.csv membership. Every shard key, the metadata
completions and the sense overrides are validated against the pinned source
lists. Only once the complete result has no blank pinyin, English or Polish are
the seven datasets and the worklist replaced as one batch, with best-effort
rollback if any replacement fails (not crash-atomic across files).
"""

import argparse
from pathlib import Path

from build_hsk_2025_data import (
    DATA_DIR,
    METADATA_COMPLETIONS_PATH,
    TRANSLATION_SHARDS,
    build_final_datasets,
    write_outputs,
)


WORKLIST_PATH = DATA_DIR / "polish_translation_worklist.csv"
METADATA_PATH = METADATA_COMPLETIONS_PATH
EXPECTED_SHARDS = list(TRANSLATION_SHARDS)


def merge(dictionary_path: Path | None = None) -> int:
    datasets, report = build_final_datasets(dictionary_path)
    missing = write_outputs(datasets, worklist_path=WORKLIST_PATH)
    if missing:
        raise ValueError(f"{missing} Polish translations remain after merge.")
    print(
        f"Merged {report['translationShardRows']} Polish translations, "
        f"{report['metadataCompletionRows']} metadata completions and "
        f"{report['senseOverrideRows']} sense overrides into seven HSK 2025 datasets."
    )
    return report["translationShardRows"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cedict",
        type=Path,
        help="Path to a CC-CEDICT cedict_ts.u8 file; downloaded to the temp directory if omitted.",
    )
    merge(parser.parse_args().cedict)
