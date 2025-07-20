import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/storage_manager.dart';
import 'api.dart';

class UserApi {
  // 发送验证码
  static Future<bool> sendVerificationCode(String phone) async {
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 实际API调用
      // final response = await httpPost('/auth/send-code', body: {'phone': phone});
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
      // 实际API调用
      final response = await httpPost('/user/login', body: {
        'mode': 'name',
        'name': username,
        'password': password,
      });
      
      return {
        'token': response['data']['token'],
        'user': response['data']['user']
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
      // final response = await httpPost('/auth/login', body: {
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
      // final response = await httpPost('/auth/register', body: {
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
      // final response = await httpPost('/auth/register', body: {
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

  // 获取用户信息
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await httpGet('/user/info');
      return response['data'] ?? {};
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }

  // 更新用户信息
  static Future<bool> updateUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final response = await httpPost('/user/update', body: userInfo);
      return response['success'] ?? false;
    } catch (e) {
      throw Exception('更新用户信息失败: $e');
    }
  }

  // 修改密码
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await httpPost('/user/change-password', body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return response['success'] ?? false;
    } catch (e) {
      throw Exception('修改密码失败: $e');
    }
  }

  // 退出登录
  static Future<bool> logout() async {
    try {
      final response = await httpPost('/user/logout');
      return response['success'] ?? false;
    } catch (e) {
      throw Exception('退出登录失败: $e');
    }
  }
}
