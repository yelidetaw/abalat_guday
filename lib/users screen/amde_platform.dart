import 'package:amde_haymanot_abalat_guday/admin%20only/platform_admin.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/user_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AmdePlatform extends StatefulWidget {
  const AmdePlatform({super.key});

  @override
  State<AmdePlatform> createState() => _AmdePlatformState();
}

class _AmdePlatformState extends State<AmdePlatform> {
  List<Map<String, dynamic>> _platformLinks = [];
  List<Map<String, dynamic>> _socialMedia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  Future<void> _fetchLinks() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final platforms = await supabase
          .from('platform_links')
          .select()
          .order('sort_order', ascending: true);
      final socials = await supabase
          .from('social_media_links')
          .select()
          .order('sort_order', ascending: true);

      if (mounted) {
        setState(() {
          _platformLinks = List<Map<String, dynamic>>.from(platforms);
          _socialMedia = List<Map<String, dynamic>>.from(socials);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching links: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $urlString')),
        );
      }
    }
  }

  // Helper to get IconData from a string name
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'googleplay':
        return FontAwesomeIcons.googlePlay;
      case 'book':
        return FontAwesomeIcons.book;
      case 'robot':
        return FontAwesomeIcons.robot;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      case 'globe':
        return FontAwesomeIcons.globe;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      default:
        return FontAwesomeIcons.link;
    }
  }

  // Helper to get Color from a hex string
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extend colors from the global theme
    final theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onBackground;
    final Color accentColor = theme.colorScheme.secondary;
    final Color cardColor = theme.brightness == Brightness.dark
        ? 
Color.fromARGB(255, 1, 37, 100)
        : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platforms'),
        // The back button will be automatically handled by the Navigator
      ),
      // Use a Consumer to conditionally show the admin button
      floatingActionButton: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // IMPORTANT: Replace '/admin/platform-manager' with the actual screen key for PlatformAdminScreen
          if (userProvider.canAccess('/admin/platform-manager')) {
            return FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PlatformAdminScreen()),
                );
                if (result == true) {
                  _fetchLinks();
                }
              },
              backgroundColor: accentColor,
              child: Icon(Icons.edit, color: theme.colorScheme.onSecondary),
            );
          }
          return const SizedBox
              .shrink(); // Return an empty widget if user is not admin
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 2),
                          ),
                          child: Icon(Icons.hub_outlined,
                              size: 40, color: accentColor),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Amde Haymanot',
                          style: GoogleFonts.notoSerif(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Platforms & Resources',
                          style: GoogleFonts.notoSerif(
                            fontSize: 18,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Platform Links Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Our Platforms',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPlatformList(
                    context,
                    platformLinks: _platformLinks,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 40),

                  // Social Media Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Connect With Us',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialMediaRow(context, socialMedia: _socialMedia),
                  const SizedBox(height: 30),

                  // Footer Section
                  FadeIn(
                    duration: const Duration(milliseconds: 1000),
                    child: Text(
                      '© ${DateTime.now().year} Amde Haymanot',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlatformList(
    BuildContext context, {
    required List<Map<String, dynamic>> platformLinks,
    required Color cardColor,
    required Color textColor,
  }) {
    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: List.generate(
            platformLinks.length,
            (index) => FadeInRight(
              duration: Duration(milliseconds: 500 + (index * 150)),
              child: _buildPlatformItem(
                context,
                label: platformLinks[index]['label'],
                linkText: platformLinks[index]['link_text'],
                url: platformLinks[index]['url'],
                icon: _getIconData(platformLinks[index]['icon_name']),
                iconColor: _getColorFromHex(platformLinks[index]['color_hex']),
                textColor: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformItem(
    BuildContext context, {
    required String label,
    required String linkText,
    required String url,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () => _launchURL(url),
      splashColor: iconColor.withOpacity(0.1),
      highlightColor: iconColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                linkText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaRow(
    BuildContext context, {
    required List<Map<String, dynamic>> socialMedia,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 20,
      children: List.generate(
        socialMedia.length,
        (index) => FadeIn(
          duration: Duration(milliseconds: 800 + (index * 200)),
          child: _buildSocialIcon(
            context,
            icon: _getIconData(socialMedia[index]['icon_name']),
            url: socialMedia[index]['url'],
            color: _getColorFromHex(socialMedia[index]['color_hex']),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(
    BuildContext context, {
    required IconData icon,
    required String url,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(50),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Center(child: FaIcon(icon, color: color, size: 28)),
        ),
      ),
    );
  }
}
