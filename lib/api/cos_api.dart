import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../utils/storage_manager.dart';
import '../utils/logger.dart';

class CosApi {
  // 腾讯云 COS 配置
  static final String _secretId = dotenv.env['COS_SECRET_ID'] ?? '';
  static final String _secretKey = dotenv.env['COS_SECRET_KEY'] ?? '';
  static final String _region = dotenv.env['COS_REGION'] ?? '';
  static final String _bucketName = dotenv.env['COS_BUCKET_NAME'] ?? '';
  // static const String _appId = 'YOUR_APP_ID'; // 替换为你的 AppId

  /// 上传图片到腾讯云 COS
  /// [filePath] 本地图片文件路径
  /// [fileName] 可选的文件名，如果不提供则使用时间戳生成
  /// 返回上传后的图片 URL
  static Future<String> uploadImage(String filePath, {String? fileName}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final userInfo = await StorageManager.getUserInfo();
      final userId = userInfo?['id'];

      // 生成文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = filePath.split('.').last;
      final finalFileName = fileName ?? '$timestamp.$extension';
      final key = 'homework-mentor/${userId??'anonymous'}/$finalFileName';

      // 读取文件内容
      final bytes = await file.readAsBytes();
      final contentLength = bytes.length;

      // 计算必要头并生成签名（参考官方文档：https://cloud.tencent.com/document/product/436/7778）
      final host = '$_bucketName.cos.$_region.myqcloud.com';
      final date = getGMTDate();
      final contentMd5 = base64Encode(md5.convert(bytes).bytes);
      final contentType = 'image/$extension';

      // 参与签名的 header 需要使用小写 key，并进行 URL 编码
      final headersForSign = <String, String>{
        'host': host,
        'date': date,
        'content-type': contentType,
        'content-length': contentLength.toString(),
        'content-md5': contentMd5,
      };

      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final startTime = nowSec;
      final endTime = nowSec + 3600; // 1 小时有效期

      // 注意：签名中的 path 不包含 bucket，只有对象路径
      final authorization = _generateSignature(
        method: 'PUT',
        path: '/$key',
        headers: headersForSign,
        queryParams: const {},
        startTime: startTime,
        endTime: endTime,
      );

      // 实际请求头（大小写不限，签名计算已用小写）
      final headers = {
        'Authorization': authorization,
        'Content-Type': contentType,
        'Content-Length': contentLength.toString(),
        'Content-MD5': contentMd5,
        'Date': date,
        'Host': host,
      };

      // 构建 COS 上传 URL
      final url = 'https://$host/$key';

      // 发送上传请求
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );

      if (response.statusCode == 200) {
        // 返回可访问的图片 URL
        String url = 'https://$_bucketName.cos.$_region.myqcloud.com/$key';
        logger.i('上传图片成功: $url');
        return url;
      } else {
        logger.e('上传图片失败: ${response.statusCode} - ${response.body}');
        throw Exception('上传失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('上传图片异常: $e');
      throw Exception('上传图片异常: $e');
    }
  }

