import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_language.dart';
import '../models/learning_target.dart';
import '../models/practice_exercise.dart';
import '../models/polish_word_forms.dart';
import '../models/word.dart';
import '../providers/word_provider.dart';

enum _PracticeMode { vocabulary, fillBlank, declension, conjugation }

class PracticeTab extends StatefulWidget {
  const PracticeTab({
    super.key,
    required this.language,
    required this.target,
  });

  final AppLanguage language;
  final LearningTarget target;

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  static const _exerciseAsset = 'assets/data/practice_exercises.json';
  static const _polishFormsAsset = 'assets/data/polish_word_forms.json';
  final _random = Random();
  final _answerController = TextEditingController();
  final List<TextEditingController> _paradigmControllers = [];

  _PracticeMode _mode = _PracticeMode.vocabulary;
  late String _selectedLevel =
      widget.target == LearningTarget.chinese ? 'HSK-1' : 'A1';
  Word? _word;
  PracticeExercise? _exercise;
  PolishWordForms? _paradigm;
  PolishFormsCatalog? _polishForms;
  List<bool>? _paradigmCorrectness;
  List<String> _options = const [];
  String? _selectedOption;
  bool? _isCorrect;
  bool _exerciseDataLoaded = false;
  bool _polishFormsLoading = false;
  String? _exerciseLoadError;
  String? _polishFormsLoadError;
  int _answered = 0;
  int _correct = 0;

