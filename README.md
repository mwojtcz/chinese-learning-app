# Cíkǎ · 词卡

**Polish and Chinese, one card at a time.** A local-first Flutter app for learning Chinese or Polish, with English translations as a bridge language.

![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue)
![Dart](https://img.shields.io/badge/Dart-3.5.4-blue)
![Version](https://img.shields.io/badge/version-1.4.0-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌐 Live Demo

**[➡️ Try the app online](https://mwojtcz.github.io/chinese-learning-app/)** (web version)

Or download the [latest portable Windows build](https://github.com/mwojtcz/chinese-learning-app/releases/tag/windows-latest).

## Features

- **Flashcard deck** with tap-to-reveal, touch swipes, keyboard controls, and persistent decisions: skip, save for study, or mark as known.
- **Polish and Chinese interfaces** (simplified or traditional script); cards retain Chinese characters, pinyin, Polish, and English as available.
- **HSK 2025 library and search**, including the shared HSK 7–9 vocabulary band.
- **Grammar guides** for Chinese and Polish, including classifiers, negation, Chinese 的/地/得, Polish cases, number agreement, adjective comparison, and verb conjugation.
- **Practice tab** with vocabulary multiple choice and typed sentence-gap exercises, localized in Polish, Simplified Chinese, and Traditional Chinese.
- **Structured 24-module Polish course from A1 to C2**, with localized examples, grammar focus, answer-reveal exercises, and practical tasks for Chinese-speaking learners.
- **Curated Polish word forms** for selected common nouns, adjectives, and verbs, with example sentences and Chinese translations.
- **Personal saved-word list** stored locally on the device.
- **Portable Windows build** with automatic update checks against the latest successful `main` build published by GitHub Actions; updates are checksum-verified, staged beside the app folder, and installed after restart.
- **Responsive layout** for desktop, tablet, and mobile.

The app keeps English and Polish meanings separate: when a Polish translation is missing, the card labels the English gloss as a bridge instead of presenting it as Polish. All 11,105 HSK entries now have Polish glosses; the 87 source rows that lacked pinyin or English glosses have also been completed. Twenty-three entries carry review notes for context-sensitive or ambiguous readings.

## 🚀 Installation

### Requirements

- Flutter 3.24.5 or newer
- Dart 3.5.4 or newer
- Windows 10/11 (for Windows builds)

### Running from Source

```bash
# Clone repository
git clone https://github.com/mwojtcz/chinese-learning-app.git
cd chinese-learning-app

# Install dependencies
flutter pub get

# Run application
flutter run -d windows
```

### Download Pre-built Application

Download the latest Windows ZIP from the [latest Windows build](https://github.com/mwojtcz/chinese-learning-app/releases/tag/windows-latest):
- Extract the ZIP archive to a folder where your Windows user can write files (for example, a folder under Downloads)
- Run `chinese_learning_app.exe`
- No installer or administrator access is required. Keep the app in the extracted folder; Windows builds check for updates at startup and let you install them with one click. The app restarts after replacing its files.

## How to Use

- Choose **PL**, **简**, or **繁** in the upper corner. Polish UI studies Chinese; Chinese UI studies Polish.
- Tap the card to reveal pinyin and translations. On a keyboard, use Space/Enter to reveal, Left to skip, Up to mark known, and Right to save for study.
- Select an HSK level to focus the deck. Revisit skipped cards from the deck controls.
- Browse and search the full available vocabulary in **HSK**; open a word to see translations and available Polish forms.
- Use **Practice** for HSK vocabulary questions or sentence-gap exercises. Polish A1 gap exercises are an initial curated set; Polish vocabulary questions draw from the shared bilingual vocabulary and are not a CEFR placement.
- With **Polish** selected as the learning target, flashcards show the Chinese word first; reveal the card to see its Polish meaning and supporting details.
- Use **Grammar** for reference lessons in both languages. The Polish tab includes 24 sequenced A1–C2 modules, each with examples, a short exercise and answer, and a practical task; it also includes a seven-case chart ordered from nominative to vocative and a sample declension table. Detailed Polish paradigms are curated for selected common words, not generated for every dictionary entry.

## 📁 Project Structure

```
chinese_learning_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Word and interface-language models
│   ├── providers/                   # Vocabulary and study-decision state
│   ├── services/                    # Platform services, including Windows updates
│   ├── screens/
│   │   ├── home_screen.dart         # Responsive shell and locale switcher
│   │   ├── learning_tabs.dart       # Deck, HSK, grammar, saved words
│   │   └── practice_tab.dart        # Vocabulary and sentence-gap practice
│   ├── database/                    # Database handling
│   │   └── database_helper.dart
├── assets/
│   └── data/                        # HSK vocabulary, grammar, exercises, and curated word forms
├── test/                            # Unit and widget tests
├── .github/
│   └── workflows/
│       ├── build-windows.yml        # Rolling Windows builds and tagged releases
│       ├── build-android.yml        # Android release builds
│       └── deploy-web.yml           # GitHub Pages deployment
```

## Data Sources and Attribution

- **HSK 2025 word lists:** [krmanik/HSK-3.0](https://github.com/krmanik/HSK-3.0), pinned to commit `182692ce5a11bc30bdc771835d2f0f27491c25de`. The repository declares its HSK word lists under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). HSK 7–9 is a single shared band. The source license and attribution are included in `assets/data/sources/hsk-2025/License.md`.
- **Traditional characters, pinyin, and English glosses:** [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict), distributed under CC BY-SA 4.0. The HSK builder joins dictionary entries by simplified form and prefers a matching legacy reading when available. See the source notice in the app and the builder at `assets/data/scripts/build_hsk_2025_data.py`.
- **Polish glosses:** authored for this application and carried over from matching local translations when the reading agrees. All 11,105 entries have Polish glosses; 23 entries include review notes for context-sensitive or ambiguous senses/readings. Translation gaps are tracked by `assets/data/polish_translation_worklist.csv`. Rebuild source data with `python assets/data/scripts/build_hsk_2025_data.py`, then run `python assets/data/scripts/merge_hsk_2025_translations.py` after all 21 validated translation shards are present. The merge refuses partial or mismatched batches.

The current source lists contain 11,105 entries: HSK 1–6 (300, 204, 507, 1,019, 1,638, and 1,815 entries) plus 5,622 entries in HSK 7–9. The levels are the supplied incremental sets, not cumulative totals. The lists themselves provide Chinese words only; pinyin, traditional characters, and English glosses are joined from CC-CEDICT, and Polish glosses are curated for the full vocabulary.

The repository's MIT license applies to application code. Source-derived vocabulary data has its own CC BY-SA 4.0 attribution and share-alike requirements; see `assets/data/sources/hsk-2025/ATTRIBUTION.md`.

Grammar lessons are localized JSON under `assets/data/grammar_*.json`. Each lesson should include Polish, Simplified Chinese, and Traditional Chinese text, examples, and notes that distinguish rules from common exceptions. Confirm the source and reuse terms for each grammar dataset independently.

Practice exercises are localized in `assets/data/practice_exercises.json`; accepted answer variants are listed explicitly to avoid overly permissive matching. Curated Polish paradigms and example sentences are stored in `assets/data/polish_word_forms.json`. These tables are educational examples for selected entries, not a complete automatic inflection engine.

The Polish course is localized in `assets/data/polish_course.json`; its 24 modules include communication outcomes, grammar guidance, translated examples, a short practice item with an answer and explanation, and an open-ended task. Its progression is informed by the [Council of Europe's CEFR Companion Volume](https://rm.coe.int/common-european-framework-of-reference-for-languages-learning-teaching/16809ea0d4) and the Polish adult certification-exam standards in the [2025 regulation (Dz.U. 2025 poz. 217)](https://dziennikustaw.gov.pl/DU/2025/217). The syllabus is an original learning plan, not an official exam syllabus or a claim of certification readiness; it does not yet include a complete graded workbook, audio course, or exhaustive word-form engine.

The seven-case reference presents nominative through vocative in order, followed by a comparison of singular noun forms. Its staged, example-first presentation is also informed by GLOSSA's [case-teaching article](https://e-polish.eu/sklep/blog/narzednik-na-start/). This is a teaching reference: actual forms depend on gender, number, animacy, stem alternations, and government.

## 🛠️ Technologies

- **Flutter** - UI framework
- **Provider** - State management
- **SQLite** - Local database
- **Shared Preferences** - Preferences storage

## 📄 Building and Releases

### Pre-built Windows Application

Download the latest Windows ZIP from the [rolling Windows build](https://github.com/mwojtcz/chinese-learning-app/releases/tag/windows-latest). Main-branch builds update this prerelease; tagged releases remain available as stable releases. Extract the archive to a user-writable folder to enable automatic updates.

### Manual Build

```bash
# Windows
flutter build windows --release

# Executable in: build/windows/x64/runner/Release/

# Web (for GitHub Pages)
flutter build web --release --base-href "/chinese-learning-app/"
```

**Note**: Due to issues with Polish characters in Windows paths, it's recommended to build in a path without special characters (e.g., `C:\build_temp\`).

### Roadmap

- [x] Add the HSK 2025 vocabulary lists, including the shared HSK 7–9 band
- [x] Complete Polish gloss coverage across all HSK 2025 levels (ambiguous entries are marked for review)
- [x] Add a localized Polish course plan from A1 to C2 with examples and short exercises
- [x] Add automatic update checks for the portable Windows build
- [ ] Expand word-level Polish declension and conjugation tables
- [ ] Add spaced repetition, audio, and printable A5 sheets
- [ ] Add word-list import/export and learning statistics

## 📝 License

MIT License - see [LICENSE](LICENSE)

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an [issue](https://github.com/mwojtcz/chinese-learning-app/issues) first to discuss proposed changes.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📧 Contact

Have questions or suggestions? Open an [issue](https://github.com/mwojtcz/chinese-learning-app/issues)!

---

**Happy Chinese learning! 加油! (jiā yóu!)** 🇨🇳
