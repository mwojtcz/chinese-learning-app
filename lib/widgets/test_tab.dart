import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../providers/word_provider.dart';
import '../models/test_config.dart';

class TestTab extends StatelessWidget {
  const TestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TestProvider>(
      builder: (context, testProvider, child) {
        if (testProvider.isTestActive) {
          return const TestScreen();
        } else {
          return const TestConfigScreen();
        }
      },
    );
  }
}

class TestConfigScreen extends StatefulWidget {
  const TestConfigScreen({super.key});

  @override
  State<TestConfigScreen> createState() => _TestConfigScreenState();
}

class _TestConfigScreenState extends State<TestConfigScreen> {
  final List<String> _selectedLevels = ['HSK-1'];
  final List<String> _selectedTags = [];
  int _questionCount = 10;
  TestMode _mode = TestMode.multipleChoice;
  TestDirection _direction = TestDirection.chineseToPolish;
  bool _includeLearnedWords = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📝 Konfiguracja Testu',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Wybór poziomów HSK
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poziomy HSK',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        children: ['HSK-1', 'HSK-2', 'HSK-3'].map((level) {
                          return FilterChip(
                            label: Text(level),
                            selected: _selectedLevels.contains(level),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedLevels.add(level);
                                } else {
                                  if (_selectedLevels.length > 1) {
                                    _selectedLevels.remove(level);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tryb testu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tryb testu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<TestMode>(
                        title: const Text('Wybór wielokrotny'),
                        subtitle: const Text('Wybierz poprawną odpowiedź z 4 opcji'),
                        value: TestMode.multipleChoice,
                        groupValue: _mode,
                        onChanged: (value) {
                          setState(() {
                            _mode = value!;
                          });
                        },
                      ),
                      RadioListTile<TestMode>(
                        title: const Text('Wpisywanie'),
                        subtitle: const Text('Wpisz poprawną odpowiedź'),
                        value: TestMode.typing,
                        groupValue: _mode,
                        onChanged: (value) {
                          setState(() {
                            _mode = value!;
                          });
                        },
                      ),
                      RadioListTile<TestMode>(
                        title: const Text('Fiszki'),
                        subtitle: const Text('Oceń czy znasz słówko'),
                        value: TestMode.flashcard,
                        groupValue: _mode,
                        onChanged: (value) {
                          setState(() {
                            _mode = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Kierunek testu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kierunek testu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<TestDirection>(
                        title: const Text('🇨🇳 → 🇵🇱 Chiński → Polski'),
                        subtitle: const Text('Zobacz chiński znak, wybierz polskie tłumaczenie'),
                        value: TestDirection.chineseToPolish,
                        groupValue: _direction,
                        onChanged: (value) {
                          setState(() {
                            _direction = value!;
                          });
                        },
                      ),
                      RadioListTile<TestDirection>(
                        title: const Text('🇵🇱 → 🇨🇳 Polski → Chiński'),
                        subtitle: const Text('Zobacz polskie słowo, wybierz chiński znak'),
                        value: TestDirection.polishToChinese,
                        groupValue: _direction,
                        onChanged: (value) {
                          setState(() {
                            _direction = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Liczba pytań
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liczba pytań: $_questionCount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: _questionCount.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: _questionCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            _questionCount = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Opcje dodatkowe
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Uwzględnij znane słówka'),
                        subtitle: const Text('Dodaj słowa z "Moje Słówka" do testu'),
                        value: _includeLearnedWords,
                        onChanged: (value) {
                          setState(() {
                            _includeLearnedWords = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Przycisk startu
              ElevatedButton.icon(
                onPressed: () async {
                  final testProvider = Provider.of<TestProvider>(context, listen: false);
                  final wordProvider = Provider.of<WordProvider>(context, listen: false);
                  
                  final config = TestConfig(
                    selectedLevels: _selectedLevels,
                    selectedTags: _selectedTags,
                    questionCount: _questionCount,
                    mode: _mode,
                    direction: _direction,
                    includeLearnedWords: _includeLearnedWords,
                  );
                  
                  testProvider.updateConfig(config);
                  
                  // Pokaż loading podczas ładowania pytań
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  // Przekaż cache słów z WordProvider dla szybszego startu
                  await testProvider.startTest(availableWords: wordProvider.allWords);
                  
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Zamknij loading
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Rozpocznij Test'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String? _selectedAnswer;
  final TextEditingController _typingController = TextEditingController();

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TestProvider>(
      builder: (context, testProvider, child) {
        final question = testProvider.currentQuestion;
        
        if (question == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Pytanie ${testProvider.currentQuestionIndex + 1}/${testProvider.totalQuestions}'),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final result = await testProvider.finishTest();
                  if (context.mounted) {
                    _showResultDialog(context, result);
                  }
                },
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('Zakończ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progres
                  LinearProgressIndicator(
                    value: (testProvider.currentQuestionIndex + 1) / testProvider.totalQuestions,
                  ),
                  const SizedBox(height: 24),
                  
                  // Pytanie
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Pokaż pytanie zależnie od kierunku
                          if (testProvider.config.direction == TestDirection.chineseToPolish) ...[
                            Text(
                              question.hanzi,
                              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.pinyin,
                              style: const TextStyle(fontSize: 24, color: Colors.black54),
                            ),
                          ] else ...[
                            const Text(
                              'Jak to powiedzieć po chińsku?',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.polish,
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              question.english,
                              style: const TextStyle(fontSize: 20, color: Colors.black54),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              question.level,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Obszar odpowiedzi
                  Expanded(
                    child: _buildAnswerArea(testProvider, question),
                  ),
                  
                  // Nawigacja
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (testProvider.currentQuestionIndex > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              testProvider.previousQuestion();
                              setState(() {
                                _selectedAnswer = null;
                                _typingController.clear();
                              });
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Poprzednie'),
                          ),
                        ),
                      if (testProvider.currentQuestionIndex > 0)
                        const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (testProvider.isLastQuestion) {
                              _finishTest(context, testProvider);
                            } else {
                              testProvider.nextQuestion();
                              setState(() {
                                _selectedAnswer = null;
                                _typingController.clear();
                              });
                            }
                          },
                          icon: Icon(testProvider.isLastQuestion ? Icons.done : Icons.arrow_forward),
                          label: Text(testProvider.isLastQuestion ? 'Zakończ' : 'Następne'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerArea(TestProvider testProvider, TestQuestion question) {
    switch (testProvider.config.mode) {
      case TestMode.multipleChoice:
        return _buildMultipleChoice(testProvider, question);
      case TestMode.typing:
        return _buildTypingMode(testProvider, question);
      case TestMode.flashcard:
        return _buildFlashcardMode(testProvider, question);
    }
  }

  Widget _buildMultipleChoice(TestProvider testProvider, TestQuestion question) {
    final hasAnswered = question.userAnswer != null;
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = _selectedAnswer == option;
              final isCorrect = option == question.correctAnswer;
              final isUserAnswer = hasAnswered && option == question.options[question.options.indexOf(question.correctAnswer)];
              
              Color? backgroundColor;
              Color? foregroundColor;
              
              if (hasAnswered) {
                // Po odpowiedzi pokaż zielony dla poprawnej, czerwony dla błędnej
                if (isCorrect) {
                  backgroundColor = Colors.green;
                  foregroundColor = Colors.white;
                } else if (isSelected) {
                  backgroundColor = Colors.red;
                  foregroundColor = Colors.white;
                }
              } else if (isSelected) {
                // Przed odpowiedzią tylko zaznacz wybraną opcję
                backgroundColor = Theme.of(context).colorScheme.primaryContainer;
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: !hasAnswered
                      ? () {
                          setState(() {
                            _selectedAnswer = option;
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20.0),
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!hasAnswered && _selectedAnswer != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedAnswer != null) {
                  testProvider.answerQuestion(_selectedAnswer!);
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Potwierdź odpowiedź'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypingMode(TestProvider testProvider, TestQuestion question) {
    final isReverse = testProvider.config.direction == TestDirection.polishToChinese;
    
    return Column(
      children: [
        Text(
          isReverse 
            ? 'Wpisz chiński znak (hanzi):'
            : 'Wpisz polskie tłumaczenie:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _typingController,
          enabled: question.userAnswer == null,
          decoration: InputDecoration(
            labelText: 'Twoja odpowiedź',
            hintText: isReverse ? 'np. 你好' : 'np. cześć',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              testProvider.answerQuestion(value);
            }
          },
        ),
        const SizedBox(height: 16),
        if (question.userAnswer == null)
          ElevatedButton(
            onPressed: () {
              if (_typingController.text.isNotEmpty) {
                testProvider.answerQuestion(_typingController.text);
              }
            },
            child: const Text('Sprawdź'),
          ),
        if (question.userAnswer != null) ...[
          const SizedBox(height: 16),
          Card(
            color: question.userAnswer! ? Colors.green[100] : Colors.red[100],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        question.userAnswer! ? Icons.check_circle : Icons.cancel,
                        color: question.userAnswer! ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        question.userAnswer! ? 'Poprawnie!' : 'Niepoprawnie',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (!question.userAnswer!)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Poprawna odpowiedź: ${question.correctAnswer}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlashcardMode(TestProvider testProvider, TestQuestion question) {
    if (question.userAnswer != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Tłumaczenie:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                question.polish,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                question.english,
                style: const TextStyle(fontSize: 20, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: question.userAnswer! ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.userAnswer! ? '✓ Znałem/am' : '? Nie znałem/am',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Czy znasz znaczenie tego słowa?',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  testProvider.answerFlashcard(false);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(24.0),
                  backgroundColor: Colors.orange,
                ),
                icon: const Icon(Icons.close, size: 32),
                label: const Text('Nie znam', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  testProvider.answerFlashcard(true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(24.0),
                  backgroundColor: Colors.green,
                ),
                icon: const Icon(Icons.check, size: 32),
                label: const Text('Znam!', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _finishTest(BuildContext context, TestProvider testProvider) async {
    final result = await testProvider.finishTest();
    
    // Odśwież listę "Moje Słowa" w WordProvider
    if (context.mounted) {
      final wordProvider = Provider.of<WordProvider>(context, listen: false);
      await wordProvider.loadData();
      _showResultDialog(context, result);
    }
  }

  void _showResultDialog(BuildContext context, TestResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.passed ? Icons.celebration : Icons.info_outline,
              color: result.passed ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(result.passed ? 'Gratulacje!' : 'Test zakończony'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wynik: ${result.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResultRow(Icons.check_circle, 'Poprawne', result.correctAnswers, Colors.green),
            _buildResultRow(Icons.cancel, 'Błędne', result.incorrectAnswers, Colors.red),
            _buildResultRow(Icons.quiz, 'Łącznie', result.totalQuestions, Colors.blue),
            const SizedBox(height: 8),
            _buildResultRow(Icons.timer, 'Czas', '${result.duration.inMinutes}:${(result.duration.inSeconds % 60).toString().padLeft(2, '0')}', Colors.grey),
            const SizedBox(height: 16),
            if (result.passed)
              const Text(
                '✨ Poprawne odpowiedzi dodano do "Moje Słówka"!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<TestProvider>(context, listen: false).resetTest();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
