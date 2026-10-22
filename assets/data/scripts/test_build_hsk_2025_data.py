"""Unit tests for CC-CEDICT homograph selection in build_hsk_2025_data."""

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hsk_2025_data as builder  # noqa: E402

CACHED_CEDICT = Path(tempfile.gettempdir()) / "chinese-learning-app-cedict.u8"
NO_OVERRIDES = Path(__file__).resolve().parent / "missing-sense-overrides.json"

SYNTHETIC_CEDICT = """\
# synthetic CC-CEDICT excerpt in upstream order (proper nouns first)
權 权 [Quan2] /surname Quan/
權 权 [quan2] /authority/power/right/
百 百 [Bai3] /surname Bai/
百 百 [bai3] /hundred/numerous/
吧 吧 [Ba1] /Ba (proper noun)/
吧 吧 [ba1] /bar (loanword)/to puff (on a pipe etc)/
吧 吧 [ba5] /(modal particle indicating suggestion or surmise)/...right?/
中國 中国 [Zhong1 guo2] /China/
長城 长城 [Chang2 cheng2] /the Great Wall/
趙 赵 [Zhao4] /surname Zhao/
長 长 [chang2] /length/long/
長 长 [zhang3] /chief/head/to grow/
都 都 [Du1] /surname Du/
都 都 [dou1] /all/both/
都 都 [du1] /capital city/metropolis/
了 了 [le5] /(completed action marker)/
了 了 [liao3] /to finish/to understand clearly/
瞭 了 [liao3] /(of eyes) bright/to understand clearly/
咊 和 [he2] /old variant of 和[he2]/
和 和 [He2] /surname He/Japanese (food, clothes etc)/
和 和 [he2] /and/together with/peace/peace/
過去 过去 [guo4 qu4] /(in the) past/former/to go over/to pass by/
過去 过去 [guo4 qu5] /(verb suffix)/
空 空 [kong1] /empty/air/sky/
空 空 [kong4] /free time/spare time/
喂 喂 [wei2] /hello (when answering the phone)/
喂 喂 [wei4] /hey/to feed (an animal etc)/
昇 升 [sheng1] /variant of 升[sheng1]/to ascend/
升 升 [sheng1] /to ascend/liter/
女 女 [nu:3] /female/woman/
體檢 体检 [ti3 jian3] /abbr. for 體格檢查|体格检查[ti3 ge2 jian3 cha2]/
體格檢查 体格检查 [ti3 ge2 jian3 cha2] /physical examination/
紀錄 纪录 [ji4 lu4] /variant of 記錄|记录[ji4 lu4] (but in Taiwan, not for the verb)/
記錄 记录 [Ji4 lu4] /Record (proper noun)/
記錄 记录 [ji4 lu4] /to record/record (written account)/
磅 磅 [bang4] /see 磅秤/pound (unit of weight)/
磅秤 磅秤 [bang4 cheng4] /scale/platform balance/
做主 做主 [zuo4 zhu3] /see 作主[zuo4 zhu3]/
星系 星系 [xing1 xi4] /see 恆星系|恒星系[heng2 xing1 xi4]/
"""


def entry(pinyin: str, english: str, traditional: str = "X") -> dict[str, str]:
    return {"traditional": traditional, "pinyin": pinyin, "english": english}


class SyntheticDictionaryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "cedict.u8"
            path.write_text(SYNTHETIC_CEDICT, encoding="utf-8")
            cls.cedict = builder.load_cedict(path)

    def pick(self, word, legacy=None, preferred=None, traditional=None):
        return builder._pick_dictionary_entry(
            self.cedict[word], legacy, preferred, traditional
        )

    def test_quan_lowercase_sense_beats_same_tone_surname(self) -> None:
        for legacy in (None, {"pinyin": "quán"}, {"pinyin": "Quán"}):
            picked = self.pick("权", legacy)
            self.assertEqual(picked["pinyin"], "quan2", legacy)
            self.assertEqual(picked["english"], "authority; power; right")
            self.assertEqual(picked["traditional"], "權")
        self.assertEqual(
            builder._previous_pick_dictionary_entry(self.cedict["权"], None)["pinyin"],
            "Quan2",
        )

    def test_bai_hundred_beats_surname(self) -> None:
        self.assertEqual(self.pick("百")["english"], "hundred; numerous")
        self.assertEqual(self.pick("百", {"pinyin": "bǎi"})["pinyin"], "bai3")

    def test_ba_proper_noun_loses_and_tone_selects_particle(self) -> None:
        self.assertEqual(self.pick("吧")["pinyin"], "ba1")
        self.assertEqual(self.pick("吧", {"pinyin": "bā"})["pinyin"], "ba1")
        self.assertEqual(self.pick("吧", {"pinyin": "ba"})["pinyin"], "ba5")
        self.assertEqual(self.pick("吧", preferred="ba5")["pinyin"], "ba5")
        self.assertEqual(builder.PREFERRED_READINGS["吧"], "ba5")

    def test_proper_nouns_and_surnames_kept_when_only_option(self) -> None:
        self.assertEqual(self.pick("中国")["english"], "China")
        self.assertEqual(self.pick("中国", {"pinyin": "Zhōngguó"})["pinyin"], "Zhong1 guo2")
        self.assertEqual(self.pick("长城")["english"], "the Great Wall")
        self.assertEqual(self.pick("赵")["english"], "surname Zhao")

    def test_polyphones_follow_legacy_reading(self) -> None:
        self.assertEqual(self.pick("长", {"pinyin": "zhǎng"})["pinyin"], "zhang3")
        self.assertEqual(self.pick("长", {"pinyin": "cháng"})["pinyin"], "chang2")
        self.assertEqual(self.pick("都", {"pinyin": "dōu"})["pinyin"], "dou1")
        self.assertEqual(self.pick("了", {"pinyin": "le"})["pinyin"], "le5")

    def test_traditional_variants_preserved(self) -> None:
        self.assertEqual(self.pick("了", {"pinyin": "liǎo"})["traditional"], "了")
        self.assertEqual(
            self.pick("了", {"pinyin": "liǎo"}, traditional="瞭")["traditional"], "瞭"
        )
        self.assertEqual(self.pick("升", {"pinyin": "shēng"})["traditional"], "升")

    def test_variant_cross_reference_and_proper_entries_lose(self) -> None:
        picked = self.pick("和", {"pinyin": "hé"})
        self.assertEqual((picked["traditional"], picked["pinyin"]), ("和", "he2"))
        self.assertEqual(picked["english"], "and; together with; peace")

    def test_neutral_legacy_tone_yields_to_matching_gloss(self) -> None:
        legacy = {"pinyin": "guò qu", "english": "go over, pass by"}
        self.assertEqual(self.pick("过去", legacy)["pinyin"], "guo4 qu4")
        self.assertEqual(self.pick("过去", {"pinyin": "guò qu"})["pinyin"], "guo4 qu5")

    def test_fully_toned_legacy_reading_is_not_overridden_by_gloss(self) -> None:
        legacy = {"pinyin": "kōng", "english": "free, with spare time"}
        self.assertEqual(self.pick("空", legacy)["pinyin"], "kong1")
        self.assertEqual(self.pick("空", {"pinyin": "kòng"})["pinyin"], "kong4")

    def test_numbered_source_words_use_curated_reading(self) -> None:
        legacy = {"pinyin": "wèi/wéi", "english": "hello (on phone)"}
        self.assertEqual(self.pick("喂", legacy)["pinyin"], "wei2")
        self.assertEqual(
            self.pick("喂", legacy, builder._preferred_reading("喂2", "喂"))["pinyin"],
            "wei4",
        )

    def test_legacy_pick_accepts_slash_readings(self) -> None:
        legacy_rows = [{"pinyin": "wèi/wéi", "english": "hello"}, {"pinyin": "wèi"}]
        self.assertIs(
            builder._pick_legacy_entry(legacy_rows, self.cedict["喂"]), legacy_rows[0]
        )

    def test_reading_keys_keep_tones_and_ignore_case_and_spacing(self) -> None:
        self.assertEqual(
            builder.pinyin_reading_key("Zhōngguó"),
            builder.cedict_reading_key("Zhong1 guo2"),
        )
        self.assertEqual(builder.pinyin_reading_key("nǚ"), builder.cedict_reading_key("nu:3"))
        self.assertNotEqual(builder.pinyin_reading_key("ba"), builder.cedict_reading_key("ba1"))
        self.assertEqual(builder.normalize_pinyin("bā"), builder.normalize_pinyin("ba5"))

    def test_entry_classification(self) -> None:
        self.assertTrue(builder.is_surname_only_entry(entry("Quan2", "surname Quan")))
        self.assertFalse(
            builder.is_surname_only_entry(entry("He2", "surname He; Japanese (food)"))
        )
        self.assertTrue(builder.is_proper_entry(entry("He2", "surname He")))
        self.assertTrue(builder.is_variant_only_entry(entry("he2", "old variant of 和[he2]")))
        self.assertFalse(builder.is_variant_only_entry(entry("sheng1", "variant of 升; to ascend")))

    def test_leading_cross_references_resolve_to_target_senses(self) -> None:
        resolve = builder.resolve_reference_english
        self.assertEqual(resolve(self.cedict["体检"][0], self.cedict), "physical examination")
        self.assertEqual(
            resolve(self.cedict["纪录"][0], self.cedict),
            "to record; record (written account)",
        )
        self.assertEqual(
            resolve(self.cedict["磅"][0], self.cedict),
            "scale; platform balance; pound (unit of weight)",
        )

    def test_unresolvable_or_non_leading_references_are_kept(self) -> None:
        resolve = builder.resolve_reference_english
        self.assertEqual(resolve(self.cedict["做主"][0], self.cedict), "see 作主[zuo4 zhu3]")
        self.assertEqual(
            resolve(self.cedict["星系"][0], self.cedict),
            "see 恆星系|恒星系[heng2 xing1 xi4]",
        )
        sheng = self.cedict["升"]
        self.assertEqual(
            [resolve(e, self.cedict) for e in sheng], ["to ascend; liter", "to ascend; liter"]
        )
        self.assertEqual(resolve(self.cedict["权"][1], self.cedict), "authority; power; right")

    def test_duplicate_glosses_are_removed(self) -> None:
        self.assertEqual(
            self.cedict["和"][2]["english"], "and; together with; peace"
        )


