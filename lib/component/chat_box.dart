import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import '../entity/question.dart';
import '../entity/session.dart';
import '../api/question_api.dart';
import '../api/session_api.dart';
import '../api/cos_api.dart';
import '../services/asr_service.dart';
import '../utils/storage_manager.dart';
import '../utils/logger.dart';

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
  // 未发送的消息（例如先选择/上传的图片，等待用户提出问题后一起发送）
  final List<ChatMessage> _newMessages = [];
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  late final AsrService _asrService;
  final bool _isLoadingQuestion = false;
  bool _isRecording = false;
  String? _currentSessionId;
  // 语音识别实时结果
  String _recognizedText = '';
  bool _isRecognizing = false;
  // 是否为文本模式（点击切换按钮后，是录音模式）
  bool _isTextMode = false;
  // 是否显示文本输入框(录音结束会展示文本输入框)
  bool _showTextInput = false;

  @override
  void initState() {
    super.initState();
    _asrService = AsrService((text, isFinal) {
      if (!mounted) return;
      setState(() {
        _recognizedText = text;
        _isRecognizing = !isFinal && text.isNotEmpty;
        // 只有在最终结果时才更新输入框
        if (isFinal && text.isNotEmpty) {
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          // 录音结束后显示文本输入框
          setState(() {
            _showTextInput = true;
          });
        }
      });
    });
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
    _asrService.dispose();
    super.dispose();
  }

  // 语音输入功能
  Future<void> _startVoiceRecording() async {
    logger.d('检测到长按，进行回调');
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
      
      logger.d('开始录音了');
      await _audioRecorder.start(
        const RecordConfig(),
        path: recordingPath,
      );
      
      logger.d('UI显示录音中状态');
      setState(() {
        _isRecording = true;
        _recognizedText = '';
        _isRecognizing = true;
      });
      
      // 启动 ASR 实时识别（AsrService 构造时已完成初始化与回调绑定）
      unawaited(_asrService.start());

    } catch (e) {
      setState(() {
        _isRecording = false;
        _isRecognizing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音失败: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    logger.e('检测到停止长按，进行回调');
    try {
      await _audioRecorder.stop();
      logger.e('UI显示录音结束');
      setState(() {
        _isRecording = false;
        // 不立即设置 _isRecognizing = false，让 ASR 继续处理
      });
      
      // 优雅停止 ASR，让它继续处理剩余的音频数据
      await _asrService.stop();
      
      // 识别结果会在 AsrService 的回调中自动处理
      // 当收到最终结果时，_isRecognizing 会被设置为 false
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isRecognizing = false;
      });
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
        try {
          // 显示上传中状态（加入未发送列表）
          setState(() {
            _newMessages.add(ChatMessage(
              text: '📷 正在上传图片...',
              isUser: true,
              isLoading: true,
              isPending: true,
            ));
          });
          _scrollToBottom();

          // 上传图片到腾讯云 COS
          final imageUrl = await CosApi.uploadImage(image.path);

          // 更新为上传完成的图片（仍在未发送列表中）
          setState(() {
            if (_newMessages.isNotEmpty) {
              _newMessages.removeLast();
            }
            _newMessages.add(ChatMessage(
              text: '📷 图片已上传',
              isUser: true,
              imageUrl: imageUrl,
              isPending: true,
            ));
          });
          _scrollToBottom();
        } catch (e) {
          // 上传失败，显示错误消息（未发送列表）
          setState(() {
            if (_newMessages.isNotEmpty) {
              _newMessages.removeLast();
            }
            _newMessages.add(ChatMessage(
              text: '❌ 图片上传失败: $e',
              isUser: true,
              isPending: true,
            ));
          });
          _scrollToBottom();
        }
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

    // 发送后隐藏文本输入框（如果不是文本模式）
    if (!_isTextMode) {
      setState(() {
        _showTextInput = false;
      });
    }

    setState(() {
      _newMessages.add(ChatMessage(
        text: _textController.text,
        isUser: true,
      ));
      // 将未发送的图片（已上传）一并展示在已发送前端，保持视觉一致
      // 真正的语义合并在 API 成功后执行
    });
    // 添加用户消息后立即滚动到底部
    _scrollToBottom();
    Map<String, String?> wrappedChatMessage = {};
    for (var message in _newMessages) {
      if (message.imageUrl != null) {
        wrappedChatMessage['image_url'] = message.imageUrl;
      } else {
        wrappedChatMessage['text'] = message.text;
      }
    }
    PostChatMessage postChatMessage = PostChatMessage(
      text: wrappedChatMessage['text'],
      image_url: wrappedChatMessage['image_url'],
    );

    try {
      String aiMessage = '';
      String sessionId = '';
      if (widget.question != null) {
        // 调用API获取AI回复
        final response = await QuestionApi.getQuestionGuide(AiChatRequest(
          question_id: widget.question!.id,
          post_chat_message: postChatMessage,
          session_id: _currentSessionId,
        ));

        aiMessage = response['ai_message'] ?? '';
        sessionId = response['session_id'] ?? '';

        // 更新session_id到本地存储
        if (sessionId.isNotEmpty && widget.examId != null && widget.question?.id != null) {
          await StorageManager.saveSessionId(buildSessionKey(widget.examId, widget.question), sessionId);
          _currentSessionId = sessionId;
        }
      } else {
        // 调用API获取AI回复
        final response = await QuestionApi.getGossipGuide(AiChatRequest(
          post_chat_message: postChatMessage,
          session_id: _currentSessionId,
        ));

        aiMessage = response['ai_message'] ?? '';
        sessionId = response['session_id'] ?? '';

        // 更新session_id到本地存储
        if (sessionId.isNotEmpty) {
          await StorageManager.saveSessionId(buildSessionKey(null, null), sessionId);
          _currentSessionId = sessionId;
        }
      }

      // 发送成功：把 _newMessages 合并到 _messages 并清空
      if (_newMessages.isNotEmpty) {
        setState(() {
          // 去掉 pending 样式
          _messages.addAll(_newMessages.map((m) => ChatMessage(
                text: m.text,
                isUser: m.isUser,
                imageUrl: m.imageUrl,
                isLoading: false,
                isPending: false,
              )));
          _newMessages.clear();
        });
        // 合并消息后滚动到底部
        _scrollToBottom();
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
    
    // 在文本模式下，发送后保持文本框显示
    if (_isTextMode) {
      setState(() {
        _showTextInput = true;
      });
    }
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
    StorageManager.clearSessionId(buildSessionKey(widget.examId, widget.question));
    _initializeChat();
  }

  // 切换输入模式
  void _toggleInputMode() {
    setState(() {
      _isTextMode = !_isTextMode;
      if (_isTextMode) {
        _showTextInput = true;
        _textController.clear();
      } else {
        _showTextInput = false;
        _textController.clear();
      }
    });
  }

  void _scrollToBottom() {
    // 使用多个延迟确保在不同情况下都能正确滚动
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // 额外延迟确保在布局完成后滚动
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
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
            child: GestureDetector(
              onTap: () {
                // 点击空白区域收起键盘
                FocusScope.of(context).unfocus();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + _newMessages.length,
                reverse: false,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _messages[index];
                  } else {
                    final pending = _newMessages[index - _messages.length];
                    return pending;
                  }
                },
              ),
            ),
          ),
          Column(
            children: [
              // 实时语音识别结果显示区域
              if (_isRecognizing && _recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '正在识别...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          _recognizedText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '松开结束录音',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              // 文本输入框区域（录音结束后或文本模式时显示）
              if (_showTextInput)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 40,
                            maxHeight: 120,
                          ),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: '输入你的问题...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: Colors.white),
                          iconSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              // 底部操作栏
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
                    // 拍照按钮
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 中间区域：录音按钮或空白
                    Expanded(
                      child: _isTextMode
                          ? const SizedBox.shrink() // 文本模式下中间留空白
                          : Listener(
                              onPointerDown: (_) {
                                logger.d('手指按下');
                                _startVoiceRecording();
                              },
                              onPointerUp: (_) {
                                logger.d('手指抬起');
                                _stopVoiceRecording();
                              },
                              onPointerCancel: (_) {
                                logger.d('手指取消');
                                _stopVoiceRecording();
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isRecording ? Colors.red.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _isRecording ? Colors.red : Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      color: _isRecording ? Colors.red : Colors.blue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isRecording ? '松开结束' : '按住说话',
                                      style: TextStyle(
                                        color: _isRecording ? Colors.red : Colors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // 切换按钮
                    GestureDetector(
                      onTap: _toggleInputMode,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isTextMode ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isTextMode ? Icons.mic : Icons.keyboard,
                          color: _isTextMode ? Colors.blue : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
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
  final String? imageUrl;
  final bool isLoading;
  // 是否未正式发送（位于 _newMessages 中）
  final bool isPending;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.imageUrl,
    this.isLoading = false,
    this.isPending = false,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  else if (imageUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  '请提出你的问题',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            text,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    )
                  else
                    Text(
                      text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                ],
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
