import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../database/database_helper.dart';

enum StudyDecision { saved, known, skipped }

class WordProvider with ChangeNotifier {
  List<Word> _allWords = [];
  List<Word> _myWords = [];
  final Map<String, StudyDecision> _studyDecisions = {};
  String _selectedLevel = 'Wszystkie';
  String _searchQuery = '';
  String _selectedTag = 'Wszystkie';
  String _selectedPartOfSpeech = 'Wszystkie';
  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Loading state
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  
  // Cache dla filteredWords
  List<Word>? _cachedFilteredWords;
  String _lastFilterState = '';
  
  // Liczniki słów per poziom
  Map<String, int> _levelCounts = {};

  List<Word> get allWords => _allWords;
  List<Word> get myWords => _myWords;
  int get learnedWordsCount => _studyDecisions.values
      .where((decision) => decision == StudyDecision.known)
      .length;
  int get savedForStudyCount => _studyDecisions.values
      .where((decision) => decision == StudyDecision.saved)
      .length;
  String get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;
  String get selectedTag => _selectedTag;
  String get selectedPartOfSpeech => _selectedPartOfSpeech;
  bool get isLoading => _isLoading;
  double get loadingProgress => _loadingProgress;

  // Get available HSK levels
  List<String> get availableLevels {
    final levels = _allWords.map((w) => w.level).toSet().toList();
    levels.sort((a, b) {
      int rank(String level) => switch (level) {
            'HSK-7-9' => 7,
            _ => int.tryParse(level.replaceFirst('HSK-', '')) ?? 99,
          };
      return rank(a).compareTo(rank(b));
    });
    return ['Wszystkie', ...levels];
  }
  
  // Get word count for specific level
  int getLevelWordCount(String level) {
    if (level == 'Wszystkie') return _allWords.length;
    return _levelCounts[level] ?? 0;
  }

  // Get available tags
  List<String> get availableTags {
    final tags = <String>{};
    for (var word in _allWords) {
      tags.addAll(word.tags);
    }
    final tagList = tags.toList()..sort();
    return ['Wszystkie', ...tagList];
  }

  // Get available parts of speech
  List<String> get availablePartsOfSpeech {
    final pos = _allWords
        .map((w) => w.partOfSpeech)
        .where((p) => p != null)
        .cast<String>()
        .toSet()
        .toList();
    pos.sort();
    return ['Wszystkie', ...pos];
  }

  // Get filtered words for dictionary view
  List<Word> get filteredWords {
    // Check if cache is valid
    final currentState = '$_selectedLevel|$_selectedTag|$_selectedPartOfSpeech|$_searchQuery';
    if (_cachedFilteredWords != null && _lastFilterState == currentState) {
      return _cachedFilteredWords!;
    }
    
    var words = _allWords;

    // Filter by level
    if (_selectedLevel != 'Wszystkie') {
      words = words.where((w) => w.level == _selectedLevel).toList();
    }

    // Filter by tag
    if (_selectedTag != 'Wszystkie') {
      words = words.where((w) => w.tags.contains(_selectedTag)).toList();
    }

    // Filter by part of speech
    if (_selectedPartOfSpeech != 'Wszystkie') {
      words = words.where((w) => w.partOfSpeech == _selectedPartOfSpeech).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final normalizedQuery = Word.normalizePinyin(query);
      
      words = words.where((w) {
        return w.displayHanzi.toLowerCase().contains(query) ||
               w.hanzi.toLowerCase().contains(query) ||
               w.pinyin.toLowerCase().contains(query) ||
               Word.normalizePinyin(w.pinyin).contains(normalizedQuery) ||
               w.englishTranslation.toLowerCase().contains(query) ||
               w.polishTranslation.toLowerCase().contains(query);
      }).toList();
    }

    // Update cache
    _cachedFilteredWords = words;
    _lastFilterState = currentState;
    
    return words;
  }

  // Get filtered "my words"
  List<Word> get filteredMyWords {
    var words = _myWords;

    if (_selectedLevel != 'Wszystkie') {
      words = words.where((w) => w.level == _selectedLevel).toList();
    }

    return words;
  }

  // Get progress statistics
  Map<String, dynamic> get progressStats {
    if (_selectedLevel == 'Wszystkie') {
      return {
        'learned': _myWords.length,
        'total': _allWords.length,
        'percentage': _allWords.isEmpty 
            ? 0.0 
            : (_myWords.length / _allWords.length * 100),
      };
    } else {
      final totalInLevel = _allWords.where((w) => w.level == _selectedLevel).length;
      final learnedInLevel = _myWords.where((w) => w.level == _selectedLevel).length;
      
      return {
        'learned': learnedInLevel,
        'total': totalInLevel,
        'percentage': totalInLevel == 0 
            ? 0.0 
            : (learnedInLevel / totalInLevel * 100),
      };
    }
  }