class SenseOverrideTest(unittest.TestCase):
    SOURCE = {"HSK-3": ["得", "灯", "得"]}

    def load(self, payload: str):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sense_overrides.json"
            path.write_text(payload, encoding="utf-8")
            return builder.load_sense_overrides(path, self.SOURCE)

    def test_missing_file_means_no_overrides(self) -> None:
        self.assertEqual(builder.load_sense_overrides(NO_OVERRIDES, self.SOURCE), {})

    def test_valid_override_is_keyed_by_level_and_frequency(self) -> None:
        overrides = self.load(
            '{"HSK-3|3": {"sourceWord": "得", "polish": " musieć ", "notes": "děi"}}'
        )
        self.assertEqual(
            overrides, {("HSK-3", 3): {"polish": " musieć ", "notes": "děi"}}
        )

    def test_invalid_overrides_are_rejected(self) -> None:
        invalid = [
            '{"HSK-3|2": {"sourceWord": "得", "polish": "x"}}',
            '{"HSK-3|4": {"sourceWord": "得", "polish": "x"}}',
            '{"HSK3|1": {"sourceWord": "得", "polish": "x"}}',
            '{"HSK-3|1": {"sourceWord": "得", "polish": " "}}',
            '{"HSK-3|1": {"sourceWord": "得", "hanzi": "x"}}',
            '{"HSK-3|1": {"sourceWord": "得"}}',
            '[]',
        ]
        for payload in invalid:
            with self.assertRaises(ValueError, msg=payload):
                self.load(payload)

    def test_positional_rows_prefer_legacy_row_with_matching_tone(self) -> None:
        rows = [{"pinyin": "de", "polish": "a"}, {"pinyin": "děi", "polish": "b"}]
        chosen = builder._reading_legacy_entry(rows, entry("dei3", "must"), rows[0])
        self.assertIs(chosen, rows[1])
        self.assertIs(
            builder._reading_legacy_entry(rows, entry("de2", "get"), rows[0]), rows[0]
        )


