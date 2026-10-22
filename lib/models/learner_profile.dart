import '../models/word.dart';

/// A local learner (or teacher) profile. [id] is stable once persisted.
class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    this.isTeacher = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final bool isTeacher;
  final DateTime? createdAt;

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) {
      throw FormatException('Invalid learner profile entry: $json');
    }
    final createdAt = json['createdAt'];
    return LearnerProfile(
      id: id,
      name: name,
      isTeacher: json['isTeacher'] == true,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isTeacher': isTeacher,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is LearnerProfile &&
      other.id == id &&
      other.name == name &&
      other.isTeacher == isTeacher;

  @override
  int get hashCode => Object.hash(id, name, isTeacher);

  @override
  String toString() => 'LearnerProfile($id, $name, teacher: $isTeacher)';
}

/// One answered exercise/question, stored per profile.
class PracticeRecord {
  PracticeRecord({
    required this.exerciseId,
    required this.kind,
    required this.correct,
    DateTime? at,
    this.answer,
    Map<String, Object?>? details,
  })  : at = at ?? DateTime.now(),
        details = Map.unmodifiable(details ?? const {});

  /// Identifier of the exercise or word (e.g. hanzi, exercise id).
  final String exerciseId;

  /// Generic exercise type, e.g. `hsk_test`, `cloze`, `polish_case`.
  final String kind;
  final bool correct;
  final DateTime at;
  final String? answer;

  /// JSON-encodable extra data.
  final Map<String, Object?> details;

  factory PracticeRecord.fromJson(Map<String, dynamic> json) {
    final exerciseId = json['exerciseId'];
    final kind = json['kind'];
    final correct = json['correct'];
    final at = json['at'];
    if (exerciseId is! String ||
        kind is! String ||
        correct is! bool ||
        at is! String ||
        DateTime.tryParse(at) == null) {
      throw FormatException('Invalid practice record: $json');
    }
    final details = json['details'];
    return PracticeRecord(
      exerciseId: exerciseId,
      kind: kind,
      correct: correct,
      at: DateTime.parse(at),
      answer: json['answer'] as String?,
      details: details is Map ? Map<String, Object?>.from(details) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'kind': kind,
        'correct': correct,
        'at': at.toIso8601String(),
        if (answer != null) 'answer': answer,
        if (details.isNotEmpty) 'details': details,
      };
}

/// Immutable snapshot of one profile's persisted learning state.
class ProfileState {
  ProfileState({
    required this.profileId,
    required List<Word> words,
    required Map<String, String> decisions,
    required List<PracticeRecord> practiceHistory,
  })  : words = List.unmodifiable(words),
        decisions = Map.unmodifiable(decisions),
        practiceHistory = List.unmodifiable(practiceHistory);

  final String profileId;

  /// "My words" of this profile, in insertion order.
  final List<Word> words;

  /// hanzi -> StudyDecision name (`saved`, `known`, `skipped`).
  final Map<String, String> decisions;
  final List<PracticeRecord> practiceHistory;
}

/// Metadata of a stored backup snapshot.
class ProfileBackupInfo {
  const ProfileBackupInfo({
    required this.createdAt,
    required this.reason,
    required this.profileCount,
  });

  final DateTime createdAt;
  final String reason;
  final int profileCount;
}
