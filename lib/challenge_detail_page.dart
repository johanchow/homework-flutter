import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'entity/question.dart';
import 'component/record_sound.dart';
import 'component/link_preview.dart';
import 'component/video_player_widget.dart';
import 'component/chat_box.dart';

class ChallengeDetailPage extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailPage({super.key, required this.challengeId});

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  Map<String, dynamic> _challengeDetail = {};
  List<Question> _questions = [];
  bool _isLoading = true;
  String? _error;
  
  // 答案状态管理
  final Map<String, dynamic> _answers = {};
  final Map<String, String> _selectedChoices = {};
  final Map<String, String> _textAnswers = {};
  final Map<String, String> _recordingPaths = {};

  @override
  void initState() {
    super.initState();
    _loadChallengeDetail();
  }

  Future<void> _loadChallengeDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.getChallengeDetail(widget.challengeId);
      
      // 将API数据转换为Question对象
      List<Question> questions = [];
      if (detail['questions'] != null) {
        questions = (detail['questions'] as List)
            .map((q) => Question.fromJson(q))
            .toList();
      }
      
      setState(() {
        _challengeDetail = detail;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目头部
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.type.label,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                // 机器人图标
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.smart_toy,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatBox(
                            questionId: question.id,
                            onQuestionLoaded: (loadedQuestion) {
                              // 可以在这里处理题目加载完成后的逻辑
                              // 题目详情已加载: ${loadedQuestion?.title}
                            },
                          ),
                        ),
                      );
                    },
                    tooltip: 'AI助手',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            // 题目内容
            Text(
              question.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4
              ),
            ),
            
            const SizedBox(height: 16),
            // 渲染链接
            if (question.links.isNotEmpty) ...[
              ...List.generate(
                question.links.length,
                (linkIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: LinkPreviewWidget(url: question.links[linkIndex]),
                ),
              ),
            ],


            // 渲染图片
            if (question.images.isNotEmpty) ...[
              ...List.generate(
                question.images.length,
                (imageIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      question.images[imageIndex],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            
            // 渲染文件附件
            if (question.attachments.isNotEmpty) ...[
              ...List.generate(
                question.attachments.length,
                (attachmentIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '附件 ${attachmentIndex + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                question.attachments[attachmentIndex],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            ApiService.showSuccess(context, '开始下载文件');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            
            // 渲染视频
            if (question.videos.isNotEmpty) ...[
              ...List.generate(
                question.videos.length,
                (videoIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.video_file,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '视频 ${videoIndex + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      VideoPlayerWidget(videoUrl: question.videos[videoIndex]),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            // 根据题目类型渲染不同的输入组件
            _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(Question question) {
    switch (question.type.name) {
      case 'choice':
        if (question.options.isNotEmpty) {
          return Column(
            children: List.generate(
              question.options.length,
              (optionIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedChoices[question.id] == question.options[optionIndex]
                          ? Colors.blue
                          : Colors.grey[300]!,
                      width: _selectedChoices[question.id] == question.options[optionIndex] ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _selectedChoices[question.id] == question.options[optionIndex]
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                  ),
                  child: RadioListTile<String>(
                    value: question.options[optionIndex],
                    groupValue: _selectedChoices[question.id],
                    onChanged: (value) {
                      setState(() {
                        _selectedChoices[question.id] = value!;
                        _answers[question.id] = value;
                      });
                    },
                    title: Text(
                      question.options[optionIndex],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedChoices[question.id] == question.options[optionIndex]
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    activeColor: Colors.blue,
                  ),
                ),
              ),
            ),
          );
        }
        break;
        
      case 'fill':
        return TextField(
          controller: TextEditingController(text: _textAnswers[question.id] ?? ''),
          decoration: InputDecoration(
            hintText: '请输入答案',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (value) {
            _textAnswers[question.id] = value;
            _answers[question.id] = value;
          },
        );
        
      case 'reading':
        return RecordSoundWidget(
          onRecordingComplete: (String path) {
            setState(() {
              _recordingPaths[question.id] = path;
              _answers[question.id] = path;
            });
            ApiService.showSuccess(context, '录音完成！');
          },
        );
        
      case 'qa':
        return TextField(
          controller: TextEditingController(text: _textAnswers[question.id] ?? ''),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '请输入答案',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (value) {
            _textAnswers[question.id] = value;
            _answers[question.id] = value;
          },
        );
        
      case 'summary':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordSoundWidget(
              onRecordingComplete: (String path) {
                setState(() {
                  _recordingPaths[question.id] = path;
                  _answers[question.id] = path;
                });
                ApiService.showSuccess(context, '总结录音完成！');
              },
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_challengeDetail['title'] ?? '挑战详情'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChallengeDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '加载失败',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChallengeDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 挑战信息卡片
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _challengeDetail['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _challengeDetail['description'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      '开始时间',
                                      _challengeDetail['start_time'] ?? '',
                                      Icons.access_time,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      '预计时长',
                                      '${_challengeDetail['duration']}分钟',
                                      Icons.timer,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // 题目列表
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '题目列表',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_questions.isNotEmpty)
                              ...List.generate(
                                _questions.length,
                                (index) => _buildQuestionCard(
                                  _questions[index],
                                  index,
                                ),
                              )
                            else
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    '暂无题目',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '提交答案',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
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

  void _handleSubmit() {
    // 检查哪些题目没有作答
    List<int> unansweredQuestions = [];
    
    for (int i = 0; i < _questions.length; i++) {
      String questionId = _questions[i].id;
      if (_answers[questionId] == null || 
          (_answers[questionId] is String && _answers[questionId].toString().trim().isEmpty)) {
        unansweredQuestions.add(i + 1);
      }
    }

    if (unansweredQuestions.isEmpty) {
      // 全部题目都已作答
      _showConfirmDialog(
        '确认提交',
        '是否要提交答案？',
        () => _submitAnswers(),
      );
    } else {
      // 有题目没有作答
      String unansweredText = unansweredQuestions.map((questionNum) => '第$questionNum题').join('、');
      _showConfirmDialog(
        '确认提交',
        '${unansweredText}没有作答，确认要提交吗？',
        () => _submitAnswers(),
        isWarning: true,
        unansweredQuestions: unansweredQuestions,
      );
    }
  }

  void _showConfirmDialog(
    String title,
    String content,
    VoidCallback onConfirm, {
    bool isWarning = false,
    List<int>? unansweredQuestions,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content),
              if (unansweredQuestions != null) ...[
                const SizedBox(height: 8),
                ...unansweredQuestions.map((questionNum) => Text(
                  '第$questionNum题没有作答',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isWarning ? Colors.orange : Colors.blue,
              ),
              child: Text(isWarning ? '确认提交' : '提交'),
            ),
          ],
        );
      },
    );
  }

  void _submitAnswers() {
    // 这里可以添加实际的提交逻辑
    ApiService.showSuccess(context, '提交成功！');
    
    // 打印答案用于调试
    // print('提交的答案: $_answers');
  }
} 