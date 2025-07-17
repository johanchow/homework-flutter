enum QuestionType {
  choice('选择题'),
  fill('填空题'),
  qa('简答题'),
  reading('阅读题'),
  summary('总结题');

  final String label;

  const QuestionType(this.label);
}

class Question {
  final String id;
  final String title;
  final String answer;
  final String subject;
  final QuestionType type;
  final List<String> options;
  final List<String> images;
  final List<String> videos;
  final List<String> audios;
  final List<String> attachments;

  Question({
    required this.id,
    required this.title,
    required this.answer,
    required this.subject,
    required this.type,
    required this.attachments,
    required this.options,
    required this.images,
    required this.videos,
    required this.audios,
  });

  // 从 Map<String, dynamic> 创建 Question 实例
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? json['content'] ?? '',
      answer: json['answer'] ?? '',
      subject: json['subject'] ?? '',
      type: _parseQuestionType(json['type']),
      attachments: _parseStringList(json['attachments']),
      options: _parseStringList(json['options']),
      images: _parseStringList(json['images']),
      videos: _parseStringList(json['videos']),
      audios: _parseStringList(json['audios']),
    );
  }

  // 辅助方法：解析字符串列表
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  // 辅助方法：解析题目类型
  static QuestionType _parseQuestionType(dynamic type) {
    if (type == null) return QuestionType.qa;
    try {
      return QuestionType.values.firstWhere((e) => e.name == type);
    } catch (e) {
      return QuestionType.qa; // 默认返回简答题
    }
  }

  // 转换 Question 实例为 Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'answer': answer,
      'subject': subject,
      'type': type,
      'attachments': attachments,
      'options': options,
      'images': images,
      'videos': videos,
      'audios': audios,
    };
  }
}