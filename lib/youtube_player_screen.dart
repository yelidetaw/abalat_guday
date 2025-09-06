import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String youtubeId;
  final String title;
  final String description;
  final String heroTag;
  final Function(int)? onVideoComplete;

  const YoutubePlayerScreen({
    Key? key,
    required this.youtubeId,
    required this.title,
    required this.description,
    required this.heroTag,
    this.onVideoComplete,
  }) : super(key: key);

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  late int _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _controller = YoutubePlayerController(
      initialVideoId: widget.youtubeId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    final duration =
        (DateTime.now().millisecondsSinceEpoch - _startTime) ~/ 1000;
    widget.onVideoComplete?.call(duration);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Hero(
            tag: widget.heroTag,
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(widget.description),
            ),
          ),
        ],
      ),
    );
  }
}
