import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/word_provider.dart';
import '../widgets/dictionary_tab.dart';
import '../widgets/my_words_tab.dart';
import '../widgets/test_tab.dart';
import '../widgets/settings_tab.dart';
import '../main.dart' show kChineseGold;

// Global notifier for emoji state
final emojiEnabledNotifier = ValueNotifier<bool>(true);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _emojiAnimationController;
  
  static const _emojis = ['🏮', '🎋', '🧧', '🎁', '🎊', '🥠', '🎆', '🧨', '🐉', '🌸', '🎐', '🍜', '🥟', '🍵'];
  // Multiplier for computing emoji X positions to create stable pseudo-random distribution.
  // Value 73 (prime number) reduces visible repeating patterns in horizontal layout.
  static const _emojiDistributionMultiplier = 73;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Emoji falling animation - infinite loop
    _emojiAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _loadEmojiPreference();
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadData();
    });
  }

  Future<void> _loadEmojiPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      emojiEnabledNotifier.value = prefs.getBool('emojis_enabled') ?? true;
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emojiAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B0000), // Burgundy (dark red)
                Color(0xFFB22222), // Firebrick red
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: Offset(0, 3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ChineseFlow',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kChineseGold,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'Słownik',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Moje Słowa',
            ),
            Tab(
              icon: Icon(Icons.quiz),
              text: 'Test',
            ),
            Tab(
              icon: Icon(Icons.settings),
              text: 'Ustawienia',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Falling emojis background layer
          ValueListenableBuilder<bool>(
            valueListenable: emojiEnabledNotifier,
            builder: (context, emojisEnabled, child) {
              if (!emojisEnabled) return const SizedBox.shrink();
              return AnimatedBuilder(
                animation: _emojiAnimationController,
                builder: (context, child) {
                  return _buildFallingEmojisLayer();
                },
              );
            },
          ),
          // Main content on top
          TabBarView(
            controller: _tabController,
            children: const [
          DictionaryTab(),
          MyWordsTab(),
          TestTab(),
          SettingsTab(),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildFallingEmojisLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        return Stack(
          children: List.generate(12, (index) {
            final progress = (_emojiAnimationController.value + index * 0.08) % 1.0;
            final xPos = ((index * _emojiDistributionMultiplier) % 100) / 100.0 * screenWidth;
            final speed = 0.8 + (index % 3) * 0.2;
            // Start above screen (-100) and fall to below screen (+100)
            final yPos = (progress * speed * (screenHeight + 200)) - 100;
            final size = 24.0 + (index % 3) * 4;
            
            return Positioned(
              left: xPos,
              top: yPos,
              child: Text(
                _emojis[index % _emojis.length],
                style: TextStyle(fontSize: size),
              ),
            );
          }),
        );
      },
    );
  }
}
