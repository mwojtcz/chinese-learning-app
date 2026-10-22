import 'dart:convert';

import 'package:chinese_flow/database/database_helper.dart';
import 'package:chinese_flow/providers/profile_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FailOnceStore extends InMemorySharedPreferencesStore {
  _FailOnceStore(Map<String, Object> data) : super.withData(data);

  bool failRegistry = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (failRegistry && key == 'flutter.${ProfileStore.registryKey}') {
      failRegistry = false;
      return Future.value(false);
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed import restores previously persisted data and keeps recovery',
      () async {
    SharedPreferences.setMockInitialValues({});
    final platform = _FailOnceStore({});
    final previousPlatform = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousPlatform);
    final preferences = await SharedPreferences.getInstance();
    final profiles = ProfileProvider(
      store: ProfileStore(legacyWordsLoader: () async => []),
    );
    await profiles.initialize();
    await preferences.setString('classroom.v1.test', '{"shared":["original"]}');
    final originalBackup = await profiles.exportBackup();
    await profiles.createProfile('Keep this pupil');
    await preferences.setString('classroom.v1.test', '{"shared":["newer"]}');
    final before = await profiles.exportBackup();
    platform.failRegistry = true;
    await expectLater(
      profiles.importBackup(originalBackup),
      throwsA(isA<BackupRestoreException>()
          .having((error) => error.rolledBack, 'rolledBack', isTrue)),
    );
    await preferences.reload();
    final after = await profiles.exportBackup();
    // Timestamp/reason differ; compare the actual persisted workspace payload.
    expect(jsonDecode(after)['data'], jsonDecode(before)['data']);
    expect(
        profiles.profiles.any((profile) => profile.name == 'Keep this pupil'),
        isTrue);
    expect(preferences.getString(ProfileStore.backupsKey), isNotNull);
    profiles.dispose();
  });
}
