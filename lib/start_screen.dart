import 'package:amde_haymanot_abalat_guday/login.dart';
import 'package:amde_haymanot_abalat_guday/signup.dart';
import 'package:amde_haymanot_abalat_guday/social_media_url.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold and SafeArea are the base for our screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // LayoutBuilder rebuilds its child when the window size changes
        child: LayoutBuilder(
          builder: (context, constraints) {
            // We define a breakpoint to switch between mobile and desktop layouts
            const double breakpoint = 600.0;

            if (constraints.maxWidth < breakpoint) {
              // Use mobile layout for narrow screens
              return _buildMobileLayout(context);
            } else {
              // Use desktop/tablet layout for wider screens
              return _buildDesktopLayout(context);
            }
          },
        ),
      ),
    );
  }

  /// Builds the layout for mobile devices (narrow screens).
  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          // All the content widgets go here
          _buildContent(context),
          const Spacer(flex: 3),
          const SocialMediaUrl(),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  /// Builds the layout for tablets and desktops (wide screens).
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left Panel: Image
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/images/login_person.png',
              height: 300, // Make image a bit larger on desktop
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Right Panel: Content
        Expanded(
          child: Center(
            // ConstrainedBox prevents the content from becoming too wide on large screens
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildContent(context),
                    const SizedBox(height: 30),
                    const SocialMediaUrl(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A shared widget containing the text and buttons to avoid code duplication.
  Widget _buildContent(BuildContext context) {
    return Column(
      // crossAxisAlignment.stretch makes children like buttons fill the width
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // On mobile, the image is part of the content column
        if (MediaQuery.of(context).size.width < 600)
          Image.asset('assets/images/login_person.png', height: 250),
        const SizedBox(height: 24),
        const Text(
          'ሰላም',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 90, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'በኢትዮጵያ ኦርቶዶክስ ተዋህዶ ቤተክርስቲያን',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 48),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    Login(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      // Use a FadeTransition
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('ይግቡ'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SignUpScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('ይመዝገቡ'),
        ),
      ],
    );
  }
}
