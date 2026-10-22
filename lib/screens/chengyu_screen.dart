import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_language.dart';
import '../models/chengyu.dart';
import '../models/word.dart';
import '../providers/word_provider.dart';
import '../widgets/chengyu_illustration.dart';

class ChengyuScreen extends StatefulWidget {
  const ChengyuScreen({
    super.key,
    this.language = AppLanguage.polish,
    @visibleForTesting this.loadIdioms,
  });

  final AppLanguage language;

  /// Replaces bundled asset loading; tests use it to avoid real asset I/O.
  final Future<List<Chengyu>> Function()? loadIdioms;

  @override
  State<ChengyuScreen> createState() => _ChengyuScreenState();
}

class _ChengyuScreenState extends State<ChengyuScreen> {
  final _search = TextEditingController();
  late Future<List<Chengyu>> _idioms;
  WordProvider? _words;

  @override
  void initState() {
    super.initState();
    _idioms = _load();
  }

  Future<List<Chengyu>> _load() async {
    final loader = widget.loadIdioms;
    if (loader != null) return loader();
    return chengyuFromJson(
      await rootBundle.loadString('assets/data/chengyu.json'),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _text(String pl, String zh, String hant) =>
      widget.language.text(pl, zh, hant);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _words = context.watch<WordProvider?>();
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomScrollView(
                key: const PageStorageKey('chengyu-list'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(child: _header(theme)),
                  FutureBuilder<List<Chengyu>>(
                    future: _idioms,
                    builder: (context, snapshot) => _results(snapshot, theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            _text('CHENGYU · OPOWIEŚCI W CZTERECH ZNAKACH', '成语 · 四字中的故事',
                '成語 · 四字中的故事'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text('Małe historie, wielkie znaczenia', '小故事，大智慧', '小故事，大智慧'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              'Poznaj idiom, zobacz przykład i odkryj jego historię. Wszystko dostępne offline.',
              '认识成语，阅读例句，探索典故。全部内容均可离线使用。',
              '認識成語，閱讀例句，探索典故。全部內容均可離線使用。',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _text('Szukaj idiomu', '搜索成语', '搜尋成語'),
              hintText: _text('Znaki, pinyin, polski lub angielski',
                  '汉字、拼音、波兰语或英语', '漢字、拼音、波蘭語或英語'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _text('Wyczyść wyszukiwanie', '清除搜索', '清除搜尋'),
                      onPressed: () => setState(_search.clear),
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _results(AsyncSnapshot<List<Chengyu>> snapshot, ThemeData theme) {
    if (snapshot.hasError) {
      return SliverToBoxAdapter(
        child: _message(
          Icons.menu_book_outlined,
          _text(
              'Nie udało się otworzyć zbioru idiomów.', '无法打开成语集。', '無法開啟成語集。'),
          FilledButton.tonal(
            onPressed: () => setState(() => _idioms = _load()),
            child: Text(_text('Spróbuj ponownie', '重试', '重試')),
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(
              semanticsLabel: _text('Wczytywanie idiomów', '正在加载成语', '正在載入成語'),
            ),
          ),
        ),
      );
    }
    final all = snapshot.data!;
    final results = all.where((item) => item.matches(_search.text)).toList();
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: _message(
          Icons.search_off_rounded,
          _text('Brak wyników. Spróbuj innego słowa.', '没有结果，请换个关键词。',
              '沒有結果，請換個關鍵詞。'),
          TextButton(
            onPressed: () => setState(_search.clear),
            child: Text(_text('Pokaż wszystkie', '显示全部', '顯示全部')),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index > 0) return _card(results[index - 1]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _text(
                    '${results.length} z ${all.length} idiomów',
                    '${results.length} / ${all.length} 个成语',
                    '${results.length} / ${all.length} 個成語'),
                style: theme.textTheme.labelMedium,
              ),
            );
          },
          childCount: results.length + 1,
        ),
      ),
    );
  }

  Widget _message(IconData icon, String message, Widget action) => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              action,
            ],
          ),
        ),
      );

  Widget _illustration(Chengyu idiom, {double height = 128}) {
    final motifLabel = switch (idiom.motif) {
      ChengyuMotif.snake => _text('wąż', '蛇', '蛇'),
      ChengyuMotif.field => _text('rośliny', '植物', '植物'),
      ChengyuMotif.well => _text('woda i studnia', '水与井', '水與井'),
      ChengyuMotif.horse => _text('koń', '马', '馬'),
      ChengyuMotif.boat => _text('łódź', '船', '船'),
      ChengyuMotif.bell => _text('dzwonek', '铃铛', '鈴鐺'),
      ChengyuMotif.dragon => _text('smok', '龙', '龍'),
      ChengyuMotif.music => _text('muzyka', '音乐', '音樂'),
      ChengyuMotif.mountain => _text('góry', '山', '山'),
      ChengyuMotif.bow => _text('łuk i strzała', '弓箭', '弓箭'),
      ChengyuMotif.forest => _text('lis i las', '狐狸与树林', '狐狸與樹林'),
    };
    return ChengyuIllustration(
      motif: idiom.motif,
      height: height,
      semanticLabel: _text(
        'Autorska ilustracja symboliczna: $motifLabel',
        '原创象征插画：$motifLabel',
        '原創象徵插畫：$motifLabel',
      ),
    );
  }

  Widget _card(Chengyu idiom) {
    final theme = Theme.of(context);
    final decision = _decisionFor(_words, idiom);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(idiom),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(idiom.characters(widget.language),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(idiom.pinyin,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      )),
                  const SizedBox(height: 12),
                  Text(idiom.meaning.forLanguage(widget.language),
                      style: theme.textTheme.bodyLarge),
                  if (decision != null) ...[
                    const SizedBox(height: 12),
                    _StatusChip(decision: decision, language: widget.language),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.auto_stories_outlined, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(_text(
                            'Odkryj historię i użycie', '探索典故与用法', '探索典故與用法'))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ]),
                ],
              );
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _illustration(idiom),
                    const SizedBox(height: 16),
                    text
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(
                      width: 210, child: _illustration(idiom, height: 160)),
                  const SizedBox(width: 24),
                  Expanded(child: text),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDetail(Chengyu idiom) {
    FocusScope.of(context).unfocus();
    final language = widget.language;
    final words = context.read<WordProvider?>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (context) {
        final theme = Theme.of(context);
        Widget section(String title, String body) => Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
                  SelectableText(body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
                ],
              ),
            );
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: language.text('Zamknij', '关闭', '關閉'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                _illustration(idiom, height: 190),
                const SizedBox(height: 20),
                SelectableText(idiom.characters(language),
                    style: theme.textTheme.headlineLarge),
                SelectableText(idiom.pinyin,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
                if (words != null)
                  _ChengyuStudyActions(
                    idiom: idiom,
                    language: language,
                    words: words,
                  ),
                section(language.text('Znaczenie', '含义', '含義'),
                    idiom.meaning.forLanguage(language)),
                section(language.text('Po angielsku', '英语释义', '英語釋義'),
                    idiom.englishMeaning),
                section(language.text('Dosłownie', '字面意思', '字面意思'),
                    idiom.literal.forLanguage(language)),
                section(
                    language.text('Przykład po chińsku', '中文例句', '中文例句'),
                    language.isTraditional
                        ? idiom.example.traditionalChinese
                        : idiom.example.simplifiedChinese),
                section(language.text('Tłumaczenie polskie', '波兰语译文', '波蘭語譯文'),
                    idiom.example.polish),
                const SizedBox(height: 20),
                Card(
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.secondaryContainer,
                  child: ExpansionTile(
                    key: ValueKey('story-${idiom.id}'),
                    leading: const Icon(Icons.auto_stories_outlined),
                    title:
                        Text(language.text('Odkryj opowieść', '展开典故', '展開典故')),
                    subtitle: Text(language.text(
                        'Krótki kontekst klasyczny', '简短的古典背景', '簡短的古典背景')),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      SelectableText(idiom.story.forLanguage(language),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(height: 1.55)),
                    ],
                  ),
                ),
                section(language.text('Używaj świadomie', '使用提醒', '使用提醒'),
                    idiom.caution.forLanguage(language)),
                const SizedBox(height: 24),
                Text(
                  language.text(
                    'Autorskie ilustracje symboliczne, współdzielone według motywu. Nie są rekonstrukcjami historycznymi. Opowieści to krótkie opracowania, nie cytaty ze źródeł.',
                    '原创象征插画按主题共用，并非历史复原。典故为简短改写，并非原文引述。',
                    '原創象徵插畫按主題共用，並非歷史復原。典故為簡短改寫，並非原文引述。',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

StudyDecision? _decisionFor(WordProvider? words, Chengyu idiom) {
  if (words == null || words.profileId == null) return null;
  return words.studyDecisionFor(idiom.studyWord(words.allWords).hanzi) ??
      words.studyDecisionFor(idiom.simplified);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.decision, required this.language});

  final StudyDecision decision;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final known = decision == StudyDecision.known;
    final foreground =
        known ? colors.onTertiaryContainer : colors.onPrimaryContainer;
    final label = switch (decision) {
      StudyDecision.saved => language.text('Do nauki', '待学习', '待學習'),
      StudyDecision.known => language.text('Znam', '已掌握', '已掌握'),
      StudyDecision.skipped => language.text('Pominięte', '已跳过', '已跳過'),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(
          known ? Icons.check_circle_outline : Icons.bookmark_added_outlined,
          size: 18,
          color: foreground,
        ),
        label: Text(label),
        labelStyle: TextStyle(color: foreground),
        backgroundColor:
            known ? colors.tertiaryContainer : colors.primaryContainer,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Persists idiom progress through the active learner's [WordProvider].
class _ChengyuStudyActions extends StatefulWidget {
  const _ChengyuStudyActions({
    required this.idiom,
    required this.language,
    required this.words,
  });

  final Chengyu idiom;
  final AppLanguage language;
  final WordProvider words;

  @override
  State<_ChengyuStudyActions> createState() => _ChengyuStudyActionsState();
}

class _ChengyuStudyActionsState extends State<_ChengyuStudyActions> {
  bool _saving = false;

  Future<void> _save(Word word, StudyDecision? decision) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (decision == null) {
        await widget.words.removeFromMyWords(word.hanzi);
      } else {
        await widget.words.recordStudyDecision(word, decision);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(widget.language.text(
            'Nie udało się zapisać postępu: $error',
            '无法保存进度：$error',
            '無法儲存進度：$error',
          )),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.words,
        builder: (context, _) {
          final language = widget.language;
          final words = widget.words;
          final word = words.profileId == null
              ? null
              : widget.idiom.studyWord(words.allWords);
          final current = _decisionFor(words, widget.idiom);
          final enabled = word != null && !_saving;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.bookmark_outline, size: 18),
                      label: Text(language.text('Do nauki', '待学习', '待學習')),
                      selected: current == StudyDecision.saved,
                      onSelected: enabled
                          ? (_) => _save(word, StudyDecision.saved)
                          : null,
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(language.text('Znam', '已掌握', '已掌握')),
                      selected: current == StudyDecision.known,
                      onSelected: enabled
                          ? (_) => _save(word, StudyDecision.known)
                          : null,
                    ),
                    if (current == StudyDecision.saved ||
                        current == StudyDecision.known)
                      TextButton(
                        onPressed: enabled ? () => _save(word, null) : null,
                        child:
                            Text(language.text('Usuń status', '清除状态', '清除狀態')),
                      ),
                  ],
                ),
                if (!enabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      language.text('Wczytywanie lub zapisywanie profilu…',
                          '正在加载或保存档案…', '正在載入或儲存檔案…'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        },
      );
}
