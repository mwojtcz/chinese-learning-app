import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../widgets/dictionary_tab.dart';
import '../widgets/my_words_tab.dart';
import '../widgets/test_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nauka Chińskiego',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'Słownik',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Moje Słowa',
            ),
            Tab(
              icon: Icon(Icons.quiz),
              text: 'Test',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DictionaryTab(),
          MyWordsTab(),
          TestTab(),
        ],
      ),
    );
  }
}
