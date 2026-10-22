enum AppLanguage {
  polish,
  simplifiedChinese,
  traditionalChinese,
}

extension AppLanguagePresentation on AppLanguage {
  bool get isPolish => this == AppLanguage.polish;
  bool get isChinese => !isPolish;
  bool get isTraditional => this == AppLanguage.traditionalChinese;

  String get code {
    switch (this) {
      case AppLanguage.polish:
        return 'pl';
      case AppLanguage.simplifiedChinese:
        return 'zh-Hans';
      case AppLanguage.traditionalChinese:
        return 'zh-Hant';
    }
  }

  String get shortLabel {
    switch (this) {
      case AppLanguage.polish:
        return 'PL';
      case AppLanguage.simplifiedChinese:
        return '简';
      case AppLanguage.traditionalChinese:
        return '繁';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.polish:
        return 'Polski';
      case AppLanguage.simplifiedChinese:
        return '简体中文';
      case AppLanguage.traditionalChinese:
        return '繁體中文';
    }
  }

  String text(String polish, String simplified, [String? traditional]) {
    switch (this) {
      case AppLanguage.polish:
        return polish;
      case AppLanguage.simplifiedChinese:
        return simplified;
      case AppLanguage.traditionalChinese:
        return traditional ?? simplified;
    }
  }
}

AppLanguage appLanguageFromCode(String? code) {
  switch (code) {
    case 'zh-Hans':
      return AppLanguage.simplifiedChinese;
    case 'zh-Hant':
      return AppLanguage.traditionalChinese;
    default:
      return AppLanguage.polish;
  }
}
