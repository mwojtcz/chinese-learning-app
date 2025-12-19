import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/test_config.dart';
import '../database/database_helper.dart';

class TestProvider with ChangeNotifier {
  TestConfig _config = TestConfig(selectedLevels: ['HSK-1']);
  List<TestQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  DateTime? _testStartTime;
  bool _isTestActive = false;
  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Random _random = Random();

  TestConfig get config => _config;
  List<TestQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isTestActive => _isTestActive;
  TestQuestion? get currentQuestion => _questions.isEmpty ? null : _questions[_currentQuestionIndex];
  int get totalQuestions => _questions.length;
  int get answeredQuestions => _questions.where((q) => q.userAnswer != null).length;
  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;

  void updateConfig(TestConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  Future<void> startTest({List<Word>? availableWords}) async {
    _testStartTime = DateTime.now();
    _isTestActive = true;
    _currentQuestionIndex = 0;
    
    // Użyj przekazanych słów lub załaduj z bazy (fallback)
    List<Word> allWords = availableWords ?? await _dbHelper.loadAllWords();
    
    // Filtruj według wybranych poziomów
    allWords = allWords.where((w) => _config.selectedLevels.contains(w.level)).toList();
    
    // Filtruj według tagów jeśli wybrano
    if (_config.selectedTags.isNotEmpty && !_config.selectedTags.contains('Wszystkie')) {
      allWords = allWords.where((w) => 
        w.tags.any((tag) => _config.selectedTags.contains(tag))
      ).toList();
    }
    
    // Filtruj znane słowa jeśli nie chcemy ich uwzględniać
    if (!_config.includeLearnedWords) {
      final learnedWords = await _dbHelper.getMyWords();
      final learnedHanzis = learnedWords.map((w) => w.hanzi).toSet();
      allWords = allWords.where((w) => !learnedHanzis.contains(w.hanzi)).toList();
    }
    
    // Losuj pytania
    allWords.shuffle(_random);
    final selectedWords = allWords.take(_config.questionCount).toList();
    
    // Twórz pytania
    _questions = selectedWords.map((word) => _createQuestion(word, allWords)).toList();
    
    notifyListeners();
  }

  TestQuestion _createQuestion(Word word, List<Word> allWords) {
    List<String> options = [];
    String correctAnswer = '';
    final isReverse = _config.direction == TestDirection.polishToChinese;
    
    switch (_config.mode) {
      case TestMode.multipleChoice:
        if (isReverse) {
          // Polish → Chinese: pokazuj polskie, odpowiedź to hanzi
          correctAnswer = word.hanzi;
          options = [correctAnswer];
          
          // Dodaj 3 losowe niepoprawne odpowiedzi (inne hanzi)
          final otherWords = allWords.where((w) => w.hanzi != word.hanzi).toList();
          otherWords.shuffle(_random);
          
          for (var i = 0; i < 3 && i < otherWords.length; i++) {
            if (!options.contains(otherWords[i].hanzi)) {
              options.add(otherWords[i].hanzi);
            }
          }
        } else {
          // Chinese → Polish: pokazuj hanzi, odpowiedź to polskie
          correctAnswer = word.polishTranslation;
          options = [correctAnswer];
          
          // Dodaj 3 losowe niepoprawne odpowiedzi
          final otherWords = allWords.where((w) => w.hanzi != word.hanzi).toList();
          otherWords.shuffle(_random);
          
          for (var i = 0; i < 3 && i < otherWords.length; i++) {
            if (!options.contains(otherWords[i].polishTranslation)) {
              options.add(otherWords[i].polishTranslation);
            }
          }
        }
        
        options.shuffle(_random);
        break;
      
      case TestMode.typing:
        correctAnswer = isReverse ? word.hanzi : word.polishTranslation;
        break;
      
      case TestMode.flashcard:
        correctAnswer = word.polishTranslation;
        break;
    }
    
    return TestQuestion(
      hanzi: word.hanzi,
      traditional: word.traditional,
      pinyin: word.pinyin,
      english: word.englishTranslation,
      polish: word.polishTranslation,
      level: word.level,
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  void answerQuestion(String answer) {
    if (_currentQuestionIndex >= _questions.length) return;
    
    final question = _questions[_currentQuestionIndex];
    final isCorrect = answer.toLowerCase().trim() == question.correctAnswer.toLowerCase().trim();
    
    _questions[_currentQuestionIndex] = TestQuestion(
      hanzi: question.hanzi,
      traditional: question.traditional,
      pinyin: question.pinyin,
      english: question.english,
      polish: question.polish,
      level: question.level,
      options: question.options,
      correctAnswer: question.correctAnswer,
      userAnswer: isCorrect,
      userInput: answer,
    );
    
    notifyListeners();
  }

  void answerFlashcard(bool knew) {
    if (_currentQuestionIndex >= _questions.length) return;
    
    final question = _questions[_currentQuestionIndex];
    
    _questions[_currentQuestionIndex] = TestQuestion(
      hanzi: question.hanzi,
      traditional: question.traditional,
      pinyin: question.pinyin,
      english: question.english,
      polish: question.polish,
      level: question.level,
      options: question.options,
      correctAnswer: question.correctAnswer,
      userAnswer: knew,
    );
    
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<TestResult> finishTest() async {
    if (_testStartTime == null) {
      throw Exception('Test not started');
    }
    
    final duration = DateTime.now().difference(_testStartTime!);
    final correctCount = _questions.where((q) => q.userAnswer == true).length;
    final incorrectCount = _questions.where((q) => q.userAnswer == false).length;
    
    final result = TestResult(
      totalQuestions: _questions.length,
      correctAnswers: correctCount,
      incorrectAnswers: incorrectCount,
      questions: _questions,
      completedAt: DateTime.now(),
      duration: duration,
    );
    
    // Automatycznie dodaj poprawnie odpowiedziane słowa do "My Words"
    for (final question in _questions) {
      if (question.userAnswer == true) {
        final word = Word(
          hanzi: question.hanzi,
          pinyin: question.pinyin,
          englishTranslation: question.english,
          polishTranslation: question.polish,
          level: question.level,
          notes: 'Dodano automatycznie po teście',
        );
        
        // Sprawdź czy już nie jest w "My Words"
        final isLearned = await _dbHelper.isWordLearned(word.hanzi);
        if (!isLearned) {
          await _dbHelper.addWord(word);
        }
      }
    }
    
    _isTestActive = false;
    notifyListeners();
    
    return result;
  }

  void resetTest() {
    _questions = [];
    _currentQuestionIndex = 0;
    _testStartTime = null;
    _isTestActive = false;
    notifyListeners();
  }
}
