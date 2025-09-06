import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String youtubeId;
  final String title;
  final String description;
  final String heroTag;
  final Function(int)? onVideoComplete;

  const YoutubePlayerScreen({
    super.key,
    required this.youtubeId,
    required this.title,
    required this.description,
    required this.heroTag,
    this.onVideoComplete,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  late int _startTime;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          disableDragSeek: false,
          loop: false,
          forceHD: true,
          // Hide the default fullscreen button; we'll use our own in the AppBar.
          hideControls: false,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
      debugPrint('YouTube Player Initialization Error: $e');
    }
  }

  @override
  void dispose() {
    // Only call onVideoComplete if the controller was successfully initialized.
    if (mounted && !_hasError) {
      final duration =
          (DateTime.now().millisecondsSinceEpoch - _startTime) ~/ 1000;
      widget.onVideoComplete?.call(duration);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold and AppBar automatically inherit their style from main.dart
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        // We provide our own fullscreen button for consistent theming.
        actions: !_hasError
            ? [
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded),
                  onPressed: () => _controller.toggleFullScreenMode(),
                  tooltip: 'Toggle Fullscreen',
                ),
              ]
            : null,
      ),
      body: _hasError ? _buildErrorView(context) : _buildPlayerLayout(context),
    );
  }

  // A dedicated, themed widget for displaying errors.
  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_disabled_rounded,
                size: 60, color: theme.colorScheme.secondary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Video',
              style:
                  theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // The main layout using YoutubePlayerBuilder for robustness.
  Widget _buildPlayerLayout(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          // Themed progress indicator colors.
          progressIndicatorColor: theme.colorScheme.secondary, // Gold
          progressColors: ProgressBarColors(
            playedColor: theme.colorScheme.secondary, // Gold
            handleColor: theme.colorScheme.secondary, // Gold
          ),
          onReady: () {
            // Player is ready.
          },
          onEnded: (metaData) {
            // onVideoComplete is now handled in dispose for more accurate duration.
          },
        ),
        builder: (context, player) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The Hero widget ensures a smooth transition.
              Hero(tag: widget.heroTag, child: player),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        // Use themed text styles for a consistent look.
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5, // Improved line spacing
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
