import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_language.dart';
import '../models/learning_target.dart';
import '../models/practice_exercise.dart';
import '../models/word.dart';
import '../providers/word_provider.dart';

const _practiceInk = Color(0xFF242521);
const _practiceMuted = Color(0xFF77776F);
const _practicePaper = Color(0xFFFFFCF6);
const _practiceAccent = Color(0xFFB44535);
const _practiceLine = Color(0xFFE9E1D5);

enum _PracticeMode { vocabulary, fillBlank }

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
  final _random = Random();
  final _answerController = TextEditingController();

  _PracticeMode _mode = _PracticeMode.vocabulary;
  String _selectedLevel = 'HSK-1';
  Word? _word;
  PracticeExercise? _exercise;
  List<String> _options = const [];
  String? _selectedOption;
  bool? _isCorrect;
  bool _exerciseDataLoaded = false;
  String? _exerciseLoadError;
  int _answered = 0;
  int _correct = 0;

  @override
  void didUpdateWidget(covariant PracticeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target ||
        oldWidget.language != widget.language) {
      _selectedLevel =
          widget.target == LearningTarget.chinese ? 'HSK-1' : 'A1';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    return Consumer<WordProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _practiceAccent),
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
                ? const CircularProgressIndicator(color: _practiceAccent)
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
                        child: Text(language.text('Spróbuj ponownie', '重试', '重試')),
                      ),
                    ],
                  ),
          );
        }
        if (_mode == _PracticeMode.fillBlank && exercises.isEmpty) {
          return Center(
            child: Text(language.text(
              'Brak ćwiczeń dla tego kursu.',
              '这个课程暂无练习。',
              '這個課程暫無練習。',
            )),
          );
        }
        if (_word == null && _exercise == null) {
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
              padding: EdgeInsets.fromLTRB(compact ? 18 : 32, 16, compact ? 18 : 32, 32),
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
                        language.text('Użyj słowa, nie tylko je poznaj.', '把词语用出来。', '把詞語用出來。'),
                        style: TextStyle(
                          color: _practiceInk,
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
                        style: const TextStyle(color: _practiceMuted, fontSize: 15),
                      ),
                      const SizedBox(height: 18),
                      _LevelSelector(
                        language: language,
                        target: widget.target,
                        selectedLevel: _selectedLevel,
                        levels: widget.target == LearningTarget.chinese
                            ? provider.availableLevels.where((l) => l != 'Wszystkie').toList()
                            : const ['A1'],
                        onSelected: (level) {
                          setState(() {
                            _selectedLevel = level;
                            _clearQuestion();
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<_PracticeMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: _PracticeMode.vocabulary,
                            icon: const Icon(Icons.style_outlined),
                            label: Text(language.text('Słownictwo', '词汇', '詞彙')),
                          ),
                          ButtonSegment(
                            value: _PracticeMode.fillBlank,
                            icon: const Icon(Icons.edit_note_rounded),
                            label: Text(language.text('Uzupełnij lukę', '填空', '填空')),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _mode = selection.first;
                            _clearQuestion();
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _PracticeStats(
                        language: language,
                        answered: _answered,
                        correct: _correct,
                      ),
                      const SizedBox(height: 12),
                      if (_mode == _PracticeMode.vocabulary)
                        _buildVocabularyQuestion(compact)
                      else if (_exercise != null)
                        _buildFillBlankQuestion(compact),
                      if (_isCorrect != null) ...[
                        const SizedBox(height: 12),
                        _FeedbackCard(
                          language: language,
                          isCorrect: _isCorrect!,
                          explanation: _mode == _PracticeMode.fillBlank
                              ? _exercise!.explanation.forLanguage(language)
                              : _wordAnswerDescription(language),
                          answer: _mode == _PracticeMode.fillBlank
                              ? _exercise!.answer
                              : _wordAnswer(_word!, language),
                        ),
                        const SizedBox(height: 12),
                        if (_mode == _PracticeMode.vocabulary &&
                            widget.target == LearningTarget.chinese)
                          _ChineseAnswerDetails(
                            word: _word!,
                            traditional: language.isTraditional,
                          ),
                      ],
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
                            backgroundColor: _practiceAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
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

  void _nextQuestion(WordProvider provider, List<PracticeExercise> exercises) {
    final previousExerciseId = _exercise?.id;
    _answerController.clear();
    _selectedOption = null;
    _isCorrect = null;
    _word = null;
    _exercise = null;

    if (_mode == _PracticeMode.fillBlank) {
      if (exercises.isEmpty) return;
      final candidates = exercises
          .where((item) => item.id != previousExerciseId)
          .toList();
      _exercise = candidates[_random.nextInt(candidates.length)];
    } else {
      final candidates = widget.target == LearningTarget.chinese
          ? provider.allWords.where((word) => word.level == _selectedLevel).toList()
          : provider.allWords;
      if (candidates.isEmpty) return;
      _word = candidates[_random.nextInt(candidates.length)];
      _options = _makeOptions(_word!, candidates);
    }
  }

  void _clearQuestion() {
    _word = null;
    _exercise = null;
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

  Widget _buildVocabularyQuestion(bool compact) {
    final word = _word;
    if (word == null) {
      return const _QuestionCard(child: Center(child: CircularProgressIndicator()));
    }
    return _QuestionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionLabel(text: widget.language.text('WYBIERZ ODPOWIEDŹ', '选择答案', '選擇答案')),
          const SizedBox(height: 10),
          Text(
            _wordPrompt(word, widget.language),
            style: TextStyle(
              color: _practiceInk,
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
                  foregroundColor: _practiceInk,
                  backgroundColor: _selectedOption == option
                      ? const Color(0xFFF5E6DF)
                      : _practicePaper,
                  side: BorderSide(
                    color: _selectedOption == option
                        ? _practiceAccent
                        : _practiceLine,
                  ),
                  padding: const EdgeInsets.all(15),
                ),
                child: Text(option, style: const TextStyle(fontSize: 18)),
              ),
            ),
          if (_isCorrect == null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _selectedOption == null ? null : _checkChoice,
                style: FilledButton.styleFrom(backgroundColor: _practiceAccent),
                child: Text(widget.language.text('Sprawdź', '检查', '檢查')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFillBlankQuestion(bool compact) {
    final exercise = _exercise!;
    return _QuestionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionLabel(text: widget.language.text('UZUPEŁNIJ ZDANIE', '完成句子', '完成句子')),
          const SizedBox(height: 12),
          Text(
            exercise.prompt.forLanguage(widget.language),
            style: TextStyle(
              color: _practiceInk,
              fontSize: compact ? 21 : 26,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            enabled: _isCorrect == null,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _checkTypedAnswer(exercise),
            decoration: InputDecoration(
              labelText: widget.language.text('Twoja odpowiedź', '你的答案', '你的答案'),
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
                style: FilledButton.styleFrom(backgroundColor: _practiceAccent),
                child: Text(widget.language.text('Sprawdź', '检查', '檢查')),
              ),
            ),
        ],
      ),
    );
  }

  void _checkChoice() {
    final word = _word!;
    final aliases = widget.target == LearningTarget.chinese
        ? [word.displayHanzi, word.traditional]
        : word.polishTranslation.split(RegExp(r'[;,]'));
    _recordAnswer(practiceAnswerMatches(_selectedOption!, aliases));
  }

  void _checkTypedAnswer(PracticeExercise exercise) {
    _recordAnswer(practiceAnswerMatches(
      _answerController.text,
      [exercise.answer, ...exercise.acceptedAnswers],
    ));
  }

  void _recordAnswer(bool correct) {
    setState(() {
      _isCorrect = correct;
      _answered++;
      if (correct) _correct++;
    });
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

  void _retryExerciseData() {
    setState(() => _exerciseLoadError = null);
    unawaited(_loadExerciseData());
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _practicePaper,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _practiceLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100F1612),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );
}

class _QuestionLabel extends StatelessWidget {
  const _QuestionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _practiceAccent,
          fontSize: 11,
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
        style: const TextStyle(
          color: _practiceAccent,
          fontSize: 11,
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
    final items = target == LearningTarget.chinese
        ? levels
        : const ['A1'];
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
                  level == 'A1'
                      ? language.text('Polski A1 · podstawy', '波兰语 A1 · 基础', '波蘭語 A1 · 基礎')
                      : _practiceLevelLabel(level),
                ),
                selected: selectedLevel == level,
                onSelected: (_) => onSelected(level),
                selectedColor: const Color(0xFFF5E6DF),
                side: BorderSide(
                  color: selectedLevel == level ? _practiceAccent : _practiceLine,
                ),
              ),
          ],
        ),
        if (target == LearningTarget.polish)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              language.text(
                'Poziom A1 obejmuje na razie ćwiczenia pilotażowe; słownictwo jest wspólne z katalogiem chińsko-polskim.',
                'A1 目前包含试点练习；词汇与中波词库共享。',
                'A1 目前包含試點練習；詞彙與中波詞庫共用。',
              ),
              style: const TextStyle(color: _practiceMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

String _practiceLevelLabel(String level) =>
    level == 'HSK-7-9'
        ? 'HSK 7–9'
        : level.replaceFirst('HSK-', 'HSK ');

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
          Icon(Icons.bolt_rounded, color: _practiceAccent, size: 18),
          const SizedBox(width: 6),
          Text(
            language.text(
              'W tej sesji: $correct/$answered poprawnych',
              '本次练习：$correct/$answered 正确',
              '本次練習：$correct/$answered 正確',
            ),
            style: const TextStyle(color: _practiceMuted, fontSize: 13),
          ),
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
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCorrect ? const Color(0xFFE5F1E8) : const Color(0xFFFFEDE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCorrect ? const Color(0xFFB7D7C0) : const Color(0xFFEFC7B9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect
                  ? language.text('Dobrze!', '答对了！', '答對了！')
                  : language.text('Jeszcze nie — poprawna odpowiedź:', '再试一次——正确答案：', '再試一次——正確答案：'),
              style: TextStyle(
                color: isCorrect ? const Color(0xFF315C57) : _practiceAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 4),
              Text(answer, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 7),
            Text(explanation, style: const TextStyle(height: 1.4)),
          ],
        ),
      );
}

class _ChineseAnswerDetails extends StatelessWidget {
  const _ChineseAnswerDetails({
    required this.word,
    required this.traditional,
  });

  final Word word;
  final bool traditional;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF1ECE4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              traditional ? word.traditional : word.displayHanzi,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(word.pinyin, style: const TextStyle(color: _practiceAccent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(word.polishTranslation),
            Text(word.englishTranslation, style: const TextStyle(color: _practiceMuted)),
          ],
        ),
      );
}