@unittest.skipUnless(CACHED_CEDICT.exists(), "cached CC-CEDICT not available")
class CachedDictionaryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.datasets = builder.build_datasets(CACHED_CEDICT, NO_OVERRIDES)
        cls.cedict = builder.load_cedict(CACHED_CEDICT)

    def rows(self, source_word: str) -> list[dict]:
        return [
            row
            for words in self.datasets.values()
            for row in words
            if row["sourceWord"] == source_word
        ]

    def test_curated_english_is_preserved(self) -> None:
        for word, english in builder.CURATED_ENGLISH.items():
            rows = self.rows(word)
            self.assertTrue(rows, word)
            for row in rows:
                self.assertEqual(row["english"], english)

    def test_row_count_and_identities_unchanged(self) -> None:
        self.assertEqual(sum(map(len, self.datasets.values())), 11105)
        for level, words in self.datasets.items():
            self.assertEqual(
                [row["frequency"] for row in words], list(range(1, len(words) + 1))
            )

    def test_reported_entries_use_everyday_senses(self) -> None:
        expected = {
            "权": ("權", "quán", "authority"),
            "百": ("百", "bǎi", "hundred"),
            "吧": ("吧", "ba", "(modal particle"),
            "张": ("張", "zhāng", "to open up"),
            "钟": ("鐘", "zhōng", "clock"),
            "都": ("都", "dōu", "all"),
            "了": ("了", "le", "(modal particle"),
            "中国": ("中國", "zhōng guó", "China"),
            "后": ("後", "hòu", "back"),
            "考": ("考", "kǎo", "to check"),
            "局1": ("局", "jú", "office"),
            "局2": ("局", "jú", "office"),
        }
        for word, (traditional, pinyin, english) in expected.items():
            rows = self.rows(word)
            self.assertTrue(rows, word)
            for row in rows:
                self.assertEqual(row["traditional"], traditional, word)
                self.assertEqual(row["pinyin"], pinyin, word)
                self.assertTrue(row["english"].startswith(english), (word, row["english"]))

    def test_peer_reported_readings(self) -> None:
        expected = {
            "吗": "ma", "那": "nà", "上": "shàng", "节": "jié", "汗": "hàn",
            "鲜": "xiān", "与": "yǔ", "沉": "chén", "化": "huà", "令": "lìng",
            "抢": "qiǎng", "趟": "tàng", "祭": "jì", "谜": "mí", "钻": "zuàn", "数": "shǔ", "背": "bèi", "片": "piàn", "盛": "shèng", "铺": "pù", "精神": "jīng shén",
            "炸": "zhà", "地道": "dì dào",
        }
        for word, pinyin in expected.items():
            rows = self.rows(word)
            self.assertTrue(rows, word)
            for row in rows:
                self.assertEqual(row["pinyin"], pinyin, word)

    def test_same_level_duplicates_get_distinct_positional_readings(self) -> None:
        for (level, frequency), numbered in builder.POSITIONAL_READINGS.items():
            row = self.datasets[level][frequency - 1]
            self.assertEqual(row["frequency"], frequency)
            self.assertEqual(row["pinyin"], builder.pinyin_with_tones(numbered), row)
            readings = {e["pinyin"] for e in self.cedict[row["sourceWord"].rstrip("0123456789")]}
            self.assertIn(numbered, readings, row)
        by_word: dict[tuple[str, str], set[str]] = {}
        for level, frequency in builder.POSITIONAL_READINGS:
            row = self.datasets[level][frequency - 1]
            by_word.setdefault((level, row["sourceWord"].rstrip("0123456789")), set()).add(row["pinyin"])
        for key, readings in by_word.items():
            self.assertEqual(len(readings), 2, key)
        self.assertEqual(self.datasets["HSK-4"][104]["pinyin"], "chóng")
        self.assertEqual(self.datasets["HSK-3"][93]["pinyin"], "děi")
        self.assertEqual(self.datasets["HSK-7-9"][2261]["pinyin"], "juān")

    def test_sense_overrides_apply_and_repository_file_is_valid(self) -> None:
        builder.load_sense_overrides()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sense_overrides.json"
            path.write_text(
                '{"HSK-3|94": {"sourceWord": "得", "polish": "musieć", "notes": "děi"}}',
                encoding="utf-8",
            )
            datasets = builder.build_datasets(CACHED_CEDICT, path)
        row = datasets["HSK-3"][93]
        self.assertEqual((row["pinyin"], row["polish"], row["notes"]), ("děi", "musieć", "děi"))
        self.assertEqual(datasets["HSK-3"][89]["pinyin"], "dé")

    def test_reference_first_glosses_are_resolved(self) -> None:
        expected = {
            "下功夫": "to put in time and energy",
            "标识": "sign; mark",
            "纯朴": "simple and honest",
            "做主": "to decide",
            "星系": "stellar system; galaxy",
            "一点儿": "a bit; a little",
        }
        for word, english in expected.items():
            rows = self.rows(word)
            self.assertTrue(rows, word)
            for row in rows:
                self.assertTrue(row["english"].startswith(english), (word, row["english"]))
        for words in self.datasets.values():
            for row in words:
                self.assertIsNone(
                    builder.REFERENCE_GLOSS.match(row["english"]),
                    (row["sourceWord"], row["english"]),
                )

    def test_curated_preferences_exist_in_dictionary(self) -> None:
        for word, pinyin in builder.PREFERRED_READINGS.items():
            base = word.rstrip("0123456789")
            readings = {e["pinyin"] for e in self.cedict.get(base, [])}
            self.assertIn(pinyin, readings, word)
        for word, traditional in builder.PREFERRED_TRADITIONAL.items():
            forms = {e["traditional"] for e in self.cedict.get(word, [])}
            self.assertIn(traditional, forms, word)

    def test_no_surname_only_gloss_when_lexical_entry_exists(self) -> None:
        for words in self.datasets.values():
            for row in words:
                base = row["sourceWord"].rstrip("0123456789")
                entries = self.cedict.get(base, [])
                lexical = [
                    e for e in entries
                    if not builder.is_surname_only_entry(e)
                    and not builder.is_proper_entry(e)
                ]
                if lexical:
                    self.assertFalse(
                        row["english"].lower().startswith("surname ")
                        and ";" not in row["english"],
                        row,
                    )


