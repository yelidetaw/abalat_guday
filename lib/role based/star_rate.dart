import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

// UI Constants for this screen
const Color kAdminBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminPrimaryAccent = Color(0xFFFFD700);
const Color kAdminSecondaryText = Color(0xFFFFD700);

class ManualStarScreen extends StatefulWidget {
  const ManualStarScreen({super.key});
  @override
  State<ManualStarScreen> createState() => _ManualStarScreenState();
}

class _ManualStarScreenState extends State<ManualStarScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      // Note: This needs a corresponding RPC function in Supabase
      final response = await supabase.rpc('get_users_for_manual_star');
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching users for manual star: $e');
      throw 'ተጠቃሚዎችን መጫን አልተሳካም።';
    }
  }

  void _refreshList() {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  void _showScoreDialog(String userId, String userName, int currentScore) {
    double sliderValue = currentScore.toDouble();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: kAdminCardColor,
              title: Text('$userName - ውጤት ይስጡ', style: GoogleFonts.notoSansEthiopic(color: kAdminPrimaryAccent)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sliderValue.toInt().toString(),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Slider(
                    value: sliderValue,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: sliderValue.round().toString(),
                    activeColor: kAdminPrimaryAccent,
                    inactiveColor: kAdminSecondaryText,
                    onChanged: (double value) {
                      setDialogState(() {
                        sliderValue = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText))),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _setScore(userId, sliderValue.toInt());
                  },
                  child: Text('አስቀምጥ', style: GoogleFonts.notoSansEthiopic()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _setScore(String userId, int score) async {
    try {
      await supabase.rpc('set_manual_star_score', params: {'p_user_id': userId, 'p_score': score});
      _refreshList(); // Refresh the list to show the change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update score: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAdminBackgroundColor,
      appBar: AppBar(
        title: Text('የኮከብ አስተዳደር', style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: kAdminBackgroundColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingShimmer();
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('ምንም ተጠቃሚ አልተገኘም', style: GoogleFonts.notoSansEthiopic()));

          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final int score = (user['manual_star_score'] as num?)?.toInt() ?? 0;
              final double starValue = score / 10.0;
              return FadeInUp(
                from: 20,
                delay: Duration(milliseconds: 50 * index),
                child: Card(
                  color: kAdminCardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _showScoreDialog(user['id'], user['full_name'], score),
                    leading: CircleAvatar(
                      backgroundImage: user['profile_image_url'] != null ? NetworkImage(user['profile_image_url']) : null,
                      child: user['profile_image_url'] == null ? Text(user['full_name']?[0] ?? '?') : null,
                    ),
                    title: Text(user['full_name'] ?? 'No Name', style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
                    trailing: Chip(
                      label: Text('$score / 10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      avatar: Icon(Icons.star, color: starValue > 0 ? Colors.amber : kAdminSecondaryText, size: 18),
                      backgroundColor: kAdminBackgroundColor,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kAdminCardColor,
      highlightColor: kAdminBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: const ListTile(
            leading: CircleAvatar(),
            title: Text(''),
          ),
        ),
      ),
    );
  }
}