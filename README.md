# 🇨🇳 Chinese Learning App

Aplikacja do nauki języka chińskiego oparta na standardzie HSK 3.0 (2021) od Ministerstwa Edukacji Chin.

![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue)
![Dart](https://img.shields.io/badge/Dart-3.5.4-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Funkcje

- 📚 **Słownik HSK** - 2,229 słów z poziomów HSK 1-3 (standard 3.0)
- ⭐ **Moje Słowa** - Zapisuj ulubione słówka do nauki
- 📝 **System Testów** - 3 tryby testowania:
  - 🇨🇳 → 🇵🇱 (Hanzi → Polski)
  - 🇵🇱 → 🇨🇳 (Polski → Hanzi)
  - 🔤 → 🇨🇳 (Pinyin → Hanzi)
- 🎨 **Ciemny Motyw** - Elegancki interfejs z matowym designem
- 🔍 **Zaawansowane Wyszukiwanie** - Filtrowanie po poziomie HSK, częściach mowy i znacznikach
- 📊 **Automatyczne Tagowanie** - Inteligentne kategoryzowanie słówek
- 💾 **Automatyczny Zapis** - Poprawne odpowiedzi dodawane do "Moich Słów"

## 🚀 Instalacja

### Wymagania

- Flutter 3.24.5 lub nowszy
- Dart 3.5.4 lub nowszy
- Windows 10/11 (dla kompilacji Windows)

### Uruchomienie

```bash
# Sklonuj repozytorium
git clone https://github.com/mwojtcz/chinese-learning-app.git
cd chinese-learning-app

# Zainstaluj zależności
flutter pub get

# Uruchom aplikację
flutter run -d windows
```

### Pobranie Gotowej Aplikacji

Pobierz najnowszą wersję z sekcji [Releases](https://github.com/mwojtcz/chinese-learning-app/releases):
- Rozpakuj archiwum ZIP
- Uruchom `chinese_learning_app.exe`
- Nie wymaga instalacji - portable!

## 📖 Jak Używać

### Słownik
- Przeglądaj wszystkie 2,229 słów HSK 1-3
- Filtruj po poziomie (HSK-1, HSK-2, HSK-3)
- Wyszukuj po hanzi, pinyin lub tłumaczeniu
- Kliknij słowo aby dodać do "Moich Słów"

### Moje Słowa
- Przeglądaj zapisane słówka
- Wszystkie funkcje filtrowania jak w Słowniku
- Usuń słowa jednym kliknięciem

### Test
1. Wybierz tryb testu
2. Wybierz poziom HSK
3. Ustaw liczbę pytań (5-50)
4. Zaznacz "Tylko z Moich Słów" (opcjonalnie)
5. Rozpocznij test!
6. Poprawne odpowiedzi automatycznie trafiają do "Moich Słów"

## 📁 Struktura Projektu

```
chinese_learning_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Modele danych
│   │   ├── word.dart
│   │   └── test_config.dart
│   ├── providers/                   # State management
│   │   ├── word_provider.dart
│   │   └── test_provider.dart
│   ├── database/                    # Obsługa bazy danych
│   │   └── database_helper.dart
│   └── widgets/                     # Komponenty UI
│       ├── dictionary_tab.dart
│       ├── my_words_tab.dart
│       └── test_tab.dart
├── assets/
│   └── data/                        # Słownictwo HSK
│       ├── hsk1_words.json          # 500 słów
│       ├── hsk2_words.json          # 763 słowa
│       └── hsk3_words.json          # 966 słów
├── .github/
│   └── workflows/
│       └── build-windows.yml        # CI/CD - automatyczne budowanie
└── releases/
    └── ChineseLearningApp-v1.0.0-Windows.zip
```

## 📊 Źródła Danych

Słownictwo HSK 3.0 pochodzi z oficjalnego standardu Ministerstwa Edukacji Chin (GF0025-2021):
- [krmanik/HSK-3.0](https://github.com/krmanik/HSK-3.0) - OCR oficjalnego PDF standardu

**Poziomy HSK 3.0:**
- **HSK-1**: 500 słów (基础 - podstawowy)
- **HSK-2**: 763 słowa (提高 - średniozaawansowany)  
- **HSK-3**: 966 słów (进阶 - zaawansowany)
- **Łącznie**: 2,229 słów

## 🛠️ Technologie

- **Flutter** - Framework UI
- **Provider** - State management
- **SQLite** - Lokalna baza danych
- **Shared Preferences** - Przechowywanie preferencji

## 📄 Budowanie i Releases

### Gotowa Aplikacja Windows

Najprościej: pobierz ZIP z [Releases](https://github.com/mwojtcz/chinese-learning-app/releases)!

### Kompilacja Ręczna

```bash
# Windows
flutter build windows --release

# Executable w: build/windows/x64/runner/Release/
```

**Uwaga**: Ze względu na problemy z polskimi znakami w ścieżce Windows, zalecane jest budowanie w ścieżce bez znaków specjalnych (np. `C:\build_temp\`).

### Roadmap

- [ ] Dodanie polskich tłumaczeń dla HSK-2 i HSK-3
- [ ] System powtórek oparty na Spaced Repetition (SRS)
- [ ] Eksport/import własnych list słów
- [ ] Statystyki postępów w nauce
- [ ] Nagrania audio wymowy (pinyin)
- [ ] Mechanizm auto-update

## 📝 Licencja

MIT License - zobacz [LICENSE](LICENSE)

## 🤝 Współpraca

Pull requesty są mile widziane! W przypadku większych zmian, proszę najpierw otworzyć [issue](https://github.com/mwojtcz/chinese-learning-app/issues) aby przedyskutować proponowane zmiany.

Zobacz [CONTRIBUTING.md](CONTRIBUTING.md) dla szczegółów.

## 📧 Kontakt

Masz pytania lub sugestie? Otwórz [issue](https://github.com/mwojtcz/chinese-learning-app/issues)!

---

**Dobrej nauki chińskiego! 加油! (jiā yóu!)** 🇨🇳
