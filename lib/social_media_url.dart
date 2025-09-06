import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaUrl extends StatelessWidget {
  const SocialMediaUrl({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    // A constant for the icon size to easily change all icons at once
    const double customIconSize = 35.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          // THE FIX: Add the iconSize property
          iconSize: customIconSize,
          onPressed: () => _launchURL('https://youtube.com/your-channel-name'),
          icon: const FaIcon(FontAwesomeIcons.youtube, color: Colors.red),
        ),
        IconButton(
          iconSize: customIconSize,
          onPressed: () => _launchURL('https://facebook.com/your-page'),
          icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue),
        ),
        IconButton(
          iconSize: customIconSize,
          onPressed: () => _launchURL('https://instagram.com/your-profile'),
          icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.purple),
        ),
        IconButton(
          iconSize: customIconSize,
          onPressed: () => _launchURL('https://t.me/your-channel'),
          icon: const FaIcon(
            FontAwesomeIcons.telegram,
            color: Colors.lightBlue,
          ),
        ),
        IconButton(
          iconSize: customIconSize,
          onPressed: () => _launchURL('https://tiktok.com/@your-profile'),
          icon: const FaIcon(FontAwesomeIcons.tiktok, color: Colors.black),
        ),
      ],
    );
  }
}
