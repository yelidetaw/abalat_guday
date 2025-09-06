import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:amde_haymanot_abalat_guday/content_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> _initializationFuture;
  List<Map<String, dynamic>> _pageItems = [];
  bool _isAboutUsExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      await Provider.of<ContentManager>(context, listen: false).fetchContent();
      final responses = await Future.wait([
        Supabase.instance.client
            .from('news_and_events')
            .select()
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('service_times')
            .select()
            .order('display_order'),
      ]);
      if (!mounted) return;
      final newsEvents = List<Map<String, dynamic>>.from(responses[0] as List);
      final serviceTimes = List<Map<String, dynamic>>.from(
        responses[1] as List,
      );
      final List<Map<String, dynamic>> items = [
        {'type': 'manage_button'},
        {'type': 'title', 'value': 'Learning & Resources'},
        {'type': 'learning_card'},
        {'type': 'title', 'value': 'About Our Church'},
        {'type': 'about_us'},
        {'type': 'title', 'value': 'Our Services'},
        ...serviceTimes,
        {'type': 'title', 'value': 'News & Events'},
        if (newsEvents.isEmpty) {'type': 'no_events_card'} else ...newsEvents,
        {'type': 'view_all_button'},
        {'type': 'title', 'value': 'Sunday School'},
        {'type': 'sunday_school'},
        {'type': 'title', 'value': 'Our History'},
        {'type': 'history'},
        {'type': 'footer'},
      ];
      if (mounted) setState(() => _pageItems = items);
    } catch (e) {
      debugPrint("Initialization Error: $e");
      throw Exception("Failed to load page data.");
    }
  }

  bool _isValidUrl(String? url) =>
      (url != null &&
      url.isNotEmpty &&
      Uri.tryParse(url)?.hasAbsolutePath == true);

  Widget _safeCachedNetworkImage(
    String? url, {
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (!_isValidUrl(url))
      return Container(
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.photo, size: 50, color: Colors.white),
        ),
      );
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: double.infinity,
      fit: fit,
      placeholder: (context, url) =>
          Container(height: height, color: Colors.grey[300]),
      errorWidget: (context, url, error) => Container(
        height: height,
        color: Colors.grey[800],
        child: const Icon(Icons.broken_image, color: Colors.white),
      ),
    );
  }

  Widget _buildHomepageShimmer() => Scaffold(
    body: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return _buildHomepageShimmer();
          if (snapshot.hasError)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: ${snapshot.error}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(
                      () => _initializationFuture = _initializePage(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );

          final theme = Theme.of(context);
          final accentColor = theme.colorScheme.primary
              .withRed(100)
              .withOpacity(0.9);

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _initializationFuture = _initializePage()),
            child: CustomScrollView(
              cacheExtent: 1000,
              slivers: [
                SliverAppBar(
                  expandedHeight: 280.0,
                  pinned: true,
                  backgroundColor: accentColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _safeCachedNetworkImage(
                          context
                              .watch<ContentManager>()
                              .siteContent['hero_image_url'],
                          height: 280,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeInDown(
                                child: Image.asset(
                                  'assets/images/am-11.png',
                                  width: 100,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FadeIn(
                                delay: const Duration(milliseconds: 300),
                                child: Text(
                                  'Amde Haymanot',
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              FadeIn(
                                delay: const Duration(milliseconds: 500),
                                child: Text(
                                  'Orthodox Tewahedo Faith',
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) =>
                        _buildItem(context, _pageItems[index], accentColor),
                    childCount: _pageItems.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    Map<String, dynamic> item,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final siteContent = context.watch<ContentManager>().siteContent;
    final type = item['type'] as String?;

    switch (type) {
      case 'manage_button':
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
          child: OutlinedButton.icon(
            onPressed: () => context.push('/home-admin'),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Manage Homepage Content'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
          ),
        );
      case 'title':
        return Padding(
          padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
          child: Text(
            item['value'] ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'learning_card':
        return _buildLearningCard(context, accentColor, siteContent);
      case 'about_us':
        final aboutText =
            siteContent['about_us_text'] ??
            'About us information not available.';
        final canBeTruncated = aboutText.length > 200;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, canBeTruncated ? 10 : 30),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  aboutText,
                  style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center,
                  maxLines: _isAboutUsExpanded ? null : 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canBeTruncated)
                TextButton(
                  onPressed: () =>
                      setState(() => _isAboutUsExpanded = !_isAboutUsExpanded),
                  child: Text(_isAboutUsExpanded ? 'Show Less' : 'Learn More'),
                ),
            ],
          ),
        );
      case 'sunday_school':
        return _buildTitledImageCard(
          context,
          siteContent['sunday_school_image_url'],
          siteContent['sunday_school_text'],
          'About Sunday School',
        );
      case 'history':
        return _buildTitledImageCard(
          context,
          siteContent['history_image_url'],
          siteContent['history_text'],
          'Explore Our History',
        );
      case 'footer':
        return Container(
          color: accentColor,
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                'Visit Us',
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Jimma, Ethiopia\namilake kidus yared ayileyen',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case 'no_events_card':
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No recent news or events.')),
        );
      case 'view_all_button':
        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Center(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('View All Events'),
            ),
          ),
        );
      default:
        if (item.containsKey('schedule')) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: _buildServiceCard(
              context,
              icon: _getIconData(item['icon_name']),
              title: item['title'] ?? '',
              accentColor: Colors.black,
              description: item['description'] ?? '',
              time: item['schedule'] ?? '',
            ),
          );
        }
        if (item.containsKey('event_date')) {
          return _buildEventCard(
            context,
            title: item['title'] ?? '',
            date: item['event_date'] ?? '',
            description: item['description'] ?? '',
            imageUrl: item['image_url'],
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildLearningCard(
    BuildContext context,
    Color accentColor,
    Map<String, String> siteContent,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/learning'),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            _safeCachedNetworkImage(
              siteContent['learning_card_image_url'],
              height: 150,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.school, size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digital Learning Area',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Access preaches, articles, and training videos.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _buildTitledImageCard(
    BuildContext context,
    String? imageUrl,
    String? text,
    String buttonText,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
    child: Column(
      children: [
        if (_isValidUrl(imageUrl))
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _safeCachedNetworkImage(imageUrl, height: 180),
          ),
        const SizedBox(height: 20),
        Text(
          text ?? 'Information not available.',
          style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {}, child: Text(buttonText)),
      ],
    ),
  );
  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required Color accentColor,
  }) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 40, color: accentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _buildEventCard(
    BuildContext context, {
    required String title,
    required String date,
    required String description,
    required String? imageUrl,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isValidUrl(imageUrl))
            _safeCachedNetworkImage(imageUrl, height: 160),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'church':
        return Icons.church;
      case 'people':
        return Icons.people;
      case 'event':
        return Icons.event;
      default:
        return Icons.info;
    }
  }
}
