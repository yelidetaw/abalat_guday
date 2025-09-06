import 'package:amde_haymanot_abalat_guday/admin_lbms.dart';
import 'package:amde_haymanot_abalat_guday/admin_manage_users.dart';
import 'package:amde_haymanot_abalat_guday/attendance_conclusion.dart';
import 'package:amde_haymanot_abalat_guday/attendance_manager.dart';
import 'package:amde_haymanot_abalat_guday/grade_management_screen.dart';
import 'package:amde_haymanot_abalat_guday/homepage.dart';
import 'package:amde_haymanot_abalat_guday/learning_admin.dart';
import 'package:amde_haymanot_abalat_guday/learning_screen.dart';
import 'package:amde_haymanot_abalat_guday/library_director_screen.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:amde_haymanot_abalat_guday/profile_admin.dart';
import 'package:amde_haymanot_abalat_guday/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Page'));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // A list of widgets to display based on selection
  final List<Widget> _widgetOptions = <Widget>[
    ProfileScreen(),
    AdminScreenp(),
    AdminScreenL(),
    LearningScreen(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- The user data variables are now correctly defined inside the build method ---
    final currentUser = supabase.auth.currentUser;
    final fullName = currentUser?.userMetadata?['full_name'] ?? 'Guest User';
    final email = currentUser?.email ?? 'no-email@example.com';

    // Adaptive theme logic
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    Color backgroundColor = isDarkMode
        ? Colors.grey[850]!
        : const Color(0xFFF0F0F3);
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color neumorphicShadowColor = isDarkMode
        ? Colors.black
        : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: textColor,
        ), // Ensures drawer icon is visible in dark/light mode
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Amde Haymanot',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => _onItemTapped(3), // Switch to the Profile tab
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: neumorphicShadowColor,
                      offset: const Offset(3, 3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/am-11.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    fullName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to a real settings page, e.g., context.go('/settings');
                print('Navigate to Settings page');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                supabase.auth.signOut();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      ),
      bottomNavigationBar: _buildNeumorphicBottomNavigationBar(
        context,
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: backgroundColor,
        neumorphicShadowColor: neumorphicShadowColor,
        textColor: textColor,
      ),
    );
  }

  Widget _buildNeumorphicBottomNavigationBar(
    BuildContext context, {
    required int selectedIndex,
    required Function(int) onTap,
    required Color backgroundColor,
    required Color neumorphicShadowColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: neumorphicShadowColor,
            offset: const Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.church_outlined,
              color: selectedIndex == 0 ? Colors.blue : textColor,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.work_history_outlined,
              color: selectedIndex == 1 ? Colors.blue : textColor,
            ),
            label: 'Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.book_online_rounded,
              color: selectedIndex == 2 ? Colors.blue : textColor,
            ),
            label: 'Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_off_outlined,
              color: selectedIndex == 3 ? Colors.blue : textColor,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: onTap,
        selectedItemColor: Colors.blue,
        unselectedItemColor: textColor,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
    );
  }
}
