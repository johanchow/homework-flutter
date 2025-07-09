import 'package:flutter/material.dart';

class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getSubjectColor(index % 4),
                                child: Icon(
                                  _getSubjectIcon(index % 4),
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getSubjectName(index % 4),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '挑战 #${1001 + index}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(index),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '开始时间: ${DateTime.now().add(Duration(hours: index)).toString().substring(11, 16)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '预计时长: ${30 + index * 5}分钟',
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
                                // 开始挑战
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getSubjectColor(index % 4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('开始挑战'),
                            ),
                          ),
                        ],
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

  Widget _buildStatusChip(int index) {
    String status;
    Color color;
    
    switch (index % 3) {
      case 0:
        status = '待开始';
        color = Colors.orange;
        break;
      case 1:
        status = '进行中';
        color = Colors.blue;
        break;
      case 2:
        status = '已完成';
        color = Colors.green;
        break;
      default:
        status = '待开始';
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
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSubjectColor(int index) {
    switch (index) {
      case 0: return Colors.red;
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.purple;
      default: return Colors.orange;
    }
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