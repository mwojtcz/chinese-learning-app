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
      version: 4,
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
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE my_words ADD COLUMN sourceWord TEXT');
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
        sourceWord TEXT,
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

    const assets = [
      'assets/data/hsk2025_1_words.json',
      'assets/data/hsk2025_2_words.json',
      'assets/data/hsk2025_3_words.json',
      'assets/data/hsk2025_4_words.json',
      'assets/data/hsk2025_5_words.json',
      'assets/data/hsk2025_6_words.json',
      'assets/data/hsk2025_7_9_words.json',
    ];

    for (final asset in assets) {
      final jsonString = await rootBundle.loadString(asset);
      final jsonList = json.decode(jsonString) as List<dynamic>;
      allWords.addAll(jsonList.map((value) {
        final word = Word.fromJson(value as Map<String, dynamic>);
        if (word.traditional != word.hanzi || word.displayHanzi != word.hanzi) {
          return word;
        }
        return Word(
          hanzi: word.hanzi,
          traditional: ChineseConverterHelper.toTraditional(word.displayHanzi),
          pinyin: word.pinyin,
          englishTranslation: word.englishTranslation,
          polishTranslation: word.polishTranslation,
          level: word.level,
          notes: word.notes,
          tags: word.tags,
          partOfSpeech: word.partOfSpeech,
          frequency: word.frequency,
          sourceWord: word.sourceWord,
        );
      }));
    }

    return allWords;
  }

  // Load words for specific HSK level
  Future<List<Word>> loadWordsByLevel(String level) async {
    final compactLevel = level
        .trim()
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('–', '-');
    final levelKey = compactLevel.startsWith('HSK') &&
            compactLevel.length > 3 &&
            compactLevel[3] != '-'
        ? 'HSK-${compactLevel.substring(3)}'
        : compactLevel;
    final asset = switch (levelKey) {
      'HSK-1' => 'assets/data/hsk2025_1_words.json',
      'HSK-2' => 'assets/data/hsk2025_2_words.json',
      'HSK-3' => 'assets/data/hsk2025_3_words.json',
      'HSK-4' => 'assets/data/hsk2025_4_words.json',
      'HSK-5' => 'assets/data/hsk2025_5_words.json',
      'HSK-6' => 'assets/data/hsk2025_6_words.json',
      'HSK-7-9' => 'assets/data/hsk2025_7_9_words.json',
      _ => throw ArgumentError.value(level, 'level', 'Unknown HSK level'),
    };
    final jsonString = await rootBundle.loadString(asset);
    final jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((value) => Word.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  // Close database
  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      await _database!.close();
    }
  }
}
