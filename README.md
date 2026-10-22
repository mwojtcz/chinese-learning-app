# Polski · 中文

**Polish and Chinese, one card at a time.** A local-first Flutter app for learning Chinese or Polish, with English translations as a bridge language.

![Flutter](https://img.shields.io/badge/Flutter-3.47.7-blue)
![Dart](https://img.shields.io/badge/Dart-3.13.5-blue)
![Version](https://img.shields.io/badge/version-1.6.0-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌐 Live Demo

**[➡️ Try the app online](https://mwojtcz.github.io/chinese-learning-app/)** (web version)

Or download the [latest portable Windows build](https://github.com/mwojtcz/chinese-learning-app/releases/tag/windows-latest).

## Features

- **Local learner and teacher profiles** with separate saved words, learning decisions, and progress. These are local workspaces, not password-protected accounts.
- **Portable lessons** for teacher-led work: student-specific notes, pictures, questions, annotated text, dictionary hints, and versioned `.cika` lesson packages. Lesson exchange is manual; there is no server or live synchronization.
- **A4 lesson notebook** with page thumbnails, direct click-to-write lines, draggable/resizable pictures, blank/lined/grid paper, selection-based formatting, and an annotated reading/board view with pinyin above recognized words and short glosses below.
- **Paper, jade, and midnight themes** with adjustable reading size.
- **20 offline chengyu** with original illustrative motifs, localized explanations, usage cautions, and examples.
- **Flashcard deck** with tap-to-reveal, touch swipes, keyboard controls, and persistent decisions: skip, save for study, or mark as known.
- **Polish and Chinese interfaces** (simplified or traditional script); cards retain Chinese characters, pinyin, Polish, and English as available.
- **HSK 2025 library and search** with localized topic filters for body parts, food, family, health, work, and other themes, including the shared HSK 7–9 vocabulary band.
- **Grammar guides** for Chinese and Polish, including classifiers, negation, Chinese 的/地/得, Polish cases, number agreement, adjective comparison, and verb conjugation.
- **Practice tab** with vocabulary multiple choice, typed sentence gaps, and random Polish noun and verb paradigms to enter form by form; directions and labels are localized in Polish, Simplified Chinese, and Traditional Chinese.
- **Structured 30-module Polish course plan from A1 to C2**, with localized examples, grammar focus, answer-reveal exercises, and practical tasks for Chinese-speaking learners.
- **49 curated Polish paradigms**, including 24 nouns with all seven singular and plural cases, with example sentences and Chinese translations.
- **169 localized practice exercises**, including 120 Polish and 49 Chinese exercises; Chinese grammar drills now span HSK 1–6 and accept simplified/traditional answer variants where appropriate.
- **Personal saved-word list** stored locally on the device.
- **Portable Windows build** with automatic update checks against the latest successful `main` build published by GitHub Actions; updates are checksum-verified, staged beside the app folder, and installed after restart.
- **Responsive layout** for desktop, tablet, and mobile.

The app keeps English and Polish meanings separate: when a Polish translation is missing, the card labels the English gloss as a bridge instead of presenting it as Polish. All 11,105 HSK entries now have Polish glosses; the 87 source rows that lacked pinyin or English glosses have also been completed. Twenty-three entries carry review notes for context-sensitive or ambiguous readings.

## 🚀 Installation

### Requirements

- Flutter 3.47.7 (the Windows and web release toolchain)
- Dart 3.13.5 (included with Flutter)
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

- Select a local profile or create a learner/teacher profile. Selecting a learner from the teacher workspace opens that learner's **Notebook and board** directly; all learner work remains associated with that profile.
- Click a line on the notebook page and type directly, without creating or moving a text box. The fixed toolbar above the page formats selected text and controls pinyin and translations, with independent show/hide overrides for a selected range. While typing, small pinyin captions sit above recognized words and short translations below them, without duplicating the sentence. Hover over a caption for the full dictionary entry. Range settings travel with exported lessons and backups. Captions use exact, unambiguous dictionary matches, not automatic full-sentence translation. Only PNG/JPEG pictures have move/resize handles. Private notes remain in a separate collapsed panel outside the page and are hidden in board mode.
- Export individual lesson packages to share with a student. Full backups are different: they can include private student notes and must not be shared as lesson handouts.
- Choose **PL**, **简**, or **繁** in the upper corner. Polish UI studies Chinese; Chinese UI studies Polish.
- Tap the card to reveal pinyin and translations. On a keyboard, use Space/Enter to reveal, Left to skip, Up to mark known, and Right to save for study.
- Select an HSK level to focus the deck. Revisit skipped cards from the deck controls.
- Browse and search the full available vocabulary in **HSK**, filter by level or topic, and open a word to see translations and available Polish forms.
- Use **Practice** for HSK vocabulary questions or sentence-gap exercises. Polish A1–B1 gap exercises are a curated set; Polish vocabulary questions draw from the shared bilingual vocabulary and are not a CEFR placement.
- With **Polish** selected as the learning target, flashcards show the Chinese word first; reveal the card to see its Polish meaning and supporting details.
- Use **Grammar** for reference lessons in both languages. The Polish tab includes 30 sequenced A1–C2 modules, each with examples, a short exercise and answer, and a practical task; it also includes seven-case charts for singular and plural nouns. Detailed Polish paradigms are curated for selected common words, not generated for every dictionary entry.

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
│       ├── build-android.yml        # Manual legacy workflow; Android runner unavailable
│       └── deploy-web.yml           # GitHub Pages deployment
```

## Data Sources and Attribution

- **HSK 2025 word lists:** [krmanik/HSK-3.0](https://github.com/krmanik/HSK-3.0), pinned to commit `182692ce5a11bc30bdc771835d2f0f27491c25de`. The repository declares its HSK word lists under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). HSK 7–9 is a single shared band. The source license and attribution are included in `assets/data/sources/hsk-2025/License.md`.
- **Traditional characters, pinyin, and English glosses:** [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict), distributed under CC BY-SA 4.0. The HSK builder joins dictionary entries by simplified form and prefers a matching legacy reading when available. See the source notice in the app and the builder at `assets/data/scripts/build_hsk_2025_data.py`.
- **Polish glosses:** authored for this application and carried over from matching local translations when the reading agrees. All 11,105 entries have Polish glosses; 23 entries include review notes for context-sensitive or ambiguous senses/readings. Coverage does not imply that every entry has completed manual semantic review. Rebuild complete data with `python assets/data/scripts/build_hsk_2025_data.py`. The builder validates and combines all 21 reviewed translation shards, metadata completions, and per-row `sense_overrides.json` (applied last); it refuses incomplete output. Use `--check` to compare a build in memory with the generated files without replacing them. `merge_hsk_2025_translations.py` is a compatibility entry point for the same complete build; no separate merge step or historical worklist is required.

The current source lists contain 11,105 entries: HSK 1–6 (300, 204, 507, 1,019, 1,638, and 1,815 entries) plus 5,622 entries in HSK 7–9. The levels are the supplied incremental sets, not cumulative totals. The lists themselves provide Chinese words only; pinyin, traditional characters, and English glosses are joined from CC-CEDICT, and Polish glosses are curated for the full vocabulary.

The repository's MIT license applies to application code. Source-derived vocabulary data has its own CC BY-SA 4.0 attribution and share-alike requirements; see `assets/data/sources/hsk-2025/ATTRIBUTION.md`.

The HSK library's localized topic filters use separately curated row-level assignments in `assets/data/sources/hsk-2025/vocabulary_categories.json`. They are checked against each source word and are deliberately independent of legacy tags and parts of speech.

Grammar lessons are localized JSON under `assets/data/grammar_*.json`. Each lesson should include Polish, Simplified Chinese, and Traditional Chinese text, examples, and notes that distinguish rules from common exceptions. Confirm the source and reuse terms for each grammar dataset independently.

Practice exercises are localized in `assets/data/practice_exercises.json`; accepted answer variants are listed explicitly to avoid overly permissive matching. Curated Polish paradigms and example sentences are stored in `assets/data/polish_word_forms.json`. These tables are educational examples for selected entries, not a complete automatic inflection engine.

The Polish course is localized in `assets/data/polish_course.json`; its 30 modules include communication outcomes, grammar guidance, translated examples, a short practice item with an answer and explanation, and an open-ended task. Its progression is informed by the [Council of Europe's CEFR Companion Volume](https://rm.coe.int/common-european-framework-of-reference-for-languages-learning-teaching/16809ea0d4) and the Polish adult certification-exam standards in the [2025 regulation (Dz.U. 2025 poz. 217)](https://dziennikustaw.gov.pl/DU/2025/217). The syllabus is an original learning plan, not an official exam syllabus or a claim of certification readiness; it does not yet include a complete graded workbook, audio course, or exhaustive word-form engine.

The seven-case reference presents nominative through vocative in order, followed by a comparison of singular noun forms. Its staged, example-first presentation is also informed by GLOSSA's [case-teaching article](https://e-polish.eu/sklep/blog/narzednik-na-start/). This is a teaching reference: actual forms depend on gender, number, animacy, stem alternations, and government.

## 🛠️ Technologies

- **Flutter** - UI framework
- **Provider** - State management
- **SQLite** - Local database
- **Shared Preferences** - Preferences storage

## 📄 Building and Releases

### Data continuity

The visible application name is **Polski · 中文**. The existing executable name, package identifiers, Windows version-resource company/product identifiers, and legacy update-data folder remain unchanged deliberately so that renaming does not create an empty application-data namespace. On Windows, profile and preference data remains under `%APPDATA%\com.example\chinese_learning_app`, outside the portable installation folder. Back up profiles before moving between devices; installing a newer ZIP is not itself a data backup.

The classroom is a local document workflow, not a secure multi-user system. Anyone with access to the same application workspace can select its profiles. Shared lesson packages should include only information intended for the recipient; keep full backups private. Dictionary matching works on typed text, not text embedded in images, and ambiguous matches should not be treated as verified translations. Audio and OCR are outside the current scope.

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
