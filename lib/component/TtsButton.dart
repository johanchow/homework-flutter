import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsButtonWidget extends StatefulWidget {
  final String sentence;

  const TtsButtonWidget({Key? key, required this.sentence}) : super(key: key);

  @override
  State<TtsButtonWidget> createState() => _TtsButtonWidgetState();
}

class _TtsButtonWidgetState extends State<TtsButtonWidget> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // 这里不设置语言，等点击时根据文本判断
  }

  Future<void> _speak() async {
    await flutterTts.stop();

    // 简单判断语言：如果包含中文字符，设置中文，否则英文
    final sentence = widget.sentence;
    final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(sentence);

    if (isChinese) {
      await flutterTts.setLanguage('zh-CN');
    } else {
      await flutterTts.setLanguage('en-US');
    }

    await flutterTts.speak(sentence);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS Button Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: _speak,
          child: Text(widget.sentence),
        ),
      ),
    );
  }
}
