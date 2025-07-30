import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _sessionIdPrefix = 'session_id_';
  
  // 保存token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
  }
  
  // 获取token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // 保存用户信息
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo));
  }
  
  // 获取用户信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString) as Map<String, dynamic>;
    }
    return null;
  }
  
  // 检查是否已登录
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  // 清除所有登录信息
  static Future<void> clearLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
  
  // 登出
  static Future<void> logout() async {
    await clearLoginInfo();
  }
  
  // 保存session_id
  static Future<void> saveSessionId(String examId, String questionId, String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionIdPrefix${examId}_$questionId';
    await prefs.setString(key, sessionId);
  }
  
  // 获取session_id
  static Future<String?> getSessionId(String examId, String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionIdPrefix${examId}_$questionId';
    return prefs.getString(key);
  }
  
  // 清除特定题目的session_id
  static Future<void> clearSessionId(String examId, String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionIdPrefix${examId}_$questionId';
    await prefs.remove(key);
  }
  
  // 清除所有session_id
  static Future<void> clearAllSessionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_sessionIdPrefix)) {
        await prefs.remove(key);
      }
    }
  }
} 