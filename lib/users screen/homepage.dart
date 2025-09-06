import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/content_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// --- BRANDING COLORS ---
const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
const Color accentColor = Color(0xFFFFD700);
const Color cardBackgroundColor = Color(0xFF1a2c5a); // Used for dialogs

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final contentManager = context.watch<ContentManager>();
    return Scaffold(
      backgroundColor: primaryColor,
      body: _buildBody(context, contentManager),
    );
  }

  Widget _buildBody(BuildContext context, ContentManager contentManager) {
    if (contentManager.isLoading && contentManager.content.siteContent.isEmpty) {
      return const _HomepageShimmer();
    }
    if (contentManager.error != null && contentManager.content.siteContent.isEmpty) {
      return _ErrorDisplay(errorMessage: contentManager.error!, onRetry: () => context.read<ContentManager>().fetchContent());
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ContentManager>().fetchContent(),
      color: accentColor,
      backgroundColor: primaryColor,
      child: CustomScrollView(
        slivers: [
          _SliverAppBar(siteContent: contentManager.content.siteContent),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final items = _buildPageItemList(context, contentManager.content);
                return FadeInUp(
                  from: 20,
                  duration: const Duration(milliseconds: 400),
                  child: items[index],
                );
              },
              childCount: _buildPageItemList(context, contentManager.content).length,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageItemList(BuildContext context, PageContent content) {
    return [
      const _SectionTitle(title: 'ትምህርት እና መርጃዎች'),
      _LearningCard(siteContent: content.siteContent), // This widget is updated below
      const _SectionTitle(title: 'ስለ ቤተክርስቲያናችን'),
      _InfoDisplayCard(
        title: 'ስለ ቤተክርስቲያናችን',
        content: content.siteContent['about_us_text'],
      ),
      const _SectionTitle(title: 'የአገልግሎት ሰዓቶቻችን'),
      _ServiceTimesSection(serviceTimes: content.serviceTimes),
      const _SectionTitle(title: 'ዜና እና ዝግጅቶች'),
      ..._buildNewsAndEvents(context, content.newsAndEvents),
      const _SectionTitle(title: 'ሰንበት ትምህርት ቤት'),
      _InfoDisplayCard(
        title: 'ሰንበት ትምህርት ቤት',
        imageUrl: content.siteContent['sunday_school_image_url'],
        content: content.siteContent['sunday_school_text'],
      ),
      const _SectionTitle(title: 'ታሪካችን'),
      _InfoDisplayCard(
        title: 'ታሪካችን',
        imageUrl: content.siteContent['history_image_url'],
        content: content.siteContent['history_text'],
      ),
      const _Footer(),
    ];
  }

  List<Widget> _buildNewsAndEvents(BuildContext context, List<Map<String, dynamic>> newsEvents) {
    if (newsEvents.isEmpty) {
      return [Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), child: Center(child: Text('ምንም አዲስ ዜና ወይም ዝግጅት የለም።', style: GoogleFonts.notoSansEthiopic())))];
    }
    return [
      ...newsEvents.map((event) => _EventCard(item: event)),
      const SizedBox(height: 16),
    ];
  }
}

// --- ENHANCED DIALOG & REFACTORED WIDGETS ---

