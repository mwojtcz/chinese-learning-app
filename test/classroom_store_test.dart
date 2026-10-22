import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Exercise the plugin's failure contract without adding a production dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:chinese_flow/models/classroom_lesson.dart';
import 'package:chinese_flow/services/classroom_store.dart';

class _QuotaStore extends InMemorySharedPreferencesStore {
  bool full = true;
  _QuotaStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (full) throw StateError('QuotaExceededError');
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  ClassroomLesson lesson({int revision = 1, String title = 'Lesson'}) =>
      ClassroomLesson(id: 'lesson', revision: revision, title: title);

  test('private teacher and pupil notes persist separately but never export',
      () async {
    final store = ClassroomStore(profileId: 'notes', preferences: preferences);
    store.put(lesson());
    store.setTeacherNote('lesson', 'teacher secret');
    store.setPupilNote('lesson', 'pupil personal');
    await store.flush();
    final exported = utf8.decode(ClassroomPackage(store.lessons).encode());
    expect(exported, isNot(contains('teacher secret')));
    expect(exported, isNot(contains('pupil personal')));
    final restored =
        ClassroomStore(profileId: 'notes', preferences: preferences);
    await restored.load();
    expect(restored.teacherNote('lesson'), 'teacher secret');
    expect(restored.pupilNote('lesson'), 'pupil personal');
    store.dispose();
    restored.dispose();
  });

  test(
      'duplicate import idempotent; old revisions and conflicting content refused',
      () async {
    final store =
        ClassroomStore(profileId: 'revisions', preferences: preferences);
    final original = ClassroomPackage([lesson()]);
    expect(store.importPackage(original), LessonImportResult.imported);
    expect(store.importPackage(original), LessonImportResult.unchanged);
    store.setTeacherNote('lesson', 'private');
    store.setPupilNote('lesson', 'my notes');
    store.importPackage(ClassroomPackage([lesson(revision: 2)]));
    expect(() => store.importPackage(original), throwsFormatException);
    expect(
        () => store.importPackage(
            ClassroomPackage([lesson(revision: 2, title: 'conflict')])),
        throwsFormatException);
    expect(store.lessons.single.revision, 2);
    expect(store.teacherNote('lesson'), 'private');
    expect(store.pupilNote('lesson'), 'my notes');
    await store.flush();
    store.dispose();
  });

  test('imports are atomic and do not modify unrelated progress preferences',
      () async {
    final store = ClassroomStore(profileId: 'atomic', preferences: preferences);
    await preferences.setString('learned_words', 'existing progress');
    store.put(lesson(revision: 3));
    expect(
        () => store.importPackage(ClassroomPackage([
              ClassroomLesson(id: 'new', title: 'New'),
              lesson(revision: 2),
            ])),
        throwsFormatException);
    expect(store.lessons.map((l) => l.id), ['lesson']);
    expect(preferences.getString('learned_words'), 'existing progress');
    await store.flush();
    store.dispose();
  });

  test('queued writes remain bound to learner, even after immediate disposal',
      () async {
    final first = ClassroomStore(profileId: 'a/b', preferences: preferences);
    final second = ClassroomStore(profileId: 'a?b', preferences: preferences);
    first.put(lesson(title: 'first'));
    first.setPupilNote('lesson', 'last keystroke');
    first.dispose();
    second.put(lesson(title: 'second'));
    final reload = ClassroomStore(profileId: 'a/b', preferences: preferences);
    await ClassroomStore.flushAll();
    await reload.load();
    await second.flush();
    expect(reload.lessons.single.title, 'first');
    expect(reload.pupilNote('lesson'), 'last keystroke');
    expect(second.lessons.single.title, 'second');
    expect(first.storageKey, isNot(second.storageKey));
    reload.dispose();
    second.dispose();
  });

  test('global flush persists final edits and notes before backup or update',
      () async {
    final store =
        ClassroomStore(profileId: 'before-update', preferences: preferences);
    final original = lesson();
    store.put(original);
    store.put(original.edit(title: 'Last edit'));
    store.setTeacherNote('lesson', 'Last teacher keystroke');
    store.setPupilNote('lesson', 'Last pupil keystroke');

    await ClassroomStore.flushAll();

    final persisted =
        jsonDecode(preferences.getString(store.storageKey)!) as Map;
    expect((persisted['shared'] as List).single['title'], 'Last edit');
    expect((persisted['shared'] as List).single['revision'], 2);
    expect(persisted['teacherNotes']['lesson'], 'Last teacher keystroke');
    expect(persisted['pupilNotes']['lesson'], 'Last pupil keystroke');
    expect(store.saving, isFalse);
    expect(store.error, isNull);
    store.dispose();
  });

  test(
      'quota failure keeps final content and blocks exit until a successful retry',
      () async {
    final backend = _QuotaStore();
    final previousBackend = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = backend;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousBackend);
    final store = ClassroomStore(profileId: 'quota', preferences: preferences);
    store.put(lesson(title: 'Retain this entire lesson'));
    store.setPupilNote('lesson', 'Retain my last edit');
    await expectLater(store.flush(), throwsStateError);
    expect(store.error, isNotNull);
    expect(store.saving, isFalse);
    await expectLater(ClassroomStore.flushAll(), throwsStateError);
    store.dispose();

    final reopened =
        ClassroomStore(profileId: 'quota', preferences: preferences);
    await reopened.load();
    await expectLater(reopened.flush(), throwsStateError);
    expect(reopened.lessons.single.title, 'Retain this entire lesson');
    expect(reopened.pupilNote('lesson'), 'Retain my last edit');
    expect(reopened.error, isNotNull);
    backend.full = false;
    reopened.retry();
    await ClassroomStore.flushAll();
    expect(reopened.error, isNull);
    expect(reopened.saving, isFalse);
    expect(preferences.getString(reopened.storageKey),
        contains('Retain my last edit'));
    reopened.dispose();
  });

  test('restore invalidation reloads persisted data and rejects stale writers',
      () async {
    final oldStore =
        ClassroomStore(profileId: 'restore', preferences: preferences);
    oldStore.put(lesson(title: 'Before restore'));
    await ClassroomStore.flushAll();
    final restored = lesson(revision: 9, title: 'Restored backup');
    await preferences.setString(
        oldStore.storageKey,
        jsonEncode({
          'version': 1,
          'shared': [restored.toJson()],
          'teacherNotes': {'lesson': 'Restored private note'},
          'pupilNotes': {},
        }));
    ClassroomStore.invalidateAfterRestore();
    final freshStore =
        ClassroomStore(profileId: 'restore', preferences: preferences);
    await freshStore.load();
    expect(freshStore.lessons.single.title, 'Restored backup');
    expect(freshStore.teacherNote('lesson'), 'Restored private note');
    expect(
        () => oldStore.setPupilNote('lesson', 'stale edit'), throwsStateError);
    await ClassroomStore.flushAll();
    expect(preferences.getString(oldStore.storageKey),
        contains('Restored backup'));
    expect(preferences.getString(oldStore.storageKey),
        isNot(contains('stale edit')));
    oldStore.dispose();
    freshStore.dispose();
  });

  test('corrupt local storage is not silently overwritten', () async {
    final store =
        ClassroomStore(profileId: 'corrupt', preferences: preferences);
    await preferences.setString(store.storageKey, '{broken');
    await expectLater(store.load(), throwsFormatException);
    expect(preferences.getString(store.storageKey), '{broken');
    store.dispose();
  });
}
