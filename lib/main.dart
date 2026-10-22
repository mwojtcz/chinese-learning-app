import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/word_provider.dart';
import 'providers/test_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/appearance_provider.dart';
import 'models/app_identity.dart';
import 'screens/home_screen.dart';

// App theme colors
const kChineseRed = Color(0xFFB44535);
const kChineseGold = Color(0xFFC49A56);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _profiles = ProfileProvider();
  final _appearance = AppearanceProvider();
  final _words = WordProvider();
  late final Future<void> _initialization = _initialize();

  Future<void> _initialize() async {
    await _appearance.initialize();
    await _profiles.initialize();
    await _words.setProfile(_profiles.activeProfile.id);
    await _words.loadData();
  }

  @override
  void dispose() {
    _profiles.dispose();
    _appearance.dispose();
    _words.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _words),
        ChangeNotifierProvider.value(value: _profiles),
        ChangeNotifierProvider.value(value: _appearance),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: Consumer<AppearanceProvider>(
        builder: (context, appearance, _) => MaterialApp(
          title: appDisplayName,
          debugShowCheckedModeBanner: false,
          theme: appearance.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.textScalerOf(context).scale(appearance.textScale),
              ),
            ),
            child: child!,
          ),
          home: FutureBuilder<void>(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        '$appDisplayName\nCould not open local data.\n'
                        '${snapshot.error}\n'
                        'Existing data has not been reset.',
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const HomeScreen();
            },
          ),
        ),
      ),
    );
  }
}
