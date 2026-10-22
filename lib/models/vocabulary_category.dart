import 'app_language.dart';
import 'word.dart';

class VocabularyCategory {
  const VocabularyCategory._(
      this.id, this.polish, this.simplified, this.traditional);

  final String id;
  final String polish;
  final String simplified;
  final String traditional;

  String label(AppLanguage language) =>
      language.text(polish, simplified, traditional);

  static const allId = 'all';
  static const _otherId = 'other';

  static const _categories = <VocabularyCategory>[
    VocabularyCategory._('body', 'Części ciała', '身体部位', '身體部位'),
    VocabularyCategory._('family', 'Rodzina i ludzie', '家庭与人物', '家庭與人物'),
    VocabularyCategory._('food', 'Jedzenie i napoje', '饮食', '飲食'),
    VocabularyCategory._('animals', 'Zwierzęta', '动物', '動物'),
    VocabularyCategory._('health', 'Zdrowie', '健康', '健康'),
    VocabularyCategory._('time', 'Czas', '时间', '時間'),
    VocabularyCategory._('nature', 'Przyroda', '自然', '自然'),
    VocabularyCategory._('places', 'Miejsca i dom', '地点与居住', '地點與居住'),
    VocabularyCategory._('transport', 'Transport i ruch', '交通与移动', '交通與移動'),
    VocabularyCategory._('work', 'Praca i zawody', '工作与职业', '工作與職業'),
    VocabularyCategory._('learning', 'Nauka i szkoła', '学习与学校', '學習與學校'),
    VocabularyCategory._('communication', 'Komunikacja', '沟通', '溝通'),
    VocabularyCategory._('emotions', 'Emocje i myślenie', '情绪与思维', '情緒與思維'),
    VocabularyCategory._('numbers', 'Liczby i ilości', '数字与数量', '數字與數量'),
    VocabularyCategory._('sports', 'Sport', '运动', '運動'),
    VocabularyCategory._('weather', 'Pogoda', '天气', '天氣'),
    VocabularyCategory._('colors', 'Kolory i wygląd', '颜色与外观', '顏色與外觀'),
    VocabularyCategory._('clothing', 'Ubrania', '衣物', '衣物'),
    VocabularyCategory._('technology', 'Technologia i media', '科技与媒体', '科技與媒體'),
    VocabularyCategory._('actions', 'Czynności', '动作', '動作'),
    VocabularyCategory._('entertainment', 'Czas wolny', '休闲娱乐', '休閒娛樂'),
    VocabularyCategory._('other', 'Pozostałe', '其他', '其他'),
  ];

  static final Set<String> _categoryIds =
      _categories.map((category) => category.id).toSet();

  static List<String> idsFor(Word word) {
    final ids = word.categories.where(_categoryIds.contains).toSet();
    if (ids.isEmpty) ids.add(_otherId);
    return ids.toList(growable: false);
  }

  static List<VocabularyCategory> availableFor(
    Iterable<Word> words, {
    String? level,
  }) {
    final present = <String>{};
    for (final word in words) {
      if (level != null && word.level != level) continue;
      present.addAll(idsFor(word));
    }
    return _categories
        .where((category) => present.contains(category.id))
        .toList();
  }

  static List<VocabularyCategory> get all => _categories;
}
