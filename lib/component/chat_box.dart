import 'package:flutter/material.dart';
import '../entity/question.dart';

class ChatBox extends StatefulWidget {
  final String? questionId;
  final String? initialMessage;
  final Function(Question?)? onQuestionLoaded;

  const ChatBox({
    super.key,
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

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // 添加欢迎消息
    String welcomeMessage = widget.initialMessage ?? '你好！我是你的学习助手，有什么问题可以随时问我。';
    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
    ));

    // 如果有questionId，加载题目详情
    if (widget.questionId != null) {
      _loadQuestionDetail();
    }
  }

  Future<void> _loadQuestionDetail() async {
    setState(() {
      _isLoadingQuestion = true;
    });

    try {
      // 模拟API调用获取题目详情
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 这里应该调用真实的API，现在用模拟数据
      final questionData = {
        'id': widget.questionId,
        'title': '这是一道关于${widget.questionId}的题目',
        'content': '请详细分析这道题目的解题思路和步骤',
        'type': 'qa',
        'subject': '数学',
        'answer': '',
        'options': [],
        'images': [],
        'videos': [],
        'audios': [],
        'attachments': [],
        'links': [],
      };

      final question = Question.fromJson(questionData);
      
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
      _addAIMessage('抱歉，加载题目详情时出现错误：$e');
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

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _textController.text,
        isUser: true,
      ));
    });

    _textController.clear();
    _scrollToBottom();

    // 模拟AI回复
    Future.delayed(const Duration(seconds: 1), () {
      String response = _generateAIResponse(_textController.text);
      _addAIMessage(response);
    });
  }

  String _generateAIResponse(String userMessage) {
    // 简单的AI回复逻辑
    if (userMessage.contains('题目') || userMessage.contains('解题')) {
      return '我来帮您分析这道题目。首先，我们需要理解题目的要求，然后...';
    } else if (userMessage.contains('答案') || userMessage.contains('结果')) {
      return '让我为您提供详细的解题步骤和答案...';
    } else if (userMessage.contains('思路') || userMessage.contains('方法')) {
      return '这道题目的解题思路是...';
    } else {
      return '我理解您的问题，让我为您提供帮助...';
    }
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