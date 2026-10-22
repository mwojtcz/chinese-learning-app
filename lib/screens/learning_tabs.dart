import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_language.dart';
import '../models/grammar_lesson.dart';
import '../models/learning_target.dart';
import '../models/polish_course.dart';
import '../models/polish_word_forms.dart';
import '../models/word.dart';
import '../providers/word_provider.dart';

const _ink = Color(0xFF242521);
const _mutedInk = Color(0xFF77776F);
const _paper = Color(0xFFFFFCF6);
const _accent = Color(0xFFB44535);
const _line = Color(0xFFE9E1D5);

String _hskLevelLabel(String level) =>
    level == 'HSK-7-9' ? 'HSK 7–9' : level.replaceFirst('-', ' ');

class StudyDeckTab extends StatefulWidget {
  const StudyDeckTab({
    super.key,
    required this.language,
    required this.target,
    required this.isActive,
  });

  final AppLanguage language;
  final LearningTarget target;
  final bool isActive;

  @override
  State<StudyDeckTab> createState() => _StudyDeckTabState();
}

class _StudyDeckTabState extends State<StudyDeckTab> {
  final FocusNode _focusNode = FocusNode();
  String _selectedLevel = 'HSK-1';
  bool _showSkipped = false;
  bool _revealed = false;

