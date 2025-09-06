// lib/widgets/app_bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';
import 'package:amde_haymanot_abalat_guday/admin%20only/user_provider.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final List<BarItem> barItems = [
      BarItem(title: 'Home', icon: Icons.home_rounded),
      if (userProvider.isAdmin)
        BarItem(title: 'Management', icon: Icons.admin_panel_settings_rounded),
      BarItem(title: 'Learning', icon: Icons.school_rounded),
      BarItem(title: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2472), // Deep blue
            Color(0xFF001C55), // Darker blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: SlidingClippedNavBar(
          backgroundColor: Colors.transparent,
          inactiveColor: Colors.white.withOpacity(0.7),
          activeColor: Colors.amber,
          selectedIndex: selectedIndex,
          onButtonPressed: onItemTapped,
          barItems: barItems,
          iconSize: 26,
          // The package doesn't support curve, buttonPadding, or animationDuration parameters
          // These have been removed to fix the error
        ),
      ),
    );
  }
}

