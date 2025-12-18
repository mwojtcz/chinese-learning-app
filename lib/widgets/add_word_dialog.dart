import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word.dart';

class AddWordDialog extends StatefulWidget {
  const AddWordDialog({super.key});

  @override
  State<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Word> _suggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final provider = context.read<WordProvider>();
    setState(() {
      _suggestions = provider.getSearchSuggestions(query);
    });
  }

  void _addWord(Word word) {
    final provider = context.read<WordProvider>();
    provider.addToMyWords(word);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dodano: ${word.hanzi} (${word.pinyin})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dodaj Słowo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search field
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Wpisz hanzi, pinyin lub tłumaczenie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),

            const SizedBox(height: 16),

            // Suggestions label
            if (_suggestions.isNotEmpty)
              Text(
                'Wybierz słowo:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),

            const SizedBox(height: 8),

            // Suggestions list
            Expanded(
              child: _suggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Zacznij wpisywać aby zobaczyć podpowiedzi'
                                : 'Nie znaleziono słów',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final word = _suggestions[index];
                        final provider = context.watch<WordProvider>();
                        final isAlreadyLearned = provider.isWordLearned(word.hanzi);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: isAlreadyLearned ? null : () => _addWord(word),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
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
                                            const SizedBox(width: 8),
                                            // Hanzi
                                            Text(
                                              word.hanzi,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Pinyin
                                            Text(
                                              word.pinyin,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          word.englishTranslation,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          word.polishTranslation,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status icon
                                  Icon(
                                    isAlreadyLearned
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color: isAlreadyLearned
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
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
}