  @override
  void didUpdateWidget(covariant StudyDeckTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _decide(WordProvider provider, Word word, StudyDecision decision) async {
    setState(() => _revealed = false);
    await provider.recordStudyDecision(word, decision);
  }

  Future<void> _skip(WordProvider provider, Word word) async {
    if (_showSkipped) {
      setState(() => _revealed = false);
      await provider.clearStudyDecision(word.hanzi);
      return;
    }
    await _decide(provider, word, StudyDecision.skipped);
  }

  KeyEventResult _handleKey(KeyEvent event, WordProvider provider, Word? word) {
    if (event is! KeyDownEvent || word == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _skip(provider, word);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _decide(provider, word, StudyDecision.saved);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _decide(provider, word, StudyDecision.known);
    } else if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      setState(() => _revealed = !_revealed);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    return Consumer<WordProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              value: provider.loadingProgress,
              color: _accent,
            ),
          );
        }

        final availableWords =
            provider.allWords.where((word) => word.level == _selectedLevel).toList();
        final words = availableWords.where((word) {
          final decision = provider.studyDecisionFor(word.hanzi);
          return _showSkipped
              ? decision == StudyDecision.skipped
              : decision == null;
        }).toList();
        final skippedCount = availableWords
            .where((word) =>
                provider.studyDecisionFor(word.hanzi) == StudyDecision.skipped)
            .length;
        final completedCount = availableWords.length - words.length -
            (_showSkipped ? 0 : skippedCount);
        final word = words.isEmpty ? null : words.first;

        return Focus(
          focusNode: _focusNode,
          autofocus: widget.isActive,
          canRequestFocus: widget.isActive,
          onKeyEvent: (node, event) => _handleKey(event, provider, word),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(compact ? 18 : 32, 8, compact ? 18 : 32, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Eyebrow(
                          language.text('NAUKA • HSK 2025', '学习 • HSK 2025', '學習 • HSK 2025'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.text('Jedna karta na raz.', '一次一张卡。', '一次一張卡。'),
                          style: TextStyle(
                            color: _ink,
                            fontSize: compact ? 30 : 40,
                            height: 1.08,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.text(
                            'Odkrywaj słowa, zapamiętuj je gestem i wracaj do trudnych.',
                            '认识新词，用手势保存，再回来复习。',
                            '認識新詞，用手勢保存，再回來複習。',
                          ),
                          style: const TextStyle(color: _mutedInk, fontSize: 15, height: 1.45),
                        ),
                        const SizedBox(height: 22),
                        _LevelPicker(
                          language: language,
                          selectedLevel: _selectedLevel,
                          counts: {
                            for (final level in provider.availableLevels)
                              if (level != 'Wszystkie')
                                level: provider.getLevelWordCount(level),
                          },
                          onSelected: (level) => setState(() {
                            _selectedLevel = level;
                            _revealed = false;
                          }),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _MetricPill(
                              icon: Icons.layers_outlined,
                              label: language.text(
                                '${words.length} w talii',
                                '${words.length} 张卡',
                                '${words.length} 張卡',
                              ),
                            ),
                            _MetricPill(
                              icon: Icons.check_circle_outline,
                              label: language.text(
                                '$completedCount ukończonych',
                                '已完成 $completedCount',
                                '已完成 $completedCount',
                              ),
                            ),
                            if (skippedCount > 0)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _showSkipped = !_showSkipped;
                                  _revealed = false;
                                }),
                                icon: Icon(
                                  _showSkipped ? Icons.refresh : Icons.undo,
                                  size: 17,
                                ),
                                label: Text(
                                  _showSkipped
                                      ? language.text('Nowe słowa', '新词', '新詞')
                                      : language.text(
                                          'Pominięte ($skippedCount)',
                                          '跳过 ($skippedCount)',
                                          '跳過 ($skippedCount)',
                                        ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (word == null)
                          _EmptyDeck(
                            language: language,
                            skippedCount: skippedCount,
                            showSkipped: _showSkipped,
                            onReviewSkipped: skippedCount == 0
                                ? null
                                : () => setState(() {
                                      _showSkipped = !_showSkipped;
                                      _revealed = false;
                                    }),
                            onResetSkipped: _showSkipped
                                ? () async {
                                    await provider.revisitSkippedWords(level: _selectedLevel);
                                    if (mounted) setState(() => _showSkipped = false);
                                  }
                                : null,
                          )
                        else ...[
                          _Flashcard(
                            word: word,
                            language: language,
                            target: widget.target,
                            revealed: _revealed,
                            onTap: () => setState(() => _revealed = !_revealed),
                            onSwipeLeft: () => _skip(provider, word),
                            onSwipeRight: () => _decide(
                              provider,
                              word,
                              StudyDecision.saved,
                            ),
                            onSwipeUp: () => _decide(
                              provider,
                              word,
                              StudyDecision.known,
                            ),
                            onDetails: () => _showWordDetails(context, word, language),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _DecisionButton(
                                  icon: Icons.close_rounded,
                                  label: language.text('Pomiń', '跳过', '跳過'),
                                  color: const Color(0xFF6B7280),
                                  onPressed: () => _skip(provider, word),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DecisionButton(
                                  icon: Icons.bookmark_add_outlined,
                                  label: language.text('Do nauki', '稍后学习', '稍後學習'),
                                  color: const Color(0xFF315C57),
                                  onPressed: () => _decide(
                                    provider,
                                    word,
                                    StudyDecision.saved,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DecisionButton(
                                  icon: Icons.check_rounded,
                                  label: language.text('Znam', '我会了', '我會了'),
                                  color: _accent,
                                  onPressed: () => _decide(
                                    provider,
                                    word,
                                    StudyDecision.known,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              language.text(
                                '← pomiń     spacja: odkryj     ↑ znam     → do nauki',
                                '← 跳过     空格：翻面     ↑ 会了     → 稍后学习',
                                '← 跳過     空格：翻面     ↑ 會了     → 稍後學習',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _mutedInk, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class HskLibraryTab extends StatefulWidget {
  const HskLibraryTab({super.key, required this.language});

  final AppLanguage language;

  @override
  State<HskLibraryTab> createState() => _HskLibraryTabState();
}

class _HskLibraryTabState extends State<HskLibraryTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLevel = 'HSK-1';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    return Consumer<WordProvider>(
      builder: (context, provider, _) {
        final words = provider.allWords.where((word) {
          final query = _searchQuery.trim().toLowerCase();
          final normalizedQuery = Word.normalizePinyin(query);
          final matchesLevel = _selectedLevel == 'Wszystkie' ||
              word.level == _selectedLevel;
          final matchesSearch = query.isEmpty ||
              word.displayHanzi.toLowerCase().contains(query) ||
              word.hanzi.toLowerCase().contains(query) ||
              word.traditional.toLowerCase().contains(query) ||
              word.pinyin.toLowerCase().contains(query) ||
              Word.normalizePinyin(word.pinyin).contains(normalizedQuery) ||
              word.englishTranslation.toLowerCase().contains(query) ||
              word.polishTranslation.toLowerCase().contains(query);
          return matchesLevel && matchesSearch;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Eyebrow(language.text('SŁOWNIK', '词库', '詞庫')),
                  const SizedBox(height: 8),
                  Text(
                    language.text('Całe HSK, bez zgadywania.', 'HSK 词库，一目了然。', 'HSK 詞庫，一目了然。'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    language.text(
                      'Przeszukuj dostępne zestawy i sprawdzaj źródło każdego poziomu.',
                      '搜索现有词表，并查看每个级别的数据来源。',
                      '搜尋現有詞表，並查看每個級別的資料來源。',
                    ),
                    style: const TextStyle(color: _mutedInk, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    language.text(
                      'Poziomy 1–6 zawierają słowa dodane na danym etapie; HSK 7–9 to wspólny zestaw.',
                      '1–6 级显示该阶段新增词汇；HSK 7–9 为一个综合词表。',
                      '1–6 級顯示該階段新增詞彙；HSK 7–9 為一個綜合詞表。',
                    ),
                    style: const TextStyle(color: _mutedInk, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: language.text(
                        'Szukaj hanzi, pinyin, polskiego lub angielskiego…',
                        '搜索汉字、拼音、波兰语或英语…',
                        '搜尋漢字、拼音、波蘭語或英語…',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: _paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LevelPicker(
                    language: language,
                    selectedLevel: _selectedLevel,
                    includeAll: true,
                    counts: {
                      for (final level in provider.availableLevels)
                        if (level != 'Wszystkie')
                          level: provider.getLevelWordCount(level),
                    },
                    onSelected: (level) => setState(() => _selectedLevel = level),
                  ),
                  const SizedBox(height: 12),
                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (words.isEmpty)
                    _EmptyLibrary(
                      language: language,
                      isSearchEmpty: _searchQuery.isNotEmpty,
                    )
                  else
                    Text(
                      language.text(
                        '${words.length} słów • HSK 2025',
                        '${words.length} 个词 • HSK 2025',
                        '${words.length} 個詞 • HSK 2025',
                      ),
                      style: const TextStyle(color: _mutedInk, fontSize: 13),
                    ),
                ]),
              ),
            ),
            if (!provider.isLoading && words.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _LibraryWordTile(
                      word: words[index],
                      language: language,
                      decision: provider.studyDecisionFor(words[index].hanzi),
                      onTap: () => _showWordDetails(context, words[index], language),
                    ),
                    childCount: words.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              sliver: SliverToBoxAdapter(child: _SourceNote(language: language)),
            ),
          ],
        );
      },
    );
  }
}

class SavedWordsTab extends StatefulWidget {
  const SavedWordsTab({super.key, required this.language});

  final AppLanguage language;

  @override
  State<SavedWordsTab> createState() => _SavedWordsTabState();
}

class _SavedWordsTabState extends State<SavedWordsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    return Consumer<WordProvider>(
      builder: (context, provider, _) {
        final words = provider.myWords.where((word) {
          final query = _query.toLowerCase().trim();
          final normalizedQuery = Word.normalizePinyin(query);
          return query.isEmpty ||
              word.displayHanzi.toLowerCase().contains(query) ||
              word.hanzi.toLowerCase().contains(query) ||
              word.traditional.toLowerCase().contains(query) ||
              word.pinyin.toLowerCase().contains(query) ||
              Word.normalizePinyin(word.pinyin).contains(normalizedQuery) ||
              word.englishTranslation.toLowerCase().contains(query) ||
              word.polishTranslation.toLowerCase().contains(query);
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Eyebrow(language.text('OSOBISTY ZBIÓR', '我的词卡', '我的詞卡')),
                  const SizedBox(height: 8),
                  Text(
                    language.text('Słowa, które zostają.', '把想学的词留下。', '把想學的詞留下。'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: language.text('Filtruj zapisane słowa…', '搜索收藏的词…', '搜尋收藏的詞…'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: _paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    language.text(
                      '${words.length} zapisanych słów',
                      '${words.length} 个收藏词',
                      '${words.length} 個收藏詞',
                    ),
                    style: const TextStyle(color: _mutedInk, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (words.isEmpty) _EmptySavedWords(language: language),
                ]),
              ),
            ),
            if (words.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final word = words[index];
                      return _LibraryWordTile(
                        word: word,
                        language: language,
                        decision: provider.studyDecisionFor(word.hanzi),
                        trailing: IconButton(
                          tooltip: language.text('Usuń z zapisanych', '取消收藏', '取消收藏'),
                          onPressed: () => provider.removeFromMyWords(word.hanzi),
                          icon: const Icon(Icons.bookmark_remove_outlined),
                        ),
                        onTap: () => _showWordDetails(context, word, language),
                      );
                    },
                    childCount: words.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class GrammarTab extends StatefulWidget {
  const GrammarTab({super.key, required this.language});

  final AppLanguage language;

  @override
  State<GrammarTab> createState() => _GrammarTabState();
}

class _GrammarTabState extends State<GrammarTab> {
  late final Future<List<GrammarLesson>> _lessons = _loadLessons();
  late final Future<List<PolishCourseLevel>> _polishCourse = rootBundle
      .loadString('assets/data/polish_course.json')
      .then(polishCourseFromJson);

  Future<List<GrammarLesson>> _loadLessons() async {
    const assetPaths = [
      'assets/data/grammar_chinese.json',
      'assets/data/grammar_polish_cases.json',
      'assets/data/grammar_polish_verbs.json',
      'assets/data/grammar_polish_numbers.json',
    ];
    final sources = await Future.wait(
      assetPaths.map(rootBundle.loadString),
    );
    return [
      for (final source in sources) ...grammarLessonsFromJson(source),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    final polish = language.isPolish;
    return FutureBuilder<List<GrammarLesson>>(
      future: _lessons,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                language.text(
                  'Nie udało się wczytać materiałów gramatycznych: ${snapshot.error}',
                  '语法课程加载失败：${snapshot.error}',
                  '語法課程載入失敗：${snapshot.error}',
                ),
                style: const TextStyle(color: _accent),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        final lessons = snapshot.data!;
        final chineseLessons = lessons.where((lesson) => lesson.id.startsWith('zh-')).toList();
        final polishLessons = lessons.where((lesson) => lesson.id.startsWith('pl-')).toList();
        final chineseTab = Tab(
          text: language.text('Chiński · 中文', '中文 · 语法', '中文 · 語法'),
        );
        final polishGrammarTab = Tab(
          text: language.text('Polski · gramatyka', '波兰语 · 语法', '波蘭語 · 語法'),
        );
        final polishCourseTab = Tab(
          text: language.text('Kurs polskiego · A1–C2', '波兰语课程 · A1–C2', '波蘭語課程 · A1–C2'),
        );
        final tabs = polish
            ? [polishCourseTab, polishGrammarTab, chineseTab]
            : [chineseTab, polishCourseTab, polishGrammarTab];
        final pages = polish
            ? [
                _PolishCourseTab(course: _polishCourse, language: language),
                _GrammarLessonList(lessons: polishLessons, language: language),
                _GrammarLessonList(lessons: chineseLessons, language: language),
              ]
            : [
                _GrammarLessonList(lessons: chineseLessons, language: language),
                _PolishCourseTab(course: _polishCourse, language: language),
                _GrammarLessonList(lessons: polishLessons, language: language),
              ];
        return DefaultTabController(
          length: tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow(language.text('GRAMATYKA', '语法手册', '語法手冊')),
                    const SizedBox(height: 8),
                    Text(
                      language.text('Zasady, które robią różnicę.', '把规则变成表达力。', '把規則變成表達力。'),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TabBar(
                      isScrollable: true,
                      labelColor: _accent,
                      unselectedLabelColor: _mutedInk,
                      indicatorColor: _accent,
                      tabs: tabs,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(children: pages),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PolishCourseTab extends StatelessWidget {
  const _PolishCourseTab({
    required this.course,
    required this.language,
  });

  final Future<List<PolishCourseLevel>> course;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PolishCourseLevel>>(
      future: course,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                language.text(
                  'Nie udało się wczytać kursu: ${snapshot.error}',
                  '课程加载失败：${snapshot.error}',
                  '課程載入失敗：${snapshot.error}',
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFECE4D9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                language.text(
                  'Kurs prowadzi od pierwszych zdań do samodzielnej, zaawansowanej komunikacji. Każdy moduł ma cel komunikacyjny, przykłady, krótkie ćwiczenie z odpowiedzią i zadanie do wykonania. Ucz się w cyklu: poznaj formę, zauważ ją w przykładzie, sprawdź odpowiedź i użyj jej we własnej wypowiedzi. Przypadki wprowadzamy stopniowo — pełna tabela jest niżej w zakładce „Gramatyka PL”.',
                  '课程从第一句话循序推进到独立的高级交流。每个单元都包含交际目标、例句、附答案的小练习和实践任务。按此循环学习：认识形式、观察例句、核对答案，再用于自己的表达。格的学习循序渐进；完整表格见下方“波兰语语法”。',
                  '課程從第一句話循序推進到獨立的進階交流。每個單元都包含交際目標、例句、附答案的小練習和實踐任務。依此循環學習：認識形式、觀察例句、核對答案，再用於自己的表達。格的學習循序漸進；完整表格見下方「波蘭語文法」。',
                ),
                style: const TextStyle(color: _ink, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            for (final level in snapshot.data!)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: _paper,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _line),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  title: Text(
                    level.title.forLanguage(language),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      level.canDo.forLanguage(language),
                      style: const TextStyle(color: _mutedInk, height: 1.4),
                    ),
                  ),
                  children: [
                    for (final unit in level.units)
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        title: Text(
                          unit.title.forLanguage(language),
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          unit.outcome.forLanguage(language),
                          style: const TextStyle(color: _mutedInk, height: 1.4),
                        ),
                        children: [
                          _CourseDetail(
                            label: language.text('Przykłady', '例句', '例句'),
                            text: unit.examples
                                .map((example) => example.forLanguage(language))
                                .join('\n'),
                          ),
                          const SizedBox(height: 8),
                          _CourseDetail(
                            label: language.text('Gramatyka i język', '语法与语言重点', '文法與語言重點'),
                            text: unit.focus.forLanguage(language),
                          ),
                          const SizedBox(height: 8),
                          ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            title: Text(
                              language.text('Ćwiczenie', '练习', '練習'),
                              style: const TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              unit.practice.forLanguage(language),
                              style: const TextStyle(color: _ink, height: 1.45),
                            ),
                            children: [
                              _CourseDetail(
                                label: language.text('Odpowiedź i wskazówka', '答案与提示', '答案與提示'),
                                text: unit.answer.forLanguage(language),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _CourseDetail(
                            label: language.text('Zadanie praktyczne', '实践任务', '實踐任務'),
                            text: unit.task.forLanguage(language),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                language.text(
                  'Poziomy i cele komunikacyjne opracowano z odniesieniem do Europejskiego systemu opisu kształcenia językowego oraz polskich standardów egzaminacyjnych z 2025 r. Układ lekcji jest autorskim planem dydaktycznym, a nie oficjalnym programem egzaminu.',
                  '课程等级和交际目标参考《欧洲语言共同参考框架》及 2025 年波兰语国家考试标准。本课程编排为自编教学方案，并非官方考试大纲。',
                  '課程等級和交際目標參考《歐洲語言共同參考架構》及 2025 年波蘭語國家考試標準。本課程編排為自編教學方案，並非官方考試大綱。',
                ),
                style: const TextStyle(color: _mutedInk, fontSize: 12, height: 1.45),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CourseDetail extends StatelessWidget {
  const _CourseDetail({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: _ink, height: 1.45)),
          ],
        ),
      );
}

class _GrammarLessonList extends StatelessWidget {
  const _GrammarLessonList({required this.lessons, required this.language});

  final List<GrammarLesson> lessons;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Center(
        child: Text(
          language.text('Materiały będą dostępne wkrótce.', '课程即将推出。', '課程即將推出。'),
          style: const TextStyle(color: _mutedInk),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title.forLanguage(language),
                style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.summary.forLanguage(language),
                style: const TextStyle(color: _mutedInk, height: 1.45),
              ),
              const SizedBox(height: 12),
              for (final section in lesson.sections)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.heading.forLanguage(language),
                        style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.explanation.forLanguage(language),
                        style: const TextStyle(color: _mutedInk, height: 1.45),
                      ),
                      for (final example in section.examples)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 7),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4EFE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                example.forLanguage(language),
                                style: const TextStyle(color: _ink, height: 1.4),
                              ),
                              if (example.pinyin?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    example.pinyin!,
                                    style: const TextStyle(color: _accent, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      for (final table in section.tables)
                        _GrammarTableView(table: table, language: language),
                      const SizedBox(height: 7),
                      Text(
                        section.note.forLanguage(language),
                        style: const TextStyle(color: _mutedInk, fontSize: 13, height: 1.4),
                      ),
                      const Divider(height: 22, color: _line),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GrammarTableView extends StatelessWidget {
  const _GrammarTableView({required this.table, required this.language});

  final GrammarTable table;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final columns = table.headers.length;
    final columnWidth = columns <= 2 ? 180.0 : 150.0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 6),
      decoration: BoxDecoration(
        color: _paper,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFECE4D9)),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 92,
            columnSpacing: 18,
            horizontalMargin: 14,
            columns: [
              for (final header in table.headers)
                DataColumn(
                  label: SizedBox(
                    width: columnWidth,
                    child: Text(
                      header.forLanguage(language),
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
            rows: [
              for (final row in table.rows)
                DataRow(
                  cells: [
                    for (final cell in row)
                      DataCell(
                        SizedBox(
                          width: columnWidth,
                          child: Text(
                            cell.forLanguage(language),
                            style: const TextStyle(color: _ink, height: 1.35),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChineseGrammar extends StatelessWidget {
  const _ChineseGrammar({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        _GrammarCard(
          title: language.text('Liczby i liczenie', '数字与计数', '數字與計數'),
          intro: language.text(
            'Liczby łączą się dziesiątkami. Przy rzeczownikach zwykle dodajemy klasyfikator.',
            '数字按十进制组合。数名词时，通常要加量词。',
            '數字按十進位組合。數名詞時，通常要加量詞。',
          ),
          examples: const [
            '零 líng · 一 yī · 二 èr · 三 sān · 四 sì · 五 wǔ',
            '六 liù · 七 qī · 八 bā · 九 jiǔ · 十 shí',
            '十一 = 10 + 1 · 二十 = 2 × 10 · 一百 = 100',
            '一个人 yí ge rén · 两本书 liǎng běn shū',
          ],
          note: language.text(
            'W liczbie „2” przed klasyfikatorem najczęściej używamy 两 liǎng: 两个人, 两本书.',
            '“2”放在量词前通常说“两”：两个人、两本书。',
            '「2」放在量詞前通常說「兩」：兩個人、兩本書。',
          ),
        ),
        _GrammarCard(
          title: language.text('Przymiotniki bez „być”', '形容词谓语', '形容詞謂語'),
          intro: language.text(
            'Przymiotnik może być orzeczeniem; 很 hěn często łączy podmiot z opisem.',
            '形容词可以直接作谓语；“很”常用于连接主语和描述。',
            '形容詞可以直接作謂語；「很」常用於連接主語和描述。',
          ),
          examples: const [
            '她很高。Tā hěn gāo. — Ona jest wysoka.',
            '今天不冷。Jīntiān bù lěng. — Dziś nie jest zimno.',
            '我没吃饭。Wǒ méi chī fàn. — Nie jadłem/am.',
          ],
          note: language.text(
            '不 bù neguje zwykle teraźniejszość, cechę lub zamiar; 没 méi neguje zaistnienie albo posiadanie.',
            '“不”常否定状态、习惯或意愿；“没”常否定已发生的动作或“有”。',
            '「不」常否定狀態、習慣或意願；「沒」常否定已發生的動作或「有」。',
          ),
        ),
        _GrammarCard(
          title: language.text('的 · 地 · 得', '的 · 地 · 得', '的 · 地 · 得'),
          intro: language.text(
            'Te same dźwięki pełnią różne funkcje — pozycja w zdaniu pomaga je rozpoznać.',
            '三个字读音相同，但功能不同；看它们在句子中的位置。',
            '三個字讀音相同，但功能不同；看它們在句子中的位置。',
          ),
          examples: const [
            '我的书 — moje książki (的: określenie)',
            '认真地学习 — uczyć się uważnie (地: sposób czynności)',
            '说得很好 — mówić bardzo dobrze (得: rezultat / stopień)',
          ],
          note: language.text(
            'W codziennym języku 的 występuje najczęściej; 地 i 得 są związane z konstrukcją czasownika.',
            '日常使用中“的”最常见；“地”和“得”与动词结构有关。',
            '日常使用中「的」最常見；「地」和「得」與動詞結構有關。',
          ),
        ),
      ],
    );
  }
}

class _PolishGrammar extends StatelessWidget {
  const _PolishGrammar({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final polish = language.isPolish;
    final examples = polish
        ? const [
            'Mianownik: student / książka',
            'Dopełniacz: studenta / książki',
            'Celownik: studentowi / książce',
            'Biernik: studenta / książkę',
            'Narzędnik: studentem / książką',
            'Miejscownik: studencie / książce',
            'Wołacz: studencie! / książko!',
          ]
        : const [
            '主格（mianownik）：student / książka',
            '属格（dopełniacz）：studenta / książki',
            '与格（celownik）：studentowi / książce',
            '宾格（biernik）：studenta / książkę',
            '工具格（narzędnik）：studentem / książką',
            '处所格（miejscownik）：studencie / książce',
            '呼格（wołacz）：studencie! / książko!',
          ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        _GrammarCard(
          title: polish ? 'Przypadki: kto? kogo? komu?' : '波兰语格变化',
          intro: polish
              ? 'Końcówka rzeczownika zmienia się zależnie od jego roli w zdaniu. Poniżej pełna odmiana dwóch częstych słów.'
              : '名词词尾会根据它在句中的作用变化。以下是两个常见词的完整变化。',
          examples: examples,
          note: polish
              ? 'To przykłady dla rodzaju męskiego i żeńskiego. Wzór zależy od rodzaju, końcówki i wyjątków.'
              : '这是阳性和阴性名词的示例。具体形式取决于词性、词尾和例外。',
        ),
        _GrammarCard(
          title: polish ? 'Liczebniki i zgoda' : '数字与名词搭配',
          intro: polish
              ? 'Jeden odmienia się przez rodzaj. Po 5–19 rzeczownik zwykle przyjmuje dopełniacz liczby mnogiej.'
              : '“一”要与名词的性别一致。5–19 后面的名词通常用复数属格。',
          examples: const [
            'jeden student · jedna książka · jedno dziecko',
            'dwaj studenci / dwóch studentów · dwie książki',
            'trzy książki · cztery książki · pięć książek',
            '22 książki · 25 książek · 12 książek',
          ],
          note: polish
              ? 'W liczebnikach złożonych liczy się ostatnia część: 22 książki, ale 25 książek. Liczebniki 12–14 zachowują wzór „pięć”.'
              : '复合数字看末尾部分：22 本书用复数主格，25 本书用复数属格。12–14 按“5”的规则。',
        ),
        _GrammarCard(
          title: polish ? 'Stopniowanie przymiotników' : '形容词比较级',
          intro: polish
              ? 'Wiele krótkich przymiotników ma formy nieregularne lub zmienia temat.'
              : '许多常用形容词有不规则变化，或需要改变词干。',
          examples: const [
            'dobry → lepszy → najlepszy',
            'szybki → szybszy → najszybszy',
            'interesujący → bardziej interesujący → najbardziej interesujący',
            'ta książka jest ciekawsza niż tamta',
          ],
          note: polish
              ? 'Porównanie często łączy się z „niż”: lepszy niż…, szybsza niż….'
              : '比较句常用“niż”（比）：lepszy niż…、szybsza niż…。',
        ),
        _GrammarCard(
          title: polish ? 'Czasownik w teraźniejszości' : '动词现在时',
          intro: polish
              ? 'Osoba i liczba są zakodowane w końcówce; zaimek można pominąć, gdy kontekst jest jasny.'
              : '动词词尾表达主语的人称和数量；语境清楚时可以省略代词。',
          examples: const [
            'ja mówię · ty mówisz · on/ona mówi',
            'my mówimy · wy mówicie · oni/one mówią',
            'uczyć się: uczę się · uczysz się · uczy się',
          ],
          note: polish
              ? 'W czasownikach zwrotnych „się” zwykle stoi po odmienionej formie: uczę się, uczysz się.'
              : '反身动词“się”通常放在变位动词之后：uczę się、uczysz się。',
        ),
      ],
    );
  }
}

class _GrammarCard extends StatelessWidget {
  const _GrammarCard({
    required this.title,
    required this.intro,
    required this.examples,
    required this.note,
  });

  final String title;
  final String intro;
  final List<String> examples;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(intro, style: const TextStyle(color: _mutedInk, height: 1.45)),
          const SizedBox(height: 12),
          for (final example in examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('·  ', style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(example, style: const TextStyle(color: _ink, height: 1.4))),
                ],
              ),
            ),
          const Divider(height: 18, color: _line),
          Text(note, style: const TextStyle(color: _mutedInk, fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }
}

class _Flashcard extends StatelessWidget {
  const _Flashcard({
    required this.word,
    required this.language,
    required this.target,
    required this.revealed,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    required this.onDetails,
  });

  final Word word;
  final AppLanguage language;
  final LearningTarget target;
  final bool revealed;
  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeUp;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final polish = word.polishTranslation.trim();
    final chinesePrimary =
        language.isTraditional ? word.traditional : word.displayHanzi;
    final polishFront = polish.isEmpty
        ? word.englishTranslation
        : polish;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null || details.primaryVelocity!.abs() < 350) return;
        if (details.primaryVelocity! < 0) {
          onSwipeLeft();
        } else {
          onSwipeRight();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -350) {
          onSwipeUp();
        }
      },
      onTap: onTap,
      child: Container(
        height: 360,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(color: Color(0x120F1612), blurRadius: 28, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LevelBadge(label: word.level),
                const Spacer(),
                IconButton(
                  tooltip: language.text('Szczegóły słowa', '词语详情', '詞語詳情'),
                  onPressed: onDetails,
                  icon: const Icon(Icons.open_in_new_rounded, color: _mutedInk),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: revealed
                      ? _RevealedWord(
                          key: const ValueKey('revealed'),
                          word: word,
                          language: language,
                          chinesePrimary: chinesePrimary,
                          polish: polish,
                        )
                      : _HiddenWord(
                          key: const ValueKey('hidden'),
                          language: language,
                          showPolish: target.showsPolishOnFlashcardFront,
                          chinese: chinesePrimary,
                          polish: polishFront,
                          hasPolishTranslation: polish.isNotEmpty,
                        ),
                ),
              ),
            ),
            Center(
              child: Text(
                language.text('DOTKNIJ, ABY ODKRYĆ', '点击翻面', '點擊翻面'),
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenWord extends StatelessWidget {
  const _HiddenWord({
    super.key,
    required this.language,
    required this.showPolish,
    required this.chinese,
    required this.polish,
    required this.hasPolishTranslation,
  });

  final AppLanguage language;
  final bool showPolish;
  final String chinese;
  final String polish;
  final bool hasPolishTranslation;

  @override
  Widget build(BuildContext context) {
    if (showPolish) {
      return Column(
        key: const ValueKey('polish-front'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasPolishTranslation
                ? language.text('PO POLSKU', '波兰语', '波蘭語')
                : language.text('ANGIELSKI POMOST', '英语辅助', '英語輔助'),
            style: const TextStyle(color: _accent, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            polish,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 42, height: 1.08, fontWeight: FontWeight.w700),
          ),
          if (!hasPolishTranslation) ...[
            const SizedBox(height: 8),
            Text(
              language.text(
                'Polskie tłumaczenie tego hasła nie jest jeszcze uzupełnione.',
                '此词的波兰语翻译尚未补充。',
                '此詞的波蘭語翻譯尚未補充。',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedInk, fontSize: 13),
            ),
          ],
        ],
      );
    }

    return Column(
      key: const ValueKey('chinese-front'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(chinese, style: const TextStyle(color: _ink, fontSize: 82, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(
          language.text('Znaczenie ukryte', '释义已隐藏', '釋義已隱藏'),
          style: const TextStyle(color: _mutedInk, fontSize: 14),
        ),
      ],
    );
  }
}

class _RevealedWord extends StatelessWidget {
  const _RevealedWord({
    super.key,
    required this.word,
    required this.language,
    required this.chinesePrimary,
    required this.polish,
  });

  final Word word;
  final AppLanguage language;
  final String chinesePrimary;
  final String polish;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('word-back'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(chinesePrimary, style: const TextStyle(color: _ink, fontSize: 58, fontWeight: FontWeight.w600)),
        if (language.isTraditional && word.traditional != word.displayHanzi) ...[
          const SizedBox(height: 2),
          Text('简体 ${word.displayHanzi}', style: const TextStyle(color: _mutedInk, fontSize: 13)),
        ],
        const SizedBox(height: 5),
        Text(
          word.pinyin,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _accent, fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 15),
        if (language.isChinese) ...[
          Text(
            polish.isEmpty ? word.englishTranslation : polish,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 27, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            polish.isEmpty
                ? language.text('English bridge', '英语辅助', '英語輔助')
                : word.englishTranslation,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedInk, fontSize: 14),
          ),
        ] else ...[
          Text(
            polish.isEmpty ? word.englishTranslation : polish,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(word.englishTranslation, style: const TextStyle(color: _mutedInk, fontSize: 14)),
        ],
      ],
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.language,
    required this.selectedLevel,
    required this.counts,
    required this.onSelected,
    this.includeAll = false,
  });

  final AppLanguage language;
  final String selectedLevel;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final levels = [
      if (includeAll) 'Wszystkie',
      for (var number = 1; number <= 6; number++) 'HSK-$number',
      'HSK-7-9',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final level in levels)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(
                  level == 'Wszystkie'
                      ? language.text('Wszystkie', '全部', '全部')
                      : _hskLevelLabel(level),
                ),
                selected: selectedLevel == level,
                onSelected: level == 'Wszystkie' || (counts[level] ?? 0) > 0
                    ? (selected) {
                        if (selected) onSelected(level);
                      }
                    : null,
                backgroundColor: _paper,
                selectedColor: _accent,
                disabledColor: const Color(0xFFEDE7DD),
                labelStyle: TextStyle(
                  color: selectedLevel == level ? Colors.white : _ink,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: _line),
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryWordTile extends StatelessWidget {
  const _LibraryWordTile({
    required this.word,
    required this.language,
    required this.decision,
    required this.onTap,
    this.trailing,
  });

  final Word word;
  final AppLanguage language;
  final StudyDecision? decision;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final chinese =
        language.isTraditional ? word.traditional : word.displayHanzi;
    final translation = word.polishTranslation.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(chinese, style: const TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.w600)),
              Text(_hskLevelLabel(word.level), style: const TextStyle(color: _mutedInk, fontSize: 10)),
            ],
          ),
        ),
        title: Text(word.pinyin, style: const TextStyle(color: _accent, fontWeight: FontWeight.w600)),
        subtitle: Text(
          translation.isEmpty
              ? word.englishTranslation
              : '$translation  ·  ${word.englishTranslation}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _mutedInk),
        ),
        trailing: trailing ?? _DecisionMark(language: language, decision: decision),
      ),
    );
  }
}

class _DecisionMark extends StatelessWidget {
  const _DecisionMark({required this.language, required this.decision});

  final AppLanguage language;
  final StudyDecision? decision;

  @override
  Widget build(BuildContext context) {
    if (decision == null) return const Icon(Icons.chevron_right, color: _mutedInk);
    final label = switch (decision!) {
      StudyDecision.saved => language.text('Do nauki', '待学习', '待學習'),
      StudyDecision.known => language.text('Znam', '已掌握', '已掌握'),
      StudyDecision.skipped => language.text('Pominięte', '已跳过', '已跳過'),
    };
    final icon = switch (decision!) {
      StudyDecision.saved => Icons.bookmark_added_outlined,
      StudyDecision.known => Icons.check_circle_outline,
      StudyDecision.skipped => Icons.fast_forward_rounded,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: _accent),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _mutedInk, fontSize: 11)),
      ],
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({
    required this.language,
    required this.skippedCount,
    required this.showSkipped,
    required this.onReviewSkipped,
    required this.onResetSkipped,
  });

  final AppLanguage language;
  final int skippedCount;
  final bool showSkipped;
  final VoidCallback? onReviewSkipped;
  final VoidCallback? onResetSkipped;

  @override
  Widget build(BuildContext context) {
    return _EmptyPanel(
      icon: showSkipped
          ? Icons.check_circle_outline
          : Icons.auto_awesome_outlined,
      title: language.text(
        showSkipped ? 'Na dziś wystarczy.' : 'Talia na tym poziomie gotowa.',
        showSkipped ? '这一轮复习完成。' : '这个级别的卡片已完成。',
        showSkipped ? '這一輪複習完成。' : '這個級別的卡片已完成。',
      ),
      message: language.text(
        showSkipped
            ? 'Możesz wrócić do nowych słów lub usunąć pominięcia z talii.'
            : 'Możesz przejrzeć pominięte słowa albo sprawdzić cały poziom w bibliotece HSK.',
        showSkipped
            ? '可以继续新词，或把跳过的词放回词卡。'
            : '可以复习跳过的词，或在 HSK 词库查看全部内容。',
        showSkipped
            ? '可以繼續新詞，或把跳過的詞放回詞卡。'
            : '可以複習跳過的詞，或在 HSK 詞庫查看全部內容。',
      ),
      action: skippedCount > 0
          ? TextButton.icon(
              onPressed: showSkipped ? onResetSkipped : onReviewSkipped,
              icon: Icon(showSkipped ? Icons.refresh : Icons.undo),
              label: Text(
                showSkipped
                    ? language.text('Wyczyść pominięcia', '重置跳过的词', '重置跳過的詞')
                    : language.text('Przejrzyj pominięte', '复习跳过的词', '複習跳過的詞'),
              ),
            )
          : null,
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.language,
    required this.isSearchEmpty,
  });

  final AppLanguage language;
  final bool isSearchEmpty;

  @override
  Widget build(BuildContext context) {
    return _EmptyPanel(
      icon: Icons.search_off,
      title: language.text('Nic tu nie znaleziono.', '没有找到词语。', '沒有找到詞語。'),
      message: language.text(
        isSearchEmpty ? 'Zmień wyszukiwanie lub wybierz inny poziom.' : 'Dla wybranego zakresu nie ma jeszcze danych.',
        isSearchEmpty ? '请调整搜索内容或选择其他级别。' : '所选范围目前没有数据。',
        isSearchEmpty ? '請調整搜尋內容或選擇其他級別。' : '所選範圍目前沒有資料。',
      ),
    );
  }
}

class _EmptySavedWords extends StatelessWidget {
  const _EmptySavedWords({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) => _EmptyPanel(
        icon: Icons.bookmark_border_rounded,
        title: language.text('Twój słownik dopiero się zaczyna.', '收藏夹还是空的。', '收藏夾還是空的。'),
        message: language.text(
          'W talii wybierz „Do nauki” albo „Znam”, aby zachować słowo.',
          '在词卡中选择“稍后学习”或“我会了”来保存词语。',
          '在詞卡中選擇「稍後學習」或「我會了」來保存詞語。',
        ),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, color: _accent, size: 32),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _mutedInk, height: 1.45)),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1E8DA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          language.text(
            'HSK 2025 • słownictwo z krmanik/HSK-3.0 (CC BY-SA 4.0); angielskie hasła z CC-CEDICT. Szczegóły licencji: assets/data/sources/hsk-2025/License.md.',
            'HSK 2025 • 词表来自 krmanik/HSK-3.0（CC BY-SA 4.0）；英文释义来自 CC-CEDICT。许可信息：assets/data/sources/hsk-2025/License.md。',
            'HSK 2025 • 詞表來自 krmanik/HSK-3.0（CC BY-SA 4.0）；英文釋義來自 CC-CEDICT。授權資訊：assets/data/sources/hsk-2025/License.md。',
          ),
          style: const TextStyle(color: _mutedInk, fontSize: 12, height: 1.45),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: _accent,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _accent),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: _mutedInk, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6DF),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          _hskLevelLabel(label),
          style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      );
}

class _WordDetailSheet extends StatelessWidget {
  const _WordDetailSheet({required this.word, required this.language});

  final Word word;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final polish = word.polishTranslation.trim();
    final primaryChinese =
        language.isTraditional ? word.traditional : word.displayHanzi;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _LevelBadge(label: word.level),
                const Spacer(),
                IconButton(
                  tooltip: language.text('Zamknij', '关闭', '關閉'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Center(
              child: Text(
                primaryChinese,
                style: const TextStyle(color: _ink, fontSize: 64, fontWeight: FontWeight.w600),
              ),
            ),
            if (language.isTraditional && word.traditional != word.displayHanzi)
              Center(child: Text('简体 ${word.displayHanzi}', style: const TextStyle(color: _mutedInk))),
            Center(
              child: Text(
                word.pinyin,
                style: const TextStyle(color: _accent, fontSize: 19, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            _DetailRow(label: language.text('Po polsku', '波兰语', '波蘭語'), value: polish.isEmpty ? '—' : polish),
            _DetailRow(label: 'English', value: word.englishTranslation),
            if (word.notes.trim().isNotEmpty)
              _DetailRow(
                label: language.text('Uwagi', '备注', '備註'),
                value: word.notes,
              ),
            if (word.partOfSpeech != null)
              _DetailRow(
                label: language.text('Część mowy', '词性', '詞性'),
                value: word.partOfSpeech!,
              ),
            if (word.tags.isNotEmpty)
              _DetailRow(label: language.text('Temat', '主题', '主題'), value: word.tags.join(' · ')),
            if (language.isChinese) ...[
              const SizedBox(height: 14),
              Text(
                language.text('Odmiana po polsku', '波兰语词形', '波蘭語詞形'),
                style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              _PolishFormsSection(gloss: polish, language: language),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolishFormsSection extends StatefulWidget {
  const _PolishFormsSection({required this.gloss, required this.language});

  final String gloss;
  final AppLanguage language;

  @override
  State<_PolishFormsSection> createState() => _PolishFormsSectionState();
}

class _PolishFormsSectionState extends State<_PolishFormsSection> {
  late final Future<PolishFormsCatalog> _catalog = rootBundle
      .loadString('assets/data/polish_word_forms.json')
      .then(PolishFormsCatalog.fromJson);

  @override
  Widget build(BuildContext context) => FutureBuilder<PolishFormsCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              widget.language.text(
                'Nie udało się wczytać tabel odmiany: ${snapshot.error}',
                '词形表加载失败：${snapshot.error}',
                '詞形表載入失敗：${snapshot.error}',
              ),
              style: const TextStyle(color: _mutedInk, height: 1.45),
            );
          }
          if (!snapshot.hasData) {
            return const LinearProgressIndicator(color: _accent);
          }

          final entry = snapshot.data!.lookup(widget.gloss);
          if (entry == null) {
            return Text(
              widget.language.text(
                'Dla tego hasła nie ma jeszcze indywidualnej tabeli odmiany. Zasady znajdziesz w zakładce Gramatyka.',
                '这个词条尚无专门的词形表。相关规则请查看“语法”标签。',
                '這個詞條尚無專門的詞形表。相關規則請查看「語法」標籤。',
              ),
              style: const TextStyle(color: _mutedInk, height: 1.45),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final form in entry.forms)
                _DetailRow(
                  label: _polishFormLabel(form.label, widget.language),
                  value: form.value,
                ),
              const SizedBox(height: 8),
              Text(
                widget.language.text('Przykład', '例句', '例句'),
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.example.forLanguage(widget.language),
                style: const TextStyle(color: _ink, height: 1.45),
              ),
            ],
          );
        },
      );
}

String _polishFormLabel(String label, AppLanguage language) {
  if (language.isPolish) return label;
  return switch (label) {
    'Mianownik' => language.text('Mianownik', '主格', '主格'),
    'Dopełniacz' => language.text('Dopełniacz', '属格', '屬格'),
    'Celownik' => language.text('Celownik', '与格', '與格'),
    'Biernik' => language.text('Biernik', '宾格', '賓格'),
    'Narzędnik' => language.text('Narzędnik', '工具格', '工具格'),
    'Miejscownik' => language.text('Miejscownik', '处所格', '處所格'),
    'Wołacz' => language.text('Wołacz', '呼格', '呼格'),
    'Liczba mnoga' => language.text('Liczba mnoga', '复数', '複數'),
    'Stopień wyższy' => language.text('Stopień wyższy', '比较级', '比較級'),
    'Stopień najwyższy' => language.text('Stopień najwyższy', '最高级', '最高級'),
    'Przykład' => language.text('Przykład', '例句', '例句'),
    'ja' => language.text('ja', '我 (ja)', '我 (ja)'),
    'ty' => language.text('ty', '你 (ty)', '你 (ty)'),
    'on/ona/ono' => language.text('on/ona/ono', '他/她/它', '他/她/它'),
    'my' => language.text('my', '我们 (my)', '我們 (my)'),
    'wy' => language.text('wy', '你们 (wy)', '你們 (wy)'),
    'oni/one' => language.text('oni/one', '他们/她们 (oni/one)', '他們/她們 (oni/one)'),
    _ => label,
  };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(label, style: const TextStyle(color: _mutedInk, fontSize: 13)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

void _showWordDetails(BuildContext context, Word word, AppLanguage language) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _WordDetailSheet(word: word, language: language),
  );
}
