import 'api.dart';
import '../entity/question.dart';

class AiChatRequest {
  final String? question_id;
  final String? session_id;
  final PostChatMessage post_chat_message;

  AiChatRequest({
    this.question_id,
    this.session_id,
    required this.post_chat_message,
  });
}

class QuestionApi {
  static Future<Question> getQuestion(String questionId) async {
    final response = await httpGet('/question/get', queryParameters: {
      'id': questionId,
    });
    final question = Question.fromJson(response['data'] ?? {});
    print('httpGet question: $question');
    return question;
  }

  static Future<Map<String, String>> getQuestionGuide(AiChatRequest r) async {
    final response = await httpPost('/ai/guide-question', body: {
      'question_id': r.question_id,
      'new_message': r.post_chat_message,
      'session_id': r.session_id,
    });
    String sessionId = response['data']['session_id'] ?? '';
    String aiMessage = response['data']['ai_message'] ?? '';
    return {
      'session_id': sessionId,
      'ai_message': aiMessage,
    };
  }

  static Future<Map<String, String>> getGossipGuide(AiChatRequest r) async {
    final response = await httpPost('/ai/gossip-chat', body: {
      'new_message': r.post_chat_message,
      'session_id': r.session_id,
    });
    String sessionId = response['data']['session_id'] ?? '';
    String aiMessage = response['data']['ai_message'] ?? '';
    return {
      'session_id': sessionId,
      'ai_message': aiMessage,
    };
  }
}

class PostChatMessage {
  final String? image_url;
  final String? text;

  PostChatMessage({
    this.image_url,
    this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'image_url': image_url,
    };
  }
}
