// lib/users screen/home_screen.dart (FINAL - Using a Simple Callback)
import 'package:amde_haymanot_abalat_guday/role%20based/attendance_manager.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/homepage.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/learning_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/profile_screen.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/drawer.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/bottom_nav_bar.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import any other pages you need
// import 'package:amde_haymanot_abalat_guday/users%20screen/homepage.dart';
// import 'package:amde_haymanot_abalat_guday/users%20screen/learning_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final List<Widget> pageOptions = [
      const HomePage(),
      if (userProvider.isAdmin) const AttendanceScreen(),
      // Use a ValueKey. When _gradeScreenKey changes, this widget will rebuild from scratch.
       const LearningScreen(),    
       const ProfileScreen(),
    ];

    final List<String> pageTitles = [
      'ዋና ገጽ', // More accurate title
      if (userProvider.isAdmin) 'አስተዳደራዊ ተግባራት ',
      'ትምህርታዊ ገጽ',
      'የግል መረጃ',
    ];

    final int displayedIndex =
        _selectedIndex < pageOptions.length ? _selectedIndex : 0;

    final String? avatarUrl = userProvider.avatarUrl;
    final bool hasImage = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(pageTitles[displayedIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                final profileIndex =
                    pageOptions.indexWhere((widget) => widget is ProfileScreen);
                if (profileIndex != -1) {
                  _onItemTapped(profileIndex);
                }
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: hasImage
                    ? NetworkImage(avatarUrl)
                    : const AssetImage('assets/images/am-11.png') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(onItemTapped: _onItemTapped),
      body: SafeArea(
        child: IndexedStack(
          index: displayedIndex,
          children: pageOptions,
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: displayedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}