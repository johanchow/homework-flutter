import 'package:flutter/material.dart';

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                        _buildStatItem('完成挑战', '156', Icons.check_circle),
                        _buildStatItem('总用时', '89小时', Icons.timer),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('连续天数', '12天', Icons.calendar_today),
                        _buildStatItem('平均时长', '34分钟', Icons.av_timer),
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
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          _getSubjectIcon(index % 4),
                          color: Colors.blue,
                        ),
                      ),
                      title: Text('${_getSubjectName(index % 4)}挑战 #${1000 - index}'),
                      subtitle: Text('完成时间: ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 16)}'),
                      trailing: Text(
                        '${25 + index}分钟',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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

  IconData _getSubjectIcon(int index) {
    switch (index) {
      case 0: return Icons.science;
      case 1: return Icons.calculate;
      case 2: return Icons.language;
      case 3: return Icons.history;
      default: return Icons.book;
    }
  }

  String _getSubjectName(int index) {
    switch (index) {
      case 0: return '物理';
      case 1: return '数学';
      case 2: return '英语';
      case 3: return '历史';
      default: return '其他';
    }
  }
} 