import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_flow/providers/appearance_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists appearance and reading size without touching learner data',
      () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('study_decisions', '{"你":"known"}');
    final provider = AppearanceProvider();
    await provider.initialize();
    await provider.setAppearance(AppAppearance.midnight);
    await provider.setTextScale(1.2);

    final restored = AppearanceProvider();
    await restored.initialize();
    expect(restored.theme.brightness, Brightness.dark);
    expect(restored.textScale, 1.2);
    expect(preferences.getString('study_decisions'), '{"你":"known"}');
  });

  test('invalid theme falls back and text size is bounded', () async {
    SharedPreferences.setMockInitialValues({
      'appearance_v1': 'unknown',
      'reading_scale_v1': 8.0,
    });
    final provider = AppearanceProvider();
    await provider.initialize();
    expect(provider.appearance, AppAppearance.paper);
    expect(provider.textScale, 1.3);
  });
}
