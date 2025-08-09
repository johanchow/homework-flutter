import 'dart:io';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/logger.dart';

class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  Future<void>? _initFuture;

  FlutterTts get tts => _flutterTts;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    _initFuture ??= _init();
    await _initFuture;
  }

  Future<void> _init() async {
    try {
      await _flutterTts.awaitSpeakCompletion(true);

      if (Platform.isIOS) {
        try {
          await _flutterTts.setSharedInstance(true);
        } catch (e) {
          logger.w('setSharedInstance failed: $e');
        }
      }

      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
    } catch (e) {
      logger.e('TTS global init failed: $e');
      rethrow;
    }
  }

  // 兼容实现：这里不再主动探测绑定，交由上层 speak 重试机制处理
  Future<void> waitUntilBound({Duration timeout = const Duration(seconds: 1)}) async {}

  Future<String> resolveLanguageForText(String text) async {
    final bool hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    return hasChinese ? 'zh-CN' : 'en-US';
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      logger.w('TTS stop failed: $e');
    }
  }

  Future<bool> speakWithRetries(String text) async {
    logger.i("speakWithRetries started for text: $text");
    if (text.trim().isEmpty) return false;
    
    logger.i("Ensuring TTS is initialized...");
    await ensureInitialized();
    logger.i("TTS initialization completed");

    final String lang = await resolveLanguageForText(text);
    logger.d("speakWithRetries lang: $lang");

    const int maxAttempts = 12;
    for (int i = 0; i < maxAttempts; i++) {
      logger.i("TTS speak attempt ${i + 1}/$maxAttempts");
      
      if (i > 0) {
        // 递增延时，给引擎更多绑定时间
        final delayMs = 300 + i * 100;
        logger.i("Waiting ${delayMs}ms before retry...");
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      
      // 使用 Completer 来处理异步回调
      final completer = Completer<bool>();
      bool callbackSet = false;
      
      // 设置错误处理回调
      _flutterTts.setErrorHandler((msg) {
        if (!callbackSet) {
          callbackSet = true;
          logger.w('TTS error callback: $msg');
          completer.complete(false);
        }
      });
      
      // 设置开始回调
      _flutterTts.setStartHandler(() {
        if (!callbackSet) {
          callbackSet = true;
          logger.i('TTS started successfully');
          completer.complete(true);
        }
      });
      
      try {
        // 先尝试简单的 speak（有些引擎会在 speak 时自动选择语言）
        if (i < 3) {
          // 前几次不设置语言，让引擎自动处理
          logger.i("Attempting speak without setting language (attempt ${i + 1})");
          await _flutterTts.speak(text);
        } else {
          // 后续尝试设置语言
          logger.i("Attempting speak with language $lang (attempt ${i + 1})");
          await _flutterTts.setLanguage(lang);
          await _flutterTts.speak(text);
        }
        
        // 等待回调结果，最多等待2秒
        final result = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            logger.w('TTS speak timeout on attempt ${i + 1}');
            return false;
          },
        );
        
        if (result) {
          logger.i('TTS speak success on attempt ${i + 1}');
          return true;
        } else {
          logger.w('TTS speak failed via callback on attempt ${i + 1}');
        }
        
      } catch (e) {
        logger.w('TTS speak exception on attempt ${i + 1}: $e');
      }
      
      // 如果到这里说明这次尝试失败了
      logger.w('TTS speak attempt ${i + 1} failed');
      
      // 先检查是否到达最大重试次数
      if (i == maxAttempts - 1) {
        logger.e('TTS speak failed after $maxAttempts attempts');
        return false;
      }
      
      // 在后续尝试中，尝试重新初始化
      if (i > 2) {
        logger.i('Attempting to re-initialize TTS due to repeated failures...');
        try {
          _isInitialized = false;
          await ensureInitialized();
          logger.i('TTS re-initialization completed');
        } catch (e2) {
          logger.w('Re-initialization failed: $e2');
        }
      }
      
      // 继续下一次重试
      logger.i('Will retry TTS speak (${i + 2}/${maxAttempts})...');
    }
    logger.e('All TTS speak attempts failed');
    return false;
  }
}


