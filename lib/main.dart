import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学习挑战',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 默认选中中间的"今日挑战"

  final List<Widget> _pages = [
    const RecordPage(),
    const ChallengePage(),
    const AIPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_selectedIndex == 0 ? Icons.history : Icons.history_outlined),
                  const Text('记录', style: TextStyle(fontSize: 12)),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _selectedIndex == 1 
                        ? [Colors.blue, Colors.blue.shade700]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                  boxShadow: _selectedIndex == 1 ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ] : null,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_selectedIndex == 2 ? Icons.smart_toy : Icons.smart_toy_outlined),
                  const Text('AI', style: TextStyle(fontSize: 12)),
                ],
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

// 记录页面
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

// 今日挑战页面
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

// AI页面
class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _messages.add(ChatMessage(
      text: '你好！我是你的学习助手，有什么问题可以随时问我。',
      isUser: false,
    ));
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
      setState(() {
        _messages.add(ChatMessage(
          text: '我收到了你的消息，正在思考如何帮助你...',
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: '你好！我是你的学习助手，有什么问题可以随时问我。',
        isUser: false,
      ));
    });
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
        title: const Text('AI助手'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
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