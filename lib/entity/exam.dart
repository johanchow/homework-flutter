import 'package:flutter/material.dart';
import 'question.dart';

enum ExamStatus {
  pending('待开始'),
  ongoing('进行中'),
  completed('已完成'),
  cancelled('已取消');

  final String label;

  const ExamStatus(this.label);
}

class Exam {
  final String id;
  final String title;
  final String plan_starttime;
  final int plan_duration;
  final ExamStatus status;
  final List<String> question_ids;
  final List<Question> questions;
  final String created_at;
  final String updated_at;

  Exam({
    required this.id,
    required this.title,
    required this.plan_starttime,
    required this.plan_duration,
    required this.status,
    required this.question_ids,
    required this.questions,
    required this.created_at,
    required this.updated_at,
  });

  // 从JSON创建Exam实例
  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      plan_starttime: json['plan_starttime'] ?? '',
      plan_duration: json['plan_duration'] ?? 0,
      status: _parseExamStatus(json['status']),
      question_ids: List<String>.from(json['question_ids'] ?? []),
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => Question.fromJson(q))
          .toList() ?? <Question>[],
      created_at: json['created_at'] ?? '',
      updated_at: json['updated_at'] ?? '',
    );
  }

  // 解析考试状态
  static ExamStatus _parseExamStatus(dynamic status) {
    if (status == null) return ExamStatus.pending;
    try {
      return ExamStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return ExamStatus.pending;
    }
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'plan_starttime': plan_starttime,
      'plan_duration': plan_duration,
      'status': status.name,
      'question_ids': question_ids,
      'questions': questions.map((q) => q.toJson()).toList(),
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}

Color getExamStatusColor(ExamStatus status) {
  switch (status) {
    case ExamStatus.pending:
      return Colors.blue;
    case ExamStatus.ongoing:
      return Colors.orange;
    case ExamStatus.completed:
      return Colors.green;
    default:
      return Colors.blue;
  }
}

