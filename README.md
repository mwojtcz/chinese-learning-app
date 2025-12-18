# 🇨🇳 ChineseFlow

**Master Chinese with flow.** A modern Chinese language learning application based on the official HSK 3.0 Standard (2021) from China's Ministry of Education.

![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue)
![Dart](https://img.shields.io/badge/Dart-3.5.4-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌐 Live Demo

**[➡️ Try the app online](https://mwojtcz.github.io/chinese-learning-app/)** (web version)

Or download the Windows application from [Releases](https://github.com/mwojtcz/chinese-learning-app/releases).

## ✨ Features

- 📚 **HSK Dictionary** - 2,229 words from HSK levels 1-3 (standard 3.0)
- ⭐ **My Words** - Save favorite words for studying
- 📝 **Test System** - 3 testing modes:
  - 🇨🇳 → 🇬🇧 (Hanzi → English/Polish)
  - 🇬🇧 → 🇨🇳 (English/Polish → Hanzi)
  - 🔤 → 🇨🇳 (Pinyin → Hanzi)
- 🎨 **Dark Theme** - Elegant interface with matte design
- 🔍 **Advanced Search** - Filter by HSK level, parts of speech, and tags
- 📊 **Auto-Tagging** - Intelligent word categorization
- 💾 **Auto-Save** - Correct answers automatically added to "My Words"

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

Download the latest version from [Releases](https://github.com/mwojtcz/chinese-learning-app/releases):
- Extract the ZIP archive
- Run `chinese_learning_app.exe`
- No installation required - portable!

## 📖 How to Use

### Dictionary
- Browse all 2,229 HSK 1-3 words
- Filter by level (HSK-1, HSK-2, HSK-3)
- Search by hanzi, pinyin, or translation
- Click a word to add to "My Words"

### My Words
- View saved words
- All filtering features as in Dictionary
- Remove words with one click

### Test
1. Choose test mode
2. Select HSK level
3. Set number of questions (5-50)
4. Check "Only from My Words" (optional)
5. Start test!
6. Correct answers are automatically added to "My Words"

## 📁 Project Structure

```
chinese_learning_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Data models
│   │   ├── word.dart
│   │   └── test_config.dart
│   ├── providers/                   # State management
│   │   ├── word_provider.dart
│   │   └── test_provider.dart
│   ├── database/                    # Database handling
│   │   └── database_helper.dart
│   └── widgets/                     # UI components
│       ├── dictionary_tab.dart
│       ├── my_words_tab.dart
│       └── test_tab.dart
├── assets/
│   └── data/                        # HSK vocabulary
│       ├── hsk1_words.json          # 500 words (with Polish)
│       ├── hsk2_words.json          # 763 words (with Polish)
│       └── hsk3_words.json          # 966 words (English only)
├── .github/
│   └── workflows/
│       └── build-windows.yml        # CI/CD - automated builds
└── releases/
    └── ChineseLearningApp-v1.0.0-Windows.zip
```

## 📊 Data Sources

HSK 3.0 vocabulary sourced from the official Ministry of Education of China standard (GF0025-2021):
- [krmanik/HSK-3.0](https://github.com/krmanik/HSK-3.0) - OCR of official PDF standard

**HSK 3.0 Levels:**
- **HSK-1**: 500 words (基础 - basic)
- **HSK-2**: 763 words (提高 - intermediate)  
- **HSK-3**: 966 words (进阶 - advanced)
- **Total**: 2,229 words

## 🛠️ Technologies

- **Flutter** - UI framework
- **Provider** - State management
- **SQLite** - Local database
- **Shared Preferences** - Preferences storage

## 📄 Building and Releases

### Pre-built Windows Application

Easiest option: download ZIP from [Releases](https://github.com/mwojtcz/chinese-learning-app/releases)!

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

- [x] HSK-2 Polish translations
- [ ] HSK-3 Polish translations
- [ ] Spaced Repetition System (SRS)
- [ ] Export/import word lists
- [ ] Learning progress statistics
- [ ] Audio pronunciation recordings (pinyin)
- [ ] Auto-update mechanism

## 📝 License

MIT License - see [LICENSE](LICENSE)

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an [issue](https://github.com/mwojtcz/chinese-learning-app/issues) first to discuss proposed changes.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📧 Contact

Have questions or suggestions? Open an [issue](https://github.com/mwojtcz/chinese-learning-app/issues)!

---

**Happy Chinese learning! 加油! (jiā yóu!)** 🇨🇳
