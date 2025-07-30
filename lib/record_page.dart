import 'package:flutter/material.dart';
import 'api/exam_api.dart';
import 'api/api.dart';
import 'challenge_detail_page.dart';
import 'entity/exam.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  Map<String, dynamic> _summaryStat = {};
  List<Map<String, dynamic>> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      // _isLoading = true;
    });

    try {
      // 并行加载数据
      final results = await Future.wait([
        ExamApi.getExamSummary(),
        ExamApi.listHistoryExams(),
      ]);

      if (!mounted) return;
      
      setState(() {
        _summaryStat = results[0] as Map<String, dynamic>;
        _exams = (results[1] as List<Exam>).map((exam) => exam.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showApiError(context, e.toString());
      }
    }
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}小时${mins}分钟';
    } else {
      return '${mins}分钟';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习记录'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 统计卡片
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '学习统计',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    '总完成挑战',
                                    '${_summaryStat['total_challenges'] ?? 0}',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    '总用时',
                                    _formatTime(_summaryStat['total_time'] ?? 0),
                                    Icons.access_time,
                                    Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    '近一周用时',
                                    _formatTime(_summaryStat['weekly_time'] ?? 0),
                                    Icons.trending_up,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 最近挑战列表
                    const Text(
                      '最近挑战',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_exams.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            '暂无挑战记录',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exams.length,
                        itemBuilder: (context, index) {
                          final exam = _exams[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getSubjectColor(exam['subject']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    exam['subject'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                exam['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('用时: ${exam['duration']}分钟'),
                                  Text('完成时间: ${exam['completed_time']}'),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getSubjectColor(String? subject) {
    switch (subject) {
      case '数学':
        return Colors.blue;
      case '英语':
        return Colors.green;
      case '物理':
        return Colors.orange;
      case '化学':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 