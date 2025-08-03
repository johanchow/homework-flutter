import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsButtonWidget extends StatefulWidget {
  final String sentence;

  const TtsButtonWidget({super.key, required this.sentence});

  @override
  State<TtsButtonWidget> createState() => _TtsButtonWidgetState();
}

class _TtsButtonWidgetState extends State<TtsButtonWidget> {
  final FlutterTts flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // 设置播放完成监听器
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    flutterTts.setSpeechRate(0.45);
  }

  bool _containsChinese(String text) {
    // 中文字符范围 \u4e00-\u9fff
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  Future<void> _playAudio() async {
    if (_isPlaying || widget.sentence.trim().isEmpty) return;

    setState(() {
      _isPlaying = true;
    });

    await flutterTts.stop();

    // 自动判断语言
    final isChinese = _containsChinese(widget.sentence);
    await flutterTts.setLanguage(isChinese ? "zh-CN" : "en-US");

    await flutterTts.speak(widget.sentence).then((_) {
      print("Speech started successfully");
    }).catchError((e) {
      print("Error in speaking: $e");
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.sentence,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.green,
              size: 32,
            ),
            onPressed: _isPlaying ? null : _playAudio,
          ),
        ],
      ),
    );
  }
}

