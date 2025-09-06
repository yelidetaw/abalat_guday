import 'package:amde_haymanot_abalat_guday/users%20screen/comments_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/direct_video.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/youtube_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:shimmer/shimmer.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// --- UI Theme Constants ---
const Color kStudentBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kStudentCardColor = Color.fromARGB(255, 4, 48, 125);
const Color kStudentPrimaryAccent = Color(0xFFFFD700);
const Color kStudentSecondaryText = Color(0xFF9A9A9A);

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // ... (All state and functions from the previous correct version remain here)
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _resources = [];
  String _selectedCategory = 'all';

  final Map<String, String> _categories = {
    'all': 'ሁሉም',
    'is_orthodox_preach': 'ስብከት', // Assuming Hebrew, replace if needed
    'is_personal_dev': 'የግል እድገት',
    'is_training': 'ስልጠና',
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentResources();
  }

  Future<void> _fetchStudentResources() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await supabase.rpc('get_all_learning_resources_for_student');
      if (mounted) {
        setState(() => _resources = List<Map<String, dynamic>>.from(response));
      }
    } catch (e, stackTrace) {
      final errorMessage = "የትምህርት መርጃዎችን መጫን አልተቻለም: ${e.toString()}";
      developer.log(errorMessage, name: 'LearningScreen.fetch', error: e, stackTrace: stackTrace);
      if (mounted) setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredResources() {
    if (_selectedCategory == 'all') {
      return _resources;
    }
    return _resources.where((res) => res[_selectedCategory] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kStudentBackgroundColor,
      appBar: AppBar(
        title: Text('ትምህርቶች', style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: kStudentBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _categories.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(entry.value, style: GoogleFonts.notoSansEthiopic()),
              selected: _selectedCategory == entry.key,
              selectedColor: kStudentPrimaryAccent,
              backgroundColor: kStudentCardColor,
              labelStyle: TextStyle(color: _selectedCategory == entry.key ? Colors.black : Colors.white, fontWeight: FontWeight.w600),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = entry.key);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const _StudentListShimmer();
    if (_error != null)
      return Center(child: Text(_error!, style: GoogleFonts.notoSansEthiopic(color: Colors.redAccent)));

    final filteredResources = _getFilteredResources();
    if (filteredResources.isEmpty) {
      return Center(child: Text('በዚህ ምድብ ምንም የትምህርት መрጃ አልተገኘም', style: GoogleFonts.notoSansEthiopic(color: kStudentSecondaryText)));
    }

    return RefreshIndicator(
      onRefresh: _fetchStudentResources,
      backgroundColor: kStudentCardColor,
      color: kStudentPrimaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredResources.length,
        itemBuilder: (context, index) {
          final resource = filteredResources[index];
          return _ResourceCard(
            key: ValueKey(resource['id']),
            resource: resource,
            onLikeChanged: (int resourceId, bool newIsLiked, int newLikeCount) {
               if (mounted) {
                 setState(() {
                   final resourceIndex = _resources.indexWhere((r) => r['id'] == resourceId);
                   if (resourceIndex != -1) {
                     _resources[resourceIndex]['is_liked_by_user'] = newIsLiked;
                     _resources[resourceIndex]['like_count'] = newLikeCount;
                   }
                 });
               }
            },
          );
        },
      ),
    );
  }
}

class _ResourceCard extends StatefulWidget {
  final Map<String, dynamic> resource;
  final Function(int resourceId, bool newIsLiked, int newLikeCount) onLikeChanged;

  const _ResourceCard({super.key, required this.resource, required this.onLikeChanged});

  @override
  State<_ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<_ResourceCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.resource['is_liked_by_user'] ?? false;
    _likeCount = widget.resource['like_count'] ?? 0;
  }
  
  Future<void> _recordActivity(int resourceId, String type, int duration, bool completed) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('user_activities').insert({
        'user_id': user.id, 'resource_id': resourceId, 'activity_type': type,
        'duration_seconds': duration, 'is_completed': completed,
      });
    } catch (e) { /* silent fail */ }
  }

  Future<void> _showAnimatedArticleSheet(BuildContext context, Map<String, dynamic> resource) async {
    HapticFeedback.lightImpact();
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Article',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => ArticleSheet(
        resource: resource,
        onReadingComplete: (duration) => _recordActivity(resource['id'], 'article', duration, true),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
  
  void _handleTap() {
    final currentContext = context;
    final resource = widget.resource;
    final String contentType = (resource['content_type'] ?? '').toString().toLowerCase();

    developer.log('Card tapped. Content Type: "$contentType"', name: 'LearningScreen');
    if (!currentContext.mounted) return;

    try {
      if (contentType == 'video') {
        Navigator.push(currentContext, MaterialPageRoute(builder: (_) => YoutubePlayerScreen(
          youtubeId: resource['youtube_id'], 
          title: resource['title'] ?? 'ርዕስ የለውም', 
          description: resource['description'] ?? '',
          heroTag: 'resource-${resource['id']}', 
          onVideoComplete: (d) => _recordActivity(resource['id'], 'video', d, true),
        )));
      } else if (contentType == 'direct_video') {
        Navigator.push(currentContext, MaterialPageRoute(builder: (_) => DirectVideoPlayerScreen(
          videoUrl: resource['video_url'], 
          title: resource['title'] ?? 'ርዕስ የለውም',
          heroTag: 'resource-${resource['id']}', 
          onVideoComplete: (d) => _recordActivity(resource['id'], 'video', d, true),
        )));
      } else if (contentType == 'article') {
        _showAnimatedArticleSheet(currentContext, resource);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to navigate on tap', 
        name: 'LearningScreen._handleTap', 
        error: e, 
        stackTrace: stackTrace
      );
    }
  }

  Future<void> _handleLike() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ይዘትን ለመውደድ መግባት አለብዎት።", style: GoogleFonts.notoSansEthiopic())));
      return;
    }
    final resourceId = widget.resource['id'];
    
    setState(() {
      if (_isLiked) { _likeCount--; } else { _likeCount++; }
      _isLiked = !_isLiked;
    });

    try {
      await supabase.rpc('toggle_like', params: {
        'resource_id_to_like': resourceId,
        'user_id_who_liked': user.id,
      });
      widget.onLikeChanged(resourceId, _isLiked, _likeCount);
    } catch (e) {
      setState(() {
        if (_isLiked) { _likeCount++; } else { _likeCount--; }
        _isLiked = !_isLiked;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("የወደዱትን ማዘመን አልተሳካም።", style: GoogleFonts.notoSansEthiopic()), 
        backgroundColor: Colors.red
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentType = (widget.resource['content_type'] ?? '').toString().toLowerCase();
    final isVideo = contentType == 'video' || contentType == 'direct_video';
    
    String? thumbnailUrl;
    if (contentType == 'video' && widget.resource['youtube_id'] != null) {
      thumbnailUrl = 'https://img.youtube.com/vi/${widget.resource['youtube_id']}/hqdefault.jpg';
    } else if (widget.resource['image_url'] != null) {
      thumbnailUrl = widget.resource['image_url'];
    }

    return Card(
      color: kStudentCardColor,
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _handleTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Hero(
                tag: 'resource-${widget.resource['id']}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl != null)
                      CachedNetworkImage(
                        imageUrl: thumbnailUrl, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: kStudentBackgroundColor),
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, color: kStudentSecondaryText)),
                      )
                    else 
                       Container(
                        color: kStudentBackgroundColor,
                        child: const Center(child: Icon(Icons.image_not_supported, color: kStudentSecondaryText, size: 40)),
                       ),
                    if (isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 60)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.resource['title'] ?? 'ርዕስ የለውም',
                    style: GoogleFonts.notoSansEthiopic(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(
                  widget.resource['description'] ?? '',
                  style: GoogleFonts.notoSansEthiopic(fontSize: 14, color: kStudentSecondaryText),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 24, color: Colors.white24),
                Row(
                  children: [
                    _StatIcon(icon: Icons.visibility_outlined, value: (widget.resource['view_count'] ?? 0).toString()),
                    const SizedBox(width: 16),
                    _LikeButton(isLiked: _isLiked, likeCount: _likeCount, onPressed: _handleLike),
                    const SizedBox(width: 16),
                    _StatIcon(icon: Icons.comment_outlined, value: (widget.resource['comment_count'] ?? 0).toString()),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(
                            resourceId: (widget.resource['id'] as num).toInt(), 
                            resourceTitle: widget.resource['title'],
                          )));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kStudentCardColor, foregroundColor: kStudentPrimaryAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: kStudentPrimaryAccent))),
                      child: Text('አስተያየቶች', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ArticleSheet extends StatefulWidget {
  final Map<String, dynamic> resource;
  final Function(int)? onReadingComplete;

  const ArticleSheet({
    super.key,
    required this.resource,
    this.onReadingComplete,
  });

  @override
  State<ArticleSheet> createState() => _ArticleSheetState();
}

class _ArticleSheetState extends State<ArticleSheet> {
  late int _startTime;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  void _checkReadingProgress(ScrollController scrollController) {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    if (maxScroll < 100) { 
      if (!_isComplete) _markAsComplete();
      return;
    }
    final currentScroll = scrollController.position.pixels;
    final scrollPercentage = (currentScroll / maxScroll) * 100;

    if (scrollPercentage > 90 && !_isComplete) {
      _markAsComplete();
    }
  }
  
  void _markAsComplete() {
      if (_isComplete) return;
      setState(() => _isComplete = true);
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final durationSeconds = ((endTime - _startTime) / 1000).round();
      widget.onReadingComplete?.call(durationSeconds);
      developer.log('Article reading completed in $durationSeconds seconds.', name: 'ArticleSheet');
  }

  // --- CRITICAL FIX: The share and copy methods are now inside the State object ---
  Future<void> _shareArticle() async {
    // 1. Capture context before the async gap.
    final currentContext = context;
    try {
      final box = currentContext.findRenderObject() as RenderBox?;
      await Share.share(
        '${widget.resource['title']}\n\nShared from Amde Haymanot App!',
        subject: widget.resource['title'],
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      // 2. Check if mounted before using the context again.
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Failed to share: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveToClipboard() async {
    try {
      await Clipboard.setData(
        ClipboardData(text: '${widget.resource['title']}\n\n${widget.resource['content_body']}'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ተቀድቷል!', style: GoogleFonts.notoSansEthiopic()),
          backgroundColor: Colors.green,
        )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return makeDismissible(
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) {
          controller.removeListener(() => _checkReadingProgress(controller));
          controller.addListener(() => _checkReadingProgress(controller));

          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverAppBar(
                  backgroundColor: kPrimaryColor,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  centerTitle: true,
                  title: _buildGrabber(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, color: kStudentSecondaryText),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: "ዝጋ",
                    ),
                  ],
                ),
                SliverToBoxAdapter(child: _buildHeaderImage()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        const Divider(height: 32, color: kStudentCardColor),
                        _buildBodyText(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget makeDismissible({required Widget child}) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => Navigator.of(context).pop(),
    child: GestureDetector(onTap: () {}, child: child),
  );
  
  Widget _buildGrabber() {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: kStudentCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Hero(
      tag: 'resource-${widget.resource['id']}',
      child: Container(
        height: 250,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: widget.resource['image_url'] != null
            ? CachedNetworkImage(
                imageUrl: widget.resource['image_url'],
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Container(color: kStudentCardColor),
              )
            : Container(color: kStudentCardColor),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.resource['title'] ?? 'ርዕስ የለም።',
            style: GoogleFonts.notoSansEthiopic(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: kStudentSecondaryText),
          onPressed: _shareArticle,
        ),
      ],
    );
  }

  Widget _buildBodyText() {
    return Text(
      widget.resource['content_body'] ?? 'ይዘት የለም።',
      style: GoogleFonts.notoSansEthiopic(
        fontSize: 18,
        color: Colors.white.withOpacity(0.85),
        height: 1.8,
        decoration: TextDecoration.none,
      ),
    );
  }
}


// --- All other widgets below this are stable ---

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onPressed;

  const _LikeButton({ required this.isLiked, required this.likeCount, required this.onPressed });

  @override
  Widget build(BuildContext context) {
    final color = isLiked ? kStudentPrimaryAccent : kStudentSecondaryText;
    final icon = isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(likeCount.toString(), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatIcon extends StatelessWidget {
  final IconData icon;
  final String value;
  const _StatIcon({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kStudentSecondaryText, size: 16),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: kStudentSecondaryText, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StudentListShimmer extends StatelessWidget {
  const _StudentListShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kStudentCardColor,
      highlightColor: kStudentBackgroundColor.withOpacity(0.5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16)
            ),
          ),
        ),
      ),
    );
  }
}