import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/providers/appearance_provider.dart';
import 'package:chinese_flow/widgets/study_atmosphere.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('study decorations leave controls interactive on narrow screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppearanceProvider().theme,
      home: Scaffold(
        body: StudyAtmosphere(
          child: Column(
            children: [
              for (final language in AppLanguage.values)
                StudyEncouragement(language: language),
              TextButton(
                onPressed: () => taps++,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
