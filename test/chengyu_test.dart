import 'dart:convert';
import 'dart:io';

import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/chengyu.dart';
import 'package:chinese_flow/screens/chengyu_screen.dart';
import 'package:chinese_flow/widgets/chengyu_illustration.dart';
import 'package:chinese_flow/database/database_helper.dart';
import 'package:chinese_flow/providers/profile_provider.dart';
import 'package:chinese_flow/providers/word_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settleCatalog(WidgetTester tester) async {
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('The bundled idiom catalog did not finish loading.');
      }
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = File('assets/data/chengyu.json').readAsStringSync();
  final idioms = chengyuFromJson(source);

  test('twenty unique classical idioms have complete localized content', () {
    expect(idioms, hasLength(20));
    expect(idioms.map((item) => item.id).toSet(), hasLength(20));
    expect(idioms.map((item) => item.simplified).toSet(), hasLength(20));
    expect(idioms.map((item) => item.traditional).toSet(), hasLength(20));
    for (final idiom in idioms) {
      expect(idiom.simplified.runes, hasLength(4));
      expect(idiom.traditional.runes, hasLength(4));
      expect(idiom.pinyin.split(' '), hasLength(4));
      expect(idiom.pinyin, matches(RegExp('[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]')));
      expect(idiom.englishMeaning.trim(), isNotEmpty);
      for (final field in [
        idiom.meaning,
        idiom.literal,
        idiom.example,
        idiom.story,
        idiom.caution,
      ]) {
        for (final language in AppLanguage.values) {
          expect(field.forLanguage(language).trim(), isNotEmpty,
              reason: '${idiom.id}: ${language.name}');
        }
      }
      expect(idiom.example.simplifiedChinese, contains(idiom.simplified));
      expect(idiom.example.traditionalChinese, contains(idiom.traditional));
    }
  });

  test('language selection preserves the requested Chinese script', () {
    final snake = idioms.first;
    expect(snake.characters(AppLanguage.polish), '画蛇添足');
    expect(snake.characters(AppLanguage.simplifiedChinese), '画蛇添足');
    expect(snake.characters(AppLanguage.traditionalChinese), '畫蛇添足');
    expect(snake.meaning.forLanguage(AppLanguage.polish), snake.meaning.polish);
    expect(snake.meaning.forLanguage(AppLanguage.simplifiedChinese),
        snake.meaning.simplifiedChinese);
    expect(snake.meaning.forLanguage(AppLanguage.traditionalChinese),
        snake.meaning.traditionalChinese);
  });

  test('offline search covers scripts, pinyin, Polish and English', () {
    final snake = idioms.first;
    for (final query in [
      '画蛇',
      '畫蛇',
      'huà shé',
      'HUA SHE',
      'zbędne',
      'zbedne',
      'unnecessary',
      '  hua   zu  ',
    ]) {
      expect(snake.matches(query), isTrue, reason: query);
    }
    expect(snake.matches(''), isTrue);
    expect(snake.matches('nieistniejącehasło'), isFalse);
    final dragon = idioms.singleWhere((item) => item.id == 'ye-gong-hao-long');
    expect(dragon.matches('ye gong hao long'), isTrue);
  });

  test('rejects duplicate ids and duplicate scripts', () {
    for (final field in ['id', 'simplified', 'traditional']) {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      final records = decoded['idioms'] as List;
      records[1][field] = records[0][field];
      expect(() => chengyuFromJson(jsonEncode(decoded)), throwsFormatException);
    }
  });

  test('rejects missing localized fields, unknown motifs and invalid roots',
      () {
    for (final key in ['pl', 'zhHans', 'zhHant']) {
      final record = Map<String, dynamic>.from(
        (jsonDecode(source)['idioms'] as List).first as Map,
      );
      (record['story'] as Map).remove(key);
      expect(() => Chengyu.fromJson(record), throwsFormatException);
    }
    final record = Map<String, dynamic>.from(
      (jsonDecode(source)['idioms'] as List).first as Map,
    );
    record['motif'] = 'unknown';
    expect(() => Chengyu.fromJson(record), throwsFormatException);
    record['motif'] = 'snake';
    record['pinyin'] = '  ';
    expect(() => Chengyu.fromJson(record), throwsFormatException);
    for (final invalid in ['[]', '{}', '{"idioms":[]}', '{"idioms":[null]}']) {
      expect(() => chengyuFromJson(invalid), throwsFormatException);
    }
    expect(() => idioms.add(idioms.first), throwsUnsupportedError);
  });

  testWidgets('bundled data loads and search can be cleared', (tester) async {
    await tester
        .runAsync(() => rootBundle.loadString('assets/data/chengyu.json'));
    await tester.pumpWidget(const MaterialApp(home: ChengyuScreen()));
    await _settleCatalog(tester);
    expect(find.text('20 z 20 idiomów'), findsOneWidget);
    expect(find.byType(ChengyuIllustration), findsWidgets);
    await tester.enterText(find.byType(TextField), '画蛇添足');
    await tester.pumpAndSettle();
    final expectedResults =
        idioms.where((idiom) => idiom.matches('画蛇添足')).length;
    expect(find.text('$expectedResults z 20 idiomów'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'xyz-nothing');
    await tester.pumpAndSettle();
    expect(find.text('Brak wyników. Spróbuj innego słowa.'), findsOneWidget);
    await tester.tap(find.byTooltip('Wyczyść wyszukiwanie'));
    await tester.pumpAndSettle();
    expect(find.text('20 z 20 idiomów'), findsOneWidget);
  });

  for (final language in AppLanguage.values) {
    testWidgets('${language.name}: localized detail and story reveal',
        (tester) async {
      await tester
          .runAsync(() => rootBundle.loadString('assets/data/chengyu.json'));
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: ChengyuScreen(language: language),
      ));
      await _settleCatalog(tester);
      await tester.tap(find.text(idioms.first.characters(language)).first);
      await tester.pumpAndSettle();
      expect(find.text(idioms.first.englishMeaning), findsOneWidget);
      expect(find.text(idioms.first.story.forLanguage(language)), findsNothing);
      final reveal =
          find.text(language.text('Odkryj opowieść', '展开典故', '展開典故'));
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(
          find.text(idioms.first.story.forLanguage(language)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all original motifs paint in light and dark themes',
      (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              for (final motif in ChengyuMotif.values)
                ChengyuIllustration(motif: motif, semanticLabel: motif.name),
            ]),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('narrow screens and large text remain scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .runAsync(() => rootBundle.loadString('assets/data/chengyu.json'));
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ChengyuScreen(),
      ),
    ));
    await _settleCatalog(tester);
    await tester.scrollUntilVisible(
      find.text('画蛇添足'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('画蛇添足'), findsOneWidget);
  });

  testWidgets('idiom decisions survive reload and remain profile-owned',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late final ProfileProvider profiles;
    late final WordProvider words;
    await tester.runAsync(() async {
      final store = ProfileStore(legacyWordsLoader: () async => []);
      profiles = ProfileProvider(store: store);
      words = WordProvider(store: store);
      await profiles.initialize();
      await profiles.createProfile('Second learner');
      await words.setProfile(profiles.activeProfile.id);
      await words.loadData();
    });
    final firstId = profiles.activeProfile.id;
    final secondId = profiles.profiles.last.id;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: words,
      child: const MaterialApp(home: ChengyuScreen()),
    ));
    await _settleCatalog(tester);
    await tester.tap(find.text(idioms.first.simplified).first);
    await tester.pumpAndSettle();
    final known = find.widgetWithText(FilterChip, 'Znam');
    await tester.ensureVisible(known);
    await tester.runAsync(() async {
      await tester.tap(known);
      await words.flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(
        words.studyDecisionFor(idioms.first.simplified), StudyDecision.known);
    await tester.runAsync(() => words.setProfile(secondId));
    expect(words.studyDecisionFor(idioms.first.simplified), isNull);
    await tester.runAsync(() => words.setProfile(firstId));
    expect(
        words.studyDecisionFor(idioms.first.simplified), StudyDecision.known);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Usuń status'));
      await words.flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(words.studyDecisionFor(idioms.first.simplified), isNull);
    expect(words.myWords.where((word) => word.hanzi == idioms.first.simplified),
        isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    words.dispose();
    profiles.dispose();
  });
}
