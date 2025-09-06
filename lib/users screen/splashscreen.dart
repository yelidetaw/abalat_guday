import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For supabase instance and colors

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isVisible = false; // Used for the fade-in animation

  @override
  void initState() {
    super.initState();
    // Start the fade-in animation shortly after the screen is built
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
    _redirect();
  }

  Future<void> _redirect() async {
    // We add a delay to allow the splash screen to be visible for a moment.
    // This improves the user experience.
    await Future.delayed(const Duration(seconds: 2));
    
    // Safety check to ensure the widget is still in the widget tree.
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session != null) {
      // Use go() for replacing the splash screen in the navigation stack
      context.go('/home');
    } else {
      // If not logged in, go to the start screen
      context.go('/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use your app's primary branding color for the background
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AnimatedOpacity provides a smooth fade-in effect
            AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(seconds: 1),
              curve: Curves.easeIn,
              child: Column(
                children: [
                  // --- YOUR LOGO GOES HERE ---
                  // Make sure you have a 'splash_logo.png' in 'assets/images/'
                  // or change the path to your actual logo file.
                  Image.asset(
                    'assets/images/am-11.png',
                    width: 150, // Adjust the size of your logo as needed
                    height: 150,
                  ),
                  const SizedBox(height: 40), // Space between logo and indicator
                ],
              ),
            ),
            
            // A clean loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}