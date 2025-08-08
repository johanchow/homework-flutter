import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../entity/question.dart';
import '../entity/session.dart';
import '../api/question_api.dart';
import '../api/session_api.dart';
import '../utils/storage_manager.dart';

class ChatBox extends StatefulWidget {
  final String? examId;
  final Question? question;
  final String? initialMessage;
  final Function(Question?)? onQuestionLoaded;

  const ChatBox({
    super.key,
    this.examId,
    this.question,
    this.initialMessage,
    this.onQuestionLoaded,
  });

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  Question? _currentQuestion;
  bool _isLoadingQuestion = false;
  bool _isRecording = false;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    // 添加欢迎消息
    String welcomeMessage = widget.initialMessage ?? ((widget.question?.title ?? '').isNotEmpty ? '你好！我是你的学习助手，让我们一起探讨 —— ${widget.question!.title}' : '你好！我是你的学习助手，有什么问题可以随时问我。');
    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
    ));

    // 如果有examId和questionId，从本地获取session_id
    _currentSessionId = await StorageManager.getSessionId(buildSessionKey(widget.examId, widget.question));
    if (_currentSessionId != null && _currentSessionId!.isNotEmpty) {
      try {
        final sessionInfo = await SessionApi.getSession(_currentSessionId!);
        if (sessionInfo.messages.isNotEmpty) {
          setState(() {
            _messages.clear(); // 清除欢迎消息
            _messages.addAll(sessionInfo.messages.map((message) => ChatMessage(
              text: message.content,
              isUser: message.role == MessageRole.user,
            )));
          });
          _scrollToBottom();
        }
      } catch (e) {
        // 如果加载session失败，继续使用欢迎消息
      }
    }
  }

  void _addAIMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // 语音输入功能
  Future<void> _startVoiceRecording() async {
    try {
      // 请求麦克风权限
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要麦克风权限才能录音')),
          );
        }
        return;
      }

      // 开始录音
      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(),
        path: recordingPath,
      );
      
      setState(() {
        _isRecording = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始录音，长按结束')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音失败: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        // 这里可以添加语音转文字的功能
        // 暂时发送录音文件路径作为消息
        setState(() {
          _messages.add(ChatMessage(
            text: '🎤 语音消息: $path',
            isUser: true,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录音失败: $e')),
        );
      }
    }
  }

  // 拍照功能
  Future<void> _takePhoto() async {
    try {
      // 检查并请求相机权限
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      // 仍未授权，引导去系统设置页面
      if (!status.isGranted) {
        // 永久拒绝或受限制，直接跳转设置
        if (status.isPermanentlyDenied || status.isRestricted) {
          final opened = await openAppSettings();
          if (!opened && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('请在系统设置中授予相机权限')),
            );
          }
        } else {
          // 普通拒绝，给出弹窗并可跳转设置
          if (mounted) {
            final goToSettings = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('需要相机权限'),
                content: const Text('拍照功能需要相机权限，请前往系统设置授予权限。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('去设置'),
                  ),
                ],
              ),
            );
            if (goToSettings == true) {
              await openAppSettings();
            }
          }
        }
        return;
      }

      // 拍照
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        // 发送图片消息
        setState(() {
          _messages.add(ChatMessage(
            text: '📷 图片: ${image.path}',
            isUser: true,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _textController.text,
        isUser: true,
      ));
    });

    try {
      String aiMessage = '';
      String sessionId = '';
      if (widget.question != null) {
        // 调用API获取AI回复
        final response = await QuestionApi.getQuestionGuide({
          'question_id': widget.question!.id,
          'new_message': _textController.text,
          'session_id': _currentSessionId ?? '',
        });

        aiMessage = response['ai_message'] ?? '';
        sessionId = response['session_id'] ?? '';

        // 更新session_id到本地存储
        if (sessionId.isNotEmpty && widget.examId != null && widget.question?.id != null) {
          await StorageManager.saveSessionId(buildSessionKey(widget.examId, widget.question), sessionId);
          _currentSessionId = sessionId;
        }
      } else {
        // 调用API获取AI回复
        final response = await QuestionApi.getGossipGuide({
          'new_message': _textController.text,
          'session_id': _currentSessionId ?? '',
        });

        aiMessage = response['ai_message'] ?? '';
        sessionId = response['session_id'] ?? '';

        // 更新session_id到本地存储
        if (sessionId.isNotEmpty) {
          await StorageManager.saveSessionId(buildSessionKey(null, null), sessionId);
          _currentSessionId = sessionId;
        }
      }

      _addAIMessage(aiMessage);
    } catch (e) {
      // alert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送消息失败: $e', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
        );
      }
      throw Exception('发送消息失败: $e');
    }

    _textController.clear();
    _scrollToBottom();
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
    _initializeChat();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question != null ? '题目助手' : 'AI助手'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingQuestion)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.clear_all_sharp),
            onPressed: _clearMessages,
            tooltip: '清空对话',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 语音输入按钮 - 长按录音
                    GestureDetector(
                      onLongPressStart: (_) => _startVoiceRecording(),
                      onLongPressEnd: (_) => _stopVoiceRecording(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: _isRecording ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 拍照按钮
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: '输入你的问题...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 聊天消息组件
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
} 

String buildSessionKey(String? examId, Question? question) {
  if (examId != null && question != null) {
    return '${examId}_${question.id}';
  } else if (examId != null) {
    return examId;
  } else if (question != null) {
    return question.id;
  }
  return 'gossip';
}
