import 'package:flutter/material.dart';

class ChallengeDetailPage extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailPage({
    super.key,
    required this.challengeId,
  });

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchChallengeDetail();
  }

  Future<void> _fetchChallengeDetail() async {
    try {
      // 模拟HTTP请求
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟API响应数据
      final responseData = {
        'success': true,
        'data': {
          'challenge_id': widget.challengeId,
          'subject': '物理',
          'title': '力学基础挑战',
          'questions': [
            {
              'id': 'q1',
              'type': 'single_choice',
              'content': '一个物体在水平面上做匀速直线运动，下列说法正确的是：',
              'options': [
                'A. 物体所受合外力为零',
                'B. 物体所受摩擦力为零',
                'C. 物体所受重力为零',
                'D. 物体所受支持力为零'
              ],
              'correct_answer': 'A'
            },
            {
              'id': 'q2',
              'type': 'multiple_choice',
              'content': '关于牛顿第一定律，下列说法正确的是：',
              'options': [
                'A. 物体不受外力时，总保持静止状态',
                'B. 物体不受外力时，总保持匀速直线运动状态',
                'C. 物体不受外力时，总保持静止或匀速直线运动状态',
                'D. 物体不受外力时，总保持静止或匀速直线运动状态，直到有外力迫使它改变这种状态'
              ],
              'correct_answer': 'D'
            },
            {
              'id': 'q3',
              'type': 'calculation',
              'content': '一个质量为2kg的物体，在水平面上受到10N的水平拉力，物体与水平面间的摩擦系数为0.2，求物体的加速度。',
              'options': [],
              'correct_answer': '3 m/s²'
            },
            {
              'id': 'q4',
              'type': 'single_choice',
              'content': '在光滑水平面上，一个物体受到一个恒定的水平力F作用，物体的加速度为：',
              'options': [
                'A. 与F成正比',
                'B. 与物体质量成正比',
                'C. 与F成正比，与质量成反比',
                'D. 与F成反比，与质量成正比'
              ],
              'correct_answer': 'C'
            },
            {
              'id': 'q5',
              'type': 'calculation',
              'content': '一个物体从静止开始做匀加速直线运动，5秒内位移为25米，求物体的加速度。',
              'options': [],
              'correct_answer': '2 m/s²'
            }
          ]
        }
      };

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final questionsList = data['questions'] as List<dynamic>;
        setState(() {
          questions = questionsList.map((q) => q as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = '获取挑战详情失败';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '网络请求失败: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('挑战详情 #${widget.challengeId}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载挑战详情...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchChallengeDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: const Icon(Icons.science, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '力学基础挑战',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '挑战ID: ${widget.challengeId}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildInfoItem('题目数量', '${questions.length}'),
                                  const SizedBox(width: 20),
                                  _buildInfoItem('预计用时', '30分钟'),
                                  const SizedBox(width: 20),
                                  _buildInfoItem('难度', '中等'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '题目列表',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getQuestionTypeColor(question['type']),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getQuestionTypeText(question['type']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '第${index + 1}题',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      question['content'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    if (question['options'] != null && (question['options'] as List).isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      ...(question['options'] as List).map<Widget>((option) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          option.toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      )),
                                    ],
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

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'single_choice':
        return Colors.blue;
      case 'multiple_choice':
        return Colors.green;
      case 'calculation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getQuestionTypeText(String type) {
    switch (type) {
      case 'single_choice':
        return '单选题';
      case 'multiple_choice':
        return '多选题';
      case 'calculation':
        return '计算题';
      default:
        return '未知';
    }
  }
} 