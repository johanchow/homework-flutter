import 'package:flutter/material.dart';
import 'component/chat_box.dart';

class AIPage extends StatelessWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatBox(
      examId: null, // AI页面不需要examId
      question: null, // AI页面不需要questionId
    );
  }
} 