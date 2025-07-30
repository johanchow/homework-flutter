import 'package:flutter/material.dart';

enum MessageRole {
  user,
  assistant,
}

class Message {
  final MessageRole role;
  final String content;
  final String timestamp;
  final String message_type;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
    required this.message_type,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'],
      timestamp: json['timestamp'],
      message_type: json['message_type'],
    );
  }
}

class Session {
  final String id;
  final String topic;
  final String question_id;
  final List<Message> messages;

  Session({
    required this.id,
    required this.topic,
    required this.question_id,
    required this.messages,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    List<Message> messages = [];
    print('json.messages: ${json['messages']}');
    if (json['messages'] != null) {
      messages = (json['messages'] as List<dynamic>)
          .map((message) => Message.fromJson(message as Map<String, dynamic>))
          .toList();
    }
    return Session(
      id: json['id'] ?? '',
      topic: json['topic'] ?? '',
      question_id: json['question_id'] ?? '',
      messages: messages,
    );
  }
}