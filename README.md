# Chinese Learning App (HSK 3.0)

Aplikacja do nauki języka chińskiego zgodna ze standardem HSK 3.0 (GF0025-2021).

## ✨ Funkcje

- 📚 **Słownik HSK 3.0** - 2,229 słów z poziomów 1-3
  - HSK Band 1: 500 słów
  - HSK Band 2: 763 słowa
  - HSK Band 3: 966 słów
  
- 🎯 **System Testów**
  - Wielokrotny wybór
  - Pisanie z klawiatury
  - Fiszki (flashcards)
  - Automatyczne dodawanie słów do "Moje Słowa"
  
- 🔍 **Zaawansowane Filtrowanie**
  - Według poziomu HSK
  - Według kategorii/tagów
  - Według części mowy
  - Wyszukiwanie pełnotekstowe
  
- 🌙 **Dark Mode** - elegancki, matowy interfejs przyjazny dla oczu
- 📱 **Responsywny Design** - grid layout z dużymi znakami chińskimi

## 🚀 Instalacja

### Windows

1. Pobierz najnowszy instalator z [Releases](https://github.com/mwojtcz/chinese_learning_app/releases)
2. Uruchom `ChineseLearningApp-Setup-1.0.0.exe`
3. Postępuj zgodnie z instrukcjami instalatora

### Web

Aplikacja dostępna online: [https://mwojtcz.github.io/chinese_learning_app](https://mwojtcz.github.io/chinese_learning_app)

## 🛠️ Rozwój

### Wymagania

- Flutter 3.24.5 lub nowszy
- Dart 3.5.4 lub nowszy
- Visual Studio 2022 z "Desktop development with C++" (tylko dla Windows build)

### Uruchomienie w trybie deweloperskim

```bash
# Klonowanie repozytorium
git clone https://github.com/mwojtcz/chinese_learning_app.git
cd chinese_learning_app

# Instalacja zależności
flutter pub get

# Uruchomienie na Windows
flutter run -d windows

# Uruchomienie w przeglądarce
flutter run -d chrome
```

### Budowanie

```bash
# Windows (wymaga środowiska bez polskich znaków w ścieżce)
flutter build windows --release

# Web
flutter build web --release
```

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
│       ├── hsk1_words.json
│       ├── hsk2_words.json
│       └── hsk3_words.json
├── .github/
│   └── workflows/
│       └── build-windows.yml        # CI/CD - automatyczne budowanie
└── installer/
    └── setup.iss                    # Inno Setup script
```

## 📊 Źródła Danych

Słownictwo HSK 3.0 pochodzi z oficjalnego standardu Ministerstwa Edukacji Chin (GF0025-2021):
- [krmanik/HSK-3.0](https://github.com/krmanik/HSK-3.0) - OCR oficjalnego PDF

## 🔄 Budowanie i Releases

Ze względu na problemy z polskimi znakami w ścieżce użytkownika Windows, budowanie odbywa się automatycznie przez GitHub Actions:

1. Utwórz tag w git: `git tag v1.0.0`
2. Wypchnij tag: `git push origin v1.0.0`
3. GitHub Actions automatycznie zbuduje aplikację Windows
4. Instalator pojawi się w sekcji Releases

### Roadmap

- [ ] Dodanie polskich tłumaczeń dla HSK-2 i HSK-3
- [ ] System powtórek oparty na Spaced Repetition (SRS)
- [ ] Eksport/import własnych list słów
- [ ] Statystyki postępów w nauce
- [ ] Nagrania audio wymowy (pinyin)
- [ ] Auto-update mechanism

## 📝 Licencja

MIT License

## 🤝 Współpraca

Pull requesty są mile widziane! W przypadku większych zmian, proszę najpierw otworzyć issue aby przedyskutować proponowane zmiany.

## 📧 Kontakt

Masz pytania lub sugestie? Otwórz [issue](https://github.com/mwojtcz/chinese_learning_app/issues)!

---

**Dobrej nauki chińskiego! 加油！(jiā yóu!)** 🇨🇳