  /// 生成腾讯云 COS Authorization（V5）
  /// 参考文档：https://cloud.tencent.com/document/product/436/7778
  static String _generateSignature({
    required String method,                // 如 "PUT"、"GET"（不区分大小写）
    required String path,                  // 对象路径，例如 "/folder/object.jpg"
    required Map<String, String> headers,  // 参与签名的 header（小写 key）
    Map<String, String>? queryParams,      // 参与签名的 URL 参数
    required int startTime,                // 开始时间（Unix 秒）
    required int endTime,                  // 结束时间（Unix 秒）
  }) {
    final keyTime = '$startTime;$endTime';

    // 规范化 header：按 key 排序，值进行 URL 编码
    final sortedHeaderKeys = headers.keys
        .map((k) => k.toLowerCase().trim())
        .toSet()
        .toList()
      ..sort();
    final headerList = sortedHeaderKeys.join(';');

    final sbHeaders = <String>[];
    for (final key in sortedHeaderKeys) {
      final originalValue = headers[key] ?? '';
      final value = Uri.encodeComponent(originalValue.trim());
      sbHeaders.add('$key=$value');
    }
    final httpHeaders = sbHeaders.join('&');

    // 规范化 URL 参数
    final qp = queryParams ?? const {};
    final paramList = qp.keys
        .map((k) => k.toLowerCase().trim())
        .toSet()
        .toList()
      ..sort();
    final urlParamList = paramList.join(';');
    final httpParams = paramList
        .map((k) => '$k=${Uri.encodeComponent((qp[k] ?? '').trim())}')
        .join('&');

    final httpString = StringBuffer()
      ..write(method.toLowerCase())
      ..write('\n')
      ..write(path)
      ..write('\n')
      ..write(httpParams)
      ..write('\n')
      ..write(httpHeaders)
      ..write('\n');

    final sha1HttpString = sha1.convert(utf8.encode(httpString.toString())).toString();

    final stringToSign = 'sha1\n$keyTime\n$sha1HttpString\n';

    final signKey = Hmac(sha1, utf8.encode(_secretKey))
        .convert(utf8.encode(keyTime))
        .toString();

    final signature = Hmac(sha1, utf8.encode(signKey))
        .convert(utf8.encode(stringToSign))
        .toString();

    final auth = StringBuffer()
      ..write('q-sign-algorithm=sha1')
      ..write('&q-ak=$_secretId')
      ..write('&q-sign-time=$keyTime')
      ..write('&q-key-time=$keyTime')
      ..write('&q-header-list=$headerList')
      ..write('&q-url-param-list=$urlParamList')
      ..write('&q-signature=$signature');

    return auth.toString();
  }

  /// 删除腾讯云 COS 中的文件
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // 从 URL 中提取 key
      final uri = Uri.parse(imageUrl);
      final key = uri.path.substring(1); // 移除开头的 '/'

      final host = '$_bucketName.cos.$_region.myqcloud.com';
      final date = getGMTDate();
      final headersForSign = <String, String>{
        'host': host,
        'date': date,
      };
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final authorization = _generateSignature(
        method: 'DELETE',
        path: '/$key',
        headers: headersForSign,
        queryParams: const {},
        startTime: nowSec,
        endTime: nowSec + 3600,
      );

      final headers = {
        'Authorization': authorization,
        'Host': host,
        'Date': date,
      };

      // 发送删除请求
      final response = await http.delete(
        Uri.parse(imageUrl),
        headers: headers,
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      throw Exception('删除图片失败: $e');
    }
  }

  /// 获取图片信息
  static Future<Map<String, dynamic>> getImageInfo(String imageUrl) async {
    try {
      // 从 URL 中提取 key
      final uri = Uri.parse(imageUrl);
      final key = uri.path.substring(1);

      final host = '$_bucketName.cos.$_region.myqcloud.com';
      final date = getGMTDate();
      final headersForSign = <String, String>{
        'host': host,
        'date': date,
      };
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final authorization = _generateSignature(
        method: 'HEAD',
        path: '/$key',
        headers: headersForSign,
        queryParams: const {},
        startTime: nowSec,
        endTime: nowSec + 3600,
      );

      final headers = {
        'Authorization': authorization,
        'Host': host,
        'Date': date,
      };

      // 发送 HEAD 请求获取文件信息
      final response = await http.head(
        Uri.parse(imageUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'contentLength': response.headers['content-length'],
          'contentType': response.headers['content-type'],
          'lastModified': response.headers['last-modified'],
          'etag': response.headers['etag'],
        };
      } else {
        throw Exception('获取图片信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取图片信息失败: $e');
    }
  }
}

String getGMTDate() {
  final now = DateTime.now().toUtc();

  // 星期缩写，周日是第7天，但DateTime.weekday 1=周一，7=周日
  const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // 月份缩写，1月是0索引
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final wd = weekDays[now.weekday - 1]; // weekday 1-7
  final day = now.day.toString().padLeft(2, '0');
  final month = months[now.month - 1];
  final year = now.year.toString();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');

  return '$wd, $day $month $year $hour:$minute:$second GMT';
}
