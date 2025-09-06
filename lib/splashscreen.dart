// lib/pages/splash_page.dart  (or splash_screen.dart)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // --- FIX 1: Import go_router ---
import 'package:amde_haymanot_abalat_guday/main.dart'; // To access the global 'supabase' client

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Start the redirection logic as soon as the page is built
    _redirect();
  }

  Future<void> _redirect() async {
    // This brief delay ensures the widget is fully mounted before we navigate.
    await Future.delayed(Duration.zero);

    // IMPORTANT: Check if the widget is still in the tree before navigating.
    if (!mounted) return;

    // --- FIX 2: Use the global supabase client directly ---
    // Get the current session from Supabase.
    final session = supabase.auth.currentSession;

    if (session != null) {
      // If a session exists, the user is already logged in.
      // --- FIX 3: Use context.go() to navigate to the home route ---
      context.go('/home');
    } else {
      // If no session, the user needs to log in.
      // --- FIX 4: Use context.go() to navigate to the login route ---
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading screen UI
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
