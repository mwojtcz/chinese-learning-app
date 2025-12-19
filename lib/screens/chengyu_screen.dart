import 'package:flutter/material.dart';

class ChengyuScreen extends StatefulWidget {
  const ChengyuScreen({super.key});

  @override
  State<ChengyuScreen> createState() => _ChengyuScreenState();
}

class _ChengyuScreenState extends State<ChengyuScreen> {
  // TODO: Replace with actual database
  final List<Map<String, String>> _chengyuList = [
    {
      'chinese': '画蛇添足',
      'pinyin': 'huà shé tiān zú',
      'literal': 'Draw a snake and add feet',
      'meaning': 'To ruin something by adding unnecessary details',
      'example': '他的演讲本来很好，但最后画蛇添足，反而让人觉得啰嗦。'
    },
    {
      'chinese': '守株待兔',
      'pinyin': 'shǒu zhū dài tù',
      'literal': 'Guard a tree stump waiting for rabbits',
      'meaning': 'To wait idly for opportunities instead of seeking them',
      'example': '成功需要努力，不能守株待兔。'
    },
    {
      'chinese': '亡羊补牢',
      'pinyin': 'wáng yáng bǔ láo',
      'literal': 'Mend the pen after the sheep are lost',
      'meaning': 'Better late than never; fix a problem after damage is done',
      'example': '虽然已经损失了一些钱，但现在改正还不算晚，亡羊补牢，为时未晚。'
    },
    {
      'chinese': '井底之蛙',
      'pinyin': 'jǐng dǐ zhī wā',
      'literal': 'A frog at the bottom of a well',
      'meaning': 'Someone with a narrow view of the world',
      'example': '不要做井底之蛙，要多出去看看世界。'
    },
    {
      'chinese': '滥竽充数',
      'pinyin': 'làn yú chōng shù',
      'literal': 'Make up the number with bad flute players',
      'meaning': 'Pass off fake or inferior goods; pretend to be an expert',
      'example': '他根本不懂技术，只是滥竽充数而已。'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _chengyuList.length,
        itemBuilder: (context, index) {
          final chengyu = _chengyuList[index];
          return _buildChengyuCard(chengyu);
        },
      ),
    );
  }

  Widget _buildChengyuCard(Map<String, String> chengyu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chinese characters
          Row(
            children: [
              const Text('🎋', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chengyu['chinese']!,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Pinyin
          Text(
            chengyu['pinyin']!,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          
          // Literal meaning
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 ',
                  style: TextStyle(fontSize: 17),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Literal:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chengyu['literal']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Actual meaning
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 ',
                  style: TextStyle(fontSize: 17),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meaning:',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFFFD700).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chengyu['meaning']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Example sentence
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✍️ ',
                  style: TextStyle(fontSize: 17),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chengyu['example']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
