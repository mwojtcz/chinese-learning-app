import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';
import '../models/learning_target.dart';
import 'learning_tabs.dart';
import 'practice_tab.dart';

final emojiEnabledNotifier = ValueNotifier<bool>(false);
final traditionalChineseNotifier = ValueNotifier<bool>(false);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _background = Color(0xFFF6F2EB);
  static const _accent = Color(0xFFB44535);
  static const _ink = Color(0xFF242521);
  static const _muted = Color(0xFF77776F);
  static const _line = Color(0xFFE9E1D5);

  int _selectedIndex = 0;
  AppLanguage _language = AppLanguage.polish;
  LearningTarget _learningTarget = LearningTarget.chinese;

  void navigateToScreen(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index.clamp(0, 5).toInt());
  }

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final language = appLanguageFromCode(preferences.getString('interface_language'));
    if (!mounted) return;
    setState(() {
      _language = language;
      _learningTarget = learningTargetFromCode(
        preferences.getString('learning_target'),
        language,
      );
    });
    traditionalChineseNotifier.value = language.isTraditional;
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    traditionalChineseNotifier.value = language.isTraditional;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('interface_language', language.code);
    await preferences.setBool('traditional_chinese', language.isTraditional);
  }

  Future<void> _setLearningTarget(LearningTarget target) async {
    setState(() => _learningTarget = target);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('learning_target', target.code);
  }

  List<String> get _navigationLabels => [
        _language.text('Talia', '词卡', '詞卡'),
        _language.text('HSK', 'HSK 词库', 'HSK 詞庫'),
        _language.text('Ćwiczenia', '练习', '練習'),
        _language.text('Gramatyka', '语法', '語法'),
        _language.text('Zapisane', '收藏', '收藏'),
        _language.text('Ustawienia', '设置', '設定'),
      ];

  List<IconData> get _navigationIcons => const [
        Icons.style_outlined,
        Icons.menu_book_outlined,
        Icons.edit_note_rounded,
        Icons.translate_rounded,
        Icons.bookmark_border_rounded,
        Icons.tune_rounded,
      ];

  Widget _pageStack() => IndexedStack(
        index: _selectedIndex,
        children: [
          StudyDeckTab(
            key: const ValueKey('deck'),
            language: _language,
            target: _learningTarget,
            isActive: _selectedIndex == 0,
          ),
          HskLibraryTab(key: const ValueKey('hsk'), language: _language),
          PracticeTab(
            key: const ValueKey('practice'),
            language: _language,
            target: _learningTarget,
          ),
          GrammarTab(key: const ValueKey('grammar'), language: _language),
          SavedWordsTab(key: const ValueKey('saved'), language: _language),
          _SettingsPage(language: _language, onLanguageChanged: _setLanguage),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Row(
                children: [
                  SizedBox(
                    width: 236,
                    child: _Sidebar(
                      language: _language,
                      selectedIndex: _selectedIndex,
                      labels: _navigationLabels,
                      icons: _navigationIcons,
                      onSelected: (index) => setState(() => _selectedIndex = index),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: _line),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          language: _language,
                          target: _learningTarget,
                          onLanguageChanged: _setLanguage,
                          onTargetChanged: _setLearningTarget,
                        ),
                        Expanded(child: _pageStack()),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _TopBar(
                  language: _language,
                  target: _learningTarget,
                  onLanguageChanged: _setLanguage,
                  onTargetChanged: _setLearningTarget,
                  compact: true,
                ),
                Expanded(child: _pageStack()),
                _BottomNavigation(
                  labels: _navigationLabels,
                  icons: _navigationIcons,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.language,
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onSelected,
  });

  final AppLanguage language;
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFB44535),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '词',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CÍKǍ', style: TextStyle(color: Color(0xFF242521), fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
                  Text('SŁOWA W RUCHU', style: TextStyle(color: Color(0xFF77776F), fontSize: 9, letterSpacing: 1.1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 38),
          Text(
            language.text('UCZ SIĘ', '开始学习', '開始學習'),
            style: const TextStyle(color: Color(0xFF77776F), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < labels.length; index++)
            _NavigationItem(
              icon: icons[index],
              label: labels[index],
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECE4D9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wb_sunny_outlined, color: Color(0xFFB44535), size: 19),
                const SizedBox(height: 8),
                Text(
                  language.text('Małe kroki. Codziennie.', '每天一点点。', '每天一點點。'),
                  style: const TextStyle(color: Color(0xFF242521), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  language.text('Zapisane słowa są tylko Twoje.', '你的词卡只保存在本机。', '你的詞卡只保存在本機。'),
                  style: const TextStyle(color: Color(0xFF77776F), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          leading: Icon(icon, size: 21),
          title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          selected: selected,
          selectedColor: Colors.white,
          textColor: const Color(0xFF242521),
          iconColor: selected ? Colors.white : const Color(0xFF77776F),
          selectedTileColor: const Color(0xFFB44535),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.language,
    required this.target,
    required this.onLanguageChanged,
    required this.onTargetChanged,
    this.compact = false,
  });

  final AppLanguage language;
  final LearningTarget target;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<LearningTarget> onTargetChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 62 : 76,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 30),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F2EB),
        border: Border(bottom: BorderSide(color: Color(0xFFE9E1D5))),
      ),
      child: Row(
        children: [
          if (compact) ...[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFB44535), borderRadius: BorderRadius.circular(11)),
              child: const Text('词', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            const Text('CÍKǍ', style: TextStyle(color: Color(0xFF242521), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            const Spacer(),
            _TargetControl(
              language: language,
              target: target,
              onChanged: onTargetChanged,
            ),
            const SizedBox(width: 8),
          ] else ...[
            const Spacer(),
            Text(
              language.text('UCZĘ SIĘ', '学习目标', '學習目標'),
              style: const TextStyle(color: Color(0xFF77776F), fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            _TargetControl(
              language: language,
              target: target,
              onChanged: onTargetChanged,
            ),
            const SizedBox(width: 20),
            Text(
              language.text('JĘZYK APLIKACJI', '界面语言', '介面語言'),
              style: const TextStyle(color: Color(0xFF77776F), fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
          ],
          _LanguageControl(language: language, onLanguageChanged: onLanguageChanged),
        ],
      ),
    );
  }
}

class _TargetControl extends StatelessWidget {
  const _TargetControl({
    required this.language,
    required this.target,
    required this.onChanged,
  });

  final AppLanguage language;
  final LearningTarget target;
  final ValueChanged<LearningTarget> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<LearningTarget>(
        showSelectedIcon: false,
        segments: [
          for (final value in LearningTarget.values)
            ButtonSegment(
              value: value,
              label: Text(value.label(language)),
            ),
        ],
        selected: {target},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: SegmentedButton.styleFrom(
          foregroundColor: const Color(0xFF77776F),
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: const Color(0xFF315C57),
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
}

class _LanguageControl extends StatelessWidget {
  const _LanguageControl({required this.language, required this.onLanguageChanged});

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<AppLanguage>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: AppLanguage.polish, label: const Text('PL'), tooltip: 'Polski'),
          ButtonSegment(value: AppLanguage.simplifiedChinese, label: const Text('简'), tooltip: '简体中文'),
          ButtonSegment(value: AppLanguage.traditionalChinese, label: const Text('繁'), tooltip: '繁體中文'),
        ],
        selected: {language},
        onSelectionChanged: (selection) => onLanguageChanged(selection.first),
        style: SegmentedButton.styleFrom(
          foregroundColor: const Color(0xFF77776F),
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: const Color(0xFFB44535),
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        backgroundColor: const Color(0xFFFFFCF6),
        indicatorColor: const Color(0xFFF5E6DF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (var index = 0; index < labels.length; index++)
            NavigationDestination(
              icon: Icon(icons[index]),
              selectedIcon: Icon(icons[index], color: const Color(0xFFB44535)),
              label: labels[index],
            ),
        ],
      );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.language, required this.onLanguageChanged});

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            language.text('USTAWIENIA', '设置', '設定'),
            style: const TextStyle(color: Color(0xFFB44535), fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            language.text('Twoja przestrzeń do nauki.', '学习偏好。', '學習偏好。'),
            style: const TextStyle(color: Color(0xFF242521), fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.7),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            title: language.text('Język interfejsu', '界面语言', '介面語言'),
            description: language.text(
              'Zmień język strony. Chiński możesz wyświetlać w zapisie uproszczonym lub tradycyjnym.',
              '切换界面语言。中文界面可选择简体或繁体。',
              '切換介面語言。中文介面可選擇簡體或繁體。',
            ),
            child: _LanguageControl(language: language, onLanguageChanged: onLanguageChanged),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: language.text('Zakres słownictwa', '词库范围', '詞庫範圍'),
            description: language.text(
              'Zawiera listę HSK 2025, w tym wspólny poziom 7–9. Polskie tłumaczenia są uzupełniane i sprawdzane etapami.',
              '包含 HSK 2025 词表，其中 7–9 级为一个综合级别。波兰语翻译正在分批补充和核对。',
              '包含 HSK 2025 詞表，其中 7–9 級為一個綜合級別。波蘭語翻譯正在分批補充和核對。',
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: language.text('Prywatność i dane', '隐私与数据', '隱私與資料'),
            description: language.text(
              'Zapisane słowa i decyzje w talii przechowujemy lokalnie na tym urządzeniu. Nie ma konta ani serwera.',
              '收藏词语和学习记录保存在本机。无需账户，也不连接服务器。',
              '收藏詞語和學習記錄保存在本機。無需帳戶，也不連接伺服器。',
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'CÍKǍ',
            description: language.text(
              'Fiszki do nauki chińskiego i polskiego. Tłumaczenia angielskie są dodatkowym językiem pomostowym.',
              '学习中文与波兰语的词卡。英语释义作为辅助桥梁。',
              '學習中文與波蘭語的詞卡。英語釋義作為輔助橋樑。',
            ),
          ),
        ],
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.description, this.child});

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9E1D5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF242521), fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(color: Color(0xFF77776F), height: 1.45)),
            if (child != null) ...[const SizedBox(height: 14), child!],
          ],
        ),
      );
}
