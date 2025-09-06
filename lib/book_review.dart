import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class BookReviewScreen extends StatefulWidget {
  final String bookId;

  const BookReviewScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  _BookReviewScreenState createState() => _BookReviewScreenState();
}

class _BookReviewScreenState extends State<BookReviewScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _bookData;
  late Future<List<Map<String, dynamic>>> _reviews;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _bookData = _fetchBookData();
      _reviews = _fetchReviews();
    });
  }

  Future<Map<String, dynamic>> _fetchBookData() async {
    final response = await _supabase
        .from('books')
        .select()
        .eq('id', widget.bookId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    final response = await _supabase
        .from('reviews')
        .select('*, user:users(*)') // Assuming your users table is 'users'
        .eq('book_id', widget.bookId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Book Reviews'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _bookData,
          builder: (context, bookSnapshot) {
            if (bookSnapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoader();
            }
            if (bookSnapshot.hasError || !bookSnapshot.hasData) {
              return Center(
                child: Text(
                  'Error: ${bookSnapshot.error ?? "Book not found."}',
                ),
              );
            }
            final book = bookSnapshot.data!;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildBookHeader(book)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _reviews,
                    builder: (context, reviewsSnapshot) {
                      if (reviewsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (reviewsSnapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'Error loading reviews: ${reviewsSnapshot.error}',
                            ),
                          ),
                        );
                      }
                      final reviews = reviewsSnapshot.data!;

                      if (reviews.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: Text(
                              'No reviews yet. Be the first!',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildReviewCard(reviews[index]),
                              ),
                            ),
                          );
                        }, childCount: reviews.length),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReviewDialog(context),
        child: const Icon(Icons.add_comment),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBookHeader(Map<String, dynamic> book) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: book['cover_url'] ?? '',
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey[200], height: 200),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                height: 200,
                child: const Icon(Icons.book, size: 60, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${book['author'] ?? 'Unknown Author'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  book['description'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>?;
    final textContent = review['text_content'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: user?['avatar_url'] != null
                  ? NetworkImage(user!['avatar_url'])
                  : null,
              child: user?['avatar_url'] == null
                  ? Text(
                      user?['email']
                              ?.toString()
                              .substring(0, 1)
                              .toUpperCase() ??
                          'A',
                    )
                  : null,
            ),
            title: Text(
              user?['email']?.toString().split('@')[0] ?? 'Anonymous',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _formatDate(review['created_at']),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: RatingBarIndicator(
              rating: (review['rating'] as num).toDouble(),
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20.0,
            ),
          ),
          if (textContent != null && textContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(textContent, style: const TextStyle(fontSize: 16)),
            ),
          if (review['video_url'] != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildVideoPlayer(review),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(Map<String, dynamic> review) {
    final videoUrl = review['video_url'] as String;
    final videoType = review['video_type'] as String?;

    switch (videoType) {
      case 'youtube':
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        return videoId != null && videoId.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: videoId,
                    flags: const YoutubePlayerFlags(autoPlay: false),
                  ),
                ),
              )
            : const Text('Invalid YouTube URL');
      case 'drive':
        return GestureDetector(
          onTap: () => _openVideoInBrowser(videoUrl),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text("Tap to play video in browser"),
                ),
              ),
              const Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white70,
              ),
            ],
          ),
        );
      case 'direct':
        return _DirectVideoPlayer(videoUrl: videoUrl);
      default:
        return Text('Unsupported video type: $videoType');
    }
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _openVideoInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video link: $url')),
        );
      }
    }
  }

  void _showAddReviewDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final textController = TextEditingController();
    double currentRating = 5.0;
    String? localVideoUrl;
    String? localVideoType;
    bool isDialogUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Review'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingBar.builder(
                      initialRating: currentRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) => currentRating = rating,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        controller: textController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Review text is required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Video Review (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (localVideoUrl == null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Video'),
                        onPressed: isDialogUploading
                            ? null
                            : () async {
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.video,
                                      withData: true,
                                    );
                                if (result != null &&
                                    result.files.single.bytes != null) {
                                  setStateDialog(
                                    () => isDialogUploading = true,
                                  );
                                  try {
                                    final fileBytes =
                                        result.files.single.bytes!;
                                    final fileExt =
                                        result.files.single.extension ?? 'mp4';
                                    final fileName =
                                        '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                                    final filePath = 'reviews/$fileName';

                                    await _supabase.storage
                                        .from('video_reviews')
                                        .uploadBinary(
                                          filePath,
                                          fileBytes,
                                          fileOptions: FileOptions(
                                            contentType: 'video/$fileExt',
                                          ),
                                        );
                                    final newVideoUrl = _supabase.storage
                                        .from('video_reviews')
                                        .getPublicUrl(filePath);

                                    setStateDialog(() {
                                      localVideoUrl = newVideoUrl;
                                      localVideoType = 'direct';
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                      ),
                                    );
                                  } finally {
                                    setStateDialog(
                                      () => isDialogUploading = false,
                                    );
                                  }
                                }
                              },
                      ),
                    if (localVideoUrl != null)
                      Chip(
                        label: const Text('Uploaded Video'),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: isDialogUploading
                            ? null
                            : () => setStateDialog(() {
                                localVideoUrl = null;
                                localVideoType = null;
                              }),
                      ),
                    if (isDialogUploading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDialogUploading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDialogUploading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setStateDialog(() => isDialogUploading = true);
                          try {
                            await _supabase.from('reviews').insert({
                              'book_id': widget.bookId,
                              'user_id': _supabase.auth.currentUser?.id,
                              'text_content': textController.text,
                              'video_url': localVideoUrl,
                              'video_type': localVideoType,
                              'rating': currentRating,
                            });
                            Navigator.of(context).pop();
                            _loadData(); // Refresh the main screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Review submitted!'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                            setStateDialog(() => isDialogUploading = false);
                          }
                        }
                      },
                child: const Text('Submit Review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DirectVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _DirectVideoPlayer({required this.videoUrl});

  @override
  _DirectVideoPlayerState createState() => _DirectVideoPlayerState();
}

class _DirectVideoPlayerState extends State<_DirectVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                GestureDetector(
                  onTap: () => setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  }),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white70,
                    size: 60,
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
