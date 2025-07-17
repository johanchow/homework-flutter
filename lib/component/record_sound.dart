import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

class RecordSoundWidget extends StatefulWidget {
  final Function(String)? onRecordingComplete;

  const RecordSoundWidget({super.key, this.onRecordingComplete});

  @override
  State<RecordSoundWidget> createState() => _RecordSoundWidgetState();
}

class _RecordSoundWidgetState extends State<RecordSoundWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限才能录音')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        const RecordConfig(),
        // config: RecordConfig(
        //   encoder: AudioEncoder.aacLc,
        //   bitRate: 128000,
        //   sampleRate: 44100,
        //   channel: 1,
        // ),
        path: _recordingPath!,
      );
      
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _hasRecording = false;
        _recordingDuration = Duration.zero;
      });
      
      // 开始计时
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音失败: $e')),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('暂停录音失败: $e')),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      setState(() {
        _isPaused = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复录音失败: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecording = true;
        _recordingPath = path;
      });
      
      if (widget.onRecordingComplete != null && path != null) {
        widget.onRecordingComplete!(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录音失败: $e')),
        );
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        _startTimer();
      }
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _player.setFilePath(_recordingPath!);
        await _player.play();
        setState(() {
          _isPlaying = true;
        });
        
        // 监听播放状态
        _player.playerStateStream.listen((state) {
          if (mounted && state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _playbackPosition = Duration.zero;
            });
          }
        });
        
        // 监听播放位置
        _player.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _playbackPosition = position;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRecording && _recordingPath != null) {
      // 显示录音文件
      return _buildRecordingFile();
    } else if (_isRecording) {
      // 显示录音控制按钮
      return _buildRecordingControls();
    } else {
      // 显示开始录音按钮
      return _buildStartButton();
    }
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            '语音作答',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic),
            label: const Text('开始录音'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '录音中... ${_formatDuration(_recordingDuration)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(_isPaused ? '继续' : '暂停'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('结束'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingFile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '录音文件',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '时长: ${_formatDuration(_recordingDuration)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _playRecording,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
            ],
          ),
          if (_isPlaying) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _recordingDuration.inMilliseconds > 0
                  ? _playbackPosition.inMilliseconds / _recordingDuration.inMilliseconds
                  : 0,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDuration(_playbackPosition)} / ${_formatDuration(_recordingDuration)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasRecording = false;
                    _recordingPath = null;
                    _recordingDuration = Duration.zero;
                    _playbackPosition = Duration.zero;
                    _isPlaying = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新录音'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
