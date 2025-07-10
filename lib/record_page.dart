import 'package:flutter/material.dart';
import 'challenge_detail_page.dart';

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final Map<String, dynamic> summaryStat = {
      'total_challenges': 156,
      'total_time': '89小时',
      'weekly_time': '12小时',
    };

    final List<Map<String, dynamic>> exams = [
      {
        'id': '123ragdsg',
        'subject': '物理',
        'cost_time': '25分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '456hjkdf',
        'subject': '数学',
        'cost_time': '30分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '789lmnop',
        'subject': '英语',
        'cost_time': '20分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'id': '012qrstu',
        'subject': '历史',
        'cost_time': '35分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 4)),
      },
      {
        'id': '345vwxyz',
        'subject': '物理',
        'cost_time': '28分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'id': '678abcde',
        'subject': '数学',
        'cost_time': '32分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 6)),
      },
      {
        'id': '901fghij',
        'subject': '英语',
        'cost_time': '18分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 7)),
      },
      {
        'id': '234klmno',
        'subject': '历史',
        'cost_time': '40分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 8)),
      },
      {
        'id': '567pqrst',
        'subject': '物理',
        'cost_time': '22分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 9)),
      },
      {
        'id': '890uvwxy',
        'subject': '数学',
        'cost_time': '45分钟',
        'finish_time': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习记录'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '总体统计',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('总完成挑战111', '${summaryStat['total_challenges']}', Icons.check_circle),
                        _buildStatItem('总用时', summaryStat['total_time'], Icons.timer),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('近一周用时', summaryStat['weekly_time'], Icons.av_timer),
                        const SizedBox(width: 80), // 占位，保持布局对称
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '最近完成',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  final exam = exams[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          _getSubjectIcon(exam['subject']),
                          color: Colors.blue,
                        ),
                      ),
                      title: Text('${exam['subject']}挑战 #${1000 - index}'),
                      subtitle: Text('完成时间: ${exam['finish_time'].toString().substring(0, 16)}'),
                      trailing: Text(
                        exam['cost_time'],
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengeDetailPage(
                              challengeId: exam['id'],
                            ),
                          ),
                        );
                      },
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

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case '物理': return Icons.science;
      case '数学': return Icons.calculate;
      case '英语': return Icons.language;
      case '历史': return Icons.history;
      default: return Icons.book;
    }
  }
} 