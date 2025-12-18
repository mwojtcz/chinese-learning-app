import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word.dart';
import 'add_word_dialog.dart';

class MyWordsTab extends StatelessWidget {
  const MyWordsTab({super.key});

  void _showAddWordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddWordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
      children: [
        // Progress bar section
        Consumer<WordProvider>(
          builder: (context, provider, child) {
            final stats = provider.progressStats;
            final percentage = stats['percentage'] as double;
            final learned = stats['learned'] as int;
            final total = stats['total'] as int;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.selectedLevel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$learned / $total',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: total > 0 ? learned / total : 0,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}% poznanych słów',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Level filter chips
        Consumer<WordProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: provider.availableLevels.map((level) {
                  final isSelected = provider.selectedLevel == level;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        level,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.setSelectedLevel(level);
                      },
                      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                      selectedColor: isDark 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                          : Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: isDark ? Colors.white : null,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // My words list
        Expanded(
          child: Consumer<WordProvider>(
            builder: (context, provider, child) {
              final words = provider.filteredMyWords;

              if (words.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Brak poznanych słów',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dodaj słowa ze Słownika',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];

                  return _MyWordCard(
                    word: word,
                    onRemove: () {
                      provider.removeFromMyWords(word.hanzi);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
        // Floating Action Button for adding words
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddWordDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Słowo'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MyWordCard extends StatelessWidget {
  final Word word;
  final VoidCallback onRemove;

  const _MyWordCard({
    required this.word,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: Key(word.hanzi),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (_) => onRemove(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(word.level),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            word.level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Hanzi
                        Text(
                          word.hanzi,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Pinyin
                    Text(
                      word.pinyin,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // English translation
                    Text(
                      word.englishTranslation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    // Polish translation
                    Text(
                      word.polishTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (word.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Usuń z Moich Słów',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    final colors = {
      'HSK-1': Colors.green,
      'HSK-2': Colors.lightGreen,
      'HSK-3': Colors.lime,
      'HSK-4': Colors.orange,
      'HSK-5': Colors.deepOrange,
      'HSK-6': Colors.red,
      'HSK-7': Colors.purple,
      'HSK-8': Colors.deepPurple,
      'HSK-9': Colors.indigo,
    };
    return colors[level] ?? Colors.blue;
  }
}