  @override
  void didUpdateWidget(covariant PracticeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target ||
        oldWidget.language != widget.language) {
      _selectedLevel = widget.target == LearningTarget.chinese ? 'HSK-1' : 'A1';
      if (widget.target == LearningTarget.chinese &&
          (_mode == _PracticeMode.declension ||
              _mode == _PracticeMode.conjugation)) {
        _mode = _PracticeMode.vocabulary;
      }
      _clearQuestion();
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadExerciseData());
  }

  @override
  void dispose() {
    _answerController.dispose();
    for (final controller in _paradigmControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isParadigmMode =>
      _mode == _PracticeMode.declension || _mode == _PracticeMode.conjugation;

  List<PolishForm> get _activeParadigmForms {
    final paradigm = _paradigm;
    if (paradigm == null) return const [];
    return _mode == _PracticeMode.declension
        ? PolishFormsCatalog.declensionFormsFor(paradigm)
        : PolishFormsCatalog.conjugationFormsFor(paradigm);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final language = widget.language;
    return Consumer<WordProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        final exercises = _exercisePool;
        if (_mode == _PracticeMode.vocabulary && provider.allWords.isEmpty) {
          return Center(
            child: Text(language.text(
              'Nie znaleziono słownictwa do ćwiczeń.',
              '没有可用于练习的词汇。',
              '沒有可用於練習的詞彙。',
            )),
          );
        }
        if (_mode == _PracticeMode.fillBlank && !_exerciseDataLoaded) {
          return Center(
            child: _exerciseLoadError == null
                ? CircularProgressIndicator(color: colors.primary)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(language.text(
                        'Nie udało się wczytać ćwiczeń: $_exerciseLoadError',
                        '练习加载失败：$_exerciseLoadError',
                        '練習載入失敗：$_exerciseLoadError',
                      )),
                      TextButton(
                        onPressed: _retryExerciseData,
                        child:
                            Text(language.text('Spróbuj ponownie', '重试', '重試')),
                      ),
                    ],
                  ),
          );
        }
        if (_isParadigmMode && _polishForms == null) {
          return Center(
            child: _polishFormsLoading || _polishFormsLoadError == null
                ? CircularProgressIndicator(color: colors.primary)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(language.text(
                        'Nie udało się wczytać form polskich: $_polishFormsLoadError',
                        '波兰语词形加载失败：$_polishFormsLoadError',
                        '波蘭語詞形載入失敗：$_polishFormsLoadError',
                      )),
                      TextButton(
                        onPressed: _retryPolishForms,
                        child:
                            Text(language.text('Spróbuj ponownie', '重试', '重試')),
                      ),
                    ],
                  ),
          );
        }
        if (_word == null &&
            _exercise == null &&
            _paradigm == null &&
            (_mode == _PracticeMode.vocabulary ||
                _isParadigmMode ||
                exercises.isNotEmpty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _nextQuestion(provider, exercises));
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 32, 16, compact ? 18 : 32, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PracticeEyebrow(language.text(
                        'CODZIENNA PRAKTYKA',
                        '每日练习',
                        '每日練習',
                      )),
                      const SizedBox(height: 8),
                      Text(
                        language.text('Użyj słowa, nie tylko je poznaj.',
                            '把词语用出来。', '把詞語用出來。'),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: compact ? 28 : 36,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.target == LearningTarget.chinese
                            ? language.text(
                                'Kurs chińskiego · HSK 2025',
                                '中文课程 · HSK 2025',
                                '中文課程 · HSK 2025',
                              )
                            : language.text(
                                'Kurs polskiego · odmiana i podstawowe słownictwo',
                                '波兰语课程 · 词形变化与基础词汇',
                                '波蘭語課程 · 詞形變化與基礎詞彙',
                              ),
                        style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 16,
                            height: 1.45),
                      ),
                      const SizedBox(height: 18),
                      _LevelSelector(
                        language: language,
                        target: widget.target,
                        selectedLevel: _selectedLevel,
                        levels: widget.target == LearningTarget.chinese
                            ? provider.availableLevels
                                .where((l) => l != 'Wszystkie')
                                .toList()
                            : const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
                        onSelected: (level) {
                          setState(() {
                            _selectedLevel = level;
                            _clearQuestion();
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            selected: _mode == _PracticeMode.vocabulary,
                            avatar: const Icon(Icons.style_outlined, size: 18),
                            label:
                                Text(language.text('Słownictwo', '词汇', '詞彙')),
                            onSelected: (_) =>
                                _selectMode(_PracticeMode.vocabulary),
                          ),
                          ChoiceChip(
                            selected: _mode == _PracticeMode.fillBlank,
                            avatar:
                                const Icon(Icons.edit_note_rounded, size: 18),
                            label: Text(
                                language.text('Uzupełnij lukę', '填空', '填空')),
                            onSelected: (_) =>
                                _selectMode(_PracticeMode.fillBlank),
                          ),
                          if (widget.target == LearningTarget.polish) ...[
                            ChoiceChip(
                              selected: _mode == _PracticeMode.declension,
                              avatar: const Icon(Icons.table_chart_outlined,
                                  size: 18),
                              label: Text(
                                  language.text('Przypadki', '格变化', '格變化')),
                              onSelected: (_) =>
                                  _selectMode(_PracticeMode.declension),
                            ),
                            ChoiceChip(
                              selected: _mode == _PracticeMode.conjugation,
                              avatar:
                                  const Icon(Icons.sync_alt_rounded, size: 18),
                              label: Text(
                                  language.text('Czasowniki', '动词变位', '動詞變位')),
                              onSelected: (_) =>
                                  _selectMode(_PracticeMode.conjugation),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _PracticeStats(
                        language: language,
                        answered: _answered,
                        correct: _correct,
                      ),
                      const SizedBox(height: 12),
                      if (_mode == _PracticeMode.fillBlank && exercises.isEmpty)
                        _EmptyPracticeState(
                          language: language,
                          onSwitchToVocabulary: () => setState(() {
                            _mode = _PracticeMode.vocabulary;
                            _clearQuestion();
                          }),
                        )
                      else if (_mode == _PracticeMode.vocabulary)
                        _buildVocabularyQuestion(compact)
                      else if (_mode == _PracticeMode.fillBlank &&
                          _exercise != null)
                        _buildFillBlankQuestion(compact),
                      if (_isParadigmMode && _paradigm != null)
                        _buildParadigmQuestion(compact),
                      if (_isCorrect != null) ...[
                        const SizedBox(height: 12),
                        _FeedbackCard(
                          language: language,
                          isCorrect: _isCorrect!,
                          explanation: _feedbackExplanation(language),
                          answer: _feedbackAnswer(language),
                        ),
                        const SizedBox(height: 12),
                        if (_mode == _PracticeMode.vocabulary &&
                            widget.target == LearningTarget.chinese)
                          _ChineseAnswerDetails(
                            word: _word!,
                            traditional: language.isTraditional,
                          ),
                      ],
                      if (_mode == _PracticeMode.vocabulary ||
                          (_mode == _PracticeMode.fillBlank &&
                              exercises.isNotEmpty) ||
                          _isParadigmMode) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isCorrect == null
                                ? null
                                : () => setState(
                                      () => _nextQuestion(provider, exercises),
                                    ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(language.text(
                              'Następne pytanie',
                              '下一题',
                              '下一題',
                            )),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<PracticeExercise> get _exercisePool {
    final loaded = _loadedExercises;
    return loaded
        .where((exercise) =>
            exercise.target == widget.target &&
            exercise.courseLevel == _selectedLevel)
        .toList(growable: false);
  }

  List<PracticeExercise> _loadedExercises = const [];

  void _selectMode(_PracticeMode mode) {
    setState(() {
      _mode = mode;
      _clearQuestion();
    });
    if (_isParadigmMode && _polishForms == null) {
      unawaited(_loadPolishForms());
      return;
    }
    final provider = context.read<WordProvider>();
    setState(() => _nextQuestion(provider, _exercisePool));
  }

  void _nextQuestion(WordProvider provider, List<PracticeExercise> exercises) {
    final previousExerciseId = _exercise?.id;
    final previousLemma = _paradigm?.lemmas.first;
    _answerController.clear();
    _selectedOption = null;
    _isCorrect = null;
    _paradigmCorrectness = null;
    _word = null;
    _exercise = null;
    _paradigm = null;
    for (final controller in _paradigmControllers) {
      controller.dispose();
    }
    _paradigmControllers.clear();

    if (_isParadigmMode) {
      final catalog = _polishForms;
      if (catalog == null) return;
      final paradigms = _mode == _PracticeMode.declension
          ? catalog.declensionParadigms
          : catalog.conjugationParadigms;
      final candidates = paradigms
          .where((item) => item.lemmas.first != previousLemma)
          .toList(growable: false);
      final source = candidates.isEmpty ? paradigms : candidates;
      if (source.isEmpty) return;
      _paradigm = source[_random.nextInt(source.length)];
      for (var i = 0; i < _activeParadigmForms.length; i++) {
        _paradigmControllers.add(TextEditingController());
      }
    } else if (_mode == _PracticeMode.fillBlank) {
      if (exercises.isEmpty) return;
      final candidates =
          exercises.where((item) => item.id != previousExerciseId).toList();
      _exercise = candidates[_random.nextInt(candidates.length)];
    } else {
      final candidates = widget.target == LearningTarget.chinese
          ? provider.allWords
              .where((word) => word.level == _selectedLevel)
              .toList()
          : provider.allWords;
      if (candidates.isEmpty) return;
      _word = candidates[_random.nextInt(candidates.length)];
      _options = _makeOptions(_word!, candidates);
    }
  }

  void _clearQuestion() {
    for (final controller in _paradigmControllers) {
      controller.dispose();
    }
    _paradigmControllers.clear();
    _word = null;
    _exercise = null;
    _paradigm = null;
    _paradigmCorrectness = null;
    _options = const [];
    _selectedOption = null;
    _isCorrect = null;
    _answerController.clear();
  }

  List<String> _makeOptions(Word word, List<Word> candidates) {
    final answer = _wordAnswer(word, widget.language);
    final options = <String>{answer};
    final attempts = min(candidates.length * 2, 100);
    for (var attempt = 0; attempt < attempts && options.length < 4; attempt++) {
      final candidate = candidates[_random.nextInt(candidates.length)];
      if (candidate.hanzi == word.hanzi) continue;
      final distractor = _wordAnswer(candidate, widget.language);
      if (distractor.trim().isNotEmpty) options.add(distractor);
    }
    final result = options.toList()..shuffle(_random);
    return result;
  }

  String _wordAnswer(Word word, AppLanguage language) =>
      widget.target == LearningTarget.chinese
          ? language.isTraditional
              ? word.traditional
              : word.displayHanzi
          : word.polishTranslation.split(RegExp(r'[;,]')).first.trim();

  String _wordPrompt(Word word, AppLanguage language) =>
      widget.target == LearningTarget.chinese
          ? word.polishTranslation
          : language.isTraditional
              ? word.traditional
              : word.displayHanzi;

  String _wordAnswerDescription(AppLanguage language) {
    if (widget.target == LearningTarget.chinese) {
      return language.text(
        'Sprawdź pinyin i tłumaczenie poniżej.',
        '请查看下面的拼音和翻译。',
        '請查看下面的拼音和翻譯。',
      );
    }
    return language.text(
      'Za poprawne uznajemy tutaj pierwszy gloss polski.',
      '本题以波兰语的第一个释义为标准答案。',
      '本題以波蘭語的第一個釋義為標準答案。',
    );
  }

  String _feedbackExplanation(AppLanguage language) {
    if (_mode == _PracticeMode.fillBlank) {
      return _exercise!.explanation.forLanguage(language);
    }
    if (_isParadigmMode) {
      return _paradigm!.example.forLanguage(language);
    }
    return _wordAnswerDescription(language);
  }

  String _feedbackAnswer(AppLanguage language) {
    if (_mode == _PracticeMode.fillBlank) return _exercise!.answer;
    if (!_isParadigmMode) return _wordAnswer(_word!, language);
    final correctCount = _paradigmCorrectness!.where((value) => value).length;
    return language.text(
      'Poprawne formy: $correctCount/${_paradigmCorrectness!.length}',
      '正确词形：$correctCount/${_paradigmCorrectness!.length}',
      '正確詞形：$correctCount/${_paradigmCorrectness!.length}',
    );
  }

  Widget _buildVocabularyQuestion(bool compact) {
    final colors = Theme.of(context).colorScheme;
    final word = _word;
    if (word == null) {
      return const _QuestionCard(
          child: Center(child: CircularProgressIndicator()));
    }
    return _QuestionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionLabel(
              text: widget.language.text('WYBIERZ ODPOWIEDŹ', '选择答案', '選擇答案')),
          const SizedBox(height: 10),
          Text(
            _wordPrompt(word, widget.language),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: widget.target == LearningTarget.chinese
                  ? (compact ? 25 : 32)
                  : (compact ? 32 : 42),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: _isCorrect == null
                    ? () => setState(() => _selectedOption = option)
                    : null,
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: _selectedOption == option
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                  disabledForegroundColor: _selectedOption == option
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  backgroundColor: _selectedOption == option
                      ? colors.primaryContainer
                      : colors.surface,
                  side: BorderSide(
                    color: _selectedOption == option
                        ? colors.primary
                        : colors.outlineVariant,
                  ),
                  padding: const EdgeInsets.all(15),
                ),
                child: Text(option,
                    style: const TextStyle(fontSize: 18, height: 1.45)),
              ),
            ),
          if (_isCorrect == null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _selectedOption == null ? null : _checkChoice,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: Text(widget.language.text('Sprawdź', '检查', '檢查')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFillBlankQuestion(bool compact) {
    final colors = Theme.of(context).colorScheme;
    final exercise = _exercise!;
    return _QuestionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionLabel(
              text: widget.language.text('UZUPEŁNIJ ZDANIE', '完成句子', '完成句子')),
          const SizedBox(height: 12),
          Text(
            exercise.prompt.forLanguage(widget.language),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: compact ? 21 : 26,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            style:
                TextStyle(color: colors.onSurface, fontSize: 16, height: 1.45),
            enabled: _isCorrect == null,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _checkTypedAnswer(exercise),
            decoration: InputDecoration(
              labelText:
                  widget.language.text('Twoja odpowiedź', '你的答案', '你的答案'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_isCorrect == null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _answerController.text.trim().isEmpty
                    ? null
                    : () => _checkTypedAnswer(exercise),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: Text(widget.language.text('Sprawdź', '检查', '檢查')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParadigmQuestion(bool compact) {
    final colors = Theme.of(context).colorScheme;
    final paradigm = _paradigm!;
    final forms = _activeParadigmForms;
    final isConjugation = _mode == _PracticeMode.conjugation;
    return _QuestionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionLabel(
            text: widget.language.text(
              isConjugation ? 'ODMIANA CZASOWNIKA' : 'ODMIANA PRZEZ PRZYPADKI',
              isConjugation ? '动词变位' : '名词格变化',
              isConjugation ? '動詞變位' : '名詞格變化',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            paradigm.lemmas.join(' / '),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: compact ? 27 : 34,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paradigm.example.forLanguage(widget.language),
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < forms.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: compact ? 102 : 170,
                    child: Text(
                      _formLabel(forms[i].label, widget.language),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: ValueKey('practice-form-$i'),
                      controller: _paradigmControllers[i],
                      enabled: _isCorrect == null,
                      textInputAction: i == forms.length - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (i == forms.length - 1) _checkParadigmAnswers();
                      },
                      decoration: InputDecoration(
                        hintText: widget.language.text(
                          'Wpisz formę',
                          '输入词形',
                          '輸入詞形',
                        ),
                        errorText: _paradigmCorrectness?[i] == false
                            ? '${widget.language.text('Poprawnie:', '正确答案：', '正確答案：')} ${forms[i].value}'
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_paradigmCorrectness != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _paradigmCorrectness![i]
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _paradigmCorrectness![i]
                          ? colors.tertiary
                          : colors.error,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          if (_isCorrect == null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _paradigmControllers
                        .any((controller) => controller.text.trim().isNotEmpty)
                    ? _checkParadigmAnswers
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: Text(widget.language.text('Sprawdź', '检查', '檢查')),
              ),
            ),
        ],
      ),
    );
  }

  String _formLabel(String label, AppLanguage language) {
    if (language.isPolish) return label;
    final caseMatch = RegExp(r'^(\d+)\. ([^(]+)').firstMatch(label);
    if (caseMatch != null) {
      final cases = language.isTraditional
          ? const {
              'Mianownik': '主格',
              'Dopełniacz': '屬格',
              'Celownik': '與格',
              'Biernik': '賓格',
              'Narzędnik': '工具格',
              'Miejscownik': '處格',
              'Wołacz': '呼格',
            }
          : const {
              'Mianownik': '主格',
              'Dopełniacz': '属格',
              'Celownik': '与格',
              'Biernik': '宾格',
              'Narzędnik': '工具格',
              'Miejscownik': '处格',
              'Wołacz': '呼格',
            };
      final number = RegExp(r'^\d+\.').firstMatch(label)?.group(0) ?? '';
      final name = caseMatch.group(2)!.trim();
      final numberType = label.contains('(lp.)')
          ? language.isTraditional
              ? '（單數）'
              : '（单数）'
          : label.contains('(lm.)')
              ? language.isTraditional
                  ? '（複數）'
                  : '（复数）'
              : '';
      return '$number ${cases[name] ?? name}$numberType';
    }
    final labels = language.isTraditional
        ? const {
            'ja': '我',
            'ty': '你',
            'on/ona/ono': '他／她／它',
            'my': '我們',
            'wy': '你們',
            'oni/one': '他們／她們',
            'Przeszły: ja (m./ż.)': '過去式：我（陽性／陰性）',
            'Przeszły: on/ona/ono': '過去式：他／她／它',
            'Przeszły: oni/one': '過去式：他們／她們',
            'Przypuszczający: ja (m./ż.)': '條件式：我（陽性／陰性）',
            'Przyszły (dokonany): ja': '將來式（完成體）：我',
            'Przyszły (niedokonany): ja': '將來式（未完成體）：我',
            'Przyszły: ja': '將來式：我',
            'Rozkazujący: my': '命令式：我們',
            'Rozkazujący: ty': '命令式：你',
            'Rozkazujący: wy': '命令式：你們',
            'Tryb przypuszczający: ja': '條件式：我',
            'Tryb przypuszczający: ty': '條件式：你',
          }
        : const {
            'ja': '我',
            'ty': '你',
            'on/ona/ono': '他/她/它',
            'my': '我们',
            'wy': '你们',
            'oni/one': '他们/她们',
            'Przeszły: ja (m./ż.)': '过去式：我（阳性/阴性）',
            'Przeszły: on/ona/ono': '过去式：他/她/它',
            'Przeszły: oni/one': '过去式：他们/她们',
            'Przypuszczający: ja (m./ż.)': '条件式：我（阳性/阴性）',
            'Przyszły (dokonany): ja': '将来时（完成体）：我',
            'Przyszły (niedokonany): ja': '将来时（未完成体）：我',
            'Przyszły: ja': '将来时：我',
            'Rozkazujący: my': '命令式：我们',
            'Rozkazujący: ty': '命令式：你',
            'Rozkazujący: wy': '命令式：你们',
            'Tryb przypuszczający: ja': '条件式：我',
            'Tryb przypuszczający: ty': '条件式：你',
          };
    return labels[label] ?? label;
  }

  void _checkChoice() {
    if (_isCorrect != null || _word == null || _selectedOption == null) return;
    final word = _word!;
    final aliases = widget.target == LearningTarget.chinese
        ? [word.displayHanzi, word.traditional]
        : word.polishTranslation.split(RegExp(r'[;,]'));
    unawaited(_recordAnswer(
      practiceAnswerMatches(_selectedOption!, aliases),
      answer: _selectedOption!,
    ));
  }

  void _checkTypedAnswer(PracticeExercise exercise) {
    if (_isCorrect != null || _answerController.text.trim().isEmpty) return;
    unawaited(_recordAnswer(
      practiceAnswerMatches(
        _answerController.text,
        [exercise.answer, ...exercise.acceptedAnswers],
      ),
      answer: _answerController.text,
    ));
  }

  void _checkParadigmAnswers() {
    if (_isCorrect != null || _paradigm == null) return;
    final forms = _activeParadigmForms;
    final correctness = List.generate(forms.length, (index) {
      return practiceAnswerMatches(
        _paradigmControllers[index].text,
        PolishFormsCatalog.answerVariantsFor(forms[index]),
      );
    });
    _paradigmCorrectness = correctness;
    unawaited(_recordAnswer(
      correctness.every((value) => value),
      answer:
          _paradigmControllers.map((controller) => controller.text).join(' | '),
      extraDetails: {
        'lemma': _paradigm!.lemmas.first,
        'forms': {
          for (var i = 0; i < forms.length; i++)
            forms[i].label: {
              'answer': _paradigmControllers[i].text,
              'correct': correctness[i],
              'expected': forms[i].value,
            },
        },
      },
    ));
  }

  Future<void> _recordAnswer(
    bool correct, {
    required String answer,
    Map<String, Object?> extraDetails = const {},
  }) async {
    final provider = context.read<WordProvider>();
    final vocabulary = _mode == _PracticeMode.vocabulary;
    final exerciseId = vocabulary
        ? 'vocabulary:${widget.target.name}:${_word!.hanzi}'
        : _isParadigmMode
            ? 'polish_forms:${_mode.name}:${_paradigm!.lemmas.first}'
            : _exercise!.id;
    final details = <String, Object?>{
      'target': widget.target.name,
      'courseLevel': _selectedLevel,
      'language': widget.language.name,
      ...extraDetails,
    };
    setState(() {
      _isCorrect = correct;
      _answered++;
      if (correct) _correct++;
    });
    try {
      await provider.recordPracticeResult(
        exerciseId: exerciseId,
        kind: vocabulary
            ? 'vocabulary'
            : _isParadigmMode
                ? _mode.name
                : 'cloze',
        correct: correct,
        answer: answer,
        details: details,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.language.text(
            'Nie udało się zapisać wyniku ćwiczenia.',
            '无法保存练习结果。',
            '無法儲存練習結果。',
          )),
        ),
      );
    }
  }

  Future<void> _loadExerciseData() async {
    try {
      final loaded = PracticeExercise.listFromJson(
        await rootBundle.loadString(_exerciseAsset),
      );
      if (!mounted) return;
      setState(() {
        _loadedExercises = loaded;
        _exerciseLoadError = null;
        _exerciseDataLoaded = true;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _exerciseLoadError = error.toString();
      });
    }
  }

  Future<void> _loadPolishForms() async {
    if (_polishFormsLoading) return;
    setState(() {
      _polishFormsLoading = true;
      _polishFormsLoadError = null;
    });
    try {
      final catalog = PolishFormsCatalog.fromJson(
        await rootBundle.loadString(_polishFormsAsset),
      );
      if (catalog.declensionParadigms.isEmpty ||
          catalog.conjugationParadigms.isEmpty) {
        throw const FormatException(
            'Polish forms asset has no practice forms.');
      }
      if (!mounted) return;
      setState(() {
        _polishForms = catalog;
        _polishFormsLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _polishFormsLoadError = error.toString();
        _polishFormsLoading = false;
      });
    }
  }

  void _retryExerciseData() {
    setState(() => _exerciseLoadError = null);
    unawaited(_loadExerciseData());
  }

  void _retryPolishForms() {
    setState(() => _polishFormsLoadError = null);
    unawaited(_loadPolishForms());
  }
}

class _EmptyPracticeState extends StatelessWidget {
  const _EmptyPracticeState({
    required this.language,
    required this.onSwitchToVocabulary,
  });

  final AppLanguage language;
  final VoidCallback onSwitchToVocabulary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('practice-empty-state'),
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.text(
                'Tego poziomu jeszcze nie ma w ćwiczeniach.',
                '这个等级暂时还没有填空练习。',
                '這個級別暫時還沒有填空練習。',
              ),
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              language.text(
                'Wybierz inny poziom powyżej albo wróć do nauki słownictwa.',
                '请在上方选择其他等级，或切换回词汇练习。',
                '請在上方選擇其他級別，或切換回詞彙練習。',
              ),
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSwitchToVocabulary,
              icon: const Icon(Icons.style_outlined),
              label: Text(language.text(
                'Wróć do słownictwa',
                '返回词汇练习',
                '返回詞彙練習',
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuestionLabel extends StatelessWidget {
  const _QuestionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      );
}

class _PracticeEyebrow extends StatelessWidget {
  const _PracticeEyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      );
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.language,
    required this.target,
    required this.selectedLevel,
    required this.levels,
    required this.onSelected,
  });

  final AppLanguage language;
  final LearningTarget target;
  final String selectedLevel;
  final List<String> levels;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = target == LearningTarget.chinese
        ? levels
        : const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionLabel(
          text: language.text(
            target == LearningTarget.chinese ? 'POZIOM HSK' : 'KURS POLSKIEGO',
            target == LearningTarget.chinese ? 'HSK 等级' : '波兰语课程',
            target == LearningTarget.chinese ? 'HSK 等級' : '波蘭語課程',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in items)
              ChoiceChip(
                label: Text(
                  target == LearningTarget.polish
                      ? language.text(
                          'Polski $level',
                          '波兰语 $level',
                          '波蘭語 $level',
                        )
                      : _practiceLevelLabel(level),
                ),
                selected: selectedLevel == level,
                onSelected: (_) => onSelected(level),
                backgroundColor: colors.surface,
                selectedColor: colors.primaryContainer,
                labelStyle: TextStyle(
                  color: selectedLevel == level
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                  fontSize: 14,
                  height: 1.45,
                ),
                checkmarkColor: colors.onPrimaryContainer,
                side: BorderSide(
                  color: selectedLevel == level
                      ? colors.primary
                      : colors.outlineVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String _practiceLevelLabel(String level) =>
    level == 'HSK-7-9' ? 'HSK 7–9' : level.replaceFirst('HSK-', 'HSK ');

class _PracticeStats extends StatelessWidget {
  const _PracticeStats({
    required this.language,
    required this.answered,
    required this.correct,
  });

  final AppLanguage language;
  final int answered;
  final int correct;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.bolt_rounded,
              color: Theme.of(context).colorScheme.primary, size: 18),
          const SizedBox(width: 6),
          Flexible(
              child: Text(
            language.text(
              'W tej sesji: $correct/$answered poprawnych',
              '本次练习：$correct/$answered 正确',
              '本次練習：$correct/$answered 正確',
            ),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.45),
          )),
        ],
      );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.language,
    required this.isCorrect,
    required this.explanation,
    required this.answer,
  });

  final AppLanguage language;
  final bool isCorrect;
  final String explanation;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground =
        isCorrect ? colors.onTertiaryContainer : colors.onErrorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? colors.tertiaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? colors.tertiary : colors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect
                ? language.text('Dobrze!', '答对了！', '答對了！')
                : language.text('Jeszcze nie — poprawna odpowiedź:',
                    '再试一次——正确答案：', '再試一次——正確答案：'),
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 4),
            Text(answer,
                style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 7),
          Text(explanation,
              style: TextStyle(color: foreground, fontSize: 16, height: 1.45)),
        ],
      ),
    );
  }
}

class _ChineseAnswerDetails extends StatelessWidget {
  const _ChineseAnswerDetails({
    required this.word,
    required this.traditional,
  });

  final Word word;
  final bool traditional;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            traditional ? word.traditional : word.displayHanzi,
            style: TextStyle(
                color: colors.onSurface,
                fontSize: 26,
                height: 1.45,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(word.pinyin,
              style: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(word.polishTranslation,
              style: TextStyle(
                  color: colors.onSurface, fontSize: 16, height: 1.45)),
          Text(word.englishTranslation,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 16, height: 1.45)),
        ],
      ),
    );
  }
}
