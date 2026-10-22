import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_flow/database/database_helper.dart';
import 'package:chinese_flow/main.dart';
import 'package:chinese_flow/screens/practice_tab.dart';

Future<void> _settleAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    do {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.byType(LinearProgressIndicator).evaluate().isEmpty) {
        return;
      }
    } while (DateTime.now().isBefore(deadline));
    throw StateError('App assets did not finish loading within 30 seconds.');
  });
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final originalLoader = ProfileStore.instance.legacyWordsLoader;
    ProfileStore.instance.legacyWordsLoader = () async => [];
    addTearDown(() {
      ProfileStore.instance.legacyWordsLoader = originalLoader;
    });
  });

  testWidgets('shows the study deck and switches the interface to Chinese',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => tester.pumpWidget(const MyApp()));
    await _settleAssets(tester);

    expect(find.text('Jedna karta na raz.'), findsOneWidget);
    expect(find.text('Talia'), findsOneWidget);

    await tester.tap(find.byTooltip('简体中文'));
    await _settleAssets(tester);

    expect(find.text('一次一张卡。'), findsOneWidget);
    expect(find.text('词卡'), findsOneWidget);

    await tester.tap(find.text('HSK 词库'));
    await _settleAssets(tester);
    final hsk1Level = find.widgetWithText(ChoiceChip, 'HSK 1').first;
    await tester.ensureVisible(hsk1Level);
    await tester.tap(hsk1Level);
    await _settleAssets(tester);
    final bodyCategory = find.byKey(const ValueKey('vocabulary-category-body'));
    await tester.ensureVisible(bodyCategory);
    await tester.tap(bodyCategory);
    await _settleAssets(tester);
    expect(find.text('口'), findsOneWidget);

    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    final hsk5Level = find.widgetWithText(ChoiceChip, 'HSK 5').first;
    await tester.ensureVisible(hsk5Level);
    await tester.tap(hsk5Level);
    await _settleAssets(tester);
    expect(find.text('班'), findsOneWidget);

    final hsk6Level = find.widgetWithText(ChoiceChip, 'HSK 6').first;
    await tester.ensureVisible(hsk6Level);
    await tester.tap(hsk6Level);
    await _settleAssets(tester);
    expect(find.text('花'), findsOneWidget);

    final hsk7to9Level = find.widgetWithText(ChoiceChip, 'HSK 7–9').first;
    await tester.ensureVisible(hsk7to9Level);
    await tester.tap(hsk7to9Level);
    await _settleAssets(tester);
    expect(find.text('次'), findsOneWidget);

    await tester.tap(find.text('词卡'));
    await _settleAssets(tester);
    final deckHsk1Level = find.widgetWithText(ChoiceChip, 'HSK 1').first;
    await tester.ensureVisible(deckHsk1Level);
    await tester.tap(deckHsk1Level);
    await _settleAssets(tester);
    final deckBodyCategory =
        find.byKey(const ValueKey('vocabulary-category-body'));
    await tester.ensureVisible(deckBodyCategory);
    await tester.tap(deckBodyCategory);
    await _settleAssets(tester);
    await tester.tap(find.text('点击翻面'));
    await _settleAssets(tester);
    expect(find.text('口'), findsOneWidget);

    await tester.tap(find.text('练习'));
    await _settleAssets(tester);
    expect(find.text('把词语用出来。'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '填空'));
    await tester.tap(find.widgetWithText(ChoiceChip, '填空'));
    await _settleAssets(tester);
    expect(find.byType(TextField), findsOneWidget);

    final practiceHsk2Level = find.widgetWithText(ChoiceChip, 'HSK 2').first;
    await tester.ensureVisible(practiceHsk2Level);
    await tester.tap(practiceHsk2Level);
    await _settleAssets(tester);
    expect(find.byKey(const ValueKey('practice-empty-state')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    await tester.ensureVisible(find.text('HSK 4'));
    await tester.tap(find.text('HSK 4'));
    await _settleAssets(tester);
    expect(find.byKey(const ValueKey('practice-empty-state')), findsNothing);
    expect(find.text('HSK 4'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '词汇'));
    await tester.tap(find.widgetWithText(ChoiceChip, '词汇'));
    await _settleAssets(tester);
    expect(find.byKey(const ValueKey('practice-empty-state')), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, '词汇'),
          )
          .selected,
      isTrue,
    );

    final polishTarget = find.text('波兰语').first;
    await tester.ensureVisible(polishTarget);
    await tester.tap(polishTarget);
    await _settleAssets(tester);
    await tester.ensureVisible(find.text('练习'));
    await tester.tap(find.text('练习'));
    await _settleAssets(tester);
    final declensionMode = find.widgetWithText(ChoiceChip, '格变化');
    await tester.ensureVisible(declensionMode);
    await tester.tap(declensionMode);
    await _settleAssets(tester);
    expect(find.byType(TextField), findsAtLeastNWidgets(7));

    final conjugationMode = find.widgetWithText(ChoiceChip, '动词变位');
    await tester.ensureVisible(conjugationMode);
    await tester.tap(conjugationMode);
    await _settleAssets(tester);
    expect(find.byType(TextField), findsAtLeastNWidgets(8));
    expect(tester.takeException(), isNull);

    await tester.runAsync(() => ProfileStore.instance.flush());
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'mobile navigation opens settings and persists a readable dark theme',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() => tester.pumpWidget(const MyApp()));
    await _settleAssets(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await _settleAssets(tester);
    await tester.tap(find.text('Ustawienia'));
    await _settleAssets(tester);
    await tester.tap(find.text('Noc'));
    await _settleAssets(tester);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('appearance_v1'), 'midnight');
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.brightness, Brightness.dark);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await _settleAssets(tester);
    await tester.tap(find.text('Ćwiczenia'));
    await _settleAssets(tester);
    final practiceHeading = find.text('Użyj słowa, nie tylko je poznaj.');
    expect(practiceHeading, findsOneWidget);
    final colors = Theme.of(tester.element(practiceHeading)).colorScheme;
    expect(tester.widget<Text>(practiceHeading).style!.color, colors.onSurface);
    expect(
      find.descendant(
        of: find.byType(PracticeTab),
        matching: find.byType(OutlinedButton),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => ProfileStore.instance.flush());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
