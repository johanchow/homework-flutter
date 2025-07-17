import 'package:flutter/material.dart';

class TtsButtonWidget extends StatefulWidget {
  final String sentence;

  const TtsButtonWidget({super.key, required this.sentence});

  @override
  State<TtsButtonWidget> createState() => _TtsButtonWidgetState();
}

class _TtsButtonWidgetState extends State<TtsButtonWidget> {
  bool _isPlaying = false;

  void _playAudio() {
    setState(() {
      _isPlaying = true;
    });

    // 模拟播放音频
    Future.delayed(const Duration(seconds:2), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
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
            size:24,
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
