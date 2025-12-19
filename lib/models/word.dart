class Word {
  final String hanzi;
  final String traditional; // Traditional Chinese (繁體字)
  final String pinyin;
  final String englishTranslation;
  final String polishTranslation;
  final String level; // HSK-1, HSK-2, etc.
  final String notes;
  final List<String> tags;
  final String? partOfSpeech;
  final int? frequency;

  Word({
    required this.hanzi,
    String? traditional,
    required this.pinyin,
    required this.englishTranslation,
    required this.polishTranslation,
    required this.level,
    this.notes = '',
    this.tags = const [],
    this.partOfSpeech,
    this.frequency,
  }) : traditional = traditional ?? hanzi; // Default to simplified if not provided

  // Convert from JSON
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      hanzi: json['hanzi'] as String,
      traditional: json['traditional'] as String?,
      pinyin: json['pinyin'] as String,
      englishTranslation: json['english'] as String,
      polishTranslation: json['polish'] as String,
      level: json['level'] as String,
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      partOfSpeech: json['partOfSpeech'] as String?,
      frequency: json['frequency'] as int?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'hanzi': hanzi,
      'traditional': traditional,
      'pinyin': pinyin,
      'english': englishTranslation,
      'polish': polishTranslation,
      'level': level,
      'notes': notes,
      'tags': tags,
      'partOfSpeech': partOfSpeech,
      'frequency': frequency,
    };
  }

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'hanzi': hanzi,
      'traditional': traditional,
      'pinyin': pinyin,
      'english': englishTranslation,
      'polish': polishTranslation,
      'level': level,
      'notes': notes,
      'tags': tags.join(','),
      'partOfSpeech': partOfSpeech,
      'frequency': frequency,
    };
  }

  // Convert from Map (SQLite)
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      hanzi: map['hanzi'] as String,
      traditional: map['traditional'] as String?,
      pinyin: map['pinyin'] as String,
      englishTranslation: map['english'] as String,
      polishTranslation: map['polish'] as String,
      level: map['level'] as String,
      notes: map['notes'] as String? ?? '',
      tags: (map['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      partOfSpeech: map['partOfSpeech'] as String?,
      frequency: map['frequency'] as int?,
    );
  }

  // Helper method to normalize pinyin (remove tones for search)
  static String normalizePinyin(String pinyin) {
    const toneMap = {
      'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
      'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
      'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
      'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
      'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
      'ǖ': 'ü', 'ǘ': 'ü', 'ǚ': 'ü', 'ǜ': 'ü',
      'ń': 'n', 'ň': 'n', 'ǹ': 'n',
    };
    
    String normalized = pinyin.toLowerCase();
    toneMap.forEach((toned, plain) {
      normalized = normalized.replaceAll(toned, plain);
    });
    return normalized;
  }
}
