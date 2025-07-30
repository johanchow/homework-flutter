import 'dart:convert';
import 'api.dart';
import '../entity/session.dart';

class SessionApi {
  static Future<Session> getSession(String sessionId) async {
    final response = await httpGet('/session/get', queryParameters: {
      'id': sessionId,
    });
    final session = Session.fromJson(response['data'] ?? {});
    return session;
  }
}
