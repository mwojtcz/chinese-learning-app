import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word.dart';

class DictionaryTab extends StatefulWidget {
  const DictionaryTab({super.key});

  @override
  State<DictionaryTab> createState() => _DictionaryTabState();
}

class _DictionaryTabState extends State<DictionaryTab> {
  Timer? _debounce;
  
  void _onSearchChanged(String query, WordProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      provider.setSearchQuery(query);
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<WordProvider>(
            builder: (context, provider, child) {
              return TextField(
                onChanged: (value) => _onSearchChanged(value, provider),
                decoration: InputDecoration(
                  hintText: 'Szukaj (hanzi, pinyin, tłumaczenie)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => provider.setSearchQuery(''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF2C3E50)
                      : Colors.grey[100],
                ),
              );
            },
          ),
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
                  final count = provider.getLevelWordCount(level);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('$level ($count)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.setSelectedLevel(level);
                      },
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF2C3E50)
                          : Colors.grey[200],
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),

        const SizedBox(height: 4),

        // Filters row with dropdowns
        Consumer<WordProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Tag filter dropdown
                  Expanded(
                    child: PopupMenuButton<String>(
                      onSelected: (tag) => provider.setSelectedTag(tag),
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                        maxWidth: 200,
                      ),
                      position: PopupMenuPosition.under,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Color(0xFF34495E)
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Color(0xFF4A5F7F)
                                : Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                provider.selectedTag == 'Wszystkie' 
                                    ? 'Kategoria: Wszystkie' 
                                    : 'Kategoria: ${provider.selectedTag}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => provider.availableTags.map((tag) {
                        return PopupMenuItem<String>(
                          value: tag,
                          child: Text(tag, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Part of speech filter dropdown
                  Expanded(
                    child: PopupMenuButton<String>(
                      onSelected: (pos) => provider.setSelectedPartOfSpeech(pos),
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                        maxWidth: 200,
                      ),
                      position: PopupMenuPosition.under,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Color(0xFF2C4A3E)
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Color(0xFF3D5E4F)
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                provider.selectedPartOfSpeech == 'Wszystkie'
                                    ? 'Część mowy: Wszystkie'
                                    : provider.selectedPartOfSpeech,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => provider.availablePartsOfSpeech.map((pos) {
                        return PopupMenuItem<String>(
                          value: pos,
                          child: Text(pos, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Words list
        Expanded(
          child: Consumer<WordProvider>(
            builder: (context, provider, child) {
              final words = provider.filteredWords;

              if (words.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nie znaleziono słów',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Responsywna liczba kolumn
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 2;
                  }
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final word = words[index];
                      final isLearned = provider.isWordLearned(word.hanzi);

                      return _WordCard(
                        word: word,
                        isLearned: isLearned,
                        onToggleLearned: () {
                          if (isLearned) {
                            provider.removeFromMyWords(word.hanzi);
                          } else {
                            provider.addToMyWords(word);
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final Word word;
  final bool isLearned;
  final VoidCallback onToggleLearned;

  const _WordCard({
    required this.word,
    required this.isLearned,
    required this.onToggleLearned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Lewa strona - DUŻY HANZI
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Color(0xFF2C3E50),
                          Color(0xFF34495E),
                        ]
                      : [
                          _getLevelColor(word.level).withOpacity(0.9),
                          _getLevelColor(word.level).withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  word.hanzi,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: word.hanzi.length == 1 ? 52 : (word.hanzi.length == 2 ? 36 : 28),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: word.hanzi.length > 1 ? 2 : 0,
                    shadows: const [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Prawa strona - SZCZEGÓŁY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pinyin + Level badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word.pinyin,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(word.level),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            word.level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Tłumaczenia
                    if (word.polishTranslation.isNotEmpty)
                      Text(
                        word.polishTranslation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (word.englishTranslation.isNotEmpty)
                      Text(
                        word.englishTranslation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Tagi + Part of Speech
                    if (word.tags.isNotEmpty || word.partOfSpeech != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (word.partOfSpeech != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                word.partOfSpeech!,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          if (word.partOfSpeech != null && word.tags.isNotEmpty)
                            const SizedBox(width: 4),
                          ...word.tags.take(2).map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getTagColor(tag),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Przycisk ulubione
            IconButton(
              icon: Icon(
                isLearned ? Icons.favorite : Icons.favorite_border,
                color: isLearned ? Colors.red : Colors.grey,
                size: 20,
              ),
              onPressed: onToggleLearned,
              tooltip: isLearned ? 'Usuń z Moich Słów' : 'Dodaj do Moich Słów',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
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

  Color _getTagColor(String tag) {
    final colors = {
      'number': Colors.blue,
      'classifier': Colors.teal,
      'pronoun': Colors.purple,
      'verb': Colors.green,
      'noun': Colors.orange,
      'adjective': Colors.pink,
      'adverb': Colors.indigo,
      'particle': Colors.brown,
      'conjunction': Colors.cyan,
      'expression': Colors.deepOrange,
      'essential': Colors.red,
      'question': Colors.amber,
      'time': Colors.blueGrey,
      'food': Colors.deepOrange[300],
      'family': Colors.pink[300],
      'location': Colors.lightGreen,
      'daily': Colors.lightBlue,
      'study': Colors.deepPurple[300],
      'emotion': Colors.pinkAccent,
      'weather': Colors.lightBlue[300],
    };
    return colors[tag] ?? Colors.grey;
  }
}
