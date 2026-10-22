#!/usr/bin/env python3
"""Translate English HSK definitions to Polish using a key supplied at runtime."""

import json
import os
import sys
import time
from pathlib import Path

import deepl


def translate_hsk4_to_polish(input_file: str, output_file: str | None = None) -> int:
    auth_key = os.environ.get("DEEPL_AUTH_KEY")
    if not auth_key:
        raise RuntimeError("Set DEEPL_AUTH_KEY in the environment before running this script.")

    source = Path(input_file)
    destination = Path(output_file) if output_file else source
    words = json.loads(source.read_text(encoding="utf-8"))
    translator = deepl.Translator(auth_key)
    translated_count = 0

    for word in words:
        if str(word.get("polish", "")).strip():
            continue
        result = translator.translate_text(
            word["english"],
            source_lang="EN",
            target_lang="PL",
        )
        word["polish"] = result.text
        translated_count += 1
        time.sleep(0.1)

    destination.write_text(
        json.dumps(words, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return translated_count


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        raise SystemExit("Usage: translate_hsk4_polish.py INPUT_JSON [OUTPUT_JSON]")
    print(translate_hsk4_to_polish(sys.argv[1], sys.argv[2] if len(sys.argv) == 3 else None))
