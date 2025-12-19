class TestConfig {
  final List<String> selectedLevels;
  final List<String> selectedTags;
  final int questionCount;
  final TestMode mode;
  final TestDirection direction;
  final bool includeLearnedWords;

  TestConfig({
    required this.selectedLevels,
    this.selectedTags = const [],
    this.questionCount = 10,
    this.mode = TestMode.multipleChoice,
    this.direction = TestDirection.chineseToPolish,
    this.includeLearnedWords = false,
  });

  TestConfig copyWith({
    List<String>? selectedLevels,
    List<String>? selectedTags,
    int? questionCount,
    TestMode? mode,
    TestDirection? direction,
    bool? includeLearnedWords,
  }) {
    return TestConfig(
      selectedLevels: selectedLevels ?? this.selectedLevels,
      selectedTags: selectedTags ?? this.selectedTags,
      questionCount: questionCount ?? this.questionCount,
      mode: mode ?? this.mode,
      direction: direction ?? this.direction,
      includeLearnedWords: includeLearnedWords ?? this.includeLearnedWords,
    );
  }
}

enum TestDirection {
  chineseToPolish,  // Chinese → Polish (default)
  polishToChinese,  // Polish → Chinese (reverse)
}

enum TestMode {
  multipleChoice,  // Wybór z 4 odpowiedzi
  typing,          // Wpisywanie odpowiedzi
  flashcard,       // Sprawdzanie czy znam (tak/nie)
}

class TestQuestion {
  final String hanzi;
  final String pinyin;
  final String english;
  final String polish;
  final String level;
  final List<String> options; // Dla trybu multiple choice
  final String correctAnswer;
  bool? userAnswer; // true = poprawna, false = błędna, null = nie odpowiedziano
  String? userInput; // Dla trybu typing

  TestQuestion({
    required this.hanzi,
    required this.pinyin,
    required this.english,
    required this.polish,
    required this.level,
    required this.options,
    required this.correctAnswer,
    this.userAnswer,
    this.userInput,
  });
}

class TestResult {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final List<TestQuestion> questions;
  final DateTime completedAt;
  final Duration duration;

  TestResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.questions,
    required this.completedAt,
    required this.duration,
  });

  double get percentage => totalQuestions == 0 ? 0.0 : (correctAnswers / totalQuestions * 100);
  
  bool get passed => percentage >= 70.0; // 70% to zdany test

  List<TestQuestion> get correctQuestions => questions.where((q) => q.userAnswer == true).toList();
  List<TestQuestion> get incorrectQuestions => questions.where((q) => q.userAnswer == false).toList();
}
