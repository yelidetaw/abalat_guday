import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Local project imports
import 'package:amde_haymanot_abalat_guday/main.dart'; // For the global 'supabase' instance and theme colors
import 'package:amde_haymanot_abalat_guday/admin%20only/user_provider.dart'; // To check user permissions

class AppDrawer extends StatelessWidget {
  // Callback to handle navigation for items on the main BottomNavBar
  final Function(int) onItemTapped;

  const AppDrawer({
    super.key,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Extend colors and styles from the global theme
    final theme = Theme.of(context);

    // Get user details that don't often change.
    final currentUser = supabase.auth.currentUser;
    final fullName = currentUser?.userMetadata?['full_name'] ?? 'Guest User';
    final email = currentUser?.email ?? 'no-email@example.com';

    // A comprehensive map of ALL possible drawer items in your app.
    final allDrawerItems = <String, Map<String, dynamic>>{
      // --- General User Items ---
      '/home': {'icon': Icons.home_filled, 'title': 'ዋና ገጽ'},
      '/profile': {'icon': Icons.person_rounded, 'title': 'የግል መረጃ'},
      '/learning': {'icon': Icons.school_outlined, 'title': 'መንፈሳዊ ትምህርት'},
      '/book-reviews': {'icon': Icons.reviews_outlined, 'title': 'የመጻሕፍት ዳሰሳ'},
      '/attendance-history': { 'icon': Icons.history_edu_outlined, 'title': 'የአቴንዳንስ ታሪክ' },
      '/amde-platform': {'icon': Icons.groups_outlined, 'title': 'ማህበራዊ ሚዲያዎች'},
      '/about-us': {'icon': Icons.info_outline_rounded, 'title': 'ስለ እኛ'},
      '/family-view': { 'icon': Icons.family_restroom_rounded, 'title': 'የቤተሰብ ቁጥጥር' },

      // --- Admin & Leadership Items ---
      '/admin/home': { 'icon': Icons.dashboard_rounded, 'title': 'የዋና ገጽ አስተዳደር' },
      '/admin/profile': { 'icon': Icons.person_search_rounded, 'title': 'የአስተዳዳሪ ፕሮፋይል' },
      '/admin/library': { 'icon': Icons.local_library_rounded, 'title': 'የቤተ-መጻሕፍት አስተዳደር' },
      '/admin/library/director': { 'icon': Icons.supervisor_account_rounded, 'title': 'የመጻሕፍት ጥቆማ' },
      '/admin/learning': { 'icon': Icons.model_training_rounded, 'title': 'የትምህርት አስተዳደር' },
      '/admin/attendance/summary': { 'icon': Icons.assessment_rounded, 'title': 'የአቴንዳንስ ማጠቃለያ' },
      '/admin/attendance/manager': { 'icon': Icons.edit_calendar_rounded, 'title': 'የአቴንዳንስ አስተዳደር' },
      '/admin/attendance/audit': { 'icon': Icons.history_edu_rounded, 'title': 'የክትትል ታሪክ ፍተሻ' },
      '/admin/planning': { 'icon': Icons.next_plan_rounded, 'title': 'የእቅድ አስተዳደር' },
      '/admin/grades': {'icon': Icons.grade_rounded, 'title': 'የውጤት አስተዳደር'},
      '/admin/notes': {'icon': Icons.note_alt_rounded, 'title': 'የግል ማስታወሻ'},
      '/admin/user-manager': { 'icon': Icons.manage_accounts_outlined, 'title': 'የአባላት አስተዳደር' },
      '/admin/permission-manager': { 'icon': Icons.shield_rounded, 'title': 'አጠቃላይ አስተዳደር' },
      '/admin/family-links': { 'icon': Icons.add_link_rounded, 'title': 'የቤተሰብ ማገናኛ አስተዳደር' },
      '/leader-reports': { 'icon': Icons.bar_chart_outlined, 'title': 'የቡድን መሪ ሪፖርቶች' },
      '/admin/reading-dashboard': { 'icon': Icons.menu_book_rounded, 'title': 'የንባብ ዳሽቦርድ' },
      '/admin/batch-management': { 'icon': Icons.group_add_rounded, 'title': 'የተማሪዎች ምዝገባና ማሳደግ' },
      '/admin/student-list': { 'icon': Icons.list_alt_rounded, 'title': 'የተማሪዎች ዝርዝር' },
      '/admin/platform': { 'icon': Icons.web_rounded, 'title': 'የማህበራዊ ሚዲያ አስተዳደር' },
      '/admin/manual-star':{'icon': Icons.star, 'title': 'አጠቃላይ ምዘና'}
    };

    // Define the visual structure and grouping of the drawer.
    final List<Map<String, dynamic>> sections = [
      { 'title': 'ዋና', 'routes': ['/home', '/profile', '/family-view'] },
      { 'title': 'አካዳሚክ', 'routes': [ '/learning', '/book-reviews', '/attendance-history' ] },
      { 'title': 'ማኅበረሰብ', 'routes': ['/amde-platform'] },
      { 'title': 'የአስተዳደር ገጾች', 'routes': [
          '/admin/home', '/admin/user-manager', '/admin/permission-manager',
          '/admin/family-links', '/admin/planning', '/admin/notes', '/admin/platform'
        ]
      },
      { 'title': 'የተማሪ አስተዳደር', 'routes': [ '/admin/student-list', '/admin/batch-management','/admin/manual-star' ] },
      { 'title': 'የቁጥጥር ገጾች', 'routes': [
          '/admin/learning', '/admin/grades', '/admin/attendance/summary',
          '/admin/attendance/manager', '/admin/attendance/audit'
        ]
      },
      { 'title': 'የቤተ-መጻሕፍት ቁጥጥር ገጾች', 'routes': [
          '/admin/library', '/admin/library/director', '/admin/reading-dashboard',
        ]
      },
      { 'title': 'መተግበሪያ', 'routes': ['/about-us'] },
    ];

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final allowedScreens = userProvider.allowedScreens;

          if (userProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary));
          }

