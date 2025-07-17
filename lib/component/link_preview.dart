import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LinkPreviewWidget extends StatefulWidget {
  final String url;

  const LinkPreviewWidget({super.key, required this.url});

  @override
  State<LinkPreviewWidget> createState() => _LinkPreviewWidgetState();
}

class _LinkPreviewWidgetState extends State<LinkPreviewWidget> {
  bool _isLoading = true;
  String? _title;
  String? _description;
  String? _imageUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLinkPreview();
  }

  Future<void> _fetchLinkPreview() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final html = response.body;
        _parseHtml(html);
      } else {
        setState(() {
          _error = '无法获取链接信息';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '网络错误';
        _isLoading = false;
      });
    }
  }

  void _parseHtml(String html) {
    // 简化的HTML解析
    final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(html);
    final descriptionMatch = RegExp(r'<meta name="description" content="(.*?)"', caseSensitive: false).firstMatch(html);
    final imageMatch = RegExp(r'<meta property="og:image" content="(.*?)"', caseSensitive: false).firstMatch(html);
    
    setState(() {
      _title = titleMatch?.group(1)?.trim();
      _description = descriptionMatch?.group(1)?.trim();
      _imageUrl = imageMatch?.group(1)?.trim();
      _isLoading = false;
    });
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: ${widget.url}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _isLoading
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('正在获取链接信息...'),
              ],
            )
          : _error != null
              ? _buildErrorWidget()
              : _buildPreviewWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '链接预览失败',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _launchUrl,
          child: const Text('打开链接'),
        ),
      ],
    );
  }

  Widget _buildPreviewWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_title != null)
                    Text(
                      _title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    widget.url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _launchUrl,
              child: const Text('打开'),
            ),
          ],
        ),
        if (_description != null) ...[
          const SizedBox(height: 8),
          Text(
            _description!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (_imageUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              _imageUrl!,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
} 