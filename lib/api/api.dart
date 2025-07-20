import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/storage_manager.dart';

String get baseUrl {
  // final url = dotenv.env['API_BASE_URL'];
  final url = 'http://192.168.10.103:5556';
  if (url == null || url.isEmpty) {
    throw Exception('API_BASE_URL环境变量未设置');
  }
  return url;
}

// 获取请求头（包含token）
Future<Map<String, String>> getHttpHeaders() async {
  final token = await StorageManager.getToken();
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

// 统一的GET请求方法
Future<Map<String, dynamic>> httpGet(
  String endpoint, {
  Map<String, dynamic>? queryParameters,
}) async {
  final headers = await getHttpHeaders();
  final uri = Uri.parse('$baseUrl$endpoint').replace(
    queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
  );
  print('uri: $uri');
  try {
    final response = await http.get(uri, headers: headers);
    return handleHttpResponse(response);
  } catch (e) {
    throw Exception('网络请求失败: $e');
  }
}

// 统一的POST请求方法
Future<Map<String, dynamic>> httpPost(
  String endpoint, {
  Map<String, dynamic>? body,
}) async {
  try {
    final headers = await getHttpHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    print('http post uri: $uri');
    
    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    return handleHttpResponse(response);
  } catch (e) {
    throw Exception('网络请求失败: $e');
  }
}

// 处理响应数据
Map<String, dynamic> handleHttpResponse(http.Response response) {
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
void showApiError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// 显示成功提示
void showApiSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}