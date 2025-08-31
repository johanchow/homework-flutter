import 'package:flutter/material.dart';
import 'tts_widget.dart';

/// TTSWidget 使用示例
class TTSWidgetUsageExample extends StatelessWidget {
  const TTSWidgetUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS组件使用示例'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TTS组件使用示例',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // 中文文本示例
            Text(
              '中文文本示例:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            TTSWidget(
              text: "这是一个中文文本语音合成示例。腾讯云语音合成技术可以将任意文本转化为语音，实现让机器和应用张口说话。",
              // 需要配置您的腾讯云凭证
              secretId: "your_secret_id",
              secretKey: "your_secret_key",
              // token: "your_token", // 如果使用临时密钥
            ),
            
            SizedBox(height: 30),
            
            // 英文文本示例
            Text(
              '英文文本示例:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            TTSWidget(
              text: "This is an English text-to-speech example. Tencent Cloud TTS can convert any text to speech with high quality.",
              primaryColor: Colors.green,
              fontSize: 14.0,
              // 需要配置您的腾讯云凭证
              secretId: "your_secret_id",
              secretKey: "your_secret_key",
            ),
            
            SizedBox(height: 30),
            
            // 混合语言示例
            Text(
              '混合语言示例:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            TTSWidget(
              text: "这是一个混合语言的示例。Hello, this is a mixed language example. 你好世界！",
              primaryColor: Colors.purple,
              fontSize: 16.0,
              padding: EdgeInsets.all(20.0),
              // 需要配置您的腾讯云凭证
              secretId: "your_secret_id",
              secretKey: "your_secret_key",
            ),
            
            SizedBox(height: 20),
            
            // 使用说明
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. 需要在初始化时提供腾讯云的secretId和secretKey'),
                    Text('2. 组件会自动检测文本语言（中文/英文）'),
                    Text('3. 支持语速调节（-2.0 到 2.0）'),
                    Text('4. 点击"合成播放"按钮开始语音合成'),
                    Text('5. 合成完成后会自动播放，也可以重复播放'),
                    Text('6. 播放过程中可以点击"停止"按钮停止播放'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
