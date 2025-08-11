import 'dart:async';
import 'package:asr_plugin/asr_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

typedef AsrResultCallback = void Function(String result, bool isFinal);

/// 语音识别服务封装（基于 asr_plugin）
/// - 负责配置鉴权、启动/停止识别
/// - 通过 resultStream 向外发布实时/最终识别文本
class AsrService {
  final ASRControllerConfig _config = ASRControllerConfig();
  ASRController? _controller;
  // 不再使用 listen 订阅，改为 await for 消费

  // 累积的句子结果，用于拼接 SLICE/SEGMENT 的中间态文本
  final List<String> _sentences = <String>[];

  // 最新识别文本
  String _currentResult = '';

  AsrResultCallback? _onResult;

  // 允许外部读取当前识别文本
  String get currentResult => _currentResult;

  AsrService(AsrResultCallback onResult, {Map<String, dynamic>? extraParams}) {
    // 构造时执行
    _onResult = onResult;
    initialize(extraParams: extraParams);
  }

  /// 初始化鉴权配置
  /// 需要由业务层传入腾讯云 ASR 的 appId/secretId/secretKey/token（token 可选）
  void initialize({
    Map<String, dynamic>? extraParams,
  }) {
    _config.appID = int.parse(dotenv.env['ASR_APP_ID'] ?? '0');
    _config.secretID = dotenv.env['ASR_SECRET_ID'] ?? '';
    _config.secretKey = dotenv.env['ASR_SECRET_KEY'] ?? '';
    // _config.token = dotenv.env['ASR_TOKEN'] ?? '';
    // 更多参数设置： https://cloud.tencent.com/document/product/1093/86888
    // _config.setCustomParam('emotion_recognition', 2); // 情绪识别
    if (extraParams != null) {
      for (final entry in extraParams.entries) {
        _config.setCustomParam(entry.key, entry.value);
      }
    }
  }

  /// 启动识别（按官方示例使用 await for 消费识别流）
  Future<void> start() async {
    // 清空历史
    _currentResult = '';
    _sentences.clear();

    try {
      // 释放上一次实例
      if (_controller != null) {
        await _controller!.release();
      }

      _controller = await _config.build();
      final Stream<ASRData> asrStream = _controller!.recognize();
      await for (final ASRData data in asrStream) {
        switch (data.type) {
          case ASRDataType.SLICE:
          case ASRDataType.SEGMENT:
            final int id = data.id ?? 0;
            final String res = data.res ?? '';
            while (_sentences.length <= id) {
              _sentences.add('');
            }
            _sentences[id] = res;
            _currentResult = _sentences.join('');
            _onResult?.call(_currentResult, false);
            break;
          case ASRDataType.SUCCESS:
            _currentResult = data.result ?? _sentences.join('');
            _sentences.clear();
            _onResult?.call(_currentResult, true);
            break;
          case ASRDataType.NOTIFY:
            logger.i('[AsrService] notify: ${data.info}');
            break;
        }
      }
    } on ASRError catch (e) {
      logger.e('ASR错误码：${e.code} 错误信息: ${e.message}'); 
      rethrow;
    }
  }

  /// 停止识别
  Future<void> stop() async {
    try {
      await _controller?.stop();
    } catch (e) {
      logger.e('[AsrService] stop error: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      await _controller?.release();
    } catch (_) {}
  }
}
