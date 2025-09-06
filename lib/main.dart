// Your existing imports
import 'package:amde_haymanot_abalat_guday/home_page_admin_screen.dart';
import 'package:amde_haymanot_abalat_guday/home_screen.dart';
import 'package:amde_haymanot_abalat_guday/learning_admin.dart';
import 'package:amde_haymanot_abalat_guday/signup.dart';
import 'package:amde_haymanot_abalat_guday/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amde_haymanot_abalat_guday/start_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:amde_haymanot_abalat_guday/content_manager.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://deganybtadxpqsgbwyii.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlZ2FueWJ0YWR4cHFzZ2J3eWlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1NjI3NDAsImV4cCI6MjA2ODEzODc0MH0.kvDxMyZvjjjN2QxIaev1WacgwjjgTplVEAfxziCjmsc',
  );

  runApp(
    ChangeNotifierProvider(
      // Wrap the entire app with ChangeNotifierProvider
      create: (context) => ContentManager(),
      child: const MyApp(),
    ),
  );
}

// --- YOUR GO_ROUTER CONFIGURATION (UNCHANGED) ---
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    // The root route that the app starts at
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        // We use a splash screen to handle auth redirection
        return const SplashPage();
      },
    ),
    // The route for your StartScreen, which will act as the login/entry page
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return StartScreen();
      },
    ),
    // The route for your sign up screen
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return SignUpScreen();
      },
    ),
    // The route for your home screen (for logged-in users)
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(); // Assuming you have a HomeScreen
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminScreenL(); // Updated to your AdminScreen
      },
    ),
    GoRoute(
      path: '/home-admin',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePageAdminScreen();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- REPLACE THE EXISTING THEME WITH THIS ---
    final baseTheme = ThemeData.light();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A4E69), // Our modern, muted primary color
      brightness: Brightness.light,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: baseTheme.copyWith(
        colorScheme: colorScheme,
        // Set the default background color for all screens
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        // Apply the 'Poppins' font across the entire app
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
        // Define a global style for all AppBars
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        // Define a global style for all Cards
        // cardTheme: CardTheme(
        //   elevation: 0,
        //   color: Colors.white,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(16.0),
        //   ),
        // )
      ),
      // --- YOUR ROUTER CONFIGURATION (UNCHANGED) ---
      routerConfig: _router,
    );
  }
}
