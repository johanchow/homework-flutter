import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/api_service.dart';
import 'api/exam_api.dart';
import 'api/cos_api.dart';
import 'entity/question.dart';
import 'entity/exam.dart';
import 'component/record_sound.dart';
import 'component/link_preview.dart';
import 'component/video_player_widget.dart';
import 'component/chat_box.dart';
import 'component/tts_button.dart';

class ChallengeDetailPage extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailPage({super.key, required this.challengeId});

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  Exam _challengeDetail = Exam(id: '', title: '', plan_starttime: '', plan_duration: 0, status: ExamStatus.pending, question_ids: [], questions: [], created_at: '', updated_at: '');
  List<Question> _questions = [];
  bool _isLoading = true;
  String? _error;
  
  // 答案状态管理
  final Map<String, dynamic> _answers = {};
  final Map<String, String> _selectedChoices = {};
  final Map<String, String> _textAnswers = {};
  final Map<String, String> _recordingPaths = {};
  final Map<String, String> _videoPaths = {};
  final Map<String, bool> _checkboxStates = {};

  @override
  void initState() {
    super.initState();
    print('ChallengeDetailPage initState');
    _loadChallengeDetail();
  }

  Future<void> _loadChallengeDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exam = await ExamApi.getExamDetail(widget.challengeId);
      
      print('exam questions: ${exam.questions}');
      setState(() {
        _challengeDetail = exam;
        _questions = exam.questions;
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
                            examId: widget.challengeId,
                            question: question,
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

            // 如果是阅读题目，则把material用tts_button组件渲染，方便直接发音阅读
            if (question.type == QuestionType.reading) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TtsButtonWidget(
                  sentence: (question.material ?? '')
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
    switch (question.type) {
      case QuestionType.choice:
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
        
      case QuestionType.reading:
        return RecordSoundWidget(
          onRecordingComplete: (String path) {
            setState(() {
              _recordingPaths[question.id] = path;
              _answers[question.id] = path;
            });
            ApiService.showSuccess(context, '录音完成！');
          },
        );
        
      case QuestionType.essay:
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
        
      case QuestionType.talking:
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

      case QuestionType.checking:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                final currentValue = _checkboxStates[question.id] ?? false;
                _checkboxStates[question.id] = !currentValue;
                _answers[question.id] = !currentValue;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: _checkboxStates[question.id] ?? false,
                  onChanged: (bool? value) {
                    setState(() {
                      _checkboxStates[question.id] = value ?? false;
                      _answers[question.id] = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text(
                  '已完成',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );

      case QuestionType.show:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 如果还没有录制视频，显示录制按钮
              if (_videoPaths[question.id] == null || _videoPaths[question.id]!.isEmpty)
                ElevatedButton.icon(
                  onPressed: () => _recordVideo(question.id),
                  icon: const Icon(Icons.videocam),
                  label: const Text('开始录制视频'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            
              // 如果已经录制了视频，显示视频播放器和重新录制按钮
              if (_videoPaths[question.id] != null && _videoPaths[question.id]!.isNotEmpty) ...[
                const SizedBox(height: 12),
                VideoPlayerWidget(videoUrl: _videoPaths[question.id]!),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _recordVideo(question.id),
                      icon: const Icon(Icons.videocam),
                      label: const Text('重新录制'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _deleteVideo(question.id),
                      icon: const Icon(Icons.delete),
                      label: const Text('删除视频'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
    
    return const SizedBox.shrink();
  }

  // 录制视频方法
  Future<void> _recordVideo(String questionId) async {
    try {
      // 检查相机权限
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          ApiService.showError(context, '需要相机权限才能录制视频');
          return;
        }
      }

      // 检查麦克风权限
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          ApiService.showError(context, '需要麦克风权限才能录制视频');
          return;
        }
      }

      // 使用image_picker录制视频
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5), // 最大录制5分钟
      );

      if (video != null) {
        setState(() {
          _videoPaths[questionId] = video.path;
          _answers[questionId] = video.path;
        });
        ApiService.showSuccess(context, '视频录制完成！');
      }
    } catch (e) {
      ApiService.showError(context, '录制视频失败: $e');
    }
  }

  // 删除视频方法
  void _deleteVideo(String questionId) {
    setState(() {
      _videoPaths.remove(questionId);
      _answers.remove(questionId);
    });
    ApiService.showSuccess(context, '视频已删除');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_challengeDetail.title ?? '挑战详情'),
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 挑战信息卡片
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _challengeDetail.title ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      '开始时间',
                                      _challengeDetail.plan_starttime ?? '',
                                      Icons.access_time,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      '预计时长',
                                      '${_challengeDetail.plan_duration}分钟',
                                      Icons.timer,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 题目列表
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
                      
                      const SizedBox(height: 100), // 底部留白，避免被 bottomNavigationBar 遮挡
                    ],
                  ),
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
          (_answers[questionId] is String && _answers[questionId].toString().trim().isEmpty) || 
          (_questions[i].type == QuestionType.checking && _answers[questionId] == false)) {
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

  void _submitAnswers() async {
    for (var question in _questions) {
      if ([QuestionType.talking, QuestionType.reading].contains(question.type) && _answers[question.id] != null) {
        final audioUrl = await CosApi.uploadAudio(_answers[question.id]!);
        _answers[question.id] = audioUrl;
      }
      if (question.type == QuestionType.show && _answers[question.id] != null) {
        final videoUrl = await CosApi.uploadVideo(_answers[question.id]!);
        _answers[question.id] = videoUrl;
      }
    }
    final answerJson = {
      'questions': _questions,
      'messages': {},
      'answers': _answers,
    };
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    late final bool isSuccess;
    late final String errorMessage;
    try {
      isSuccess = await ExamApi.submitAnswers(widget.challengeId, answerJson);
    } catch (e) {
      isSuccess = false;
      errorMessage = e.toString();
    }
    if (isSuccess) {
      ApiService.showSuccess(context, '提交成功');
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = errorMessage;
      });
    }
  }
} 