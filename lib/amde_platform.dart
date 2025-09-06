import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class AmdePlatform extends StatelessWidget {
  const AmdePlatform({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Color Scheme
    Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color accentColor = const Color(0xFF8B4513); // Deep Maroon/Brown
    Color cardColor = isDarkMode ? Colors.grey[850]! : Colors.grey[50]!;
    Color shadowColor = isDarkMode ? Colors.black : Colors.grey.shade400;
    Color lightShadowColor = isDarkMode ? Colors.grey[800]! : Colors.white;

    // Platform Links Data
    const List<Map<String, dynamic>> platformLinks = [
      {
        'label': 'Amde Haymanot Zimare',
        'linkText': 'Playstore',
        'url':
            'https://play.google.com/store/apps/details?id=com.example.amdehaymanot_abalat_guday',
        'icon': FontAwesomeIcons.googlePlay,
        'color': Colors.green,
      },
      {
        'label': 'Amde Haymanot Library (PDF)',
        'linkText': 'Telegram',
        'url': 'https://t.me/amdehaymanot',
        'icon': FontAwesomeIcons.book,
        'color': Colors.blue,
      },
      {
        'label': 'Serate Timihrt Bot',
        'linkText': 'Telegram',
        'url': 'https://t.me/amdehaymanot',
        'icon': FontAwesomeIcons.robot,
        'color': Colors.orange,
      },
      {
        'label': 'Official Telegram Channel',
        'linkText': 'Telegram',
        'url': 'https://t.me/amdehaymanot',
        'icon': FontAwesomeIcons.telegram,
        'color': Colors.lightBlue,
      },
      {
        'label': 'Amde Haymanot Official Website',
        'linkText': 'Website',
        'url': 'https://amdehaymanot.org/',
        'icon': FontAwesomeIcons.globe,
        'color': Colors.indigo,
      },
    ];

    // Social Media Data
    const List<Map<String, dynamic>> socialMedia = [
      {
        'icon': FontAwesomeIcons.youtube,
        'url': 'https://youtube.com/your-channel-name',
        'color': Colors.red,
      },
      {
        'icon': FontAwesomeIcons.facebook,
        'url': 'https://facebook.com/your-page',
        'color': Colors.blue,
      },
      {
        'icon': FontAwesomeIcons.instagram,
        'url': 'https://instagram.com/your-profile',
        'color': Colors.purple,
      },
      {
        'icon': FontAwesomeIcons.telegram,
        'url': 'https://t.me/your-channel',
        'color': Colors.lightBlue,
      },
      {
        'icon': FontAwesomeIcons.tiktok,
        'url': 'https://tiktok.com/@your-profile',
        'color': Colors.black,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with Logo and Title
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
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: accentColor,
                      ),
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
                platformLinks: platformLinks,
                cardColor: cardColor,
                textColor: textColor,
                shadowColor: shadowColor,
                lightShadowColor: lightShadowColor,
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

              _buildSocialMediaRow(
                context,
                socialMedia: socialMedia,
                backgroundColor: backgroundColor,
                shadowColor: shadowColor,
                lightShadowColor: lightShadowColor,
              ),

              const SizedBox(height: 30),

              // Footer
              FadeIn(
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  '© 2023 Amde Haymanot',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformList(
    BuildContext context, {
    required List<Map<String, dynamic>> platformLinks,
    required Color cardColor,
    required Color textColor,
    required Color shadowColor,
    required Color lightShadowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: lightShadowColor,
            offset: const Offset(-4, -4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: cardColor,
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
                    linkText: platformLinks[index]['linkText'],
                    url: platformLinks[index]['url'],
                    icon: platformLinks[index]['icon'],
                    iconColor: platformLinks[index]['color'],
                    textColor: textColor,
                    isLast: index == platformLinks.length - 1,
                  ),
                ),
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
    required bool isLast,
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
    required Color backgroundColor,
    required Color shadowColor,
    required Color lightShadowColor,
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
            icon: socialMedia[index]['icon'],
            url: socialMedia[index]['url'],
            color: socialMedia[index]['color'],
            backgroundColor: backgroundColor,
            shadowColor: shadowColor,
            lightShadowColor: lightShadowColor,
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
    required Color backgroundColor,
    required Color shadowColor,
    required Color lightShadowColor,
  }) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(4, 4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: lightShadowColor,
              offset: const Offset(-4, -4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: color, size: 28)),
      ),
    );
  }
}
