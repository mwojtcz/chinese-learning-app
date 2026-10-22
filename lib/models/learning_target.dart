import 'app_language.dart';

enum LearningTarget { chinese, polish }

extension LearningTargetPresentation on LearningTarget {
  String get code => this == LearningTarget.chinese ? 'chinese' : 'polish';
  bool get showsPolishOnFlashcardFront => this == LearningTarget.chinese;

  String label(AppLanguage language) => this == LearningTarget.chinese
      ? language.text('Chiński', '中文', '中文')
      : language.text('Polski', '波兰语', '波蘭語');
}

LearningTarget learningTargetFromCode(String? code, AppLanguage interfaceLanguage) {
  return switch (code) {
    'chinese' => LearningTarget.chinese,
    'polish' => LearningTarget.polish,
    _ => interfaceLanguage.isPolish
        ? LearningTarget.chinese
        : LearningTarget.polish,
  };
}
