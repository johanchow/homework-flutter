import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tts_plugin/tts_plugin.dart';

class TTSWidget extends StatefulWidget {
  final String text;
  final Color? primaryColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const TTSWidget({
    super.key,
    required this.text,
    this.primaryColor,
    this.fontSize = 16.0,
    this.padding,
  });

  @override
  State<TTSWidget> createState() => _TTSWidgetState();
}

class _TTSWidgetState extends State<TTSWidget> {
  late TTSControllerConfig _config;
  late AudioPlayer _player;
  late StreamSubscription<TTSData> _subscription;
  
  String _status = "待播放";
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _audioFilePath;
  double _speechRate = 0.0; // 默认语速
  
  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _initializeAudioPlayer();
    _setupTTSListener();
  }

  void _initializeConfig() {
    _config = TTSControllerConfig();
    // 设置基本配置
    _config.secretId = dotenv.env['TTS_SECRET_ID'] ?? '';
    _config.secretKey = dotenv.env['TTS_SECRET_KEY'] ?? '';
    _config.voiceSpeed = _speechRate;
    _config.voiceVolume = 1.0;
    _config.voiceType = 101004; // 智云(精品-男)
    _config.voiceLanguage = _detectLanguage(widget.text);
    _config.codec = "mp3";
  }

  void _initializeAudioPlayer() {
    final AudioContext audioContext = AudioContext(
        iOS: AudioContextIOS(
          // defaultToSpeaker: true,
          category: AVAudioSessionCategory.playAndRecord,
          options: [
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          ],
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ));
    AudioPlayer.global.setGlobalAudioContext(audioContext);
    _player = AudioPlayer();
    _player.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _status = "播放完成";
      });
    });
  }

  void _setupTTSListener() {
    _subscription = TTSController.instance.listener.handleError((error) {
      if (error is TTSError) {
        setState(() {
          _status = "错误: ${error.message}";
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = "未知错误: $error";
          _isLoading = false;
        });
      }
    }).listen((ttsData) async {
      try {
        // 保存音频文件
        final dir = await getTemporaryDirectory();
        final file = await File(
          "${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.${_config.codec}"
        ).writeAsBytes(ttsData.data);
        
        setState(() {
          _audioFilePath = file.absolute.path;
          _status = "合成完成";
          _isLoading = false;
        });
        
        // 自动播放
        await _playAudio();
      } catch (e) {
        setState(() {
          _status = "保存音频失败: $e";
          _isLoading = false;
        });
      }
    });
  }

  int _detectLanguage(String text) {
    // 检测是否包含中文字符
    final bool hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    return hasChinese ? 1 : 2; // 1=中文, 2=英文
  }

  Future<void> _synthesizeAndPlay() async {
    if (widget.text.trim().isEmpty) {
      setState(() {
        _status = "文本为空";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "合成中...";
      _audioFilePath = null;
    });

    try {
      // 停止当前播放
      await _player.stop();
      
      // 设置配置
      TTSController.instance.config = _config;
      
      // 开始合成
      await TTSController.instance.synthesize(widget.text, null);
    } catch (e) {
      setState(() {
        _status = "合成失败: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio() async {
    if (_audioFilePath == null) return;

    try {
      await _player.setSourceDeviceFile(_audioFilePath!);
      await _player.resume();
      setState(() {
        _isPlaying = true;
        _status = "播放中...";
      });
    } catch (e) {
      setState(() {
        _status = "播放失败: $e";
      });
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player.stop();
      setState(() {
        _isPlaying = false;
        _status = "已停止";
      });
    } catch (e) {
      setState(() {
        _status = "停止失败: $e";
      });
    }
  }

  void _updateSpeechRate(double rate) {
    setState(() {
      _speechRate = rate;
      _config.voiceSpeed = rate;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 文本显示区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // 语速控制
          Row(
            children: [
              const Text("语速: ", style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: Slider(
                  value: _speechRate,
                  min: -2.0,
                  max: 2.0,
                  divisions: 40,
                  label: _speechRate.toStringAsFixed(1),
                  onChanged: _updateSpeechRate,
                ),
              ),
              Text(_speechRate.toStringAsFixed(1)),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // 控制按钮和状态
          Row(
            children: [
              // 播放/合成按钮
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                  if (_audioFilePath != null && !_isPlaying) {
                    _playAudio();
                  } else {
                    _synthesizeAndPlay();
                  }
                },
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_audioFilePath != null && !_isPlaying 
                      ? Icons.play_arrow 
                      : Icons.volume_up),
                label: Text(_audioFilePath != null && !_isPlaying ? "播放" : "合成播放"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(width: 8.0),
              
              // 停止按钮
              if (_isPlaying)
                ElevatedButton.icon(
                  onPressed: _stopAudio,
                  icon: const Icon(Icons.stop),
                  label: const Text("停止"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              
              const SizedBox(width: 16.0),
              
              // 状态显示
              Expanded(
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains("错误") || _status.contains("失败") 
                      ? Colors.red 
                      : Colors.grey.shade600,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
