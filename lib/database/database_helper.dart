import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show MissingPluginException, rootBundle;
import '../models/learner_profile.dart';
import '../models/word.dart';
import '../services/vocabulary_category_store.dart';
import '../utils/chinese_converter_helper.dart';
import 'legacy_file.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static SharedPreferences? _prefs;

  DatabaseHelper._init();

  Future<void> _initPrefs() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDB('my_words.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns for version 2
      await db.execute('ALTER TABLE my_words ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE my_words ADD COLUMN partOfSpeech TEXT');
      await db.execute('ALTER TABLE my_words ADD COLUMN frequency INTEGER');
    }
    if (oldVersion < 3) {
      // Add traditional Chinese column for version 3
      await db.execute('ALTER TABLE my_words ADD COLUMN traditional TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE my_words ADD COLUMN sourceWord TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE my_words (
        hanzi TEXT PRIMARY KEY,
        traditional TEXT,
        pinyin TEXT NOT NULL,
        english TEXT NOT NULL,
        polish TEXT NOT NULL,
        level TEXT NOT NULL,
        tags TEXT,
        partOfSpeech TEXT,
        frequency INTEGER,
        sourceWord TEXT,
        notes TEXT,
        added_date TEXT NOT NULL
      )
    ''');
  }

  // Add word to "My Words"
  @Deprecated('Legacy global store. Use ProfileStore for per-profile data.')
  Future<void> addWord(Word word) async {
    if (kIsWeb) {
      await _initPrefs();
      // ignore: deprecated_member_use_from_same_package
      final words = await getMyWords();
      words.add(word);
      final jsonList = words.map((w) => w.toJson()).toList();
      await _prefs!.setString('my_words', json.encode(jsonList));
    } else {
      final db = await database;
      await db.insert(
        'my_words',
        {
          ...word.toMap(),
          'added_date': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Remove word from "My Words"
  @Deprecated('Legacy global store. Use ProfileStore for per-profile data.')
  Future<void> removeWord(String hanzi) async {
    if (kIsWeb) {
      await _initPrefs();
      // ignore: deprecated_member_use_from_same_package
      final words = await getMyWords();
      words.removeWhere((w) => w.hanzi == hanzi);
      final jsonList = words.map((w) => w.toJson()).toList();
      await _prefs!.setString('my_words', json.encode(jsonList));
    } else {
      final db = await database;
      await db.delete(
        'my_words',
        where: 'hanzi = ?',
        whereArgs: [hanzi],
      );
    }
  }

  // Get all "My Words"
  @Deprecated('Legacy global store. Use ProfileStore for per-profile data.')
  Future<List<Word>> getMyWords() async {
    if (kIsWeb) {
      await _initPrefs();
      final jsonString = _prefs!.getString('my_words');
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Word.fromJson(json)).toList();
    } else {
      final db = await database;
      final maps = await db.query('my_words');
      return maps.map((map) => Word.fromMap(map)).toList();
    }
  }

  // Check if word is in "My Words"
  @Deprecated('Legacy global store. Use ProfileStore for per-profile data.')
  Future<bool> isWordLearned(String hanzi) async {
    if (kIsWeb) {
      // ignore: deprecated_member_use_from_same_package
      final words = await getMyWords();
      return words.any((w) => w.hanzi == hanzi);
    } else {
      final db = await database;
      final result = await db.query(
        'my_words',
        where: 'hanzi = ?',
        whereArgs: [hanzi],
      );
      return result.isNotEmpty;
    }
  }

  // Get count of learned words by level
  @Deprecated('Legacy global store. Use ProfileStore for per-profile data.')
  Future<Map<String, int>> getLearnedCountByLevel() async {
    // ignore: deprecated_member_use_from_same_package
    final words = await getMyWords();
    final Map<String, int> counts = {};

    for (var word in words) {
      counts[word.level] = (counts[word.level] ?? 0) + 1;
    }

    return counts;
  }

  /// Absolute path of the legacy (pre-profile) SQLite database. On Windows and
  /// Linux (sqflite FFI) this resolves against the process working directory
  /// (`.dart_tool/sqflite_common_ffi/databases`), i.e. usually the install
  /// directory, so it is only read for migration and never written by profiles.
  /// Computing the path does not load the SQLite library.
  Future<String> legacyDatabasePath() async =>
      join(await getDatabasesPath(), 'my_words.db');

  /// Reads the legacy global "My Words" without modifying or creating it.
  /// Returns Word JSON maps, with `addedDate` when known.
  ///
  /// Native: if no legacy file exists, returns `[]` without opening SQLite
  /// (so a missing sqlite3 library does not block new installs). If the file
  /// exists it is opened read-only, without schema upgrades; any failure
  /// (e.g. SQLite library missing, corrupt file) is thrown, never ignored.
  Future<List<Map<String, dynamic>>> readLegacyMyWordEntries() async {
    if (kIsWeb) return readLegacyPrefsWordEntries();
    final String path;
    try {
      path = await legacyDatabasePath();
    } on MissingPluginException {
      rethrow;
    } on StateError catch (error) {
      // No sqflite backend configured in this process (e.g. widget tests on a
      // desktop host). The location of legacy data cannot be resolved.
      throw LegacySqliteUnavailableException(error);
    }
    if (!await legacyFileExists(path)) return [];
    final Database db;
    try {
      db = await openDatabase(path, readOnly: true, singleInstance: false);
    } catch (error) {
      throw LegacyMigrationException(path, error);
    }
    try {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'my_words'");
      if (tables.isEmpty) return [];
      final rows = await db.rawQuery('SELECT * FROM my_words');
      return rows
          .map((row) => <String, dynamic>{
                ...Word.fromMap(row).toJson(),
                if (row['added_date'] != null) 'addedDate': row['added_date'],
              })
          .toList();
    } catch (error) {
      throw LegacyMigrationException(path, error);
    } finally {
      await db.close();
    }
  }

  /// Reads the legacy web store (SharedPreferences key `my_words`).
  Future<List<Map<String, dynamic>>> readLegacyPrefsWordEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('my_words');
    if (raw == null) return [];
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw const FormatException('Legacy my_words value is not a list');
    }
    return decoded
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  // Load all words from separate HSK level files
  Future<List<Word>> loadAllWords() async {
    final List<Word> allWords = [];
    final categoryStore = await VocabularyCategoryStore.load();

    const assets = [
      'assets/data/hsk2025_1_words.json',
      'assets/data/hsk2025_2_words.json',
      'assets/data/hsk2025_3_words.json',
      'assets/data/hsk2025_4_words.json',
      'assets/data/hsk2025_5_words.json',
      'assets/data/hsk2025_6_words.json',
      'assets/data/hsk2025_7_9_words.json',
    ];

    for (final asset in assets) {
      final jsonString = await rootBundle.loadString(asset);
      final jsonList = json.decode(jsonString) as List<dynamic>;
      allWords.addAll(jsonList.map((value) {
        final row = value as Map<String, dynamic>;
        final word = Word.fromJson({
          ...row,
          'categories': categoryStore.categoriesFor(row),
        });
        if (word.traditional != word.hanzi || word.displayHanzi != word.hanzi) {
          return word;
        }
        return Word(
          hanzi: word.hanzi,
          traditional: ChineseConverterHelper.toTraditional(word.displayHanzi),
          pinyin: word.pinyin,
          englishTranslation: word.englishTranslation,
          polishTranslation: word.polishTranslation,
          level: word.level,
          notes: word.notes,
          tags: word.tags,
          categories: word.categories,
          partOfSpeech: word.partOfSpeech,
          frequency: word.frequency,
          sourceWord: word.sourceWord,
        );
      }));
    }

    categoryStore.validateLoaded();
    return allWords;
  }

  // Load words for specific HSK level
  Future<List<Word>> loadWordsByLevel(String level) async {
    final compactLevel =
        level.trim().toUpperCase().replaceAll(' ', '').replaceAll('–', '-');
    final levelKey = compactLevel.startsWith('HSK') &&
            compactLevel.length > 3 &&
            compactLevel[3] != '-'
        ? 'HSK-${compactLevel.substring(3)}'
        : compactLevel;
    final asset = switch (levelKey) {
      'HSK-1' => 'assets/data/hsk2025_1_words.json',
      'HSK-2' => 'assets/data/hsk2025_2_words.json',
      'HSK-3' => 'assets/data/hsk2025_3_words.json',
      'HSK-4' => 'assets/data/hsk2025_4_words.json',
      'HSK-5' => 'assets/data/hsk2025_5_words.json',
      'HSK-6' => 'assets/data/hsk2025_6_words.json',
      'HSK-7-9' => 'assets/data/hsk2025_7_9_words.json',
      _ => throw ArgumentError.value(level, 'level', 'Unknown HSK level'),
    };
    final categoryStore = await VocabularyCategoryStore.load();
    final jsonString = await rootBundle.loadString(asset);
    final jsonList = json.decode(jsonString) as List<dynamic>;
    final words = jsonList.map((value) {
      final row = value as Map<String, dynamic>;
      return Word.fromJson({
        ...row,
        'categories': categoryStore.categoriesFor(row),
      });
    }).toList(growable: false);
    categoryStore.validateLoaded(level: levelKey);
    return words;
  }

  // Close database
  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      await _database!.close();
    }
  }
}

/// The SQLite backend is not configured, so the legacy database location
/// cannot even be resolved. Migration records this in its marker.
class LegacySqliteUnavailableException implements Exception {
  LegacySqliteUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'Legacy SQLite storage unavailable: $cause';
}

/// Importing or restoring a backup failed while writing. [rolledBack] tells
/// whether the previous state was fully put back; if not, the state may be
/// mixed and the user must restore the retained `pre-import`/`pre-restore`
/// backup (see [ProfileStore.listBackups]).
class BackupRestoreException implements Exception {
  BackupRestoreException({
    required this.cause,
    required this.rolledBack,
    required this.rollbackFailures,
    required this.recoveryBackupReason,
  });

  final Object cause;
  final bool rolledBack;
  final List<String> rollbackFailures;
  final String recoveryBackupReason;

  @override
  String toString() => rolledBack
      ? 'Backup could not be applied ($cause). Previous data was restored.'
      : 'Backup could not be applied ($cause) and rollback failed for '
          '${rollbackFailures.join('; ')}. Data may be inconsistent: restore '
          'the "$recoveryBackupReason" backup.';
}

/// Legacy saved words exist but could not be read. Nothing was migrated and
/// the legacy file was left untouched; migration is retried on next start.
class LegacyMigrationException implements Exception {
  LegacyMigrationException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() =>
      'Could not read saved words from the previous version ($path): $cause. '
      'The file was not modified.';
}

/// Loads legacy global "My Words" entries (Word JSON maps).
typedef LegacyWordsLoader = Future<List<Map<String, dynamic>>> Function();

/// Profiles and the currently active profile id.
class ProfileRegistry {
  ProfileRegistry(
      {required List<LearnerProfile> profiles, required this.activeId})
      : profiles = List.unmodifiable(profiles);

  final List<LearnerProfile> profiles;
  final String activeId;

  LearnerProfile get activeProfile =>
      profiles.firstWhere((profile) => profile.id == activeId);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'activeId': activeId,
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
      };

  factory ProfileRegistry.fromJson(Map<String, dynamic> json) {
    final rawProfiles = json['profiles'];
    final activeId = json['activeId'];
    if (rawProfiles is! List || activeId is! String) {
      throw FormatException('Invalid learner profile registry: $json');
    }
    final profiles = rawProfiles
        .map((entry) =>
            LearnerProfile.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    if (profiles.isEmpty) {
      throw const FormatException('Learner profile registry has no profiles');
    }
    if (profiles.map((profile) => profile.id).toSet().length !=
        profiles.length) {
      throw const FormatException('Learner profile registry has duplicate ids');
    }
    return ProfileRegistry(
      profiles: profiles,
      activeId: profiles.any((profile) => profile.id == activeId)
          ? activeId
          : profiles.first.id,
    );
  }
}

/// Persistent per-profile learning state in SharedPreferences.
///
/// SharedPreferences lives in the per-user application data directory
/// (e.g. `%APPDATA%\<company>\<product>\shared_preferences.json` on Windows,
/// `localStorage` on web), so it survives replacing the installation folder
/// as long as the application identity is unchanged.
///
/// All reads and writes run through one serial queue, so read-modify-write
/// updates never interleave. Every write is checked; failures throw.
/// The legacy global data (`study_decisions` key and the `my_words` SQLite
/// database / web key) is migrated once into the default profile and is
/// never modified or deleted.
class ProfileStore {
  ProfileStore({LegacyWordsLoader? legacyWordsLoader, Random? random})
      : legacyWordsLoader = legacyWordsLoader ??
            DatabaseHelper.instance.readLegacyMyWordEntries,
        _random = random ?? Random.secure();

  static final ProfileStore instance = ProfileStore();

  static const defaultProfileId = 'default';
  static const defaultProfileName = 'Learner';
  static const registryKey = 'learner_profiles_v1';
  static const migrationKey = 'learner_profiles_migration_v1';
  static const backupsKey = 'learner_profiles_backups_v1';
  static const legacyDecisionsKey = 'study_decisions';
  static const maxPracticeRecords = 5000;
  static const maxBackups = 3;

  /// SharedPreferences key prefixes of other per-learner data (classroom
  /// lessons/notes) that are included in backups, export and import. Values
  /// under these prefixes must be JSON-object strings.
  static const backupNamespacePrefixes = ['classroom.v1.', 'classroom_v1_'];

  static bool isNamespaceKey(String key) =>
      backupNamespacePrefixes.any((prefix) => key.startsWith(prefix));
  static const maxNameLength = 80;
  static const validDecisions = {'saved', 'known', 'skipped'};

  static String wordsKey(String profileId) => 'profile.$profileId.my_words.v1';
  static String decisionsKey(String profileId) =>
      'profile.$profileId.study_decisions.v1';
  static String historyKey(String profileId) =>
      'profile.$profileId.practice_history.v1';

  /// Source of legacy global "My Words", read once during migration.
  /// Defaults to the SQLite database (native) / `my_words` prefs key (web).
  /// Tests may replace it on [instance] to avoid native database access.
  LegacyWordsLoader legacyWordsLoader;
  final Random _random;
  Future<void> _tail = Future<void>.value();

  /// Profile currently shown by the WordProvider. Used by components that do
  /// not receive a profile explicitly (e.g. TestProvider) to capture a target.
  String? boundProfileId;

  /// Completes once every operation queued before this call has finished.
  Future<void> flush() => _tail;

  Future<T> _serial<T>(Future<T> Function(SharedPreferences prefs) operation) {
    final result = _tail.then<T>((_) async {
      final prefs = await SharedPreferences.getInstance();
      await _ensureInitialized(prefs);
      return operation(prefs);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  // ---------------------------------------------------------------- registry

  Future<ProfileRegistry> loadRegistry() =>
      _serial((prefs) async => _readRegistry(prefs));

  Future<(ProfileRegistry, LearnerProfile)> createProfile(
    String name, {
    bool isTeacher = false,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name must not be empty');
    }
    if (trimmed.length > maxNameLength) {
      throw ArgumentError.value(name, 'name',
          'Profile name is longer than $maxNameLength characters');
    }
    return _serial((prefs) async {
      final registry = _readRegistry(prefs);
      final lower = trimmed.toLowerCase();
      if (registry.profiles
          .any((profile) => profile.name.toLowerCase() == lower)) {
        throw ArgumentError.value(
            name, 'name', 'A profile with this name exists');
      }
      final ids = registry.profiles.map((profile) => profile.id).toSet();
      String id;
      do {
        id = 'p_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
            '_${_random.nextInt(0x7fffffff).toRadixString(36)}';
      } while (ids.contains(id));
      final profile = LearnerProfile(
        id: id,
        name: trimmed,
        isTeacher: isTeacher,
        createdAt: DateTime.now(),
      );
      final updated = ProfileRegistry(
        profiles: [...registry.profiles, profile],
        activeId: registry.activeId,
      );
      await _write(prefs, registryKey, json.encode(updated.toJson()));
      return (updated, profile);
    });
  }

  Future<ProfileRegistry> setActiveProfile(String id) => _serial((prefs) async {
        final registry = _readRegistry(prefs);
        _requireProfile(registry, id);
        if (registry.activeId == id) return registry;
        final updated =
            ProfileRegistry(profiles: registry.profiles, activeId: id);
        await _write(prefs, registryKey, json.encode(updated.toJson()));
        return updated;
      });

  // ----------------------------------------------------------- profile data

  Future<ProfileState> loadProfileState(String profileId) =>
      _serial((prefs) async {
        _requireProfile(_readRegistry(prefs), profileId);
        return _readState(prefs, profileId);
      });

  /// Adds or replaces [word] in the profile's words, optionally recording a
  /// study [decision] in the same atomic update.
  Future<ProfileState> saveWord(String profileId, Word word,
      {String? decision}) {
    _checkDecision(decision);
    return _mutate(profileId, (entries, decisions, history) {
      _upsertWord(entries, word, replace: true);
      if (decision != null) decisions[word.hanzi] = decision;
    });
  }

  /// Adds words that are not yet saved (existing entries stay untouched).
  Future<ProfileState> addWordsIfAbsent(
    String profileId,
    List<Word> words, {
    List<PracticeRecord> practiceResults = const [],
  }) =>
      _mutate(profileId, (entries, decisions, history) {
        for (final word in words) {
          _upsertWord(entries, word, replace: false);
        }
        history.addAll(practiceResults);
      });

  /// Removes [hanzi] from the profile's words and clears its decision when it
  /// is one of [clearDecisions].
  Future<ProfileState> removeWord(
    String profileId,
    String hanzi, {
    Set<String> clearDecisions = const {'saved', 'known'},
  }) =>
      _mutate(profileId, (entries, decisions, history) {
        entries.removeWhere((entry) => entry['hanzi'] == hanzi);
        if (clearDecisions.contains(decisions[hanzi])) decisions.remove(hanzi);
      });

  /// Sets ([decision] non-null) or clears the study decision for [hanzi].
  Future<ProfileState> setDecision(
      String profileId, String hanzi, String? decision) {
    _checkDecision(decision);
    return _mutate(profileId, (entries, decisions, history) {
      if (decision == null) {
        decisions.remove(hanzi);
      } else {
        decisions[hanzi] = decision;
      }
    });
  }

  Future<ProfileState> removeDecisionsWhere(
    String profileId,
    bool Function(String hanzi, String decision) test,
  ) =>
      _mutate(profileId, (entries, decisions, history) {
        decisions.removeWhere(test);
      });

  /// Appends practice results. Only the newest [maxPracticeRecords] are kept.
  Future<ProfileState> recordPracticeResults(
    String profileId,
    List<PracticeRecord> results,
  ) =>
      _mutate(profileId, (entries, decisions, history) {
        history.addAll(results);
      });

  Future<ProfileState> _mutate(
    String profileId,
    void Function(
      List<Map<String, dynamic>> entries,
      Map<String, String> decisions,
      List<PracticeRecord> history,
    ) change,
  ) =>
      _serial((prefs) async {
        _requireProfile(_readRegistry(prefs), profileId);
        final entries = _readWordEntries(prefs, profileId);
        final decisions = _readDecisions(prefs, decisionsKey(profileId));
        final history = _readHistory(prefs, profileId);
        final originalEntries = json.encode(entries);
        final originalDecisions = json.encode(decisions);
        final originalHistory = history.length;
        change(entries, decisions, history);
        final historyChanged = history.length != originalHistory;
        if (history.length > maxPracticeRecords) {
          history.removeRange(0, history.length - maxPracticeRecords);
        }
        // Encode everything first so invalid data never causes a partial write.
        final encodedEntries = json.encode(entries);
        final encodedDecisions = json.encode(decisions);
        final encodedHistory = historyChanged
            ? json.encode(history.map((record) => record.toJson()).toList())
            : null;
        if (encodedEntries != originalEntries) {
          await _write(prefs, wordsKey(profileId), encodedEntries);
        }
        if (encodedDecisions != originalDecisions) {
          await _write(prefs, decisionsKey(profileId), encodedDecisions);
        }
        if (encodedHistory != null) {
          await _write(prefs, historyKey(profileId), encodedHistory);
        }
        return _stateFrom(profileId, entries, decisions, history);
      });

  // ---------------------------------------------------------------- backups

  /// Stores a snapshot of every profile key (plus [backupNamespacePrefixes]
  /// keys) inside SharedPreferences
  /// (rotating, newest [maxBackups] kept). Protects against a faulty update
  /// or migration; it does not protect against loss of the preferences file
  /// itself — use [exportSnapshotJson] to keep an external copy.
  Future<ProfileBackupInfo> createBackup({String reason = 'manual'}) =>
      _serial((prefs) => _createBackup(prefs, reason));

  Future<List<ProfileBackupInfo>> listBackups() => _serial((prefs) async =>
      _readBackups(prefs).map(_backupInfo).toList(growable: false));

  /// JSON document with all profile data (same format as stored backups).
  /// With [includeTeacherNotes] false, every classroom value's private
  /// `teacherNotes` is emptied and the document is marked
  /// `teacherNotesIncluded: false`; importing such a document keeps the
  /// teacher notes already stored on the device.
  Future<String> exportSnapshotJson(
          {String reason = 'export', bool includeTeacherNotes = true}) =>
      _serial((prefs) async {
        final snapshot = _snapshot(prefs, reason);
        if (!includeTeacherNotes) {
          final data = snapshot['data'] as Map<String, String?>;
          for (final key in data.keys.where(isNamespaceKey).toList()) {
            data[key] = _withTeacherNotes(data[key]!, const {});
          }
          snapshot['teacherNotesIncluded'] = false;
        }
        return json.encode(snapshot);
      });

  static String _withTeacherNotes(String raw, Object notes) {
    final decoded = Map<String, dynamic>.from(json.decode(raw) as Map);
    if (!decoded.containsKey('teacherNotes')) return raw;
    decoded['teacherNotes'] = notes;
    return json.encode(decoded);
  }

  /// Restores the backup created at [createdAt]. The current state is saved
  /// as a `pre-restore` backup first, so restoring is reversible.
  Future<ProfileRegistry> restoreBackup(DateTime createdAt) =>
      _serial((prefs) async {
        final target = _readBackups(prefs).where((backup) =>
            DateTime.parse(backup['createdAt'] as String)
                .isAtSameMomentAs(createdAt));
        if (target.isEmpty) {
          throw ArgumentError.value(createdAt, 'createdAt', 'No such backup');
        }
        return _restoreSnapshot(prefs, target.first, 'pre-restore');
      });

  /// Replaces all profiles with a document produced by [exportSnapshotJson].
  /// The document is fully validated before anything is written, and the
  /// current state is saved as a `pre-import` backup first.
  Future<ProfileRegistry> importSnapshotJson(String document) {
    final decoded = json.decode(document);
    if (decoded is! Map) {
      throw const FormatException('Backup is not a JSON object');
    }
    final snapshot = Map<String, dynamic>.from(decoded);
    return _serial((prefs) => _restoreSnapshot(prefs, snapshot, 'pre-import'));
  }

  static final _profileKeyPattern = RegExp(
      r'^profile\.([^.]+)\.(my_words|study_decisions|practice_history)\.v1$');

  Future<ProfileRegistry> _restoreSnapshot(
    SharedPreferences prefs,
    Map<String, dynamic> snapshot,
    String backupReason,
  ) async {
    if (snapshot['version'] != 1 || snapshot['data'] is! Map) {
      throw const FormatException('Unsupported profile backup format');
    }
    final data = Map<String, dynamic>.from(snapshot['data'] as Map);
    final registryRaw = data[registryKey];
    if (registryRaw is! String) {
      throw const FormatException('Backup does not contain a profile registry');
    }
    final registry = ProfileRegistry.fromJson(
        Map<String, dynamic>.from(json.decode(registryRaw) as Map));
    final ids = registry.profiles.map((profile) => profile.id).toSet();
    for (final entry in data.entries) {
      final value = entry.value;
      if (value != null && value is! String) {
        throw FormatException('Invalid backup value for ${entry.key}');
      }
      if (entry.key == registryKey || entry.key == migrationKey) continue;
      if (isNamespaceKey(entry.key)) {
        if (value == null || json.decode(value as String) is! Map) {
          throw FormatException('Invalid backup value for ${entry.key}');
        }
        continue;
      }
      final match = _profileKeyPattern.firstMatch(entry.key);
      if (match == null || !ids.contains(match.group(1))) {
        throw FormatException('Unexpected backup key ${entry.key}');
      }
      if (value == null) continue;
      final decodedValue = json.decode(value as String);
      switch (match.group(2)) {
        case 'my_words':
          if (decodedValue is! List)
            throw FormatException('Invalid ${entry.key}');
          for (final word in decodedValue) {
            try {
              Word.fromJson(Map<String, dynamic>.from(word as Map));
            } catch (error) {
              throw FormatException('Invalid word in ${entry.key}: $error');
            }
          }
        case 'study_decisions':
          if (decodedValue is! Map)
            throw FormatException('Invalid ${entry.key}');
        case 'practice_history':
          if (decodedValue is! List)
            throw FormatException('Invalid ${entry.key}');
          for (final record in decodedValue) {
            PracticeRecord.fromJson(Map<String, dynamic>.from(record as Map));
          }
      }
    }

    if (snapshot['teacherNotesIncluded'] == false) {
      // Learner export: carry over the device's private teacher notes.
      for (final key in data.keys.where(isNamespaceKey).toList()) {
        final current = prefs.get(key);
        if (current is! String) continue;
        final notes = (json.decode(current) as Map)['teacherNotes'];
        if (notes is Map && notes.isNotEmpty) {
          data[key] = _withTeacherNotes(data[key] as String, notes);
        }
      }
    }

    await _createBackup(prefs, backupReason);
    final affectedKeys = <String>{
      registryKey,
      migrationKey,
      ...data.keys,
      ...prefs.getKeys().where(
          (key) => isNamespaceKey(key) || _profileKeyPattern.hasMatch(key)),
    };
    final before = <String, String?>{
      for (final key in affectedKeys) key: prefs.getString(key),
    };
    try {
      await _applyImportedData(prefs, data, ids, registryRaw);
    } catch (error) {
      // SharedPreferences has no transactions: put every touched key back,
      // registry last, and keep going past individual failures.
      final rollbackFailures = <String>[];
      final ordered = before.keys.where((key) => key != registryKey).toList()
        ..add(registryKey);
      for (final key in ordered) {
        final value = before[key];
        try {
          if (value != null) {
            await _write(prefs, key, value);
          } else if (prefs.containsKey(key)) {
            await _remove(prefs, key);
          }
        } catch (rollbackError) {
          rollbackFailures.add('$key: $rollbackError');
        }
      }
      throw BackupRestoreException(
        cause: error,
        rolledBack: rollbackFailures.isEmpty,
        rollbackFailures: rollbackFailures,
        recoveryBackupReason: backupReason,
      );
    }
    return registry;
  }

  Future<void> _applyImportedData(
    SharedPreferences prefs,
    Map<String, dynamic> data,
    Set<String> ids,
    String registryRaw,
  ) async {
    for (final entry in data.entries) {
      if (entry.key == registryKey) continue;
      final value = entry.value;
      if (value is String) {
        await _write(prefs, entry.key, value);
      } else if (prefs.containsKey(entry.key)) {
        await _remove(prefs, entry.key);
      }
    }
    // Keys a restored profile does not carry must not mix in current data.
    for (final key in prefs.getKeys().where(isNamespaceKey).toList()) {
      if (!data.containsKey(key)) await _remove(prefs, key);
    }
    for (final id in ids) {
      for (final key in [wordsKey(id), decisionsKey(id), historyKey(id)]) {
        if (!data.containsKey(key) && prefs.containsKey(key)) {
          await _remove(prefs, key);
        }
      }
    }
    if (prefs.getString(migrationKey) == null) {
      await _write(
          prefs,
          migrationKey,
          json.encode({
            'status': 'imported',
            'at': DateTime.now().toUtc().toIso8601String()
          }));
    }
    await _write(prefs, registryKey, registryRaw);
  }

  Future<ProfileBackupInfo> _createBackup(
      SharedPreferences prefs, String reason) async {
    final backups = _readBackups(prefs);
    final snapshot = _snapshot(prefs, reason);
    backups.add(snapshot);
    while (backups.length > maxBackups) {
      backups.removeAt(0);
    }
    await _write(prefs, backupsKey, json.encode(backups));
    return _backupInfo(snapshot);
  }

  Map<String, dynamic> _snapshot(SharedPreferences prefs, String reason) {
    final registry = _readRegistry(prefs);
    final keys = <String>[
      registryKey,
      migrationKey,
      for (final profile in registry.profiles) ...[
        wordsKey(profile.id),
        decisionsKey(profile.id),
        historyKey(profile.id),
      ],
    ];
    final namespaceKeys = prefs.getKeys().where(isNamespaceKey).toList()
      ..sort();
    final data = <String, String?>{
      for (final key in keys) key: prefs.getString(key),
    };
    for (final key in namespaceKeys) {
      final value = prefs.get(key);
      if (value is! String) {
        throw StateError('Cannot back up $key: value is not a string');
      }
      data[key] = value;
    }
    return {
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'reason': reason,
      'profileCount': registry.profiles.length,
      'data': data,
    };
  }

  List<Map<String, dynamic>> _readBackups(SharedPreferences prefs) {
    final raw = prefs.getString(backupsKey);
    if (raw == null) return [];
    final decoded = json.decode(raw);
    if (decoded is! List)
      throw const FormatException('Invalid profile backups');
    return decoded
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  ProfileBackupInfo _backupInfo(Map<String, dynamic> backup) =>
      ProfileBackupInfo(
        createdAt: DateTime.parse(backup['createdAt'] as String),
        reason: backup['reason'] as String? ?? '',
        profileCount: backup['profileCount'] as int? ?? 0,
      );

  // ---------------------------------------------------------------- helpers

  Future<void> _ensureInitialized(SharedPreferences prefs) async {
    if (prefs.getString(migrationKey) != null &&
        prefs.getString(registryKey) != null) {
      return;
    }
    await _migrateLegacy(prefs);
  }

  /// Copies legacy global data into the default profile (merge, idempotent).
  /// The marker is written last, so an interrupted migration is retried.
  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    var status = 'migrated';
    String? note;
    List<Map<String, dynamic>> legacyWords;
    try {
      legacyWords = await legacyWordsLoader();
    } on MissingPluginException catch (error) {
      // No SQLite plugin on this platform: the legacy app could not have
      // stored words here either. Recorded in the marker, not hidden.
      legacyWords = const [];
      status = 'legacy_sqlite_unavailable';
      note = error.toString();
    } on LegacySqliteUnavailableException catch (error) {
      legacyWords = const [];
      status = 'legacy_sqlite_unavailable';
      note = error.toString();
    }
    final legacyDecisions = _readDecisions(prefs, legacyDecisionsKey);

    var registry = prefs.getString(registryKey) == null
        ? ProfileRegistry(
            profiles: [
              LearnerProfile(
                id: defaultProfileId,
                name: defaultProfileName,
                createdAt: DateTime.now(),
              ),
            ],
            activeId: defaultProfileId,
          )
        : _readRegistry(prefs);
    if (!registry.profiles.any((profile) => profile.id == defaultProfileId)) {
      registry = ProfileRegistry(
        profiles: [
          LearnerProfile(id: defaultProfileId, name: defaultProfileName),
          ...registry.profiles,
        ],
        activeId: registry.activeId,
      );
    }

    final entries = _readWordEntries(prefs, defaultProfileId);
    var migratedWords = 0;
    for (final legacy in legacyWords) {
      final Word word;
      try {
        word = Word.fromJson(legacy);
      } catch (error) {
        throw FormatException('Invalid legacy saved word $legacy: $error');
      }
      if (entries.any((entry) => entry['hanzi'] == word.hanzi)) continue;
      entries.add({
        ...word.toJson(),
        'addedDate':
            legacy['addedDate'] as String? ?? DateTime.now().toIso8601String(),
      });
      migratedWords++;
    }
    final decisions = {
      ...legacyDecisions,
      ..._readDecisions(prefs, decisionsKey(defaultProfileId)),
    };

    await _write(prefs, wordsKey(defaultProfileId), json.encode(entries));
    await _write(prefs, decisionsKey(defaultProfileId), json.encode(decisions));
    await _write(prefs, registryKey, json.encode(registry.toJson()));
    await _write(
      prefs,
      migrationKey,
      json.encode({
        'status': status,
        'at': DateTime.now().toUtc().toIso8601String(),
        'legacyWords': legacyWords.length,
        'migratedWords': migratedWords,
        'legacyDecisions': legacyDecisions.length,
        if (note != null) 'note': note,
      }),
    );
  }

  ProfileRegistry _readRegistry(SharedPreferences prefs) {
    final raw = prefs.getString(registryKey);
    if (raw == null) throw StateError('Learner profile registry is missing');
    return ProfileRegistry.fromJson(
        Map<String, dynamic>.from(json.decode(raw) as Map));
  }

  void _requireProfile(ProfileRegistry registry, String id) {
    if (!registry.profiles.any((profile) => profile.id == id)) {
      throw ArgumentError.value(id, 'profileId', 'Unknown learner profile');
    }
  }

  void _checkDecision(String? decision) {
    if (decision != null && !validDecisions.contains(decision)) {
      throw ArgumentError.value(decision, 'decision', 'Unknown study decision');
    }
  }

  void _upsertWord(List<Map<String, dynamic>> entries, Word word,
      {required bool replace}) {
    final index = entries.indexWhere((entry) => entry['hanzi'] == word.hanzi);
    if (index < 0) {
      entries.add(
          {...word.toJson(), 'addedDate': DateTime.now().toIso8601String()});
    } else if (replace) {
      entries[index] = {
        ...word.toJson(),
        'addedDate': entries[index]['addedDate']
      };
    }
  }

  List<Map<String, dynamic>> _readWordEntries(
      SharedPreferences prefs, String profileId) {
    final raw = prefs.getString(wordsKey(profileId));
    if (raw == null) return [];
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw FormatException('Saved words of profile $profileId are corrupt');
    }
    return decoded
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  Map<String, String> _readDecisions(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    final decoded = json.decode(raw);
    if (decoded is! Map)
      throw FormatException('Study decisions in $key are corrupt');
    return {
      for (final entry in decoded.entries)
        if (entry.value is String && validDecisions.contains(entry.value))
          entry.key as String: entry.value as String,
    };
  }

  List<PracticeRecord> _readHistory(SharedPreferences prefs, String profileId) {
    final raw = prefs.getString(historyKey(profileId));
    if (raw == null) return [];
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw FormatException(
          'Practice history of profile $profileId is corrupt');
    }
    return decoded
        .map((entry) =>
            PracticeRecord.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
  }

  ProfileState _readState(SharedPreferences prefs, String profileId) =>
      _stateFrom(
        profileId,
        _readWordEntries(prefs, profileId),
        _readDecisions(prefs, decisionsKey(profileId)),
        _readHistory(prefs, profileId),
      );

  ProfileState _stateFrom(
    String profileId,
    List<Map<String, dynamic>> entries,
    Map<String, String> decisions,
    List<PracticeRecord> history,
  ) =>
      ProfileState(
        profileId: profileId,
        words: entries.map(Word.fromJson).toList(),
        decisions: decisions,
        practiceHistory: history,
      );

  /// Test hook: return true to make the write/remove of a key fail as if
  /// the platform rejected it.
  @visibleForTesting
  bool Function(String key)? debugFailWrite;

  Future<void> _write(SharedPreferences prefs, String key, String value) async {
    if (debugFailWrite?.call(key) == true ||
        !await prefs.setString(key, value)) {
      throw StateError('Failed to persist $key');
    }
  }

  Future<void> _remove(SharedPreferences prefs, String key) async {
    if (debugFailWrite?.call(key) == true || !await prefs.remove(key)) {
      throw StateError('Failed to remove $key');
    }
  }

  /// Status of the one-time legacy migration (`migrated`, `imported`,
  /// `legacy_sqlite_unavailable`) or null before initialization.
  Future<String?> legacyMigrationStatus() => _serial((prefs) async {
        final raw = prefs.getString(migrationKey);
        if (raw == null) return null;
        final decoded = json.decode(raw);
        return decoded is Map ? decoded['status'] as String? : null;
      });

  @visibleForTesting
  Future<void> debugReset() async {
    await flush();
    boundProfileId = null;
  }
}
