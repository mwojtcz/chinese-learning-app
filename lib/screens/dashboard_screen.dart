import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../screens/home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final wordProvider = context.watch<WordProvider>();
    final totalWords = wordProvider.allWords.length;
    final myWordsCount = wordProvider.myWords.length;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(),
            const SizedBox(height: 12),
            
            // Streak Counter
            _buildStreakCard(),
            const SizedBox(height: 10),
            
            // Quick Actions & Stats Combined
            _buildQuickStatsGrid(totalWords, myWordsCount),
            const SizedBox(height: 12),
            
            // Progress Chart (placeholder)
            _buildProgressChart(),
            const SizedBox(height: 12),
            
            // Chengyu of the Day
            _buildChengyuOfTheDay(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting = '早上好'; // Good morning
    if (hour >= 12 && hour < 18) {
      greeting = '下午好'; // Good afternoon
    } else if (hour >= 18) {
      greeting = '晚上好'; // Good evening
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF800020), // Burgundy
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Ready to learn Chinese today?',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    // TODO: Implement actual streak tracking
    const currentStreak = 3; // Placeholder
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF800020), Color(0xFF600018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔥 Study Streak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$currentStreak days',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Text(
            '🔥',
            style: TextStyle(fontSize: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(int totalWords, int myWordsCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Actions Card - Left side
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCompactActionButton(
                  context,
                  '📖 Continue Learning',
                  'Practice new words',
                  () {
                    final homeState = context.findAncestorStateOfType<HomeScreenState>();
                    if (homeState != null) {
                      homeState.navigateToScreen(1);
                    }
                  },
                ),
                const SizedBox(height: 6),
                _buildCompactActionButton(
                  context,
                  '📝 Daily Practice',
                  '5-10 questions',
                  () {
                    final homeState = context.findAncestorStateOfType<HomeScreenState>();
                    if (homeState != null) {
                      homeState.navigateToScreen(3);
                    }
                  },
                ),
                const SizedBox(height: 6),
                _buildCompactActionButton(
                  context,
                  '🔄 Review Words',
                  'Improve accuracy',
                  () {
                    final homeState = context.findAncestorStateOfType<HomeScreenState>();
                    if (homeState != null) {
                      homeState.navigateToScreen(2);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Stats Column - Right side
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildCompactStatCard('📚', 'Total', '$totalWords', '/ 11,092'),
              const SizedBox(height: 6),
              _buildCompactStatCard('⭐', 'Saved', '$myWordsCount', 'words'),
              const SizedBox(height: 6),
              _buildCompactStatCard('🔄', 'Review', '0', 'today'),
              const SizedBox(height: 6),
              _buildCompactStatCard('🎯', 'Accuracy', '0%', 'avg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionButton(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 11,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatCard(String emoji, String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Progress This Week',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Placeholder for chart
          Container(
            height: 60,
            alignment: Alignment.center,
            child: Text(
              'Chart coming soon...',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChengyuOfTheDay() {
    // TODO: Implement actual chengyu database
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎋', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'Chengyu of the Day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '画蛇添足',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'huà shé tiān zú',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Literal: Draw a snake and add feet',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Meaning: To ruin something by adding unnecessary details',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
