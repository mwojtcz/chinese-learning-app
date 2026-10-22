import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_flow/main.dart';

void main() {
  testWidgets('shows the study deck and switches the interface to Chinese', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Jedna karta na raz.'), findsOneWidget);
    expect(find.text('Talia'), findsOneWidget);

    await tester.tap(find.byTooltip('简体中文'));
    await tester.pumpAndSettle();

    expect(find.text('一次一张卡。'), findsOneWidget);
    expect(find.text('词卡'), findsOneWidget);

    await tester.tap(find.text('HSK 词库'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('HSK 5'));
    await tester.tap(find.text('HSK 5'));
    await tester.pumpAndSettle();
    expect(find.text('班'), findsOneWidget);

    await tester.ensureVisible(find.text('HSK 6'));
    await tester.tap(find.text('HSK 6'));
    await tester.pumpAndSettle();
    expect(find.text('花'), findsOneWidget);

    await tester.ensureVisible(find.text('HSK 7–9'));
    await tester.tap(find.text('HSK 7–9'));
    await tester.pumpAndSettle();
    expect(find.text('次'), findsOneWidget);

    await tester.tap(find.text('练习'));
    await tester.pumpAndSettle();
    expect(find.text('把词语用出来。'), findsOneWidget);

    await tester.tap(find.text('填空'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
}
