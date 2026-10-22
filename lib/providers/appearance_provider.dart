import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearance { paper, jade, midnight }

class AppearanceProvider extends ChangeNotifier {
  AppAppearance _appearance = AppAppearance.paper;
  double _textScale = 1;

  AppAppearance get appearance => _appearance;
  double get textScale => _textScale;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString('appearance_v1');
    _appearance = AppAppearance.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => AppAppearance.paper,
    );
    _textScale = (preferences.getDouble('reading_scale_v1') ?? 1)
        .clamp(1, 1.3)
        .toDouble();
    notifyListeners();
  }

  Future<void> setAppearance(AppAppearance value) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString('appearance_v1', value.name)) {
      throw StateError('Could not save the appearance preference.');
    }
    _appearance = value;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    final scale = value.clamp(1, 1.3).toDouble();
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setDouble('reading_scale_v1', scale)) {
      throw StateError('Could not save the reading preference.');
    }
    _textScale = scale;
    notifyListeners();
  }

  ThemeData get theme {
    final dark = _appearance == AppAppearance.midnight;
    final jade = _appearance == AppAppearance.jade;
    final scheme = ColorScheme.fromSeed(
      seedColor: jade ? const Color(0xFF245E52) : const Color(0xFFA53D30),
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: dark
          ? const Color(0xFF191D20)
          : jade
              ? const Color(0xFFF0F5EF)
              : const Color(0xFFF6F2EB),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        bodyLarge:
            base.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.6),
        bodyMedium:
            base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
        bodySmall:
            base.textTheme.bodySmall?.copyWith(fontSize: 14, height: 1.45),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}
