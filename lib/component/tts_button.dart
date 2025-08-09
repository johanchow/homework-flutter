import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/logger.dart';
import '../services/tts_service.dart';

class TtsButtonWidget extends StatefulWidget {
  final String sentence;

  const TtsButtonWidget({super.key, required this.sentence});

  @override
  State<TtsButtonWidget> createState() => _TtsButtonWidgetState();
}

class _TtsButtonWidgetState extends State<TtsButtonWidget> {
  final FlutterTts flutterTts = TtsService.instance.tts;
  bool _isPlaying = false;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initTts();
  }

  Future<void> _initTts() async {
    try {
      await TtsService.instance.ensureInitialized();

      // 事件监听器
      flutterTts.setStartHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
        });
      });

      flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });

      flutterTts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });

      flutterTts.setErrorHandler((msg) {
        logger.e('TTS Error: $msg');
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });
    } catch (e) {
      logger.e('TTS init failed: $e');
    }
  }

  // 由全局 TTS 服务进行语言解析，这里不再需要局部中文检测

  Future<void> _playAudio() async {
    logger.i("playAudio: ${widget.sentence}");
    if (widget.sentence.trim().isEmpty) return;

    // 确保初始化完成
    await (_initFuture ?? Future.value());

    if (_isPlaying) {
      await TtsService.instance.stop();
    }

    final ok = await TtsService.instance.speakWithRetries(widget.sentence);
    if (mounted) {
      setState(() {
        _isPlaying = ok;
      });
    }
  }

  Future<void> _stopAudio() async {
    try {
      await flutterTts.stop();
    } finally {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _stopAudio();
    } else {
      await _playAudio();
    }
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
            onPressed: _togglePlay,
          ),
        ],
      ),
    );
  }
}

