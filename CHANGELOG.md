# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Loading indicator with progress percentage in Dictionary tab
- Async initialization ensures vocabulary loads before UI renders

### Fixed
- Words not loading immediately in Dictionary tab - now loads on app start
- Loading progress shows 0-100% with animated circular indicator

### To Be Added
- Grouping words by tags in Dictionary view
- Footer with thanks (PL/EN/CN) and feedback link
- Chinese-themed color scheme (dark + red)
- Improved tag visibility on word cards
- Spaced Repetition System (SRS)
- HSK-3 Polish translations
- Audio pronunciation recordings

### To Be Fixed
- HSK filter buttons low contrast in My Words tab
- No minimum window width in desktop version

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

[Unreleased]: https://github.com/mwojtcz/chinese-learning-app/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/mwojtcz/chinese-learning-app/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/mwojtcz/chinese-learning-app/releases/tag/v1.0.0
