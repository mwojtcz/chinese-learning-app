import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'providers/word_provider.dart';
import 'providers/test_provider.dart';
import 'screens/home_screen.dart';

// App theme colors
const kChineseRed = Color(0xFFE63946);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WordProvider()..loadData(),
        ),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: MaterialApp(
        title: 'ChineseFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kChineseRed,
            brightness: Brightness.dark,
            primary: kChineseRed, // Vibrant Chinese red
            secondary: const Color(0xFFFFD700), // Chinese gold
            surface: const Color(0xFF1A1A1A), // Dark black
            background: const Color(0xFF0D0D0D), // Deeper black
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          cardTheme: const CardTheme(
            color: Color(0xFF1A1A1A),
            elevation: 3,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 2,
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: Color(0xFFFFD700), // Chinese gold for active tab
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFFFD700),
          ),
        ),
        themeMode: ThemeMode.dark, // Domyślnie ciemny motyw
        home: const HomeScreen(),
      ),
    );
  }
}