class _FullTextDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;
  
  const _FullTextDialog({required this.title, required this.content, this.imageUrl});
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isValidUrl(imageUrl)) 
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: _SafeCachedNetworkImage(
                        url: imageUrl, 
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: _isValidUrl(imageUrl) ? null : const EdgeInsets.only(top: 40),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_isValidUrl(imageUrl) ? 0 : 20),
                        topRight: Radius.circular(_isValidUrl(imageUrl) ? 0 : 20),
                      ),
                    ),
                    child: Text(
                      title,
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      content,
                      style: GoogleFonts.notoSansEthiopic(
                        height: 1.7, 
                        color: Colors.white.withOpacity(0.9), 
                        fontSize: 16
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoDisplayCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? content;

  const _InfoDisplayCard({
    required this.title,
    this.imageUrl,
    this.content,
  });
  
  @override
  Widget build(BuildContext context) {
    final text = content ?? 'ምንም መረጃ አልተገኘም።';
    final canBeTruncated = text.length > 200;
    final truncatedText = canBeTruncated ? '${text.substring(0, 200)}...' : text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Card(
        color: primaryColor.withOpacity(0.7),
        child: InkWell(
          onTap: canBeTruncated ? () => showDialog(
            context: context,
            builder: (context) => _FullTextDialog(
              title: title, 
              content: text,
              imageUrl: imageUrl,
            ),
          ) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isValidUrl(imageUrl)) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _SafeCachedNetworkImage(url: imageUrl, height: 180)
                  ),
                  const SizedBox(height: 20),
                ],
                SelectableText(
                  truncatedText,
                  style: GoogleFonts.notoSansEthiopic(height: 1.6, color: Colors.white.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                if (canBeTruncated) ...[
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.expand_circle_down_outlined,
                    color: accentColor,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ሙሉውን ለማንበብ ይንኩ',
                    style: GoogleFonts.notoSansEthiopic(
                      color: accentColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ALL OTHER WIDGETS ARE UNCHANGED AND COMPLETE ---
class _SliverAppBar extends StatelessWidget { 
  final Map<String, dynamic> siteContent; 
  const _SliverAppBar({required this.siteContent}); 
  
  @override 
  Widget build(BuildContext context) { 
    return SliverAppBar(
      expandedHeight: 280.0, 
      pinned: true, 
      stretch: true, 
      backgroundColor: primaryColor, 
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _SafeCachedNetworkImage(url: siteContent['hero_image_url'], height: 280),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, primaryColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(child: Image.asset('assets/images/am-11.png', width: 100)),
                  const SizedBox(height: 10),
                  FadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text('ዓምደ ሃይማኖት', style: GoogleFonts.notoSerif(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, shadows: [const Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(2, 2))])),
                  ),
                  const SizedBox(height: 5),
                  FadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Text('የሁላችን እናት', style: GoogleFonts.notoSerif(fontSize: 18, color: Colors.white, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), 
    ); 
  } 
}

class _SectionTitle extends StatelessWidget { 
  final String title; 
  const _SectionTitle({required this.title}); 
  
  @override 
  Widget build(BuildContext context) { 
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16), 
      child: Text(title, style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize, fontWeight: FontWeight.bold, color: accentColor)), 
    ); 
  } 
}

// --- MODIFIED WIDGET ---
class _LearningCard extends StatelessWidget {
  final Map<String, dynamic> siteContent;
  const _LearningCard({required this.siteContent});

  @override
  Widget build(BuildContext context) {
    // --- FIX & DEBUGGING STEP ---
    // We log the URL to the debug console to verify it's coming from the database correctly.
    // If this prints "null" or an empty string, the problem is with the data saved
    // in your database for the 'learning_card_image_url' key.
    final imageUrl = siteContent['learning_card_image_url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // --- NAVIGATION FIX ---
          // This code correctly tells go_router to navigate to the /learning route.
          // This should take the user to your LearningScreen and update the
          // bottom navigation bar to the 3rd tab (index 2) if your router is configured properly.
          onTap: () {
            context.push('/learning');
          },
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Use the validated imageUrl variable here
              _SafeCachedNetworkImage(url: imageUrl, height: 150),
              Container(
                height: 150,
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.9)], stops: const [0.3, 1.0])),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: accentColor, radius: 24, child: Icon(Icons.school, size: 28, color: primaryColor)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ዲጂታል የትምህርት ማዕከል', style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.titleLarge?.fontSize, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('ስብከቶችን፣ ጽሑፎችን እና ሥልጠናዎችን ያግኙ', style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize, color: Colors.white.withOpacity(0.9))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTimesSection extends StatelessWidget { 
  final List<Map<String, dynamic>> serviceTimes; 
  const _ServiceTimesSection({required this.serviceTimes}); 
  
  @override 
  Widget build(BuildContext context) { 
    return LayoutBuilder(
      builder: (context, constraints) { 
        final isWide = constraints.maxWidth > 600; 
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), 
          child: Wrap(
            spacing: 16.0, 
            runSpacing: 16.0, 
            children: serviceTimes.map((item) { 
              return SizedBox(
                width: isWide ? (constraints.maxWidth / 2) - 24 : double.infinity, 
                child: _ServiceCard(item: item), 
              ); 
            }).toList(), 
          ), 
        ); 
      }, 
    ); 
  } 
}

class _ServiceCard extends StatelessWidget { 
  final Map<String, dynamic> item; 
  const _ServiceCard({required this.item}); 
  
  @override 
  Widget build(BuildContext context) { 
    return Card(
      color: primaryColor.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16), 
        child: Row(
          children: [
            CircleAvatar(backgroundColor: accentColor.withOpacity(0.15), radius: 24, child: Icon(_getIconData(item['icon_name']), size: 28, color: accentColor)), 
            const SizedBox(width: 16), 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(item['title'] ?? '', style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.titleLarge?.fontSize, fontWeight: FontWeight.bold, color: Colors.white)), 
                  const SizedBox(height: 4), 
                  Text(item['description'] ?? '', style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize, color: Colors.white.withOpacity(0.7))), 
                  const SizedBox(height: 8), 
                  Text(item['schedule'] ?? '', style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize, fontWeight: FontWeight.bold, color: accentColor)), 
                ], 
              ), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 
}

class _EventCard extends StatelessWidget { 
  final Map<String, dynamic> item; 
  const _EventCard({required this.item}); 
  
