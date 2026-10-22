import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/learning_target.dart';
import 'package:chinese_flow/models/practice_exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the graded localized exercises from the bundled asset', () async {
    final source =
        await rootBundle.loadString('assets/data/practice_exercises.json');
    final exercises = PracticeExercise.listFromJson(source);

    expect(exercises, hasLength(169));
    expect(
      exercises.where((exercise) => exercise.target == LearningTarget.polish),
      hasLength(120),
    );
    expect(
      exercises.where((exercise) => exercise.target == LearningTarget.chinese),
      hasLength(49),
    );
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(
        exercises.where(
          (exercise) =>
              exercise.target == LearningTarget.polish &&
              exercise.courseLevel == level,
        ),
        isNotEmpty,
      );
    }
    expect(
      exercises.every(
        (exercise) =>
            exercise.prompt.polish.trim().isNotEmpty &&
            exercise.prompt.simplifiedChinese.trim().isNotEmpty &&
            exercise.prompt.traditionalChinese.trim().isNotEmpty &&
            exercise.explanation.polish.trim().isNotEmpty &&
            exercise.explanation.simplifiedChinese.trim().isNotEmpty &&
            exercise.explanation.traditionalChinese.trim().isNotEmpty &&
            exercise.acceptedAnswers.isNotEmpty,
      ),
      isTrue,
    );
    for (final exercise in exercises) {
      expect(
        practiceAnswerMatches(exercise.answer, exercise.acceptedAnswers),
        isTrue,
        reason: 'Canonical answer must be accepted for ${exercise.id}.',
      );
      expect(
          exercise.acceptedAnswers.every((answer) => answer.trim().isNotEmpty),
          isTrue);
    }
  });

  test('professional Polish expansion preserves constrained answer contrasts',
      () async {
    final exercises = PracticeExercise.listFromJson(
      await rootBundle.loadString('assets/data/practice_exercises.json'),
    );
    final byId = {for (final exercise in exercises) exercise.id: exercise};
    const contrasts = {
      'pl-a1-formal-third-person': ['mówi', 'mówisz'],
      'pl-a1-repeat-infinitive': ['powtórzyć', 'powtórzysz'],
      'pl-a1-location-question-word': ['gdzie', 'czy'],
      'pl-a2-calendar-date': ['drugiego maja', 'drugi maj'],
      'pl-a2-appointment-hour': ['ósmej', 'ósma'],
      'pl-a2-transport-habit': ['jeżdżę', 'jadę'],
      'pl-a2-transport-current-journey': ['jadę', 'jecham'],
      'pl-a2-transport-perfective-departure': ['pojadę', 'będę pojechać'],
      'pl-a2-reflexive-after-preposition': ['sobie', 'się'],
      'pl-a2-recipient-short-long-pronoun': ['mu', 'niemu'],
      'pl-b1-document-needed-genitive': ['ważnego dokumentu', 'ważny dokument'],
      'pl-b1-depend-on-response': ['szybkiej odpowiedzi', 'szybką odpowiedź'],
      'pl-b1-refund-money': ['pieniędzy', 'pieniądze'],
      'pl-b1-no-obligation-not-prohibition': ['brak obowiązku', 'zakaz'],
      'pl-b1-own-subject-passport': ['swój', 'swoją'],
      'pl-b1-relative-recipient': ['której', 'która'],
      'pl-b1-relative-prepositional-topic': ['którym', 'który'],
      'pl-b1-reported-yes-no-question': ['czy', 'że'],
      'pl-b1-unsent-document-negation': ['tego dokumentu', 'ten dokument'],
      'pl-b1-prohibition-imperfective-send': ['wysyłaj', 'wyślij'],
      'pl-b2-passive-completed-report': ['zatwierdzony', 'zatwierdzona'],
      'pl-b2-passive-review-process': ['sprawdzany', 'sprawdzony'],
      'pl-b2-impersonal-sent': ['wysłano', 'wysłane'],
      'pl-b2-participle-shared-agent': ['zauważyłam', 'pojawił się'],
      'pl-b2-anterior-participle': ['sprawdziwszy', 'sprawdzając'],
      'pl-b2-two-doctors-nominative-agreement': ['przyszli', 'przyszło'],
      'pl-b2-two-doctors-oblique-agreement': ['przyszło', 'przyszli'],
      'pl-b2-five-people-agreement': ['zostało', 'zostały'],
      'pl-b2-collective-instrumental': ['dwojgiem dzieci', 'dwojgiem dziećmi'],
      'pl-b2-collective-plural-only-doors': ['dwoje', 'dwa'],
      'pl-c1-concession-nominal': ['niewielkiej próby', 'niewielka próba'],
      'pl-c1-concession-clause': ['że', 'czy'],
      'pl-c1-thanks-to-dative': [
        'doświadczonemu zespołowi',
        'doświadczonego zespołu'
      ],
      'pl-c1-corrective-not-so-much': ['ile', 'i'],
      'pl-c2-partial-negation-scope': [
        'brak jednomyślności',
        'brak jakiegokolwiek poparcia'
      ],
      'pl-c2-modal-negation-scope': [
        'niekoniecznie oznacza odmowę',
        'na pewno nie oznacza odmowy'
      ],
    };
    expect(contrasts, hasLength(36));
    for (final contrast in contrasts.entries) {
      final exercise = byId[contrast.key]!;
      expect(exercise.target, LearningTarget.polish);
      expect(
          practiceAnswerMatches(contrast.value.first, exercise.acceptedAnswers),
          isTrue,
          reason: contrast.key);
      expect(
          practiceAnswerMatches(contrast.value.last, exercise.acceptedAnswers),
          isFalse,
          reason: contrast.key);
    }
    final recipient = byId['pl-a2-recipient-short-long-pronoun']!;
    for (final answer in ['mu', 'jemu', '  JEMU! ']) {
      expect(practiceAnswerMatches(answer, recipient.acceptedAnswers), isTrue);
    }
    expect(
      [
        for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
          exercises
              .where((exercise) =>
                  exercise.target == LearningTarget.polish &&
                  exercise.courseLevel == level)
              .length,
      ],
      [26, 32, 45, 11, 4, 2],
    );
  });

  test(
      'expanded practice accepts variants without erasing grammatical contrasts',
      () async {
    final exercises = PracticeExercise.listFromJson(
      await rootBundle.loadString('assets/data/practice_exercises.json'),
    );
    final byId = {for (final exercise in exercises) exercise.id: exercise};
    const contrasts = {
      'pl-b1-aspect-duration-result': ['w', 'za'],
      'pl-b1-aspect-duration-process': ['przez', 'za'],
      'pl-b1-aspect-negated-result': ['napisałam', 'pisałam'],
      'pl-b1-condition-open-future': ['wrócę', 'wracam'],
      'pl-b2-condition-unreal-past': ['wyszła', 'wyszłabym'],
      'pl-b1-purpose-different-subject': ['trafiła', 'trafić'],
      'pl-a2-motion-within-place': ['parku', 'park'],
      'pl-a2-source-post-office': ['poczty', 'pocztą'],
      'pl-a2-accompaniment-source-contrast': ['koleżanką', 'koleżanki'],
      'pl-b1-half-feminine-measure': ['półtorej', 'półtora'],
      'pl-b1-numeral-dative-phrase': [
        'pięciu starym zdjęciom',
        'pięć starych zdjęć',
      ],
      'pl-b1-comparison-reference-genitive': ['brata', 'brat'],
      'pl-b1-comparison-difference-preposition': ['o', 'od'],
      'zh-hsk3-cause-result-connector': ['所以', '因为'],
      'zh-hsk3-concession-connector': ['雖然', '所以'],
      'zh-hsk3-condition-jiu': ['就', '如果'],
      'zh-hsk2-time-before': ['以前', '以后'],
      'zh-hsk2-time-after': ['以後', '以前'],
      'zh-hsk2-sequence-zai': ['再', '又'],
      'zh-hsk3-future-completion-le': ['了', '着'],
      'zh-hsk3-negation-partial-scope': ['不都', '都不'],
      'zh-hsk3-negation-total-scope': ['都不', '不都'],
    };
    for (final contrast in contrasts.entries) {
      final exercise = byId[contrast.key]!;
      expect(
          practiceAnswerMatches(contrast.value.first, exercise.acceptedAnswers),
          isTrue,
          reason: contrast.key);
      expect(
          practiceAnswerMatches(contrast.value.last, exercise.acceptedAnswers),
          isFalse,
          reason: contrast.key);
    }
    final numeral = byId['pl-b1-numeral-instrumental-variants']!;
    for (final answer in ['dwiema', 'dwoma']) {
      expect(practiceAnswerMatches(answer, numeral.acceptedAnswers), isTrue);
    }
    final sequence = byId['zh-hsk2-sequence-full-sentence']!;
    for (final answer in [
      '先看问题，再写答案。',
      '先看問題，再寫答案！',
      '先看问题, 再写答案',
      '先看問題， 再寫答案。',
    ]) {
      expect(practiceAnswerMatches(answer, sequence.acceptedAnswers), isTrue);
    }
    expect(
        practiceAnswerMatches('先写答案，再看问题。', sequence.acceptedAnswers), isFalse);
    final chinese = exercises
        .where((exercise) => exercise.target == LearningTarget.chinese);
    expect(
      [
        for (final level in [
          'HSK-1',
          'HSK-2',
          'HSK-3',
          'HSK-4',
          'HSK-5',
          'HSK-6',
        ])
          chinese.where((exercise) => exercise.courseLevel == level).length
      ],
      [9, 8, 8, 8, 8, 8],
    );
  });

  test('Chinese practice spans HSK 1–6 and accepts traditional script forms',
      () async {
    final exercises = PracticeExercise.listFromJson(
      await rootBundle.loadString('assets/data/practice_exercises.json'),
    );
    final byId = {for (final exercise in exercises) exercise.id: exercise};
    const traditionalVariants = {
      'zh-hsk1-yes-no-particle': '嗎',
      'zh-hsk2-experience-guo': '過',
      'zh-hsk2-choice-question-haishi': '還是',
      'zh-hsk3-continuing-state-zhe': '著',
      'zh-hsk4-except-also-hai': '還',
      'zh-hsk4-topic-duiyu': '對於',
      'zh-hsk5-otherwise-fouze': '否則',
      'zh-hsk5-reported-source-jushuo': '據說',
      'zh-hsk6-in-view-of-jianyu': '鑒於',
      'zh-hsk6-summary-zongeryanzhi': '總而言之',
    };
    for (final variant in traditionalVariants.entries) {
      expect(
        byId[variant.key]!.acceptedAnswers,
        contains(variant.value),
        reason: variant.key,
      );
    }
    expect(
      exercises
          .where((exercise) => exercise.target == LearningTarget.chinese)
          .where((exercise) => exercise.courseLevel == 'HSK-6'),
      hasLength(8),
    );
  });

  test('normalizes case, whitespace, and trailing punctuation only', () {
    expect(practiceAnswerMatches('  KSIĄŻKĘ! ', ['książkę']), isTrue);
    expect(practiceAnswerMatches('  我  是。 ', ['我是']), isFalse);
    expect(practiceAnswerMatches('książka', ['książkę']), isFalse);
  });

  test('flashcards prompt in the language being learned', () {
    expect(
      LearningTarget.polish.showsPolishOnFlashcardFront,
      isFalse,
      reason: 'Polish learners should see Chinese and recall Polish.',
    );
    expect(
      LearningTarget.chinese.showsPolishOnFlashcardFront,
      isTrue,
      reason: 'Chinese learners should see Polish and recall Chinese.',
    );
  });

  test('rejects duplicate exercise IDs', () {
    const source = '''
    {
      "exercises": [
        {
          "id": "same",
          "target": "polish",
          "courseLevel": "A1",
          "prompt": {"pl": "A", "zhHans": "A", "zhHant": "A"},
          "answer": "a",
          "acceptedAnswers": [],
          "explanation": {"pl": "A", "zhHans": "A", "zhHant": "A"}
        },
        {
          "id": "same",
          "target": "polish",
          "courseLevel": "A1",
          "prompt": {"pl": "B", "zhHans": "B", "zhHant": "B"},
          "answer": "b",
          "acceptedAnswers": [],
          "explanation": {"pl": "B", "zhHans": "B", "zhHant": "B"}
        }
      ]
    }
    ''';

    expect(
      () => PracticeExercise.listFromJson(source),
      throwsFormatException,
    );
  });
}
