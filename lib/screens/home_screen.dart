import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/word_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/chengyu_screen.dart';
import '../widgets/dictionary_tab.dart';
import '../widgets/my_words_tab.dart';
import '../widgets/test_tab.dart';
import '../widgets/settings_tab.dart';
import '../main.dart' show kChineseGold;

// Global notifier for emoji state
final emojiEnabledNotifier = ValueNotifier<bool>(true);

// Global notifier for Traditional Chinese mode
final traditionalChineseNotifier = ValueNotifier<bool>(false);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _emojiAnimationController;
  int _selectedIndex = 0;
  
  // Make _selectedIndex accessible for dashboard navigation
  void navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  static const _emojis = ['🏮', '🎋', '🧧', '🎁', '🎊', '🥠', '🎆', '🧨', '🐉', '🌸', '🎐', '🍜', '🥟', '🍵'];
  // Multiplier for computing emoji X positions to create stable pseudo-random distribution.
  // Value 73 (prime number) reduces visible repeating patterns in horizontal layout.
  static const _emojiDistributionMultiplier = 73;

  final List<Widget> _screens = [
    const DashboardScreen(),
    DictionaryTab(),
    MyWordsTab(),
    TestTab(),
    const ChengyuScreen(),
    const SettingsTab(),
  ];

  final List<String> _titles = [
    'ChineseFlow',
    'Dictionary',
    'My Words',
    'Tests',
    'Chengyu',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    
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
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      drawer: _buildDrawer(context),
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
          // Main content with smooth transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Container(
              key: ValueKey<int>(_selectedIndex),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey.shade900,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF800020),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'ChineseFlow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Master Chinese with HSK 3.0',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              index: 0,
              icon: Icons.home,
              title: 'Home',
              subtitle: 'Dashboard & Progress',
            ),
            _buildDrawerItem(
              context,
              index: 1,
              icon: Icons.book,
              title: 'Dictionary',
              subtitle: 'HSK Vocabulary',
            ),
            _buildDrawerItem(
              context,
              index: 2,
              icon: Icons.favorite,
              title: 'My Words',
              subtitle: 'Saved Words',
            ),
            _buildDrawerItem(
              context,
              index: 3,
              icon: Icons.quiz,
              title: 'Tests',
              subtitle: 'Practice & Review',
            ),
            _buildDrawerItem(
              context,
              index: 4,
              icon: Icons.auto_stories,
              title: 'Chengyu',
              subtitle: 'Chinese Idioms',
            ),
            const Divider(height: 32, color: Colors.grey),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.grey.shade600, size: 28),
              title: Text(
                'Statistics',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              subtitle: Text(
                'Coming soon...',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              enabled: false,
              trailing: Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600),
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.grey.shade600, size: 28),
              title: Text(
                'SRS Review',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              subtitle: Text(
                'Coming soon...',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              enabled: false,
              trailing: Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600),
            ),
            const Divider(height: 32, color: Colors.grey),
            _buildDrawerItem(
              context,
              index: 5,
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Preferences',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFFFD700) : Colors.grey.shade400,
        size: 30,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey.shade300,
          fontSize: 17,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF800020).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
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
