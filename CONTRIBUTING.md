# Contributing

Thank you for helping improve Cíkǎ. Keep repository-facing documentation, commit messages, issue titles, and pull request titles/descriptions in English. User-facing learning content should remain localized.

## Development setup

- Flutter 3.24.5 and Dart 3.5.4 or newer.
- Visual Studio 2022 with the Desktop development with C++ workload for Windows builds.
- Git.

```powershell
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

Run the app on Windows with `flutter run -d windows`. Build the web app with:

```powershell
flutter build web --release --base-href /chinese-learning-app/
```

## Project layout

- `lib/models/`: vocabulary, language, grammar, and course models.
- `lib/providers/`: application and study state.
- `lib/screens/` and `lib/widgets/`: user interface.
- `lib/services/`: platform services, including Windows update handling.
- `assets/data/`: localized course, grammar, exercise, and vocabulary data.
- `test/`: unit and widget tests.
- `.github/workflows/`: Windows builds and releases, Android builds, and Pages deployment.

## Changes and pull requests

1. Create a focused branch and keep changes scoped to one feature or fix.
2. Add or update tests for behavior changes and update related documentation.
3. Run `flutter analyze`, `flutter test`, and `dart format --output=none --set-exit-if-changed .`.
4. Use a concise English Conventional Commit message, such as `feat(updater): add portable Windows updates`.
5. Open a pull request against `main` with an English title and description. Summarize the change and list the checks you ran.

Do not claim a check passed if it was not run. If Flutter is unavailable locally, say so in the pull request and rely on the relevant GitHub Actions build.

## Vocabulary and learning content

- Preserve the existing JSON schema and localization keys when editing data.
- Include Polish, Simplified Chinese, and Traditional Chinese text wherever the model requires all three.
- Add tests or data validation when introducing a new schema or parser rule.
- Keep source attribution and license notices with source-derived data. HSK source files and their CC BY-SA 4.0 terms are documented under `assets/data/sources/hsk-2025/`.
- Do not add API keys, credentials, or unreviewed bulk translations.

## Release automation

- Merging to `main` builds a portable Windows ZIP, updates the `windows-latest` prerelease, and deploys the web app to GitHub Pages.
- Pushing a `v*` tag builds versioned Windows and Android release assets.
- See [RELEASE.md](RELEASE.md) for the release procedure and artifact locations.

## License

By contributing, you agree that your contributions are licensed under the MIT License. Data with separate source licenses remains subject to its own attribution and share-alike terms.
