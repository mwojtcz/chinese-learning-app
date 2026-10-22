import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classroom_lesson.dart';

enum LessonImportResult { imported, unchanged }

/// One store is permanently bound to one learner. Every mutation immediately
/// queues a complete snapshot; switching screens cannot redirect a pending save.
class ClassroomStore extends ChangeNotifier {
  static final Map<String, Future<void>> _queues = {};
  static final Map<String, String> _unsaved = {};
  static int _restoreEpoch = 0;

  /// Call after restoring app data and before recreating the workspace.
  /// Call [flushAll] BEFORE the restore itself; an in-flight platform write
  /// cannot be cancelled once it has reached SharedPreferences.
  static void invalidateAfterRestore() {
    _restoreEpoch++;
    _queues.clear();
    _unsaved.clear();
  }

  /// The parent profile shell can await this before switching learners or roles.
  /// Throws when persistence failed so navigation can be cancelled.
  static Future<void> flushAll() async {
    while (true) {
      final pending = Map<String, Future<void>>.from(_queues);
      await Future.wait(pending.values);
      if (_queues.entries
          .every((entry) => identical(pending[entry.key], entry.value))) {
        break;
      }
    }
    if (_unsaved.isNotEmpty) throw StateError('classroom-save-failed');
  }

  final String profileId;
  final SharedPreferences preferences;
  final int _epoch = _restoreEpoch;
  List<ClassroomLesson> _lessons = [];
  Map<String, String> _teacherNotes = {};
  Map<String, String> _pupilNotes = {};
  Object? error;
  bool saving = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void> _pending = Future.value();

  ClassroomStore({required this.profileId, required this.preferences});

  String get storageKey =>
      'classroom.v1.${base64Url.encode(utf8.encode(profileId))}';
  List<ClassroomLesson> get lessons => List.unmodifiable(_lessons);
  String teacherNote(String id) => _teacherNotes[id] ?? '';
  String pupilNote(String id) => _pupilNotes[id] ?? '';

  Future<void> load() async {
    await (_queues[storageKey] ?? Future.value());
    await preferences.reload();
    final unsaved = _unsaved[storageKey];
    final raw = unsaved ?? preferences.getString(storageKey);
    if (raw == null) return;
    try {
      final local = jsonDecode(raw) as Map<String, dynamic>;
      if (local['version'] != 1) {
        throw const FormatException('unsupported-schema');
      }
      final shared = local['shared'] as List<dynamic>;
      final lessons = shared.map(ClassroomLesson.fromJson).toList();
      if (lessons.map((l) => l.id).toSet().length != lessons.length) {
        throw const FormatException('invalid-package');
      }
      final teacher = Map<String, String>.from(local['teacherNotes'] as Map);
      final pupil = Map<String, String>.from(local['pupilNotes'] as Map);
      _lessons = lessons;
      _teacherNotes = teacher;
      _pupilNotes = pupil;
      error = null;
      if (unsaved != null) _save();
    } catch (e) {
      // Never replace unreadable stored content with an empty notebook.
      error = e;
      rethrow;
    }
  }

  void put(ClassroomLesson lesson) {
    final index = _lessons.indexWhere((l) => l.id == lesson.id);
    if (index >= 0 && lesson.revision <= _lessons[index].revision) {
      throw const FormatException('older-revision');
    }
    if (index < 0) {
      _lessons = [..._lessons, lesson];
    } else {
      _lessons = [..._lessons]..[index] = lesson;
    }
    _save();
  }

  void setTeacherNote(String id, String value) {
    _teacherNotes = {..._teacherNotes, id: value};
    _save();
  }

  void setPupilNote(String id, String value) {
    _pupilNotes = {..._pupilNotes, id: value};
    _save();
  }

  LessonImportResult importPackage(ClassroomPackage package) {
    // Check the entire package before applying any changes.
    for (final incoming in package.lessons) {
      final existing = _lessons.where((l) => l.id == incoming.id).firstOrNull;
      if (existing == null) continue;
      if (incoming.revision < existing.revision) {
        throw const FormatException('older-revision');
      }
      if (incoming.revision == existing.revision &&
          jsonEncode(incoming.toJson()) != jsonEncode(existing.toJson())) {
        throw const FormatException('revision-conflict');
      }
    }
    final updated = <String, ClassroomLesson>{
      for (final lesson in _lessons) lesson.id: lesson
    };
    var changed = false;
    for (final incoming in package.lessons) {
      if (updated[incoming.id]?.revision == incoming.revision) continue;
      updated[incoming.id] = incoming;
      changed = true;
    }
    if (!changed) return LessonImportResult.unchanged;
    _lessons = updated.values.toList();
    // Notes are intentionally not read from incoming content.
    _save();
    return LessonImportResult.imported;
  }

  Future<void> flush() async {
    while (true) {
      final pending = _pending;
      await pending;
      if (identical(pending, _pending)) break;
    }
    if (error != null || _unsaved.containsKey(storageKey)) {
      throw StateError('classroom-save-failed');
    }
  }
  void retry() => _save();

  void _save() {
    if (_epoch != _restoreEpoch) {
      throw StateError('classroom-workspace-invalidated');
    }
    final snapshot = jsonEncode({
      'version': 1,
      'shared': _lessons.map((l) => l.toJson()).toList(),
      'teacherNotes': _teacherNotes,
      'pupilNotes': _pupilNotes,
    });
    final generation = ++_generation;
    _unsaved[storageKey] = snapshot;
    saving = true;
    error = null;
    final previous = _queues[storageKey] ?? Future.value();
    final write = previous.then((_) async {
      if (_epoch != _restoreEpoch) return;
      if (!await preferences.setString(storageKey, snapshot)) {
        throw StateError('save-failed');
      }
    });
    // The serial queue always recovers; the visible error retains failed writes.
    final observed = write.then<void>((_) {
      if (_epoch != _restoreEpoch) return;
      if (_unsaved[storageKey] == snapshot) _unsaved.remove(storageKey);
      if (generation == _generation) {
        saving = false;
        error = null;
        _notify();
      }
    }, onError: (Object e) {
      if (_epoch != _restoreEpoch) return;
      if (generation == _generation) {
        saving = false;
        error = e;
        _notify();
      }
    });
    _queues[storageKey] = observed;
    _pending = observed;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
