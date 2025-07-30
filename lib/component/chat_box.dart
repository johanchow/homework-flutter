import 'package:flutter/material.dart';
import '../entity/question.dart';
import '../entity/session.dart';
import '../api/question_api.dart';
import '../api/session_api.dart';
import '../utils/storage_manager.dart';

class ChatBox extends StatefulWidget {
  final String? examId;
  final String? questionId;
  final String? initialMessage;
  final Function(Question?)? onQuestionLoaded;

  const ChatBox({
    super.key,
    this.examId,
    this.questionId,
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
  Question? _currentQuestion;
  bool _isLoadingQuestion = false;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    // 添加欢迎消息
    String welcomeMessage = widget.initialMessage ?? '你好！我是你的学习助手，有什么问题可以随时问我。';
    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
    ));

    // 如果有examId和questionId，从本地获取session_id
    print('aaaaaaaaaaaaa');
    if (widget.examId != null && widget.questionId != null) {
      _currentSessionId = await StorageManager.getSessionId(widget.examId!, widget.questionId!);
      print('bbbbbbbbbbbbbb');
      if (_currentSessionId != null && _currentSessionId!.isNotEmpty) {
        try {
          final sessionInfo = await SessionApi.getSession(_currentSessionId!);
          print('sessionInfo.messages: ${sessionInfo.messages}');
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
          print('加载session失败: $e');
          // 如果加载session失败，继续使用欢迎消息
        }
      }
    }

    // // 如果有questionId，加载题目详情
    // if (widget.questionId != null) {
    //   _loadQuestionDetail();
    // }
  }

  Future<void> _loadQuestionDetail() async {
    setState(() {
      _isLoadingQuestion = true;
    });

    try {
      // 模拟API调用获取题目详情
      final question = await QuestionApi.getQuestion(widget.questionId!);
      
      setState(() {
        _currentQuestion = question;
        _isLoadingQuestion = false;
      });

      // 通知父组件题目已加载
      if (widget.onQuestionLoaded != null) {
        widget.onQuestionLoaded!(question);
      }

      // 自动发送题目相关的消息
      _addAIMessage('我已经为您加载了题目详情。题目内容：${question.title}\n\n请问您需要什么帮助？');

    } catch (e) {
      setState(() {
        _isLoadingQuestion = false;
      });
      throw Exception('加载题目详情失败');
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
    super.dispose();
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
      // 调用API获取AI回复
      final response = await QuestionApi.getQuestionGuide({
        'question_id': widget.questionId!,
        'new_message': _textController.text,
        'session_id': _currentSessionId ?? '',
      });

      String aiMessage = response['ai_message'] ?? '';
      String sessionId = response['session_id'] ?? '';

      // 更新session_id到本地存储
      if (sessionId.isNotEmpty && widget.examId != null && widget.questionId != null) {
        await StorageManager.saveSessionId(widget.examId!, widget.questionId!, sessionId);
        _currentSessionId = sessionId;
      }

      _addAIMessage(aiMessage);
    } catch (e) {
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
        title: Text(widget.questionId != null ? '题目助手' : 'AI助手'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            icon: const Icon(Icons.clear_all),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // 语音输入功能
                  },
                  icon: const Icon(Icons.mic),
                  color: Colors.blue,
                ),
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