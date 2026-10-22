# Release Process

## Continuous Windows build

Every successful build of `main` runs `.github/workflows/build-windows.yml`. It creates a portable Windows ZIP and publishes or updates the `windows-latest` prerelease with a SHA-256 update manifest. The app checks this release at startup and in **Settings → App updates**.

Users should extract the ZIP to a folder they can modify without administrator access. When an update is installed, the app closes, stages the new files beside the existing folder, preserves other files in that folder, and restarts. User preferences and saved learning data are stored separately from the application bundle.

## Stable Windows releases

1. Update the version in `pubspec.yaml` and add release notes under `Unreleased` in `CHANGELOG.md`.
2. Merge the release changes into `main` and confirm the Windows build and Pages deployment succeed.
3. Create and push a version tag from the release commit:

   ```powershell
   git tag v1.5.0
   git push origin v1.5.0
   ```

4. GitHub Actions creates a versioned Windows ZIP and attaches it to the GitHub Release.
5. Verify the release assets and the live web app.

Replace `v1.5.0` with the version being released. Do not create a tag before its commit is on `main`.

Android distribution is currently unavailable: this repository does not contain a supported Android runner project. The legacy Android workflow must not be described as a working release target until that project is restored and built successfully.

## Data migration and updates

Before installation, flush pending learning and classroom writes and create a local recovery snapshot. Preserve existing platform identifiers when changing the display brand. Check migration from legacy saved words, profile switching, backup restore, and repeat lesson imports before publishing changes to persistence.

On Windows, `path_provider_windows` derives the preference directory from `CompanyName` and `ProductName` in `windows/runner/Runner.rc`. Keep these at `com.example` and `chinese_learning_app`; change the window title and file description for display branding instead.

The automatic local snapshot is a recovery aid, not an off-device backup. Encourage users to export a private backup before moving to another computer. Do not share full backups as lesson packages because they may contain private teacher notes.

Full backup files have a 32 MiB import/export limit. If embedded lesson images take the workspace beyond that limit, full export reports an error rather than producing an unrestorable file; export image-heavy lessons separately. Local recovery snapshots remain subject to the capacity of the device's preference storage, especially browser storage.

## GitHub Pages

The `Deploy to GitHub Pages` workflow runs on pushes to `main` and can also be started manually. It builds the web app with the repository base path and deploys it to:

`https://mwojtcz.github.io/chinese-learning-app/`

## Artifacts

- The latest portable Windows build is published at the [`windows-latest` prerelease](https://github.com/mwojtcz/chinese-learning-app/releases/tag/windows-latest).
- Versioned Windows assets are attached to tagged releases.
- Workflow run artifacts are temporary build outputs; use GitHub Releases for downloads intended for users.
