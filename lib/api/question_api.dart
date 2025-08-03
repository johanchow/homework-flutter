import 'dart:convert';
import 'api.dart';
import '../entity/question.dart';
import '../entity/session.dart';

class QuestionApi {
  static Future<Question> getQuestion(String questionId) async {
    final response = await httpGet('/question/get', queryParameters: {
      'id': questionId,
    });
    final question = Question.fromJson(response['data'] ?? {});
    print('httpGet question: $question');
    return question;
  }

  static Future<Map<String, String>> getQuestionGuide(Map<String, String> params) async {
    final response = await httpPost('/ai/guide-question', body: {
      'question_id': params['question_id'],
      'new_message': params['new_message'],
      'session_id': params['session_id'],
    });
    String sessionId = response['data']['session_id'] ?? '';
    String aiMessage = response['data']['ai_message'] ?? '';
    return {
      'session_id': sessionId,
      'ai_message': aiMessage,
    };
  }
}
