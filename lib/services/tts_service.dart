import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/logger.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  FlutterTts get tts => _flutterTts;

  TtsService() {
    _init();
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _init();
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
      await _flutterTts.setSpeechRate(0.3);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
    } catch (e) {
      logger.e('TTS init failed: $e');
      rethrow;
    }
  }

  String resolveLanguageForText(String text) {
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

  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;
    
    try {
      await ensureInitialized();
      final String lang = resolveLanguageForText(text);
      final String adjustedText;
      if (lang == 'zh-CN') {
        // 在每个字之间插入空格，效果类似逐字发音
        adjustedText = text.split("").join(" ");
      } else {
        // 英文单词之间插入短停顿
        adjustedText = text.split(" ").join(", ");
      }
      await _flutterTts.setLanguage(lang);
      await _flutterTts.speak(adjustedText);
      return true;
    } catch (e) {
      logger.e('TTS speak failed: $e');
      return false;
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}