          return Column(
            children: [
              _buildDrawerHeader(context, theme, fullName, email, userProvider), // Pass the provider
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...sections.expand((section) {
                      final visibleRoutes = section['routes']
                          .where((route) => allowedScreens.contains(route))
                          .toList();
                      if (visibleRoutes.isEmpty) return <Widget>[];

                      return [
                        _buildSectionHeader(context, theme, section['title']),
                        ...visibleRoutes.map((route) {
                          final item = allDrawerItems[route]!;
                          return _buildDrawerItem(
                            context, theme,
                            icon: item['icon'],
                            title: item['title'],
                            onTap: () => _handleNavigation(context, route),
                          );
                        }),
                        Divider(thickness: 1, indent: 16, endIndent: 16, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      ];
                    }),
                    _buildDrawerItem(
                      context, theme,
                      icon: Icons.logout_rounded,
                      title: 'ውጣ',
                      onTap: () => _confirmLogout(context, theme),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- THIS WIDGET IS NOW UPDATED ---
  Widget _buildDrawerHeader(
      BuildContext context, ThemeData theme, String fullName, String email, UserProvider userProvider) {
    return UserAccountsDrawerHeader(
      accountName: Text(fullName,
          style: GoogleFonts.notoSansEthiopic(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.secondary)),
      accountEmail: Text(email,
          style: GoogleFonts.poppins(
              color: theme.colorScheme.onPrimary.withOpacity(0.8))),
      currentAccountPicture: CircleAvatar(
        backgroundColor: theme.colorScheme.secondary,
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'G',
          style: TextStyle(
              fontSize: 40.0,
              color: theme.colorScheme.onSecondary,
              fontWeight: FontWeight.bold),
        ),
      ),
      decoration: BoxDecoration(color: theme.primaryColor),
      // --- THIS IS THE NEW REFRESH BUTTON ---
      otherAccountsPictures: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: Colors.white,
            tooltip: 'Refresh Permissions',
            onPressed: () {
              userProvider.fetchUserPermissions();
              Scaffold.of(context).closeDrawer(); // Close drawer after tapping
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.notoSansEthiopic(
          color: theme.colorScheme.secondary.withOpacity(0.7),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, ThemeData theme,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.8)),
      title: Text(title,
          style: GoogleFonts.notoSansEthiopic(
              fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
      onTap: onTap,
      dense: true,
      hoverColor: theme.colorScheme.secondary.withOpacity(0.1),
      focusColor: theme.colorScheme.secondary.withOpacity(0.2),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    Navigator.pop(context); // Always close the drawer first

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final learningIndex = userProvider.isAdmin ? 2 : 1;
    final profileIndex = userProvider.isAdmin ? 3 : 2;

    if (route == '/home') {
      onItemTapped(0);
    } else if (route == '/learning') {
      onItemTapped(learningIndex);
    } else if (route == '/profile') {
      onItemTapped(profileIndex);
    } else {
      context.push(route);
    }
  }

  Future<void> _confirmLogout(BuildContext context, ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('መውጣቱን ያረጋግጡ',
            style: GoogleFonts.notoSansEthiopic(
                color: theme.colorScheme.secondary)),
        content: Text('ከመለያዎ መውጣት ይፈልጋሉ?',
            style: GoogleFonts.notoSansEthiopic(
                color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ይቅር',
                style: GoogleFonts.notoSansEthiopic(
                    color: theme.colorScheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ውጣ', style: GoogleFonts.notoSansEthiopic()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.of(context).pop(); 
      await supabase.auth.signOut();
    }
  }
}