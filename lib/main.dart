import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- CRITICAL FIX: Added the missing import

// --- LOCALIZATION IMPORTS ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- PROVIDER IMPORTS ---
import 'package:amde_haymanot_abalat_guday/admin%20only/user_provider.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/content_manager.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/grade_provider.dart';

// --- SCREEN IMPORTS (All Screens) ---
import 'package:amde_haymanot_abalat_guday/admin%20only/attendance_audit_screen.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/manage_family.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/family_detail_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/about_us.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/splashscreen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/start_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/login.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/signup.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/home_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/book_read_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/book_review.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/attendance_history_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/amde_platform.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/admin_info.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/admin_manage_users.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/home_page_admin_screen.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/permission_management.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/profile_admin.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/admin_lbms.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/attendance_conclusion.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/attendance_manager.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/grade_management_screen.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/learning_admin.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/library_director_screen.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/private.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/ekid.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/student_list.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/student_reading_history.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/student_status_registeration.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/platform_admin.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/family_view_screen.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/star_rate.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/learning_screen.dart';


// --- GLOBAL INSTANCES & CONSTANTS ---
final supabase = Supabase.instance.client;
const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
const Color accentColor = Color(0xFFFFD700);

// --- MAIN APP INITIALIZATION ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load the file by its new name
  await dotenv.load(fileName: "dotenv"); // <-- UPDATED to match the new filename

  // --- The rest of your main function remains the same ---
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw StateError('FATAL ERROR: Supabase credentials not found in dotenv file.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  await initializeDateFormatting('am', null);
  runApp(const MyApp());
}

// ... The rest of your MyApp class and router code remains the same
// --- ROOT WIDGET ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ContentManager()),
        ChangeNotifierProvider(create: (context) => GradeProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final router = _createRouter(userProvider);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('am', ''),
              Locale('en', ''),
            ],
            locale: const Locale('am', ''),
            
            theme: _buildThemeData(),
          );
        },
      ),
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        brightness: Brightness.dark,
        background: primaryColor,
        onPrimary: Colors.white,
        onSecondary: primaryColor,
        onBackground: Colors.white,
        surface: const Color(0xFF1D2939),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
            color: accentColor, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      textTheme: GoogleFonts.poppinsTextTheme()
          .apply(bodyColor: Colors.white, displayColor: accentColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryColor,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1D2939).withOpacity(0.5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white38)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white38)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentColor, width: 2)),
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: accentColor),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  GoRouter _createRouter(UserProvider userProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: userProvider,
      debugLogDiagnostics: true,
      
      redirect: (BuildContext context, GoRouterState state) {
        final loggedIn = supabase.auth.currentSession != null;
        final isPublicRoute = ['/login', '/signup', '/start', '/splash']
            .contains(state.matchedLocation);
        final destination = state.uri.toString();
        final isPermissionsLoading = userProvider.isLoading;

        if (isPermissionsLoading && loggedIn) {
          return null;
        }

        if (!loggedIn && !isPublicRoute) return '/start';
        if (loggedIn && isPublicRoute) return '/home';

        if (loggedIn && !isPublicRoute) {
          final allowedScreens = userProvider.allowedScreens;

          if (allowedScreens.contains(destination)) return null;

          if (destination.startsWith('/family-view/')) {
            if (allowedScreens.contains('/family-view')) return null;
          }
          if (destination.startsWith('/admin/user-editor/')) {
            if (allowedScreens.contains('/admin/user-manager')) return null;
          }
          // Fix for book reviews route
          if (destination.startsWith('/book-reviews/')) {
             if (allowedScreens.contains('/book-reviews')) return null;
          }

          debugPrint(
              "Redirecting: User does not have permission for $destination. Sending to /home.");
          return '/home';
        }

        return null;
      },
      
      routes: [
        GoRoute(path: '/', redirect: (_, __) => '/splash'),
        GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
        GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
        GoRoute(path: '/login', builder: (context, state) => const Login()),
        GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/modern-books', builder: (context, state) => const ModernBookListScreen()),
        GoRoute(path: '/attendance-history', builder: (context, state) => const AttendanceHistoryScreen()),
        GoRoute(path: '/amde-platform', builder: (context, state) => const AmdePlatform()),
        GoRoute(path: '/book-reviews', builder: (context, state) => const UserLibraryScreen()),
        GoRoute(path: '/admin/user-manager', builder: (context, state) => const UnifiedAdminScreen()),
        GoRoute(path: '/learning', builder: (context, state) => const LearningScreen()),
        GoRoute(path: '/admin/user-editor/:userId', builder: (context, state) => AdminUserEditorScreen(userId: state.pathParameters['userId']!),),
        GoRoute(path: '/admin/permission-manager', builder: (context, state) => const SuperAdminDashboardScreen()),
        GoRoute(path: '/admin/home', builder: (context, state) => const HomePageAdminScreen()),
        GoRoute(path: '/admin/profile', builder: (context, state) => const AdminScreenp()),
        GoRoute(path: '/admin/library', builder: (context, state) => const AdminLibraryScreen()),
        GoRoute(path: '/admin/library/director', builder: (context, state) => const LibraryDirectorScreen()),
        GoRoute(path: '/admin/learning', builder: (context, state) => const LearningAdminScreen()),
        GoRoute(path: '/admin/attendance/summary', builder: (context, state) => const AttendanceSummaryScreen()),
        GoRoute(path: '/admin/attendance/manager', builder: (context, state) => const AttendanceScreen()),
        GoRoute(path: '/admin/planning', builder: (context, state) => const PlanControlScreen()),
        GoRoute(
            path: '/admin/grades',
            builder: (context, state) {
              final gradeProvider = Provider.of<GradeProvider>(context);
              return GradeManagementScreen(key: ValueKey(gradeProvider.refreshKey));
            },
        ),
        GoRoute(path: '/admin/notes', builder: (context, state) => const AdminPrivateManagementScreen()),
        GoRoute(path: '/family-view', builder: (context, state) => const FamilyViewScreen()),
        GoRoute(path: '/admin/family-links', builder: (context, state) => const FamilyLinkingScreen()),
        GoRoute(
          path: '/family-view/:studentId',
          builder: (context, state) {
            final studentId = state.pathParameters['studentId']!;
            return FamilyStudentDetailScreen(studentId: studentId);
          },
        ),
        // --- NEW/FIXED ROUTE FOR BOOK REVIEWS ---
        GoRoute(path: '/about-us', builder: (context, state) => const AboutUsScreen()),
        GoRoute(path: '/admin/attendance/audit', builder: (context, state) => const AuditScreen()),
        GoRoute(
          path: '/admin/reading-dashboard',
          builder: (context, state) => const ReadingDashboardScreen(),
        ),
          GoRoute(
          path: '/admin/platform',
          builder: (context, state) => const PlatformAdminScreen(),
        ),
        GoRoute(
          path: '/admin/batch-management',
          builder: (context, state) {
            return BatchManagementScreen(
              onBatchRegistered: () {
                Provider.of<GradeProvider>(context, listen: false).triggerRefresh();
              },
            );
          },
        ),
        GoRoute(
          path: '/admin/student-list',
          builder: (context, state) => const StudentListScreen(),
        ),
         GoRoute(
          path:  '/admin/manual-star',
          builder: (context, state) => const ManualStarScreen(),
        ),
      ],

      errorBuilder: (context, state) => Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: accentColor, size: 80),
                const SizedBox(height: 24),
                Text('404 - Page Not Found',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                Text(
                  "The page you tried to access (${state.uri.toString()}) doesn't exist or you don't have permission to view it.",
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}