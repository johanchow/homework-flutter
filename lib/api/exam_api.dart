import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/storage_manager.dart';
import 'api.dart';
import '../entity/exam.dart';

class ExamApi {
  // 获取历史挑战统计
  static Future<Map<String, dynamic>> getExamSummary() async {
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

  static Future<List<Exam>> listTodayExams() async {
    late final Map<String, dynamic> response;
    try {
      response = await httpGet('/exam/list',queryParameters: {
        'page': 1, 'page_size': 10,
        // 今天0点
        // 'plan_starttime_from': DateTime.now().toIso8601String().split('T')[0],
        // 明天0点
        // 'plan_starttime_to': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0]
      });
      // 将API响应转换为Exam对象列表
    } catch (e, stack) {
      print('📍 堆栈信息:\n$stack');
      throw Exception('获取今日挑战失败: $e');
    }
    final List<dynamic> examData = response['data'] ?? [];
    return examData.map((data) => Exam.fromJson(data)).toList();
  }
  
  // 获取最近挑战列表
  static Future<List<Exam>> listHistoryExams({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await httpGet('/exam/list', queryParameters: {
        'page': 1, 'page_size': 10,
        // 今日0点
        'plan_starttime_to': DateTime.now().toIso8601String().split('T')[0],
      });
      
      // 将API响应转换为Exam对象列表
      final List<dynamic> examData = response['data'] ?? [];
      return examData.map((data) => Exam.fromJson(data)).toList();
    } catch (e) {
      throw Exception('获取最近挑战失败: $e');
    }
  }
  
  // 获取挑战详情
  static Future<Map<String, dynamic>> getExamDetail(int examId) async {
    try {
      final response = await httpGet('/exam/get', queryParameters: {
        'id': examId,
      });
      return response['data'] ?? {};
    } catch (e) {
      throw Exception('获取挑战详情失败: $e');
    }
  }
}
