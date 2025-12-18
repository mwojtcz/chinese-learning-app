# Release Process

## 1. Update Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment version number
```

## 2. Update Installer Script

Edit `installer/setup.iss`:
```iss
#define MyAppVersion "1.0.1"
```

## 3. Commit and Tag

```bash
git add .
git commit -m "Release v1.0.1"
git tag v1.0.1
git push origin main
git push origin v1.0.1
```

## 4. GitHub Actions

GitHub Actions will automatically:
- Build the Windows application
- Create a ZIP archive
- Publish to the Releases section

## 5. Create Installer (Optional, Local)

If you have Inno Setup installed:

1. Download the build from GitHub Actions
2. Extract to `build/windows/x64/runner/Release/`
3. Run Inno Setup Compiler
4. Open `installer/setup.iss`
5. Click "Compile"
6. Installer will appear in `installer/Output/`

## Notes

- GitHub Actions builds in a clean Windows environment (no Polish characters in path)
- Local building requires a path without Polish characters
- Each release should have a unique version tag
