import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import '../models/word.dart';
import '../utils/chinese_converter_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static SharedPreferences? _prefs;

  DatabaseHelper._init();

  Future<void> _initPrefs() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDB('my_words.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented to version 3 for traditional Chinese support
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns for version 2
      await db.execute('ALTER TABLE my_words ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE my_words ADD COLUMN partOfSpeech TEXT');
      await db.execute('ALTER TABLE my_words ADD COLUMN frequency INTEGER');
    }
    if (oldVersion < 3) {
      // Add traditional Chinese column for version 3
      await db.execute('ALTER TABLE my_words ADD COLUMN traditional TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE my_words (
        hanzi TEXT PRIMARY KEY,
        traditional TEXT,
        pinyin TEXT NOT NULL,
        english TEXT NOT NULL,
        polish TEXT NOT NULL,
        level TEXT NOT NULL,
        tags TEXT,
        partOfSpeech TEXT,
        frequency INTEGER,
        notes TEXT,
        added_date TEXT NOT NULL
      )
    ''');
  }

  // Add word to "My Words"
  Future<void> addWord(Word word) async {
    if (kIsWeb) {
      await _initPrefs();
      final words = await getMyWords();
      words.add(word);
      final jsonList = words.map((w) => w.toJson()).toList();
      await _prefs!.setString('my_words', json.encode(jsonList));
    } else {
      final db = await database;
      await db.insert(
        'my_words',
        {
          ...word.toMap(),
          'added_date': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Remove word from "My Words"
  Future<void> removeWord(String hanzi) async {
    if (kIsWeb) {
      await _initPrefs();
      final words = await getMyWords();
      words.removeWhere((w) => w.hanzi == hanzi);
      final jsonList = words.map((w) => w.toJson()).toList();
      await _prefs!.setString('my_words', json.encode(jsonList));
    } else {
      final db = await database;
      await db.delete(
        'my_words',
        where: 'hanzi = ?',
        whereArgs: [hanzi],
      );
    }
  }

  // Get all "My Words"
  Future<List<Word>> getMyWords() async {
    if (kIsWeb) {
      await _initPrefs();
      final jsonString = _prefs!.getString('my_words');
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Word.fromJson(json)).toList();
    } else {
      final db = await database;
      final maps = await db.query('my_words');
      return maps.map((map) => Word.fromMap(map)).toList();
    }
  }

  // Check if word is in "My Words"
  Future<bool> isWordLearned(String hanzi) async {
    if (kIsWeb) {
      final words = await getMyWords();
      return words.any((w) => w.hanzi == hanzi);
    } else {
      final db = await database;
      final result = await db.query(
        'my_words',
        where: 'hanzi = ?',
        whereArgs: [hanzi],
      );
      return result.isNotEmpty;
    }
  }

  // Get count of learned words by level
  Future<Map<String, int>> getLearnedCountByLevel() async {
    final words = await getMyWords();
    final Map<String, int> counts = {};
    
    for (var word in words) {
      counts[word.level] = (counts[word.level] ?? 0) + 1;
    }
    
    return counts;
  }

  // Load all words from separate HSK level files
  Future<List<Word>> loadAllWords() async {
    final List<Word> allWords = [];
    
    // Lista plików dla każdego poziomu HSK
    final levels = ['hsk1', 'hsk2', 'hsk3'];
    
    for (final level in levels) {
      try {
        final String jsonString = await rootBundle.loadString('assets/data/${level}_words.json');
        final List<dynamic> jsonList = json.decode(jsonString);
        final words = jsonList.map((json) {
          final word = Word.fromJson(json);
          // Auto-convert to traditional if not already set
          if (word.traditional == word.hanzi) {
            return Word(
              hanzi: word.hanzi,
              traditional: ChineseConverterHelper.toTraditional(word.hanzi),
              pinyin: word.pinyin,
              englishTranslation: word.englishTranslation,
              polishTranslation: word.polishTranslation,
              level: word.level,
              notes: word.notes,
              tags: word.tags,
              partOfSpeech: word.partOfSpeech,
              frequency: word.frequency,
            );
          }
          return word;
        }).toList();
        allWords.addAll(words);
      } catch (e) {
        print('Error loading $level: $e');
      }
    }
    
    return allWords;
  }

  // Load words for specific HSK level
  Future<List<Word>> loadWordsByLevel(String level) async {
    try {
      final levelKey = level.toLowerCase().replaceAll('-', '');
      final String jsonString = await rootBundle.loadString('assets/data/${levelKey}_words.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Word.fromJson(json)).toList();
    } catch (e) {
      print('Error loading $level: $e');
      return [];
    }
  }

  // Close database
  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      await _database!.close();
    }
  }
}