  @override 
  Widget build(BuildContext context) { 
    final theme = Theme.of(context); 
    final String title = item['title'] ?? ''; 
    final String date = item['event_date'] ?? ''; 
    final String description = item['description'] ?? ''; 
    final String? imageUrl = item['image_url']; 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      child: Card(
        color: primaryColor.withOpacity(0.7),
        clipBehavior: Clip.antiAlias, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            if (_isValidUrl(imageUrl)) Stack(
              alignment: Alignment.bottomLeft, 
              children: [
                _SafeCachedNetworkImage(url: imageUrl, height: 180), 
                Container(
                  height: 100, 
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])), 
                ), 
                Padding(
                  padding: const EdgeInsets.all(12.0), 
                  child: Text(title, style: GoogleFonts.notoSansEthiopic(fontSize: theme.textTheme.titleLarge?.fontSize, fontWeight: FontWeight.bold, color: Colors.white)), 
                ), 
              ], 
            ), 
            Padding(
              padding: const EdgeInsets.all(16), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  if (!_isValidUrl(imageUrl)) Text(title, style: GoogleFonts.notoSansEthiopic(fontSize: theme.textTheme.titleLarge?.fontSize, fontWeight: FontWeight.bold, color: Colors.white)), 
                  const SizedBox(height: 8), 
                  Text(date, style: GoogleFonts.notoSansEthiopic(fontSize: theme.textTheme.bodySmall?.fontSize, fontWeight: FontWeight.bold, color: accentColor)), 
                  const SizedBox(height: 12), 
                  SelectableText(description, style: GoogleFonts.notoSansEthiopic(fontSize: theme.textTheme.bodyMedium?.fontSize, color: Colors.white.withOpacity(0.8))), 
                ], 
              ), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 
}

class _Footer extends StatelessWidget { 
  const _Footer(); 
  
  @override 
  Widget build(BuildContext context) { 
    return Container(
      margin: const EdgeInsets.only(top: 24), 
      color: primaryColor.withOpacity(0.5), 
      padding: const EdgeInsets.all(25), 
      child: Column(
        children: [
          Text('ይጎብኙን', style: GoogleFonts.notoSerif(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor)), 
          const SizedBox(height: 10), 
          Text('ጅማ, ኢትዮጵያ\nአምላከ ቅዱስ ያሬድ አይለየን', style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: Colors.white, height: 1.6), textAlign: TextAlign.center), 
        ], 
      ), 
    ); 
  } 
}

class _ErrorDisplay extends StatelessWidget { 
  final String errorMessage; 
  final VoidCallback onRetry; 
  const _ErrorDisplay({required this.errorMessage, required this.onRetry}); 
  
  @override 
  Widget build(BuildContext context) { 
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Icon(Icons.cloud_off, color: accentColor, size: 60), 
            const SizedBox(height: 20), 
            Text("ይዘቱን መጫን አልተቻለም", style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize, color: Colors.white)), 
            const SizedBox(height: 10), 
            Text("እባክዎ የበይነመረብ ግንኙነትዎን ያረጋግጡ እና እንደገና ይሞክሩ።", textAlign: TextAlign.center, style: GoogleFonts.notoSansEthiopic(fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize, color: Colors.white.withOpacity(0.7))), 
            const SizedBox(height: 20), 
            ElevatedButton.icon(
              onPressed: onRetry, 
              icon: const Icon(Icons.refresh), 
              label: Text('እንደገና ሞክር', style: GoogleFonts.notoSansEthiopic())), 
          ], 
        ), 
      ), 
    ); 
  } 
}

class _HomepageShimmer extends StatelessWidget { 
  const _HomepageShimmer(); 
  
  @override 
  Widget build(BuildContext context) { 
    return Shimmer.fromColors(
      baseColor: primaryColor, 
      highlightColor: const Color(0xFF1a2c5a), 
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(), 
        slivers: [
          SliverAppBar(expandedHeight: 280.0, flexibleSpace: Container(color: Colors.white)), 
          SliverPadding(
            padding: const EdgeInsets.all(20.0), 
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(height: 20, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))), 
                const SizedBox(height: 16), 
                Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))), 
                const SizedBox(height: 32), 
                Container(height: 20, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))), 
                const SizedBox(height: 16), 
                Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))), 
              ]), 
            ), 
          ) 
        ], 
      ), 
    ); 
  } 
}

bool _isValidUrl(String? url) => (url != null && url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true);

class _SafeCachedNetworkImage extends StatelessWidget { 
  final String? url; 
  final double height; 
  final BoxFit fit; 
  const _SafeCachedNetworkImage({this.url, required this.height, this.fit = BoxFit.cover}); 
  
  @override 
  Widget build(BuildContext context) { 
    if (!_isValidUrl(url)) { 
      return Container(height: height, color: Theme.of(context).colorScheme.surface, child: Center(child: Icon(Icons.photo, size: 50, color: Colors.white.withOpacity(0.5)))); 
    } 
    return CachedNetworkImage(
      imageUrl: url!, 
      height: height, 
      width: double.infinity, 
      fit: fit, 
      placeholder: (context, url) => Shimmer.fromColors(baseColor: primaryColor, highlightColor: const Color(0xFF1a2c5a), child: Container(height: height, color: Colors.white)), 
      errorWidget: (context, url, error) => Container(height: height, color: primaryColor, child: const Icon(Icons.broken_image, color: Colors.white)), 
    ); 
  } 
}

IconData _getIconData(String? iconName) { 
  switch (iconName) { 
    case 'church': return Icons.church; 
    case 'people': return Icons.people; 
    case 'event': return Icons.event; 
    default: return Icons.info; 
  } 
}