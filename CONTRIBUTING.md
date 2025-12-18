# Contributing to Chinese Learning App

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## 🚀 Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/chinese-learning-app.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit: `git commit -m "feat: add your feature"`
7. Push: `git push origin feature/your-feature-name`
8. Open a Pull Request

## 📋 Development Setup

### Prerequisites

- Flutter 3.24.5+ ([install guide](https://flutter.dev/docs/get-started/install))
- Dart 3.5.4+
- Visual Studio 2022 (for Windows builds)
- Git

### Initial Setup

```bash
# Clone repository
git clone https://github.com/mwojtcz/chinese-learning-app.git
cd chinese-learning-app

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run application
flutter run -d windows
```

## 🎯 Areas for Contribution

### High Priority

- [ ] **HSK-3 Polish translations** (966 words)
- [ ] **Spaced Repetition System (SRS)** implementation
- [ ] **Audio pronunciation** for words
- [ ] **Progress statistics** and analytics
- [ ] **Export/Import** word lists

### Medium Priority

- [ ] Additional test modes
- [ ] Flashcard study mode
- [ ] Custom word lists
- [ ] Theme customization
- [ ] Mobile (Android/iOS) support

### Low Priority

- [ ] More languages support
- [ ] Dark/Light theme toggle
- [ ] Keyboard shortcuts
- [ ] Accessibility improvements

## 📝 Code Standards

### Flutter/Dart Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` before committing
- Format code with `dart format .`
- Maximum line length: 120 characters

### File Organization

```
lib/
├── models/          # Data models only
├── providers/       # State management (Provider pattern)
├── widgets/         # Reusable UI components
├── database/        # Database layer
└── main.dart        # App entry point
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`

### Example Code

```dart
// Good
class WordProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Future<void> addWord(Word word) async {
    await _dbHelper.insertWord(word);
    notifyListeners();
  }
}

// Bad
class word_provider extends ChangeNotifier {
  var db_helper = DatabaseHelper();
  
  add_word(word) {
    db_helper.insert_word(word);
    notifyListeners();
  }
}
```

## 🧪 Testing

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/models/word_test.dart

# With coverage
flutter test --coverage
```

### Test Requirements

- All new features must include tests
- Maintain >80% code coverage
- Test edge cases and error conditions

## 📦 Commit Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add spaced repetition algorithm
fix: correct pinyin tone display
docs: update README installation steps
style: format code with dart format
refactor: simplify word provider logic
test: add tests for test provider
chore: update dependencies
```

### Commit Message Structure

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Example:**

```
feat(test): add difficulty-based question selection

- Implement algorithm to select questions based on user performance
- Add difficulty tracking to Word model
- Update test UI to show difficulty indicators

Closes #42
```

## 🔍 Pull Request Process

1. **Update Documentation** - README, code comments, etc.
2. **Add Tests** - Ensure new code is tested
3. **Run Quality Checks**:
   ```bash
   flutter analyze
   flutter test
   dart format . --set-exit-if-changed
   ```
4. **Update CHANGELOG** (if applicable)
5. **Fill PR Template** - Describe changes, testing done
6. **Request Review** - Tag maintainers

### PR Title Format

```
feat: Add spaced repetition system
fix: Resolve HSK-2 translation encoding issue
docs: Update contribution guidelines
```

## 📊 Adding Vocabulary Data

### File Format

All vocabulary files follow this JSON structure:

```json
[
  {
    "hanzi": "你好",
    "pinyin": "nǐ hǎo",
    "english": "hello, hi",
    "polish": "cześć, witaj",
    "level": "HSK-1",
    "notes": "",
    "tags": ["Greetings"],
    "partOfSpeech": "greeting",
    "frequency": 1
  }
]
```

### Translation Scripts

Located in `assets/data/scripts/`:

```bash
# Add Polish translations
python scripts/translate_hsk3.py

# Validate JSON structure
python scripts/validate_vocab.py

# Check word counts
python scripts/check_counts.py
```

## 🐛 Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md):

1. **Clear title** - Describe the issue briefly
2. **Steps to reproduce** - Exact steps to trigger bug
3. **Expected behavior** - What should happen
4. **Actual behavior** - What actually happens
5. **Environment** - OS, Flutter version, etc.
6. **Screenshots** - If applicable

## 💡 Requesting Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md):

1. **Problem description** - What problem does this solve?
2. **Proposed solution** - How should it work?
3. **Alternatives** - Other approaches considered
4. **Additional context** - Mockups, examples, etc.

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Questions?

- Open an [issue](https://github.com/mwojtcz/chinese-learning-app/issues)
- Tag maintainers in discussions
- Be respectful and constructive

---

**Thank you for contributing! 加油! (jiā yóu!)** 🇨🇳
