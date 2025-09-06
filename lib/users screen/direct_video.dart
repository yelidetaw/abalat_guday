// lib/screens/direct_video_player.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DirectVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String heroTag;
  final Function(int)? onVideoComplete;

  const DirectVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.heroTag,
    this.onVideoComplete,
  });

  @override
  State<DirectVideoPlayerScreen> createState() =>
      _DirectVideoPlayerScreenState();
}

class _DirectVideoPlayerScreenState extends State<DirectVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  late int _startTime;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
        }).catchError((e, stackTrace) {
          debugPrint('Error initializing video player: $e');
          debugPrint('StackTrace: $stackTrace');
          if (mounted) setState(() => _hasError = true);
        });

      _controller.addListener(() {
        if (!mounted) return;
        if (_controller.value.hasError) {
          debugPrint(
              'Video Player Error: ${_controller.value.errorDescription}');
          if (!_hasError) setState(() => _hasError = true);
        }
        if (_controller.value.isPlaying != _isPlaying) {
          setState(() => _isPlaying = _controller.value.isPlaying);
        }
        if (_controller.value.position == _controller.value.duration &&
            widget.onVideoComplete != null) {
          final endTime = DateTime.now().millisecondsSinceEpoch;
          final durationSeconds = ((endTime - _startTime) / 1000).round();
          widget.onVideoComplete!(durationSeconds);
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Could not create video player controller: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 8),
                  Text('Could not play video',
                      style: TextStyle(color: Colors.white)),
                ],
              )
            : _controller.value.isInitialized
                ? Hero(
                    tag: widget.heroTag,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          VideoProgressIndicator(_controller,
                              allowScrubbing: true),
                          _buildPlayPauseOverlay(),
                        ],
                      ),
                    ),
                  )
                : CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play()),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 200),
        child: _controller.value.isPlaying
            ? const SizedBox.shrink()
            : Container(
                color: Colors.black26,
                child: Center(
                  child: Icon(Icons.play_arrow,
                      color: Colors.white,
                      size: 80.0,
                      key: ValueKey<bool>(_controller.value.isPlaying)),
                ),
              ),
      ),
    );
  }
}
