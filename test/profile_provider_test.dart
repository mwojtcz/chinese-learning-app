import 'dart:convert';

import 'package:chinese_flow/database/database_helper.dart';
import 'package:chinese_flow/models/word.dart';
import 'package:chinese_flow/providers/profile_provider.dart';
import 'package:chinese_flow/providers/test_provider.dart';
import 'package:chinese_flow/providers/word_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

Word _word(String hanzi, {String level = 'HSK-1'}) => Word(
      hanzi: hanzi,
      pinyin: 'py-$hanzi',
      englishTranslation: 'en-$hanzi',
      polishTranslation: 'pl-$hanzi',
      level: level,
    );

ProfileStore _store([List<Map<String, dynamic>> legacy = const []]) =>
    ProfileStore(legacyWordsLoader: () async => legacy);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('migration', () {
    test(
        'copies legacy words and decisions into the default profile without touching legacy data',
        () async {
      SharedPreferences.setMockInitialValues({
        'study_decisions': '{"你":"known","好":"skipped","bad":"nope"}',
        'my_words': '[]',
      });
      final legacyWord = {
        ..._word('你').toJson(),
        'addedDate': '2024-01-01T00:00:00.000'
      };
      final profiles = ProfileProvider(store: _store([legacyWord]));
      await profiles.initialize();

      expect(profiles.ready, isTrue);
      expect(profiles.profiles, hasLength(1));
      expect(profiles.activeProfile.id, ProfileStore.defaultProfileId);
      expect(profiles.activeProfile.isTeacher, isFalse);

      final words = WordProvider(store: _store([legacyWord]));
      await words.setProfile(profiles.activeProfile.id);
      expect(words.myWords.map((w) => w.hanzi), ['你']);
      expect(words.studyDecisionFor('你'), StudyDecision.known);
      expect(words.studyDecisionFor('好'), StudyDecision.skipped);
      expect(words.studyDecisionFor('bad'), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('study_decisions'),
          '{"你":"known","好":"skipped","bad":"nope"}');
      expect(prefs.getString('my_words'), '[]');
      final marker =
          json.decode(prefs.getString(ProfileStore.migrationKey)!) as Map;
      expect(marker['status'], 'migrated');
      expect(marker['migratedWords'], 1);
    });

    test('runs once: later legacy changes are not re-imported or duplicated',
        () async {
      SharedPreferences.setMockInitialValues(
          {'study_decisions': '{"你":"known"}'});
      final store = _store([_word('你').toJson()]);
      await ProfileProvider(store: store).initialize();
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      await words.clearStudyDecision('你');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('study_decisions', '{"新":"known"}');
      final again = WordProvider(
          store: _store([_word('你').toJson(), _word('新').toJson()]));
      await ProfileProvider(store: store).initialize();
      await again.setProfile(ProfileStore.defaultProfileId);
      expect(again.myWords.map((w) => w.hanzi), ['你']);
      expect(again.studyDecisionFor('你'), isNull);
      expect(again.studyDecisionFor('新'), isNull);
    });

    test('missing SQLite plugin is recorded, not treated as data', () async {
      final store = ProfileStore(
          legacyWordsLoader: () async =>
              throw MissingPluginException('no sqflite'));
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      final prefs = await SharedPreferences.getInstance();
      final marker =
          json.decode(prefs.getString(ProfileStore.migrationKey)!) as Map;
      expect(marker['status'], 'legacy_sqlite_unavailable');
      expect(profiles.activeProfile.id, ProfileStore.defaultProfileId);
    });

    test('a failing legacy read fails initialization and is retried later',
        () async {
      SharedPreferences.setMockInitialValues(
          {'study_decisions': '{"你":"known"}'});
      var fail = true;
      final store = ProfileStore(legacyWordsLoader: () async {
        if (fail) throw StateError('database locked');
        return [_word('你').toJson()];
      });
      final profiles = ProfileProvider(store: store);
      await expectLater(profiles.initialize(), throwsStateError);
      expect(profiles.ready, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ProfileStore.migrationKey), isNull);
      expect(prefs.getString(ProfileStore.registryKey), isNull);

      fail = false;
      await profiles.initialize();
      expect(profiles.ready, isTrue);
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      expect(words.myWords.map((w) => w.hanzi), ['你']);
    });

    test(
        'unreadable existing legacy database surfaces an error and writes nothing',
        () async {
      SharedPreferences.setMockInitialValues(
          {'study_decisions': '{"你":"known"}'});
      final store = ProfileStore(
          legacyWordsLoader: () async => throw LegacyMigrationException(
              'C:/app/.dart_tool/sqflite_common_ffi/databases/my_words.db',
              ArgumentError('Failed to load dynamic library sqlite3.dll')));
      final profiles = ProfileProvider(store: store);
      await expectLater(
          profiles.initialize(), throwsA(isA<LegacyMigrationException>()));
      expect(profiles.ready, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'study_decisions'});
    });

    test('corrupt legacy decisions are reported instead of being dropped',
        () async {
      SharedPreferences.setMockInitialValues({'study_decisions': '[1,2]'});
      await expectLater(ProfileProvider(store: _store()).initialize(),
          throwsA(isA<FormatException>()));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('study_decisions'), '[1,2]');
    });
  });

  group('legacy sources', () {
    test('legacy web prefs my_words are migrated through the injected loader',
        () async {
      SharedPreferences.setMockInitialValues({
        'my_words': json.encode([_word('你').toJson(), _word('好').toJson()]),
        'study_decisions': '{"好":"saved"}',
      });
      final store = ProfileStore(
          legacyWordsLoader:
              DatabaseHelper.instance.readLegacyPrefsWordEntries);
      await ProfileProvider(store: store).initialize();
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      expect(words.myWords.map((w) => w.hanzi), ['你', '好']);
      expect(words.studyDecisionFor('好'), StudyDecision.saved);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('my_words'), isNotNull);
    });

    test('default native loader in the test binding never opens a database',
        () async {
      // Mirrors main(): default store, Android target, no sqflite plugin.
      final previousFactory = databaseFactoryOrNull;
      databaseFactory = databaseFactorySqflitePlugin;
      addTearDown(() => databaseFactoryOrNull = previousFactory);
      final store = ProfileStore();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      final words = WordProvider(store: store);
      await words.setProfile(profiles.activeProfile.id);
      expect(profiles.activeProfile.id, ProfileStore.defaultProfileId);
      expect(words.myWords, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      final marker =
          json.decode(prefs.getString(ProfileStore.migrationKey)!) as Map;
      expect(marker['status'], 'legacy_sqlite_unavailable');
    });

    test('shared instance loader can be overridden and static backup works',
        () async {
      final original = ProfileStore.instance.legacyWordsLoader;
      addTearDown(() => ProfileStore.instance.legacyWordsLoader = original);
      ProfileStore.instance.legacyWordsLoader =
          () async => [_word('你').toJson()];
      final profiles = ProfileProvider();
      await profiles.initialize();
      final words = WordProvider();
      await words.setProfile(profiles.activeProfile.id);
      expect(words.myWords.map((w) => w.hanzi), ['你']);

      await words.flush();
      await profiles.flush();
      final info = await ProfileProvider.backupNow();
      expect(info.reason, 'pre-update');
      final backup = await profiles.createBackup();
      expect(backup.profileCount, 1);
      expect(profiles.backups.map((b) => b.reason), ['pre-update', 'manual']);
    });

    test(
        'teacher can inspect a student profile without changing the active one',
        () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Teacher', isTeacher: true);
      final teacher = profiles.profiles.last;
      await profiles.createProfile('Student');
      final student = profiles.profiles.last;
      await profiles.selectProfile(teacher.id);

      final words = WordProvider(store: store);
      await words.setProfile(student.id);
      await words.recordStudyDecision(_word('你'), StudyDecision.known);
      await words.setProfile(teacher.id);
      expect(words.myWords, isEmpty);
      expect(profiles.activeProfile.id, teacher.id);
      expect(profiles.activeProfile.isTeacher, isTrue);
    });
  });

  group('profiles', () {
    test('creates profiles with stable ids and persists the selection',
        () async {
      final profiles = ProfileProvider(store: _store());
      await profiles.initialize();
      await profiles.createProfile('  Ania ');
      await profiles.createProfile('Teacher', isTeacher: true);
      final ania = profiles.profiles[1];
      expect(ania.name, 'Ania');
      expect(ania.id, isNot(ProfileStore.defaultProfileId));
      expect(profiles.profiles.last.isTeacher, isTrue);
      expect(profiles.activeProfile.id, ProfileStore.defaultProfileId);

      await profiles.selectProfile(ania.id);
      await profiles.flush();

      final reloaded = ProfileProvider(store: _store());
      await reloaded.initialize();
      expect(reloaded.profiles.map((p) => p.id),
          profiles.profiles.map((p) => p.id));
      expect(reloaded.activeProfile.id, ania.id);
      expect(reloaded.profiles.last.isTeacher, isTrue);
    });

    test('rejects unknown ids, empty and duplicate names', () async {
      final profiles = ProfileProvider(store: _store());
      expect(() => profiles.activeProfile, throwsStateError);
      await profiles.initialize();
      await expectLater(profiles.selectProfile('missing'), throwsArgumentError);
      await expectLater(profiles.createProfile('   '), throwsArgumentError);
      await expectLater(
          profiles.createProfile(ProfileStore.defaultProfileName.toUpperCase()),
          throwsArgumentError);
      expect(profiles.profiles, hasLength(1));
      expect(profiles.activeProfile.id, ProfileStore.defaultProfileId);
    });

    test(
        'backup snapshot restores earlier state and keeps a pre-restore backup',
        () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      await words.recordStudyDecision(_word('你'), StudyDecision.known);

      final backup = await profiles.createBackupSnapshot(reason: 'pre-update');
      expect(backup.reason, 'pre-update');
      await profiles.createProfile('Later');
      await words.removeFromMyWords('你');
      expect(words.myWords, isEmpty);

      final exported = json.decode(await profiles.exportSnapshotJson()) as Map;
      expect((exported['data'] as Map).containsKey(ProfileStore.registryKey),
          isTrue);

      await profiles.restoreBackupSnapshot(backup.createdAt);
      await words.setProfile(profiles.activeProfile.id);
      expect(profiles.profiles, hasLength(1));
      expect(words.myWords.map((w) => w.hanzi), ['你']);
      expect(words.studyDecisionFor('你'), StudyDecision.known);
      expect(
          profiles.backups.map((b) => b.reason), ['pre-update', 'pre-restore']);
    });
  });

  group('backup import', () {
    test('a failed write rolls back to the previous state and is reported',
        () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Ania');
      final exported = await profiles.exportBackup();
      await profiles.createProfile('Bartek');
      final prefs = await SharedPreferences.getInstance();
      final before = {
        for (final key in prefs.getKeys())
          if (key != ProfileStore.backupsKey) key: prefs.get(key),
      };

      final calls = <String>[];
      var registryWrites = 0;
      store.debugFailWrite = (key) {
        calls.add(key);
        // Fail the import's registry write only; the rollback succeeds.
        return key == ProfileStore.registryKey && registryWrites++ == 0;
      };
      await expectLater(
          profiles.importBackup(exported),
          throwsA(isA<BackupRestoreException>()
              .having((e) => e.rolledBack, 'rolledBack', isTrue)));
      store.debugFailWrite = null;

      final after = {
        for (final key in prefs.getKeys())
          if (key != ProfileStore.backupsKey) key: prefs.get(key),
      };
      expect(after, before);
      expect(calls.last, ProfileStore.registryKey);
      expect(profiles.profiles.map((p) => p.name), contains('Bartek'));
      expect(profiles.backups.last.reason, 'pre-import');
    });

    test('a failed rollback is an explicit error, never success', () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Ania');
      final exported = await profiles.exportBackup();
      await profiles.createProfile('Bartek');

      store.debugFailWrite = (key) => key == ProfileStore.registryKey;
      await expectLater(
          profiles.importBackup(exported),
          throwsA(isA<BackupRestoreException>()
              .having((e) => e.rolledBack, 'rolledBack', isFalse)
              .having((e) => e.rollbackFailures.single, 'failure',
                  contains(ProfileStore.registryKey))));
      store.debugFailWrite = null;

      // The retained pre-import backup recovers the previous state.
      final recovery = (await store.listBackups())
          .lastWhere((backup) => backup.reason == 'pre-import');
      await profiles.restoreBackupSnapshot(recovery.createdAt);
      expect(profiles.profiles.map((p) => p.name), contains('Bartek'));
    });

    test(
        'round-trips an exported document and rejects invalid ones without writing',
        () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Ania');
      final ania = profiles.profiles.last.id;
      final words = WordProvider(store: store);
      await words.setProfile(ania);
      await words.recordStudyDecision(_word('你'), StudyDecision.saved);
      await words.recordPracticeResult(
          exerciseId: 'x', kind: 'cloze', correct: false);
      final exported = await profiles.exportBackup();

      SharedPreferences.setMockInitialValues({});
      final target = ProfileProvider(store: _store());
      await target.initialize();
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(ProfileStore.registryKey);

      await expectLater(target.importBackup('{"version":1,"data":{}}'),
          throwsA(isA<FormatException>()));
      final tampered = json.decode(exported) as Map<String, dynamic>;
      (tampered['data'] as Map)['profile.$ania.my_words.v1'] = '[{"hanzi":1}]';
      await expectLater(target.importBackup(json.encode(tampered)),
          throwsA(isA<FormatException>()));
      expect(prefs.getString(ProfileStore.registryKey), before);
      expect(target.backups, isEmpty);

      await target.importBackup(exported);
      expect(target.profiles.map((p) => p.name), ['Learner', 'Ania']);
      expect(target.backups.single.reason, 'pre-import');
      final restored = WordProvider(store: _store());
      await restored.setProfile(ania);
      expect(restored.studyDecisionFor('你'), StudyDecision.saved);
      expect(restored.practiceHistory.single.correct, isFalse);
    });
  });

  group('reload after import', () {
    test('setProfile with the same id and reloadProfile drop stale progress',
        () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      final exported = await profiles.exportBackup();

      await words.recordStudyDecision(_word('你'), StudyDecision.known);
      await words.recordPracticeResult(
          exerciseId: 'a', kind: 'cloze', correct: true);
      expect(words.myWords, hasLength(1));

      await words.flush();
      await profiles.importBackup(exported);
      expect(words.myWords, hasLength(1), reason: 'not reloaded yet');
      await words.setProfile(profiles.activeProfile.id);
      expect(words.myWords, isEmpty);
      expect(words.studyDecisionFor('你'), isNull);
      expect(words.practiceHistory, isEmpty);

      await words.recordStudyDecision(_word('好'), StudyDecision.saved);
      await profiles.importBackup(exported);
      await words.reloadProfile();
      expect(words.myWords, isEmpty);
    });

    test('teacher preview of a learner is independent of the active profile',
        () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Teacher', isTeacher: true);
      final teacher = profiles.profiles.last.id;
      await profiles.createProfile('Learner 2');
      final learner = profiles.profiles.last.id;
      await profiles.selectProfile(teacher);
      final words = WordProvider(store: store);
      await words.setProfile(learner);
      await words.recordPracticeResult(
          exerciseId: 'q', kind: 'cloze', correct: true);

      final reloaded = ProfileProvider(store: _store());
      await reloaded.initialize();
      expect(reloaded.activeProfile.id, teacher);
      expect(words.profileId, learner);
      await words.setProfile(teacher);
      expect(words.practiceHistory, isEmpty);
    });
  });

  group('classroom namespace in backups', () {
    test('learner export never contains teacher notes; import keeps them',
        () async {
      final key = 'classroom.v1.${base64Url.encode(utf8.encode('default'))}';
      String value(Map<String, String> teacher, Map<String, String> pupil) =>
          json.encode({
            'version': 1,
            'shared': [],
            'teacherNotes': teacher,
            'pupilNotes': pupil,
          });
      SharedPreferences.setMockInitialValues(
          {key: value({'l1': 'private'}, {'l1': 'mine'})});
      final profiles = ProfileProvider(store: _store());
      await profiles.initialize();
      expect(profiles.activeProfile.isTeacher, isFalse);

      final learnerExport = await profiles.exportBackup();
      expect(learnerExport, isNot(contains('private')));
      expect(learnerExport, contains('mine'));
      final full = await profiles.exportBackup(includeTeacherNotes: true);
      expect(full, contains('private'));

      await profiles.importBackup(learnerExport);
      final prefs = await SharedPreferences.getInstance();
      final stored = json.decode(prefs.getString(key)!) as Map;
      expect(stored['teacherNotes'], {'l1': 'private'});
      expect(stored['pupilNotes'], {'l1': 'mine'});
    });

    test('export/import carries classroom keys and drops stale ones', () async {
      final store = _store();
      final profiles = ProfileProvider(store: store);
      await profiles.initialize();
      final prefs = await SharedPreferences.getInstance();
      const lessonKey = 'classroom.v1.ZGVmYXVsdA==';
      await prefs.setString(lessonKey, '{"version":1,"shared":[]}');
      await prefs.setString('appearance_v1', 'midnight');
      final exported = await profiles.exportBackup();
      final data = (json.decode(exported) as Map)['data'] as Map;
      expect(data[lessonKey], '{"version":1,"shared":[]}');
      expect(data.containsKey('appearance_v1'), isFalse);

      await prefs.setString(lessonKey, '{"version":1,"shared":["changed"]}');
      await prefs.setString('classroom_v1_stale', '{}');
      await profiles.importBackup(exported);
      expect(prefs.getString(lessonKey), '{"version":1,"shared":[]}');
      expect(prefs.containsKey('classroom_v1_stale'), isFalse);
      expect(prefs.getString('appearance_v1'), 'midnight');

      final preImport =
          json.decode(prefs.getString(ProfileStore.backupsKey)!) as List;
      expect(
          ((preImport.last as Map)['data'] as Map)['classroom_v1_stale'], '{}');
    });

    test('invalid classroom value rejects the whole import without writes',
        () async {
      final profiles = ProfileProvider(store: _store());
      await profiles.initialize();
      final document =
          json.decode(await profiles.exportBackup()) as Map<String, dynamic>;
      (document['data'] as Map)['classroom.v1.x'] = 'not json';
      await profiles.createProfile('Kept');
      await expectLater(profiles.importBackup(json.encode(document)),
          throwsA(isA<FormatException>()));
      final reloaded = ProfileProvider(store: _store());
      await reloaded.initialize();
      expect(reloaded.profiles.map((p) => p.name), contains('Kept'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('classroom.v1.x'), isFalse);
      expect(prefs.containsKey(ProfileStore.backupsKey), isFalse);
    });
  });

  group('WordProvider isolation', () {
    late ProfileStore store;
    late ProfileProvider profiles;
    late String other;

    setUp(() async {
      store = _store();
      profiles = ProfileProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Other');
      other = profiles.profiles.last.id;
    });

    test('saved words, decisions and practice history are per profile',
        () async {
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      await words.recordStudyDecision(_word('你'), StudyDecision.known);
      await words.recordStudyDecision(_word('好'), StudyDecision.skipped);
      await words.recordPracticeResult(
          exerciseId: 'cloze-1',
          kind: 'cloze',
          correct: true,
          details: {'n': 1});
      expect(words.learnedWordsCount, 1);
      expect(words.myWords.map((w) => w.hanzi), ['你']);

      await words.setProfile(other);
      expect(words.profileId, other);
      expect(words.myWords, isEmpty);
      expect(words.studyDecisionFor('你'), isNull);
      expect(words.practiceHistory, isEmpty);
      await words.recordStudyDecision(_word('学'), StudyDecision.saved);

      final fresh = WordProvider(store: _store());
      await fresh.setProfile(ProfileStore.defaultProfileId);
      expect(fresh.myWords.map((w) => w.hanzi), ['你']);
      expect(fresh.studyDecisionFor('好'), StudyDecision.skipped);
      expect(fresh.practiceHistory.single.exerciseId, 'cloze-1');
      expect(fresh.practiceHistory.single.details['n'], 1);
      await fresh.revisitSkippedWords();
      expect(fresh.studyDecisionFor('好'), isNull);

      await fresh.setProfile(other);
      expect(fresh.myWords.map((w) => w.hanzi), ['学']);
      expect(fresh.savedForStudyCount, 1);
    });

    test('a superseded profile switch never overwrites the newer one',
        () async {
      final words = WordProvider(store: store);
      await words.setProfile(other);
      await words.recordStudyDecision(_word('学'), StudyDecision.known);

      final first = words.setProfile(other);
      final second = words.setProfile(ProfileStore.defaultProfileId);
      await Future.wait([first, second]);
      expect(words.profileId, ProfileStore.defaultProfileId);
      expect(words.myWords, isEmpty);
    });

    test('a write started before a switch lands in its own profile only',
        () async {
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);

      final pendingWrite =
          words.recordStudyDecision(_word('你'), StudyDecision.known);
      final pendingSwitch = words.setProfile(other);
      await Future.wait([pendingWrite, pendingSwitch]);
      expect(words.profileId, other);
      expect(words.myWords, isEmpty);
      expect(words.studyDecisionFor('你'), isNull);

      await words.setProfile(ProfileStore.defaultProfileId);
      expect(words.studyDecisionFor('你'), StudyDecision.known);
    });

    test('concurrent writes are serialized without lost updates', () async {
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      await Future.wait([
        for (final hanzi in ['一', '二', '三', '四'])
          words.recordStudyDecision(_word(hanzi), StudyDecision.saved),
      ]);
      await words.flush();
      final fresh = WordProvider(store: _store());
      await fresh.setProfile(ProfileStore.defaultProfileId);
      expect(fresh.myWords.map((w) => w.hanzi).toSet(), {'一', '二', '三', '四'});
    });

    test('unknown profile is rejected and mutations need a profile', () async {
      final words = WordProvider(store: store);
      await expectLater(words.addToMyWords(_word('你')), throwsStateError);
      await expectLater(words.setProfile('missing'), throwsArgumentError);
      expect(words.profileId, isNull);
    });

    test('test results are saved to the profile the test started in', () async {
      final words = WordProvider(store: store);
      await words.setProfile(ProfileStore.defaultProfileId);
      final tests = TestProvider(store: store);
      await tests.startTest(availableWords: [_word('你'), _word('好')]);
      expect(tests.testProfileId, ProfileStore.defaultProfileId);
      while (true) {
        tests.answerQuestion(tests.currentQuestion!.correctAnswer);
        if (tests.isLastQuestion) break;
        tests.nextQuestion();
      }

      await words.setProfile(other);
      await tests.finishTest();
      await words.loadData();
      expect(words.myWords, isEmpty);
      expect(words.practiceHistory, isEmpty);

      await words.setProfile(ProfileStore.defaultProfileId);
      expect(words.myWords.map((w) => w.hanzi).toSet(), {'你', '好'});
      expect(words.practiceHistory.map((r) => r.kind).toSet(), {'hsk_test'});
      expect(words.practiceHistory.every((r) => r.correct), isTrue);
    });
  });
}