  // Initialize data
  Future<void> loadData() async {
    _isLoading = true;
    _loadingProgress = 0.0;
    notifyListeners();
    
    // Load main vocabulary first (most important)
    await _loadAllWords();
    _loadingProgress = 0.5;
    notifyListeners();
    
    // Load "my words" (completes loading)
    await _loadMyWords();
    await _loadStudyDecisions();
    _loadingProgress = 1.0;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadStudyDecisions() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString('study_decisions');
    if (stored == null) return;

    final decoded = json.decode(stored) as Map<String, dynamic>;
    _studyDecisions.clear();
    for (final entry in decoded.entries) {
      if (entry.value is! String) continue;
      for (final decision in StudyDecision.values) {
        if (decision.name == entry.value) {
          _studyDecisions[entry.key] = decision;
          break;
        }
      }
    }
  }

  // Load all words from JSON
  Future<void> _loadAllWords() async {
    try {
      _allWords = await _dbHelper.loadAllWords();
      
      // Oblicz liczniki per poziom
      _levelCounts.clear();
      for (var word in _allWords) {
        _levelCounts[word.level] = (_levelCounts[word.level] ?? 0) + 1;
      }
      
      _cachedFilteredWords = null;
    } catch (e) {
      debugPrint('Error loading words: $e');
      _allWords = [];
    }
  }

  // Load "my words" from database
  Future<void> _loadMyWords() async {
    try {
      _myWords = await _dbHelper.getMyWords().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Warning: getMyWords() timeout, returning empty list');
          return [];
        },
      );
    } catch (e) {
      debugPrint('Error loading my words: $e');
      _myWords = [];
    }
  }

  // Add word to "my words"
  Future<void> addToMyWords(Word word) async {
    await _dbHelper.addWord(word);
    await _loadMyWords();
    notifyListeners();
  }

  // Remove word from "my words"
  Future<void> removeFromMyWords(String hanzi) async {
    await _dbHelper.removeWord(hanzi);
    final decision = _studyDecisions[hanzi];
    if (decision == StudyDecision.saved || decision == StudyDecision.known) {
      _studyDecisions.remove(hanzi);
      await _persistStudyDecisions();
    }
    await _loadMyWords();
    notifyListeners();
  }

  // Check if word is learned
  bool isWordLearned(String hanzi) {
    return _myWords.any((w) => w.hanzi == hanzi);
  }

  StudyDecision? studyDecisionFor(String hanzi) => _studyDecisions[hanzi];

  Future<void> recordStudyDecision(Word word, StudyDecision decision) async {
    _studyDecisions[word.hanzi] = decision;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'study_decisions',
      json.encode(_studyDecisions.map((key, value) => MapEntry(key, value.name))),
    );

    if (decision != StudyDecision.skipped) {
      await _dbHelper.addWord(word);
      await _loadMyWords();
    }
    notifyListeners();
  }

  Future<void> revisitSkippedWords({String? level}) async {
    final levelWords = level == null
        ? null
        : _allWords
            .where((word) => word.level == level)
            .map((word) => word.hanzi)
            .toSet();
    _studyDecisions.removeWhere((hanzi, decision) =>
        decision == StudyDecision.skipped &&
        (levelWords == null || levelWords.contains(hanzi)));
    await _persistStudyDecisions();
    notifyListeners();
  }

  Future<void> clearStudyDecision(String hanzi) async {
    _studyDecisions.remove(hanzi);
    await _persistStudyDecisions();
    notifyListeners();
  }

  Future<void> _persistStudyDecisions() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'study_decisions',
      json.encode(_studyDecisions.map((key, value) => MapEntry(key, value.name))),
    );
  }

  // Set selected level filter
  void setSelectedLevel(String level) {
    _selectedLevel = level;
    _cachedFilteredWords = null;
    notifyListeners();
  }

  // Set selected tag filter
  void setSelectedTag(String tag) {
    _selectedTag = tag;
    _cachedFilteredWords = null;
    notifyListeners();
  }

  // Set selected part of speech filter
  void setSelectedPartOfSpeech(String pos) {
    _selectedPartOfSpeech = pos;
    _cachedFilteredWords = null;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _cachedFilteredWords = null;
    notifyListeners();
  }

  // Get search suggestions
  List<Word> getSearchSuggestions(String query) {
    if (query.isEmpty) return [];

    final normalizedQuery = Word.normalizePinyin(query.toLowerCase());
    
    return _allWords.where((w) {
      return w.displayHanzi.toLowerCase().contains(query.toLowerCase()) ||
             w.hanzi.toLowerCase().contains(query.toLowerCase()) ||
             w.pinyin.toLowerCase().contains(query.toLowerCase()) ||
             Word.normalizePinyin(w.pinyin).contains(normalizedQuery) ||
             w.englishTranslation.toLowerCase().contains(query.toLowerCase()) ||
             w.polishTranslation.toLowerCase().contains(query.toLowerCase());
    }).take(10).toList();
  }
}
