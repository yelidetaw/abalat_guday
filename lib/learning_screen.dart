import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

// Import your other screens here
import 'learning_admin.dart';
import 'youtube_player_screen.dart';
import 'article_detail_screen.dart';
import 'downloads_screen.dart';
import 'comments_screen.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  debugPrint(
    'Download task ($id) is in status ($status) and progress ($progress)',
  );
  // You'll need to implement a way to update your UI with this information
  // Typically using a state management solution
}

class LearningScreen extends StatefulWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedCategory = 'all';
  bool _isOffline = false;
  final Map<String, String> _categories = {
    'all': 'All',
    'orthodox': 'Orthodox Preaches',
    'personal_dev': 'Personal Development',
    'training': 'Training',
  };
  final Connectivity _connectivity = Connectivity();

  // Download management
  final Map<int, bool> _downloadedArticles = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadTasks = {};

  // Bookmarks
  final Map<int, bool> _bookmarkedResources = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initConnectivity();
    _fetchResources();
    _loadDownloadedArticles();
    _loadBookmarks();
    _initDownloads();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _fetchResources);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      setState(() => _isOffline = result == ConnectivityResult.none);
      _connectivity.onConnectivityChanged.listen((result) {
        setState(() => _isOffline = result == ConnectivityResult.none);
      });
    } catch (e) {
      debugPrint('Connectivity error: $e');
    }
  }

  Future<void> _initDownloads() async {
    await FlutterDownloader.initialize(debug: true);
    FlutterDownloader.registerCallback(downloadCallback);
  }

  Future<void> _fetchResources() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final searchTerm = _searchController.text.trim();
      var query = _supabase.from('learning_resources').select();

      if (_selectedCategory != 'all') {
        final column = _selectedCategory == 'orthodox'
            ? 'is_orthodox_preach'
            : 'is_$_selectedCategory';
        query = query.eq(column, true);
      }
      if (searchTerm.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%',
        );
      }

      final response = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() => _resources = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = _isOffline
              ? "Offline mode - showing cached content"
              : "Failed to load resources",
        );
      }
      debugPrint('Fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDownloadedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedArticleIds =
        prefs.getStringList('downloaded_articles') ?? [];

    setState(() {
      for (final idString in downloadedArticleIds) {
        final id = int.tryParse(idString);
        if (id != null) {
          _downloadedArticles[id] = true;
        }
      }
    });
  }

  Future<void> _saveDownloadedArticle(int articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedArticleIds =
        prefs.getStringList('downloaded_articles') ?? [];
    if (!downloadedArticleIds.contains(articleId.toString())) {
      downloadedArticleIds.add(articleId.toString());
      await prefs.setStringList('downloaded_articles', downloadedArticleIds);
    }
  }

  Future<void> _removeDownloadedArticle(int articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedArticleIds =
        prefs.getStringList('downloaded_articles') ?? [];
    downloadedArticleIds.remove(articleId.toString());
    await prefs.setStringList('downloaded_articles', downloadedArticleIds);
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedIds = prefs.getStringList('bookmarked_resources') ?? [];

    setState(() {
      for (final idString in bookmarkedIds) {
        final id = int.tryParse(idString);
        if (id != null) {
          _bookmarkedResources[id] = true;
        }
      }
    });
  }

  Future<void> _toggleBookmark(int resourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedIds = prefs.getStringList('bookmarked_resources') ?? [];

    if (_bookmarkedResources.containsKey(resourceId)) {
      bookmarkedIds.remove(resourceId.toString());
    } else {
      bookmarkedIds.add(resourceId.toString());
    }

    await prefs.setStringList('bookmarked_resources', bookmarkedIds);

    setState(() {
      if (_bookmarkedResources.containsKey(resourceId)) {
        _bookmarkedResources.remove(resourceId);
      } else {
        _bookmarkedResources[resourceId] = true;
      }
    });
  }

  Future<void> _recordActivity(
    int resourceId,
    String type,
    int duration,
    bool completed,
  ) async {
    try {
      await _supabase.from('user_activities').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'resource_id': resourceId,
        'activity_type': type,
        'duration_seconds': duration,
        'is_completed': completed,
      });
    } catch (e) {
      debugPrint('Activity recording failed: $e');
    }
  }

  Future<bool> _checkStoragePermission() async {
    if (await Permission.storage.request().isGranted) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required for downloads'),
        ),
      );
    }
    return false;
  }

  Future<void> _downloadVideo(String youtubeId, String title) async {
    if (!await _checkStoragePermission()) return;

    setState(() {});

    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(youtubeId);
      final manifest = await yt.videos.streamsClient.getManifest(youtubeId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      final videoUrl = streamInfo.url.toString();

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${video.id}.mp4';

      final taskId = await FlutterDownloader.enqueue(
        url: videoUrl,
        savedDir: dir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );

      setState(() {
        _downloadTasks[youtubeId] = taskId!;
        _downloadProgress[youtubeId] = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloading $title...')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {});
    }
  }

  Future<void> _downloadArticle(
    int resourceId,
    String title,
    String contentBody,
  ) async {
    if (_downloadedArticles.containsKey(resourceId)) {
      await _removeDownloadedArticle(resourceId);
      if (mounted) {
        setState(() => _downloadedArticles.remove(resourceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article removed from downloads')),
        );
      }
      return;
    }

    if (!await _checkStoragePermission()) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/article_$resourceId.html');

      final htmlContent =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>${title}</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { color: #2c3e50; }
            .content { line-height: 1.6; }
          </style>
        </head>
        <body>
          <h1>${title}</h1>
          <div class="content">${contentBody.replaceAll('\n', '<br>')}</div>
        </body>
        </html>
      ''';

      await file.writeAsString(htmlContent);
      await _saveDownloadedArticle(resourceId);

      if (mounted) {
        setState(() => _downloadedArticles[resourceId] = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article downloaded for offline reading')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: 200, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DownloadsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminScreenL()),
            ).then((_) => _fetchResources()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedCategory == entry.key,
                    onSelected: (selected) {
                      if (mounted) {
                        setState(
                          () =>
                              _selectedCategory = selected ? entry.key : 'all',
                        );
                      }
                      _fetchResources();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Offline Mode',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader()
                : _error != null
                ? Center(child: Text(_error!))
                : _resources.isEmpty
                ? const Center(child: Text('No resources found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resources.length,
                    itemBuilder: (context, index) {
                      final resource = _resources[index];
                      final isVideo = resource['content_type'] == 'video';
                      final thumbnailUrl = isVideo
                          ? 'https://img.youtube.com/vi/${resource['youtube_id']}/hqdefault.jpg'
                          : resource['image_url'] ??
                                'https://via.placeholder.com/150';
                      final heroTag = 'resource-${resource['id']}';
                      final isDownloading = _downloadTasks.containsKey(
                        resource['youtube_id'],
                      );
                      final downloadProgress =
                          _downloadProgress[resource['youtube_id']] ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            if (isVideo) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => YoutubePlayerScreen(
                                    youtubeId: resource['youtube_id'],
                                    title: resource['title'],
                                    description: resource['description'],
                                    heroTag: heroTag,
                                    onVideoComplete: (duration) =>
                                        _recordActivity(
                                          resource['id'],
                                          'video',
                                          duration,
                                          true,
                                        ),
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArticleReaderScreen(
                                    title: resource['title'],
                                    body: resource['content_body'],
                                    heroTag: heroTag,
                                    imageUrl: thumbnailUrl,
                                    resourceId: resource['id'],
                                    onReadingComplete: (duration) =>
                                        _recordActivity(
                                          resource['id'],
                                          'article',
                                          duration,
                                          true,
                                        ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Stack(
                                children: [
                                  Hero(
                                    tag: heroTag,
                                    child: CachedNetworkImage(
                                      imageUrl: thumbnailUrl,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 200,
                                        color: Colors.grey[200],
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            height: 200,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.broken_image,
                                            ),
                                          ),
                                    ),
                                  ),
                                  if (isDownloading)
                                    Positioned.fill(
                                      child: LinearProgressIndicator(
                                        value: downloadProgress,
                                        backgroundColor: Colors.black54,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.red,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            resource['title'],
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _bookmarkedResources.containsKey(
                                                  resource['id'],
                                                )
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                          ),
                                          onPressed: () =>
                                              _toggleBookmark(resource['id']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      resource['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('MMM d, y').format(
                                            DateTime.parse(
                                              resource['created_at'],
                                            ),
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.comment),
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CommentsScreen(
                                                        resourceId:
                                                            resource['id'],
                                                        resourceTitle:
                                                            resource['title'],
                                                      ),
                                                ),
                                              ),
                                            ),
                                            if (isVideo)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.download,
                                                ),
                                                onPressed: isDownloading
                                                    ? null
                                                    : () => _downloadVideo(
                                                        resource['youtube_id'],
                                                        resource['title'],
                                                      ),
                                              ),
                                            if (!isVideo)
                                              IconButton(
                                                icon: Icon(
                                                  _downloadedArticles
                                                          .containsKey(
                                                            resource['id'],
                                                          )
                                                      ? Icons.check_circle
                                                      : Icons.download,
                                                ),
                                                onPressed: () =>
                                                    _downloadArticle(
                                                      resource['id'],
                                                      resource['title'],
                                                      resource['content_body'],
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
