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
  late final TtsService _ttsService;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _ttsService = TtsService();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _ttsService.ensureInitialized();
      
      // 设置事件监听器
      _ttsService.tts.setStartHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
        });
      });

      _ttsService.tts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });

      _ttsService.tts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });

      _ttsService.tts.setErrorHandler((msg) {
        logger.e('TTS Error: $msg');
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      logger.e('TTS init failed: $e');
    }
  }

  Future<void> _playAudio() async {
    if (widget.sentence.trim().isEmpty || !_isInitialized) return;

    if (_isPlaying) {
      await _stopAudio();
      return;
    }

    final success = await _ttsService.speak(widget.sentence);
    if (mounted && !success) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _ttsService.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
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
            onPressed: _isInitialized ? _playAudio : null,
          ),
        ],
      ),
    );
  }
}

