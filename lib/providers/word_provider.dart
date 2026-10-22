import 'package:flutter/material.dart';
import '../models/learner_profile.dart';
import '../models/word.dart';
import '../database/database_helper.dart';

enum StudyDecision { saved, known, skipped }

class WordProvider with ChangeNotifier {
  WordProvider({ProfileStore? store}) : _store = store ?? ProfileStore.instance;

  final ProfileStore _store;
  String? _profileId;
  int _profileGeneration = 0;
  List<PracticeRecord> _practiceHistory = const [];

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
    final currentState =
        '$_selectedLevel|$_selectedTag|$_selectedPartOfSpeech|$_searchQuery';
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
      words =
          words.where((w) => w.partOfSpeech == _selectedPartOfSpeech).toList();
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
      final totalInLevel =
          _allWords.where((w) => w.level == _selectedLevel).length;
      final learnedInLevel =
          _myWords.where((w) => w.level == _selectedLevel).length;

      return {
        'learned': learnedInLevel,
        'total': totalInLevel,
        'percentage':
            totalInLevel == 0 ? 0.0 : (learnedInLevel / totalInLevel * 100),
      };
    }
  }

  /// Id of the profile whose words/decisions/history are loaded.
  String? get profileId => _profileId;

  /// Practice results of the active profile, oldest first.
  List<PracticeRecord> get practiceHistory => _practiceHistory;

  /// Switches to [profileId], reloading only per-profile state (saved words,
  /// study decisions, practice history). The global dictionary is kept.
  /// If another switch starts before this one finishes, this result is
  /// discarded. Always re-reads storage, also when [profileId] is unchanged.
  /// Throws [ArgumentError] for an unknown profile.
  Future<void> setProfile(String profileId) async {
    final generation = ++_profileGeneration;
    final state = await _store.loadProfileState(profileId);
    if (generation != _profileGeneration) return;
    _profileId = profileId;
    _store.boundProfileId = profileId;
    _applyState(state);
    notifyListeners();
  }

  /// Waits until all queued progress writes are persisted.
  Future<void> flush() => _store.flush();

  /// Re-reads the current profile from storage (e.g. after a backup import
  /// or restore). Equivalent to `setProfile(profileId!)`; it is never a no-op.
  Future<void> reloadProfile() => setProfile(_requireProfileId());

  // Initialize data
  Future<void> loadData() async {
    _isLoading = true;
    _loadingProgress = 0.0;
    notifyListeners();

    try {
      // Load main vocabulary first (most important); it is profile-independent.
      if (_allWords.isEmpty) await _loadAllWords();
      _loadingProgress = 0.5;
      notifyListeners();

      await _reloadProfileState();
    } finally {
      _loadingProgress = 1.0;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadProfileState() async {
    final profileId = _profileId;
    if (profileId == null) {
      final registry = await _store.loadRegistry();
      if (_profileId == null) await setProfile(registry.activeId);
      return;
    }
    final generation = _profileGeneration;
    final state = await _store.loadProfileState(profileId);
    if (generation != _profileGeneration || _profileId != profileId) return;
    _applyState(state);
  }

  void _applyState(ProfileState state) {
    _myWords = List.of(state.words);
    _studyDecisions.clear();
    for (final entry in state.decisions.entries) {
      for (final decision in StudyDecision.values) {
        if (decision.name == entry.value) {
          _studyDecisions[entry.key] = decision;
          break;
        }
      }
    }
    _practiceHistory = state.practiceHistory;
  }

  String _requireProfileId() {
    final profileId = _profileId;
    if (profileId == null) {
      throw StateError(
          'No learner profile selected; call setProfile() or loadData() first');
    }
    return profileId;
  }

  /// Runs a store update for the profile active at call time. The result is
  /// applied only if that profile is still active when the write completes.
  Future<void> _mutate(
      Future<ProfileState> Function(String profileId) update) async {
    final profileId = _requireProfileId();
    final state = await update(profileId);
    if (_profileId != profileId) return;
    _applyState(state);
    notifyListeners();
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

  // Add word to "my words"
  Future<void> addToMyWords(Word word) =>
      _mutate((profileId) => _store.saveWord(profileId, word));

  // Remove word from "my words"
  Future<void> removeFromMyWords(String hanzi) =>
      _mutate((profileId) => _store.removeWord(profileId, hanzi));

  // Check if word is learned
  bool isWordLearned(String hanzi) {
    return _myWords.any((w) => w.hanzi == hanzi);
  }

  StudyDecision? studyDecisionFor(String hanzi) => _studyDecisions[hanzi];

  Future<void> recordStudyDecision(Word word, StudyDecision decision) =>
      _mutate((profileId) => decision == StudyDecision.skipped
          ? _store.setDecision(profileId, word.hanzi, decision.name)
          : _store.saveWord(profileId, word, decision: decision.name));

  Future<void> revisitSkippedWords({String? level}) {
    final levelWords = level == null
        ? null
        : _allWords
            .where((word) => word.level == level)
            .map((word) => word.hanzi)
            .toSet();
    return _mutate((profileId) => _store.removeDecisionsWhere(
          profileId,
          (hanzi, decision) =>
              decision == StudyDecision.skipped.name &&
              (levelWords == null || levelWords.contains(hanzi)),
        ));
  }

  Future<void> clearStudyDecision(String hanzi) =>
      _mutate((profileId) => _store.setDecision(profileId, hanzi, null));

  /// Records one answered exercise for the active profile. [kind] is a
  /// generic exercise type (e.g. `cloze`, `polish_case`, `hsk_test`);
  /// [details] must be JSON-encodable.
  Future<void> recordPracticeResult({
    required String exerciseId,
    required String kind,
    required bool correct,
    String? answer,
    Map<String, Object?>? details,
  }) =>
      _mutate((profileId) => _store.recordPracticeResults(profileId, [
            PracticeRecord(
              exerciseId: exerciseId,
              kind: kind,
              correct: correct,
              answer: answer,
              details: details,
            ),
          ]));

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

    return _allWords
        .where((w) {
          return w.displayHanzi.toLowerCase().contains(query.toLowerCase()) ||
              w.hanzi.toLowerCase().contains(query.toLowerCase()) ||
              w.pinyin.toLowerCase().contains(query.toLowerCase()) ||
              Word.normalizePinyin(w.pinyin).contains(normalizedQuery) ||
              w.englishTranslation
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              w.polishTranslation.toLowerCase().contains(query.toLowerCase());
        })
        .take(10)
        .toList();
  }
}
