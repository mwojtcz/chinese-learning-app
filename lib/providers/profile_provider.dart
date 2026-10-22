import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/learner_profile.dart';

/// Local learner profiles. Persisted in SharedPreferences via [ProfileStore].
///
/// Selecting a profile here only changes the persisted active profile; the
/// caller must also `await wordProvider.setProfile(activeProfile.id)`.
class ProfileProvider with ChangeNotifier {
  ProfileProvider({ProfileStore? store})
      : _store = store ?? ProfileStore.instance;

  final ProfileStore _store;
  Future<void>? _initialization;
  bool _ready = false;
  List<LearnerProfile> _profiles = const [];
  String? _activeId;
  List<ProfileBackupInfo> _backups = const [];
  String? _migrationStatus;

  bool get ready => _ready;

  /// Legacy migration outcome: `migrated`, `imported`, or
  /// `legacy_sqlite_unavailable` (SQLite backend missing; legacy words were
  /// not read — not deleted either — and are not retried automatically).
  String? get legacyMigrationStatus => _migrationStatus;
  List<LearnerProfile> get profiles => _profiles;
  List<ProfileBackupInfo> get backups => _backups;

  LearnerProfile get activeProfile {
    if (!_ready) {
      throw StateError('ProfileProvider.initialize() has not completed');
    }
    return _profiles.firstWhere((profile) => profile.id == _activeId);
  }

  /// Loads profiles, migrating legacy global progress into the default
  /// profile on first run. Safe to call repeatedly; retried after a failure.
  Future<void> initialize() {
    return _initialization ??=
        _initialize().catchError((Object error, StackTrace stackTrace) {
      _initialization = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> _initialize() async {
    final registry = await _store.loadRegistry();
    _backups = await _store.listBackups();
    _migrationStatus = await _store.legacyMigrationStatus();
    _apply(registry);
    _ready = true;
    notifyListeners();
  }

  /// Creates a profile (not selected). The new profile is `profiles.last`.
  Future<void> createProfile(String name, {bool isTeacher = false}) async {
    _requireReady();
    final (registry, _) =
        await _store.createProfile(name, isTeacher: isTeacher);
    _apply(registry);
    notifyListeners();
  }

  /// Persists [id] as the active profile. Throws [ArgumentError] if unknown.
  Future<void> selectProfile(String id) async {
    _requireReady();
    final registry = await _store.setActiveProfile(id);
    _apply(registry);
    notifyListeners();
  }

  /// Waits for all queued profile/progress writes to finish.
  Future<void> flush() => _store.flush();

  /// Stores an in-preferences backup snapshot of all profiles (e.g. call with
  /// `reason: 'pre-update'` before launching an updater). Kept: newest
  /// [ProfileStore.maxBackups]. Does not protect against loss of the
  /// preferences storage itself; use [exportBackup] for an external copy.
  Future<ProfileBackupInfo> createBackup({String reason = 'manual'}) async {
    _requireReady();
    final info = await _store.createBackup(reason: reason);
    _backups = await _store.listBackups();
    notifyListeners();
    return info;
  }

  /// Backs up the shared [ProfileStore.instance] without a provider instance
  /// (e.g. from updater code). Queued after all pending writes, so call
  /// `await wordProvider.flush()` first only if you need to know they finished.
  static Future<ProfileBackupInfo> backupNow({String reason = 'pre-update'}) =>
      ProfileStore.instance.createBackup(reason: reason);

  /// Alias of [createBackup].
  Future<ProfileBackupInfo> createBackupSnapshot({String reason = 'manual'}) =>
      createBackup(reason: reason);

  /// All profile data as a JSON document, suitable for an external file.
  ///
  /// Private classroom `teacherNotes` are included only when the active
  /// profile is a teacher (or [includeTeacherNotes] is given explicitly);
  /// learner exports carry empty teacher notes and importing them keeps the
  /// device's existing notes. Stored [createBackup] snapshots are always full.
  Future<String> exportBackup({bool? includeTeacherNotes}) {
    _requireReady();
    return _store.exportSnapshotJson(
        includeTeacherNotes: includeTeacherNotes ?? activeProfile.isTeacher);
  }

  /// Alias of [exportBackup].
  Future<String> exportSnapshotJson() => exportBackup();

  /// Replaces all profiles, progress and classroom data
  /// ([ProfileStore.backupNamespacePrefixes]) with an [exportBackup] document.
  /// The whole document is validated before anything is written, and the
  /// current state is kept as a `pre-import` in-preferences backup.
  /// Before calling: flush WordProvider and every ClassroomStore. Afterwards:
  /// `await wordProvider.setProfile(activeProfile.id)` and recreate/reload
  /// classroom stores (their in-memory state is stale).
  ///
  /// Throws [FormatException] (nothing written) for an invalid document, or
  /// [BackupRestoreException] if writing failed; then [backups] and
  /// [profiles] are refreshed so a recovery UI can offer the retained
  /// `pre-import` entry via [restoreBackupSnapshot].
  Future<void> importBackup(String document) async {
    _requireReady();
    try {
      _apply(await _store.importSnapshotJson(document));
    } on BackupRestoreException {
      await _reloadAfterFailure();
      rethrow;
    }
    _backups = await _store.listBackups();
    notifyListeners();
  }

  /// Re-reads stored backups and profiles (e.g. for a recovery screen).
  Future<void> refreshBackups() async {
    _requireReady();
    _apply(await _store.loadRegistry());
    _backups = await _store.listBackups();
    notifyListeners();
  }

  Future<void> _reloadAfterFailure() async {
    try {
      await refreshBackups();
    } catch (_) {
      // Preferences are inconsistent; the original BackupRestoreException
      // (rethrown by the caller) describes the failure and recovery path.
    }
  }

  /// Restores a stored backup (the current state is backed up first). Callers
  /// must afterwards `await wordProvider.setProfile(activeProfile.id)`.
  Future<void> restoreBackupSnapshot(DateTime createdAt) async {
    _requireReady();
    try {
      _apply(await _store.restoreBackup(createdAt));
    } on BackupRestoreException {
      await _reloadAfterFailure();
      rethrow;
    }
    _backups = await _store.listBackups();
    notifyListeners();
  }

  // Store operations complete in queue order, so the latest completed
  // result always reflects every earlier write.
  void _apply(ProfileRegistry registry) {
    _profiles = registry.profiles;
    _activeId = registry.activeId;
  }

  void _requireReady() {
    if (!_ready) {
      throw StateError('ProfileProvider.initialize() has not completed');
    }
  }
}
