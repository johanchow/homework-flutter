import 'package:flutter/material.dart';
import 'challenge_detail_page.dart';

class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final List<Map<String, dynamic>> challenges = [
      {
        'id': '1001',
        'subject': '物理',
        'challenge_id': '1001',
        'start_time': '09:00',
        'expected_duration': '30分钟',
        'status': 'pending', // pending, ongoing, completed
      },
      {
        'id': '1002',
        'subject': '数学',
        'challenge_id': '1002',
        'start_time': '10:30',
        'expected_duration': '45分钟',
        'status': 'ongoing',
      },
      {
        'id': '1003',
        'subject': '英语',
        'challenge_id': '1003',
        'start_time': '14:00',
        'expected_duration': '25分钟',
        'status': 'completed',
      },
      {
        'id': '1004',
        'subject': '历史',
        'challenge_id': '1004',
        'start_time': '16:00',
        'expected_duration': '35分钟',
        'status': 'pending',
      },
      {
        'id': '1005',
        'subject': '物理',
        'challenge_id': '1005',
        'start_time': '19:30',
        'expected_duration': '40分钟',
        'status': 'pending',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日挑战'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日待完成',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengeDetailPage(
                              challengeId: challenge['id'],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getSubjectColor(challenge['subject']),
                                  child: Icon(
                                    _getSubjectIcon(challenge['subject']),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        challenge['subject'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '挑战 #${challenge['challenge_id']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusChip(challenge['status']),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '开始时间: ${challenge['start_time']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '预计时长: ${challenge['expected_duration']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // 根据状态执行不同操作
                                  switch (challenge['status']) {
                                    case 'pending':
                                      // 开始挑战
                                      break;
                                    case 'ongoing':
                                      // 继续挑战
                                      break;
                                    case 'completed':
                                      // 查看结果
                                      break;
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getSubjectColor(challenge['subject']),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(_getButtonText(challenge['status'])),
                              ),
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

  Widget _buildStatusChip(String status) {
    String statusText;
    Color color;
    
    switch (status) {
      case 'pending':
        statusText = '待开始';
        color = Colors.orange;
        break;
      case 'ongoing':
        statusText = '进行中';
        color = Colors.blue;
        break;
      case 'completed':
        statusText = '已完成';
        color = Colors.green;
        break;
      default:
        statusText = '待开始';
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'pending':
        return '开始挑战';
      case 'ongoing':
        return '继续挑战';
      case 'completed':
        return '查看';
      default:
        return '开始挑战';
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case '物理': return Colors.red;
      case '数学': return Colors.blue;
      case '英语': return Colors.green;
      case '历史': return Colors.purple;
      default: return Colors.orange;
    }
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