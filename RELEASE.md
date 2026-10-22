# Release Process

## Continuous Windows build

Every successful build of `main` runs `.github/workflows/build-windows.yml`. It creates a portable Windows ZIP and publishes or updates the `windows-latest` prerelease with a SHA-256 update manifest. The app checks this release at startup and in **Settings → App updates**.

Users should extract the ZIP to a folder they can modify without administrator access. When an update is installed, the app closes, stages the new files beside the existing folder, preserves other files in that folder, and restarts. User preferences and saved learning data are stored separately from the application bundle.

## Stable Windows and Android releases

1. Update the version in `pubspec.yaml` and add release notes under `Unreleased` in `CHANGELOG.md`.
2. Merge the release changes into `main` and confirm the Windows build and Pages deployment succeed.
3. Create and push a version tag from the release commit:

   ```powershell
   git tag v1.5.0
   git push origin v1.5.0
   ```

4. GitHub Actions creates a versioned Windows ZIP and Android APK/AAB and attaches them to the GitHub Release.
5. Verify the release assets and the live web app.

Replace `v1.5.0` with the version being released. Do not create a tag before its commit is on `main`.

## GitHub Pages

The `Deploy to GitHub Pages` workflow runs on pushes to `main` and can also be started manually. It builds the web app with the repository base path and deploys it to:

`https://mwojtcz.github.io/chinese-learning-app/`

## Artifacts

- The latest portable Windows build is published at the [`windows-latest` prerelease](https://github.com/mwojtcz/chinese-learning-app/releases/tag/windows-latest).
- Versioned Windows and Android assets are attached to tagged releases.
- Workflow run artifacts are temporary build outputs; use GitHub Releases for downloads intended for users.