SOURCE = {level: ["甲", "乙"] for level in builder.LEVEL_FILES}


def _row(level: str, frequency: int, **fields: str) -> dict:
    return {
        "hanzi": SOURCE[level][frequency - 1],
        "traditional": SOURCE[level][frequency - 1],
        "pinyin": fields.get("pinyin", "jiǎ"),
        "english": fields.get("english", "first"),
        "polish": fields.get("polish", "pierwszy"),
        "level": level,
        "notes": fields.get("notes", ""),
        "tags": [],
        "partOfSpeech": None,
        "frequency": frequency,
        "sourceWord": SOURCE[level][frequency - 1],
        "sourceEdition": "HSK 2025",
    }


def _complete_datasets() -> dict[str, list[dict]]:
    return {level: [_row(level, 1), _row(level, 2)] for level in builder.LEVEL_FILES}


class ReviewedSourcesTest(unittest.TestCase):
    def write_json(self, directory: Path, name: str, data: object) -> Path:
        path = directory / name
        path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        return path

    def test_layers_apply_in_order_without_mutating_raw(self) -> None:
        raw = _complete_datasets()
        raw["HSK-1"][0].update(pinyin="", english="raw", polish="", notes="legacy")
        raw["HSK-1"][1].update(english="", polish="")
        translations = {
            ("HSK-1", 1): {"polish": "przegląd", "english": "reviewed", "review": "checked"},
            ("HSK-1", 2): {"polish": "drugi"},
        }
        completions = {
            ("HSK-1", 1): {"pinyin": "jiǎ", "english": "completion"},
            ("HSK-1", 2): {"english": "second"},
        }
        overrides = {("HSK-1", 2): {"english": "authored", "polish": " autorski "}}
        final, report = builder.apply_reviewed_sources(raw, translations, completions, overrides)
        first, second = final["HSK-1"]
        self.assertEqual(
            (first["pinyin"], first["english"], first["polish"], first["notes"]),
            ("jiǎ", "reviewed", "przegląd", "legacy; Review: checked"),
        )
        self.assertEqual((second["english"], second["polish"]), ("authored", "autorski"))
        self.assertEqual(report["supersededCompletionFields"], ["HSK-1|1:english"])
        self.assertEqual((raw["HSK-1"][0]["english"], raw["HSK-1"][0]["polish"]), ("raw", ""))
        builder.validate_final_datasets(final, SOURCE)

    def test_reviewed_keys_must_exist_in_build(self) -> None:
        with self.assertRaisesRegex(ValueError, "absent from the build"):
            builder.apply_reviewed_sources(
                _complete_datasets(), {("HSK-1", 3): {"polish": "x"}}, {}, {}
            )

    def test_translation_shards_are_validated_against_source_keys(self) -> None:
        ranges = ((1, 2), (3, 3))
        valid = (
            {"HSK-1|1": {"polish": "a"}, "HSK-1|2": {"polish": "b", "english": "b"}},
            {"HSK-2|1": {"polish": "c", "review": "note"}},
        )
        invalid_cases = {
            "expected 2": ({"HSK-1|1": {"polish": "a"}}, valid[1]),
            "out of source order": (valid[0], {"HSK-1|2": {"polish": "c"}}),
            "unknown fields": (valid[0], {"HSK-2|1": {"polish": "c", "hanzi": "甲"}}),
            "no Polish": (valid[0], {"HSK-2|1": {"polish": " "}}),
            "empty english": (valid[0], {"HSK-2|1": {"polish": "c", "english": ""}}),
            "invalid key": (valid[0], {"HSK2|1": {"polish": "c"}}),
            "outside HSK-2": (valid[0], {"HSK-2|3": {"polish": "c"}}),
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            names = [f"hsk2025_polish_{start:04d}_{end:04d}.json" for start, end in ranges]
            for name, shard in zip(names, valid):
                self.write_json(root, name, shard)
            loaded = builder.load_translation_shards(SOURCE, root, ranges)
            self.assertEqual(
                loaded,
                {
                    ("HSK-1", 1): {"polish": "a"},
                    ("HSK-1", 2): {"polish": "b", "english": "b"},
                    ("HSK-2", 1): {"polish": "c", "review": "note"},
                },
            )
            for message, shards in invalid_cases.items():
                with self.subTest(message):
                    for name, shard in zip(names, shards):
                        self.write_json(root, name, shard)
                    with self.assertRaisesRegex(ValueError, message):
                        builder.load_translation_shards(SOURCE, root, ranges)
            (root / names[1]).unlink()
            with self.assertRaises(FileNotFoundError):
                builder.load_translation_shards(SOURCE, root, ranges)

    def test_metadata_completions_are_validated(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = self.write_json(root, "c.json", {"HSK-3|2": {"english": " two "}})
            self.assertEqual(
                builder.load_metadata_completions(SOURCE, path),
                {("HSK-3", 2): {"english": "two"}},
            )
            for message, data in {
                "unknown fields": {"HSK-3|2": {"polish": "x"}},
                "empty field": {"HSK-3|2": {"pinyin": ""}},
                "non-empty object": {"HSK-3|2": {}},
                "outside HSK-3": {"HSK-3|9": {"english": "x"}},
            }.items():
                with self.subTest(message):
                    self.write_json(root, "c.json", data)
                    with self.assertRaisesRegex(ValueError, message):
                        builder.load_metadata_completions(SOURCE, path)
            with self.assertRaises(FileNotFoundError):
                builder.load_metadata_completions(SOURCE, root / "missing.json")

    def test_final_validation_rejects_blank_text_and_wrong_identity(self) -> None:
        for field in builder.REQUIRED_TEXT_FIELDS:
            datasets = _complete_datasets()
            datasets["HSK-6"][1][field] = " "
            with self.subTest(field), self.assertRaisesRegex(ValueError, f"blank {field}"):
                builder.validate_final_datasets(datasets, SOURCE)
        datasets = _complete_datasets()
        datasets["HSK-2"][0]["sourceWord"] = "乙"
        with self.assertRaisesRegex(ValueError, "does not match"):
            builder.validate_final_datasets(datasets, SOURCE)
        datasets = _complete_datasets()
        datasets["HSK-7-9"].pop()
        with self.assertRaisesRegex(ValueError, "expected 2"):
            builder.validate_final_datasets(datasets, SOURCE)

    def test_write_is_validated_atomic_and_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            incomplete = _complete_datasets()
            incomplete["HSK-7-9"][1]["polish"] = ""
            with self.assertRaises(ValueError):
                builder.write_datasets(incomplete, root, SOURCE)
            self.assertEqual(list(root.iterdir()), [])

            datasets = _complete_datasets()
            builder.write_datasets(datasets, root, SOURCE)
            first = {path.name: path.read_bytes() for path in root.iterdir()}
            self.assertEqual(len(first), 7)
            builder.write_datasets(datasets, root, SOURCE)
            self.assertEqual({path.name: path.read_bytes() for path in root.iterdir()}, first)


    def files(self, root: Path) -> dict[str, bytes]:
        return {path.name: path.read_bytes() for path in sorted(root.iterdir())}

    def fail_replace_calls(self, *failing: int):
        """Patch os.replace so the given 1-based calls fail and others really run."""
        real_replace = builder.os.replace
        calls = []

        def replace(source, target):
            calls.append((Path(source), Path(target)))
            if len(calls) in failing:
                raise OSError(f"locked on call {len(calls)}")
            return real_replace(source, target)

        return mock.patch.object(builder.os, "replace", side_effect=replace), calls

    def batch(self, root: Path) -> tuple[dict[Path, str], dict[Path, str]]:
        old = {root / "a.json": "old a\n", root / "b.json": "old b\n"}
        for path, content in old.items():
            path.write_text(content, encoding="utf-8", newline="")
        new = {
            root / "a.json": "new a\n",
            root / "b.json": "new b\n",
            root / "c.json": "new c\n",
        }
        return old, new

    def test_failed_later_replace_rolls_back_earlier_files(self) -> None:
        for failing_call in (2, 3):
            with self.subTest(failing_call), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                old, new = self.batch(root)
                before = self.files(root)
                patch, calls = self.fail_replace_calls(failing_call)
                with patch, self.assertRaisesRegex(OSError, "locked") as raised:
                    builder.replace_files_transactionally(new)
                self.assertNotIsInstance(raised.exception, builder.RollbackError)
                self.assertGreaterEqual(len(calls), failing_call)
                self.assertEqual(calls[0][1], root / "a.json")
                self.assertEqual(self.files(root), before)
                self.assertFalse((root / "c.json").exists())

    def test_rollback_failure_keeps_recoverable_backup(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old, new = self.batch(root)
            # Call 1 replaces a.json, call 2 (b.json) fails, call 3 restores a.json and fails.
            patch, calls = self.fail_replace_calls(2, 3)
            with patch, self.assertRaises(builder.RollbackError) as raised:
                builder.replace_files_transactionally(new)
            retained = raised.exception.retained_backups
            self.assertEqual(list(retained), [root / "a.json"])
            self.assertEqual(retained[root / "a.json"].read_text(encoding="utf-8"), old[root / "a.json"])
            self.assertIn(str(retained[root / "a.json"]), str(raised.exception))
            self.assertEqual((root / "b.json").read_text(encoding="utf-8"), old[root / "b.json"])
            leftovers = {path.name for path in root.iterdir()} - {"a.json", "b.json"}
            self.assertEqual(leftovers, {retained[root / "a.json"].name})

    def test_successful_batch_leaves_no_staging_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _, new = self.batch(root)
            builder.replace_files_transactionally(new)
            self.assertEqual(
                self.files(root),
                {path.name: content.encode("utf-8") for path, content in new.items()},
            )

    def test_outputs_replace_datasets_and_worklist_together(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            worklist = root / "worklist.csv"
            builder.write_outputs(_complete_datasets(), root, worklist, SOURCE)
            before = self.files(root)
            self.assertEqual(len(before), 8)
            changed = _complete_datasets()
            changed["HSK-1"][0]["english"] = "changed"
            # Eight files: fail on the last replacement (the worklist).
            patch, calls = self.fail_replace_calls(8)
            with patch, self.assertRaises(OSError):
                builder.write_outputs(changed, root, worklist, SOURCE)
            self.assertEqual(calls[7][1], worklist)
            self.assertEqual(self.files(root), before)

    def test_repository_shards_match_expected_slices(self) -> None:
        expected = {
            f"hsk2025_polish_{start:04d}_{end:04d}.json"
            for start, end in builder.TRANSLATION_SHARDS
        }
        actual = {path.name for path in builder.DATA_DIR.glob("hsk2025_polish_*.json")}
        self.assertEqual(actual, expected)
        self.assertEqual(builder.TRANSLATION_SHARDS[-1][1], 8280)


GENERATED_DATASET = re.compile(r"hsk2025_.+_words\.json")


@unittest.skipUnless(CACHED_CEDICT.is_file(), "cached CC-CEDICT not available")
class FinalBuildTest(unittest.TestCase):
    @classmethod
    def build_without_generated_files(cls) -> tuple[dict, dict]:
        original_open = Path.open

        def guarded_open(path: Path, *args, **kwargs):
            if GENERATED_DATASET.fullmatch(path.name):
                raise AssertionError(f"final build must not read {path.name}")
            return original_open(path, *args, **kwargs)

        with mock.patch.object(Path, "open", autospec=True, side_effect=guarded_open):
            return builder.build_final_datasets(CACHED_CEDICT)

    @classmethod
    def setUpClass(cls) -> None:
        cls.datasets, cls.report = cls.build_without_generated_files()
        cls.source_words = builder._load_source_words()
        cls.index = {
            (row["level"], row["frequency"]): row
            for rows in cls.datasets.values()
            for row in rows
        }
        cls.translations = builder.load_translation_shards(cls.source_words)
        cls.completions = builder.load_metadata_completions(cls.source_words)
        cls.overrides = builder.load_sense_overrides(None, cls.source_words)

    def test_final_build_is_complete(self) -> None:
        self.assertEqual(len(self.index), 11105)
        self.assertEqual(self.report["translationShardRows"], 8280)
        builder.validate_final_datasets(self.datasets, self.source_words)

    def test_reviewed_sources_are_preserved(self) -> None:
        for key, translation in self.translations.items():
            override = self.overrides.get(key, {})
            for field in ("polish", "english", "pinyin"):
                if field in translation and field not in override:
                    self.assertEqual(self.index[key][field], translation[field], (key, field))
            if "review" in translation and "notes" not in override:
                self.assertIn(f"Review: {translation['review']}", self.index[key]["notes"])
        superseded = set(self.report["supersededCompletionFields"])
        for key, completion in self.completions.items():
            for field, value in completion.items():
                if f"{key[0]}|{key[1]}:{field}" not in superseded and field not in self.overrides.get(key, {}):
                    self.assertEqual(self.index[key][field], value, (key, field))
        for key, override in self.overrides.items():
            for field, value in override.items():
                expected = value.strip() if field == "polish" else value
                self.assertEqual(self.index[key][field], expected, (key, field))
        for word, english in builder.CURATED_ENGLISH.items():
            for row in self.index.values():
                if row["sourceWord"] == word:
                    self.assertTrue(row["english"], word)

    def test_rebuild_and_serialization_are_idempotent(self) -> None:
        again, report = self.build_without_generated_files()
        self.assertEqual(again, self.datasets)
        self.assertEqual(report, self.report)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            builder.write_datasets(self.datasets, root)
            first = {path.name: path.read_bytes() for path in root.iterdir()}
            builder.write_datasets(again, root)
            self.assertEqual({path.name: path.read_bytes() for path in root.iterdir()}, first)
            for level, words in self.datasets.items():
                written = json.loads(builder.dataset_path(level, root).read_text(encoding="utf-8"))
                self.assertEqual(written, words)


if __name__ == "__main__":
    unittest.main()
