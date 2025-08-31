import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('初始化视频播放器: ${widget.videoUrl}');
      
      // 检查是否为本地文件，如果是则验证文件是否存在
      if (!_isNetworkUrl(widget.videoUrl)) {
        final file = File(widget.videoUrl);
        if (!await file.exists()) {
          setState(() {
            _errorMessage = '视频文件不存在: ${widget.videoUrl}';
            _isLoading = false;
          });
          return;
        }
        final fileSize = await file.length();
        print('本地视频文件存在，大小: $fileSize 字节');
        
        if (fileSize == 0) {
          setState(() {
            _errorMessage = '视频文件为空: ${widget.videoUrl}';
            _isLoading = false;
          });
          return;
        }
      }

      // 创建视频播放器控制器
      if (_isNetworkUrl(widget.videoUrl)) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.videoUrl));
      }

      // 初始化视频播放器
      await _videoPlayerController!.initialize();
      
      // 创建 Chewie 控制器提供友好的播放控制
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '视频播放错误',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
      
      print('视频播放器初始化成功，视频时长: ${_videoPlayerController!.value.duration}');
    } catch (e) {
      print('视频播放器初始化失败: $e');
      setState(() {
        _errorMessage = '视频播放器初始化失败: $e';
        _isLoading = false;
      });
    }
  }

  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildVideoWidget(),
      ),
    );
  }

  Widget _buildVideoWidget() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                '正在加载视频...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                '视频加载失败',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeVideoPlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          '视频播放器未初始化',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}