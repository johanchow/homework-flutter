import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../utils/storage_manager.dart';

class ApiService {
  static const String baseUrl = 'https://api.example.com'; // 替换为实际的API地址
  
  // 获取请求头（包含token）
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // 统一的GET请求方法
  static Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
      );
      
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }
  
  // 统一的POST请求方法
  static Future<Map<String, dynamic>> _post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }
  
  // 处理响应数据
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        throw Exception('响应数据为空');
      }
      
      final data = jsonDecode(response.body);
      
      // 检查业务状态码
      if (data['code'] != 0) {
        throw Exception(data['message'] ?? '请求失败');
      }
      
      return data;
    } else {
      throw Exception('HTTP错误: ${response.statusCode}');
    }
  }
  
  // 显示错误提示
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // 显示成功提示
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // ========== API 方法 ==========
  
  // 发送验证码
  static Future<bool> sendVerificationCode(String phone) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _post('/auth/send-code', body: {'phone': phone});
      // return response['success'] ?? false;
      
      // Mock返回
      return true;
    } catch (e) {
      throw Exception('发送验证码失败: $e');
    }
  }
  
  // 账号密码登录
  static Future<Map<String, dynamic>> loginWithPassword(String username, String password) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _post('/auth/login', body: {
      //   'username': username,
      //   'password': password,
      //   'login_type': 'password',
      // });
      
      // Mock返回
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 1,
          'username': username,
          'phone': '13800138000',
        }
      };
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }
  
  // 手机验证码登录
  static Future<Map<String, dynamic>> loginWithSms(String phone, String code) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _post('/auth/login', body: {
      //   'phone': phone,
      //   'code': code,
      //   'login_type': 'sms',
      // });
      
      // Mock返回
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 1,
          'username': '用户${phone.substring(7)}',
          'phone': phone,
        }
      };
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }
  
  // 账号密码注册
  static Future<Map<String, dynamic>> registerWithPassword(String username, String password) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _post('/auth/register', body: {
      //   'username': username,
      //   'password': password,
      //   'register_type': 'password',
      // });
      
      // Mock返回
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 1,
          'username': username,
          'phone': '13800138000',
        }
      };
    } catch (e) {
      throw Exception('注册失败: $e');
    }
  }
  
  // 手机验证码注册
  static Future<Map<String, dynamic>> registerWithSms(String phone, String code) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _post('/auth/register', body: {
      //   'phone': phone,
      //   'code': code,
      //   'register_type': 'sms',
      // });
      
      // Mock返回
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 1,
          'username': '用户${phone.substring(7)}',
          'phone': phone,
        }
      };
    } catch (e) {
      throw Exception('注册失败: $e');
    }
  }
  
  // 获取今日挑战列表
  static Future<List<Map<String, dynamic>>> getTodayChallenges() async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _get('/challenges/today');
      // return List<Map<String, dynamic>>.from(response['data'] ?? []);
      
      // Mock返回
      return [
        {
          'id': 1,
          'subject': '数学',
          'title': '高等数学练习',
          'start_time': '09:00',
          'duration': 120,
          'status': 'pending', // pending, in_progress, completed
        },
        {
          'id': 2,
          'subject': '英语',
          'title': '阅读理解训练',
          'start_time': '14:00',
          'duration': 90,
          'status': 'in_progress',
        },
        {
          'id': 3,
          'subject': '物理',
          'title': '力学计算题',
          'start_time': '16:00',
          'duration': 60,
          'status': 'completed',
        },
      ];
    } catch (e) {
      throw Exception('获取今日挑战失败: $e');
    }
  }
  
  // 获取历史挑战统计
  static Future<Map<String, dynamic>> getChallengeSummary() async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _get('/challenges/summary');
      // return response['data'] ?? {};
      
      // Mock返回
      return {
        'total_challenges': 156,
        'total_time': 23400, // 分钟
        'weekly_time': 420, // 分钟
      };
    } catch (e) {
      throw Exception('获取统计信息失败: $e');
    }
  }
  
  // 获取最近挑战列表
  static Future<List<Map<String, dynamic>>> getRecentChallenges() async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _get('/challenges/recent');
      // return List<Map<String, dynamic>>.from(response['data'] ?? []);
      
      // Mock返回
      return [
        {
          'id': 1,
          'subject': '数学',
          'title': '高等数学练习',
          'duration': 120,
          'completed_time': '2024-01-15 09:30',
        },
        {
          'id': 2,
          'subject': '英语',
          'title': '阅读理解训练',
          'duration': 90,
          'completed_time': '2024-01-14 14:20',
        },
        {
          'id': 3,
          'subject': '物理',
          'title': '力学计算题',
          'duration': 60,
          'completed_time': '2024-01-13 16:15',
        },
        {
          'id': 4,
          'subject': '化学',
          'title': '有机化学实验',
          'duration': 150,
          'completed_time': '2024-01-12 10:45',
        },
      ];
    } catch (e) {
      throw Exception('获取最近挑战失败: $e');
    }
  }
  
  // 获取挑战详情
  static Future<Map<String, dynamic>> getChallengeDetail(int challengeId) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _get('/challenges/$challengeId');
      // return response['data'] ?? {};
      
      // Mock返回
      return {
        'id': challengeId,
        'subject': '数学',
        'title': '高等数学练习',
        'description': '本次练习包含微积分、线性代数等知识点',
        'start_time': '09:00',
        'duration': 120,
        'status': 'pending',
        'questions': [
          {
            'id': 1,
            'type': 'choice',
            'content': '求函数f(x)=x²+2x+1的导数',
            'options': ['2x+2', '2x+1', 'x+2', 'x+1'],
            'answer': '2x+2',
          },
          {
            'id': 2,
            'type': 'fill',
            'content': '计算∫(2x+1)dx',
            'answer': 'x²+x+C',
          },
          {
            'id': 3,
            'type': 'essay',
            'content': '请解释微积分基本定理的含义',
            'answer': '',
          },
        ],
      };
    } catch (e) {
      throw Exception('获取挑战详情失败: $e');
    }
  }
} 