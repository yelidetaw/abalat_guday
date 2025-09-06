import 'package:amde_haymanot_abalat_guday/users%20screen/social_media_url.dart';
import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold and all child widgets will automatically use the
    // theme defined in your main.dart file.
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      // Use a LayoutBuilder to create a responsive design.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              // Add more horizontal padding on wider screens.
              horizontal: constraints.maxWidth > 760 ? 80.0 : 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeroSection(context),
                const SizedBox(height: 48),
                _buildOurStorySection(context, constraints),
                const SizedBox(height: 48),
                _buildCoreValuesSection(context, constraints),
                const SizedBox(height: 48),
                _buildConnectSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The main heading and mission statement.
  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.church_rounded,
          size: 80,
          color: theme.colorScheme.secondary, // Gold
        ),
        const SizedBox(height: 16),
        Text(
          'ዓምደ ሃይማኖት',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nurturing Faith, Building Community',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// The "Our Story" section, which is responsive.
  Widget _buildOurStorySection(
      BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    const storyText =
        "Amde Haymanot began as a humble initiative to bring together the faithful through technology. Our goal is to provide accessible spiritual resources, foster a strong sense of community, and support the spiritual growth of every member in accordance with the teachings of the Ethiopian Orthodox Tewahedo Church. We believe in the power of faith to transform lives and are dedicated to being a pillar of support for our community.";

    // For wider screens, show an image next to the text.
    if (constraints.maxWidth > 760) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/login_person.png', // Replace with a relevant image
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: theme.colorScheme.surface,
                  child: Icon(Icons.groups_2_rounded,
                      size: 100,
                      color: theme.colorScheme.secondary.withOpacity(0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 3,
            child: Text(storyText,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
          ),
        ],
      );
    }

    // On mobile, show the text only.
    return Text(storyText,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6));
  }

  /// The "Core Values" section, responsive with a GridView on wider screens.
  Widget _buildCoreValuesSection(
      BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final values = [
      {
        'icon': Icons.favorite_rounded,
        'title': 'Faith',
        'subtitle': 'Rooted in Orthodox tradition.'
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'Community',
        'subtitle': 'United in love and support.'
      },
      {
        'icon': Icons.school_rounded,
        'title': 'Learning',
        'subtitle': 'Growing in knowledge and wisdom.'
      },
      {
        'icon': Icons.volunteer_activism_rounded,
        'title': 'Service',
        'subtitle': 'Serving God and one another.'
      },
    ];

    return Column(
      children: [
        Text('Our Core Values',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 760 ? 4 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.0,
          ),
          itemCount: values.length,
          itemBuilder: (context, index) {
            final value = values[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(value['icon'] as IconData,
                        size: 40, color: theme.colorScheme.secondary),
                    const SizedBox(height: 12),
                    Text(
                      // CORRECTED: Explicitly cast the value to a String.
                      value['title'] as String,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // CORRECTED: Explicitly cast the value to a String.
                      value['subtitle'] as String,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// The final section with social media links.
  Widget _buildConnectSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Connect With Us',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          "Join our community on social media to stay updated with the latest news, events, and teachings.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        const SocialMediaUrl(), // Your existing social media widget
      ],
    );
  }
}
