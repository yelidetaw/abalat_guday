import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ArticleReaderScreen extends StatefulWidget {
  final String title;
  final String body;
  final String heroTag;
  final String? imageUrl;
  final int resourceId;
  final Function(int)? onReadingComplete;

  const ArticleReaderScreen({
    Key? key,
    required this.title,
    required this.body,
    required this.heroTag,
    this.imageUrl,
    required this.resourceId,
    this.onReadingComplete,
  }) : super(key: key);

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  late int _startTime;
  final ScrollController _scrollController = ScrollController();
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _scrollController.addListener(_checkReadingProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkReadingProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkReadingProgress() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final scrollPercentage = (currentScroll / maxScroll) * 100;

    if (scrollPercentage > 90 && !_isComplete) {
      _isComplete = true;
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final durationSeconds = ((endTime - _startTime) / 1000).round();

      if (widget.onReadingComplete != null) {
        widget.onReadingComplete!(durationSeconds);
      }
    }
  }

  Future<void> _shareArticle() async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        '${widget.title}\n\n${widget.body}\n\nShared from Learning App',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }

  Future<void> _saveToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: '${widget.title}\n\n${widget.body}'),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareArticle),
          IconButton(icon: const Icon(Icons.copy), onPressed: _saveToClipboard),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            if (widget.imageUrl != null)
              Hero(
                tag: widget.heroTag,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
