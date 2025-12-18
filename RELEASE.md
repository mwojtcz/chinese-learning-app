# Jak przygotować release

## 1. Aktualizacja wersji

Edytuj `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Zwiększ numer wersji
```

## 2. Aktualizacja skryptu instalatora

Edytuj `installer/setup.iss`:
```iss
#define MyAppVersion "1.0.1"
```

## 3. Commit i tag

```bash
git add .
git commit -m "Release v1.0.1"
git tag v1.0.1
git push origin main
git push origin v1.0.1
```

## 4. GitHub Actions

GitHub Actions automatycznie:
- Zbuduje aplikację Windows
- Utworzy archiwum ZIP
- Opublikuje w sekcji Releases

## 5. Utworzenie instalatora (opcjonalne, lokalnie)

Jeśli masz zainstalowany Inno Setup:

1. Pobierz build z GitHub Actions
2. Rozpakuj do `build/windows/x64/runner/Release/`
3. Uruchom Inno Setup Compiler
4. Otwórz `installer/setup.iss`
5. Kliknij "Compile"
6. Instalator pojawi się w folderze `installer/Output/`

## Uwagi

- GitHub Actions buduje na czystym środowisku Windows (bez polskich znaków)
- Lokalne budowanie wymaga ścieżki bez polskich znaków
- Każdy release powinien mieć unikalny tag wersji
