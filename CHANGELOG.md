# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### To Be Added
- Grouping words by tags in Dictionary view
- Footer with thanks (PL/EN/CN) and feedback link
- Spaced Repetition System (SRS)
- Audio pronunciation recordings
- HSK 5-6 vocabulary (2,211 additional words)

## [1.2.0] - 2025-12-19

### Added
- **HSK 4 Complete Vocabulary** - 1,000 new words with full translations
- **Total Vocabulary Expansion** - Now 3,229 words (HSK 1-4)
- **Improved Traditional Chinese** - OpenCC library for 100% accurate 简体→繁體 conversion
  - Updated all HSK 1-3 traditional forms (1,745 unique traditional characters)
  - Professional-grade conversion replacing custom mapping
- **Complete Polish Translations** - DeepL API integration
  - HSK 3: 966 words translated to Polish
  - HSK 4: 1,000 words translated to Polish
  - High-quality contextual translations
- **Web Scraping Tools** - Automated HSK vocabulary acquisition from mandarinbean.com
- **Translation Scripts** - Python automation for batch translations

### Changed
- Database now loads HSK 1-4 (previously HSK 1-3)
- Traditional Chinese conversion quality improved from ~22% to 54% coverage
- All vocabulary now includes 4 complete languages: 简体字, 繁體字, English, Polski

### Technical
- Added OpenCC Python library for traditional Chinese conversion
- Integrated DeepL API for professional-grade translations (used 15% of free tier)
- Created scraping scripts for HSK vocabulary extraction
- Updated `database_helper.dart` to include HSK 4
- Updated `pubspec.yaml` assets to include `hsk4_words.json`

## [1.1.0] - 2025-12-18

### Added
- **ChineseFlow** - New application name and branding
- Settings tab with emoji animation toggle and issue reporting
- Animated falling Chinese emojis (14 types: 🏮🎋🧧🎁🎊🥠🎆🧨🐉🌸🎐🍜🥟🍵)
- Minimum window size (800x600px) for desktop version
- Burgundy gradient AppBar with white bottom shadow
- Loading indicator with progress percentage in Dictionary tab
- Async initialization ensures vocabulary loads before UI renders
- Database schema version 2 with tags, partOfSpeech, and frequency columns
- Wrap widget for tags to prevent overflow on narrow screens

### Changed
- Unified HSK filter chip styling across Dictionary and My Words tabs
- Enhanced tag and part of speech styling with borders and shadows
- Improved tab label visibility with gold color for active tabs
- Centered ChineseFlow title in AppBar
- Enhanced contrast for HSK filter buttons
- Database column naming convention to camelCase

### Fixed
- Words not loading immediately in Dictionary tab - now loads on app start
- Window resize overflow issues in word cards
- HSK filter buttons low contrast in My Words tab
- Database initialization errors on Windows platform
- Inconsistent styling between tags and part of speech labels
- SQL errors when adding words to "My Words" (missing database columns)
- Tag layout overflow with Row replaced by Wrap widget

## [1.0.1] - 2025-12-18

### Added
- 763 Polish translations for HSK-2 vocabulary
- Custom issue templates (bug report, feature request)
- English documentation (README, CONTRIBUTING, RELEASE)

### Fixed
- GitHub Actions permissions for automated releases

### Changed
- All project documentation translated to English

## [1.0.0] - 2025-12-18

### Added
- Initial release
- 2,229 HSK 3.0 words (levels 1-3)
- 3 test modes (Hanzi→Translation, Translation→Hanzi, Pinyin→Hanzi)
- Dictionary with advanced filtering
- My Words collection
- Dark theme with matte design
- Responsive grid layout (1-3 columns)
- Auto-tagging system
- Auto-save correct answers to My Words
- Windows portable application
- Web version (GitHub Pages)

[Unreleased]: https://github.com/mwojtcz/chinese-learning-app/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/mwojtcz/chinese-learning-app/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/mwojtcz/chinese-learning-app/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/mwojtcz/chinese-learning-app/releases/tag/v1.0.0
