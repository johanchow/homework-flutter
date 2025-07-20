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
  
  // 获取今日挑战列表
  static Future<List<Map<String, dynamic>>> getTodayChallenges() async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      final response = await _get('/exam/list',queryParameters: {
        'page': 1, 'page_size': 10,
        // 今天0点
        'plan_starttime_from': DateTime.now().toIso8601String().split('T')[0],
        // 明天0点
        'plan_starttime_to': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0]
      });
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
      
      // Mock返回
      /*
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
      */
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
      final response = await _get('/exam/list', queryParameters: {
        'page': 1, 'page_size': 10,
        // 今日0点
        'plan_starttime_to': DateTime.now().toIso8601String().split('T')[0],
      });
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
      
      // Mock返回
      // return [
      //   {
      //     'id': 1,
      //     'subject': '数学',
      //     'title': '高等数学练习',
      //     'duration': 120,
      //     'completed_time': '2024-01-15 09:30',
      //   },
      //   {
      //     'id': 2,
      //     'subject': '英语',
      //     'title': '阅读理解训练',
      //     'duration': 90,
      //     'completed_time': '2024-01-14 14:20',
      //   },
      //   {
      //     'id': 3,
      //     'subject': '物理',
      //     'title': '力学计算题',
      //     'duration': 60,
      //     'completed_time': '2024-01-13 16:15',
      //   },
      //   {
      //     'id': 4,
      //     'subject': '化学',
      //     'title': '有机化学实验',
      //     'duration': 150,
      //     'completed_time': '2024-01-12 10:45',
      //   },
      // ];
    } catch (e) {
      throw Exception('获取最近挑战失败: $e');
    }
  }
  
  // 获取挑战详情
  static Future<Map<String, dynamic>> getChallengeDetail(String challengeId) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await _get('/challenges/$challengeId');
      // return response['data'] ?? {};
      
      // Mock返回 - 根据challengeId返回不同的数据
      if (challengeId == 1) {
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
              'title': '求函数f(x)=x²+2x+1的导数',
              'options': ['2x+2', '2x+1', 'x+2', 'x+1'],
            },
            {
              'id': 2,
              'type': 'fill',
              'title': '计算∫(2x+1)dx',
              'images': ['https://www.baidu.com/img/PCtm_d9c8750bed0b3c7d089fa7d55720d6cf.png'],
              'links': ['https://www.iqiyi.com/v_cqgw7gjol0.html'],
            },
            {
              'id': 3,
              'type': 'qa',
              'title': '请解释微积分基本定理的含义',
              'attachments': ['https://clothing-try-on-1306401232.cos.ap-guangzhou.myqcloud.com/homework-mentor/1752648300-1b_13.pdf'],
            },
            {
              'id': 4,
              'type': 'reading',
              'title': '读一读',
              'answer': 'This is a reading question \n I want to go to the park',
            },
            {
              'id': 5,
              'type': 'summary',
              'title': '总结',
              'videos': ['https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'],
            },
            
          ],
        };
      } else if (challengeId == 2) {
        return {
          'id': challengeId,
          'subject': '英语',
          'title': '阅读理解训练',
          'description': '通过阅读文章提高英语理解能力',
          'start_time': '14:00',
          'duration': 90,
          'status': 'in_progress',
          'questions': [
            {
              'id': 1,
              'type': 'choice',
              'title': 'What is the main idea of the passage?',
              'options': ['Technology advancement', 'Environmental protection', 'Economic development', 'Social progress'],
              'answer': 'Technology advancement',
            },
            {
              'id': 2,
              'type': 'choice',
              'title': 'According to the text, which statement is correct?',
              'options': ['eat', 'sleep', 'code', 'play'],
              'answer': 'code',
            },
          ],
        };
      } else if (challengeId == 3) {
        return {
          'id': challengeId,
          'subject': '物理',
          'title': '力学计算题',
          'description': '涉及牛顿力学和运动学计算',
          'start_time': '16:00',
          'duration': 60,
          'status': 'completed',
          'questions': [
            {
              'id': 1,
              'type': 'choice',
              'title': '一个物体从静止开始做匀加速直线运动，加速度为2m/s²，5秒后的速度是多少？',
              'options': ['5m/s', '10m/s', '15m/s', '20m/s'],
              'answer': '10m/s',
              'images': ['https://www.baidu.com/img/PCtm_d9c8750bed0b3c7d089fa7d55720d6cf.png'],
            },
            {
              'id': 2,
              'type': 'fill',
              'title': '计算物体在重力作用下的自由落体运动，从10米高度落下需要多长时间？',
              'answer': '1.43s',
            },
          ],
        };
      } else if (challengeId == 4) {
        return {
          'id': challengeId,
          'subject': '化学',
          'title': '有机化学实验',
          'description': '学习有机化学实验操作和原理',
          'start_time': '10:00',
          'duration': 150,
          'status': 'pending',
          'questions': [
            {
              'id': 1,
              'type': 'qa',
              'title': '请阅读实验手册，回答以下问题：有机化学实验的安全注意事项有哪些？',
              'answer': '',
              'attachments': ['https://clothing-try-on-1306401232.cos.ap-guangzhou.myqcloud.com/homework-mentor/1752648300-1b_13.pdf'],
            },
            {
              'id': 2,
              'type': 'choice',
              'title': '在有机化学实验中，以下哪种操作是正确的？',
              'options': ['直接用手接触化学试剂', '在通风橱中进行实验', '将废液倒入下水道', '在实验室内饮食'],
              'answer': '在通风橱中进行实验',
            },
          ],
        };
      } else {
        // 默认返回
        return {
          'id': challengeId,
          'subject': '综合',
          'title': '综合练习',
          'description': '包含多种题型的综合练习',
          'start_time': '10:00',
          'duration': 120,
          'status': 'pending',
          'questions': [
            {
              'id': 1,
              'type': 'choice',
              'content': '这是一道选择题',
              'options': ['选项A', '选项B', '选项C', '选项D'],
              'answer': '选项A',
            },
          ],
        };
      }
    } catch (e) {
      throw Exception('获取挑战详情失败: $e');
    }
  }
} 