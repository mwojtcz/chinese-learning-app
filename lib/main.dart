import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/word_provider.dart';
import 'providers/test_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: MaterialApp(
        title: 'Nauka Chińskiego',
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
            seedColor: Colors.blueGrey,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          cardTheme: CardTheme(
            color: Color(0xFF1E2530),
            elevation: 2,
          ),
        ),
        themeMode: ThemeMode.dark, // Domyślnie ciemny motyw
        home: const HomeScreen(),
      ),
    );
  }
}
