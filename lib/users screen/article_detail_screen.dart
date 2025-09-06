import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

// --- Branding Colors ---
const Color kPrimaryColor = Color.fromARGB(255, 1, 37, 100);
const Color kAccentColor = Color(0xFFFFD700);
const Color kCardColor = Color.fromARGB(255, 4, 48, 125);

class ArticleReaderScreen extends StatefulWidget {
  final String title;
  final String body;
  final String heroTag;
  final String? imageUrl;
  final int resourceId;
  final Function(int)? onReadingComplete;

  const ArticleReaderScreen({
    super.key,
    required this.title,
    required this.body,
    required this.heroTag,
    this.imageUrl,
    required this.resourceId,
    this.onReadingComplete,
  });

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
    if (maxScroll == 0) return;
    final currentScroll = _scrollController.position.pixels;
    final scrollPercentage = (currentScroll / maxScroll) * 100;

    if (scrollPercentage > 90 && !_isComplete) {
      setState(() => _isComplete = true);
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final durationSeconds = ((endTime - _startTime) / 1000).round();
      widget.onReadingComplete?.call(durationSeconds);
    }
  }

  Future<void> _shareArticle() async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        '${widget.title}\n\nCheck out this article from Amde Haymanot App!',
        subject: widget.title,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveToClipboard() async {
    try {
      await Clipboard.setData(
        ClipboardData(text: '${widget.title}\n\n${widget.body}'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text('ጽሑፉ ወደ ቅንጥብ ሰሌዳ ተቀድቷል', style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      floatingActionButton: SpeedDial(
        icon: Icons.more_vert,
        activeIcon: Icons.close,
        backgroundColor: kAccentColor,
        foregroundColor: kPrimaryColor,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.share),
            backgroundColor: kCardColor,
            foregroundColor: kAccentColor,
            label: 'አጋራ',
            labelStyle: GoogleFonts.notoSansEthiopic(color: Colors.white),
            onTap: _shareArticle,
          ),
          SpeedDialChild(
            child: const Icon(Icons.copy_all_rounded),
            backgroundColor: kCardColor,
            foregroundColor: kAccentColor,
            label: 'ቅዳ',
            labelStyle: GoogleFonts.notoSansEthiopic(color: Colors.white),
            onTap: _saveToClipboard,
          ),
        ],
      ),
      // --- CRITICAL FIX: Wrap the body in a Material widget ---
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 280.0,
              pinned: true,
              stretch: true,
              backgroundColor: kPrimaryColor,
              iconTheme: const IconThemeData(color: kAccentColor),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                title: Text(
                  widget.title,
                  style: GoogleFonts.notoSansEthiopic(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(blurRadius: 4.0, color: Colors.black87, offset: Offset(2, 2))
                      ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                centerTitle: true,
                background: _buildHeroImage(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                child: Text(
                  widget.body,
                  style: GoogleFonts.notoSansEthiopic(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.8,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Hero(
      tag: widget.heroTag,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: kPrimaryColor,
                child: const Center(child: CircularProgressIndicator(color: kAccentColor)),
              ),
              errorWidget: (context, url, error) => Container(
                color: kCardColor,
                child: Icon(Icons.image_not_supported_outlined, color: kAccentColor.withOpacity(0.7), size: 60),
              ),
            )
          else
            Container(color: kCardColor),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  kPrimaryColor.withOpacity(0.2),
                  kPrimaryColor
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}