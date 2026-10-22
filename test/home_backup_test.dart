import 'package:chinese_flow/database/database_helper.dart';
import 'package:chinese_flow/main.dart';
import 'package:chinese_flow/models/word.dart';
import 'package:chinese_flow/providers/profile_provider.dart';
import 'package:chinese_flow/providers/word_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settleWorkspace(WidgetTester tester) async {
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    do {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.byType(LinearProgressIndicator).evaluate().isEmpty) {
        return;
      }
    } while (DateTime.now().isBefore(deadline));
    throw StateError('Workspace did not finish loading.');
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('local restore reloads progress and removes the selected pupil',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final originalLoader = ProfileStore.instance.legacyWordsLoader;
    ProfileStore.instance.legacyWordsLoader = () async => [];
    addTearDown(() => ProfileStore.instance.legacyWordsLoader = originalLoader);
    late String pupilId;
    await tester.runAsync(() async {
      final profiles = ProfileProvider();
      await profiles.initialize();
      await profiles.createProfile('Teacher', isTeacher: true);
      await profiles.selectProfile(profiles.profiles.last.id);
      await profiles.createBackup();
      await profiles.createProfile('Temporary pupil');
      pupilId = profiles.profiles.last.id;
      final words = WordProvider();
      await words.setProfile(profiles.activeProfile.id);
      await words.recordStudyDecision(
        Word(
          hanzi: '你好',
          pinyin: 'nǐ hǎo',
          englishTranslation: 'hello',
          polishTranslation: 'cześć',
          level: 'HSK-1',
        ),
        StudyDecision.known,
      );
      words.dispose();
      profiles.dispose();
    });
    await tester.pumpWidget(const MyApp());
    await _settleWorkspace(tester);
    final students = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButton<String> &&
          widget.items!.any((item) => item.value == pupilId) &&
          widget.value == null,
    );
    await tester.tap(students);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temporary pupil').last);
    await _settleWorkspace(tester);
    await tester.tap(find.text('Ustawienia'));
    await _settleWorkspace(tester);
    final recovery = find.text('Lokalne punkty odzyskiwania');
    await tester.ensureVisible(recovery);
    await tester.tap(recovery);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SimpleDialogOption).first);
    await _settleWorkspace(tester);
    expect(find.text('Temporary pupil'), findsNothing);
    expect(find.text('Opanowane: 0 · Do nauki: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => ProfileStore.instance.flush());
  });
}
