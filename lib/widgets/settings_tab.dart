import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      emojiEnabledNotifier.value = prefs.getBool('emojis_enabled') ?? true;
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _toggleEmojis(bool value) async {
    emojiEnabledNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emojis_enabled', value);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _launchGitHubIssues() async {
    final Uri url = Uri.parse('https://github.com/mwojtcz/chinese-learning-app/issues');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Failed to open GitHub Issues page in browser: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // App Info Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O Aplikacji',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('ChineseFlow v1.0.1'),
                const SizedBox(height: 4),
                const Text('Master Chinese with flow'),
                const SizedBox(height: 4),
                const Text('基于HSK 3.0标准的现代中文学习应用'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Display Settings Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wygląd',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: emojiEnabledNotifier,
                  builder: (context, emojisEnabled, child) {
                    return SwitchListTile(
                      title: const Text('Spadające emotki'),
                      subtitle: const Text('Pokaż animowane chińskie emotki w tle'),
                      value: emojisEnabled,
                      onChanged: _toggleEmojis,
                      secondary: const Icon(Icons.auto_awesome),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Feedback Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zgłoś Problem lub Pomysł',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dziękujemy za korzystanie z aplikacji! Jeśli napotkałeś problem lub masz pomysł na ulepszenie, daj nam znać.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for using this app! If you encountered a problem or have an idea for improvement, let us know.',
                ),
                const SizedBox(height: 8),
                const Text(
                  '谢谢您使用这个应用！如果您遇到问题或有改进的想法，请告诉我们。',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _launchGitHubIssues,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Otwórz GitHub Issues'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Credits Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podziękowania',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Dane słownikowe: CC-CEDICT\n'
                  '• Framework: Flutter\n'
                  '• Open Source Project',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
