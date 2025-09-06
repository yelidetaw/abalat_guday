// lib/screens/user_activity_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class UserActivityScreen extends StatefulWidget {
  const UserActivityScreen({super.key});

  @override
  State<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen> {
  late Future<List<Map<String, dynamic>>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _fetchActivities();
  }

  Future<List<Map<String, dynamic>>> _fetchActivities() async {
    final supabase = Supabase.instance.client;
    try {
      // This is a powerful query that fetches related data from other tables.
      final response = await supabase
          .from('user_activities')
          .select('''
        id,
        created_at,
        activity_type,
        duration_seconds,
        is_completed,
        profiles (full_name),
        learning_resources (title)
      ''')
          .order('created_at', ascending: false)
          .limit(100); // Added a limit for performance
      return response;
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      throw 'Failed to load user activities.';
    }
  }

  // Refreshes the data by re-calling the fetch method.
  Future<void> _handleRefresh() async {
    setState(() {
      _activityFuture = _fetchActivities();
    });
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  // A shimmer effect for a better loading experience.
  Widget _buildLoadingShimmer() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.primaryColor.withOpacity(0.5),
      highlightColor: theme.colorScheme.surface,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(),
              title: Container(
                height: 16,
                width: 200,
                color: Colors.white,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(height: 12, width: 150, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(height: 12, width: 100, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // AppBar is automatically styled by the global theme in main.dart
      appBar: AppBar(
        title: const Text('User Activity'),
        // The back arrow will appear automatically when pushed onto the stack
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.secondary, // Gold
        backgroundColor: theme.primaryColor, // Purple
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShimmer();
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off,
                          color: theme.colorScheme.secondary, size: 60),
                      const SizedBox(height: 20),
                      Text("Failed to Load Activities",
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      Text("${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _handleRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off,
                        color: theme.colorScheme.secondary, size: 60),
                    const SizedBox(height: 20),
                    Text('No Activity Found',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text('User activity will be recorded here.',
                        style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
            }

            final activities = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                // Safely access nested data
                final userName =
                    activity['profiles']?['full_name'] ?? 'Unknown User';
                final resourceTitle = activity['learning_resources']
                        ?['title'] ??
                    'Deleted Resource';
                final isCompleted = activity['is_completed'] as bool;

                // Using brand colors for status
                final statusColor = isCompleted
                    ? theme.colorScheme.secondary
                    : Colors.grey.shade600;
                final iconColor =
                    isCompleted ? theme.colorScheme.onSecondary : Colors.white;

                return FadeInUp(
                  from: 20,
                  duration: const Duration(milliseconds: 400),
                  child: Card(
                    // Card color is now handled by the global theme
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      leading: CircleAvatar(
                        backgroundColor: statusColor,
                        child: Icon(
                          activity['activity_type'] == 'video'
                              ? Icons.videocam_rounded
                              : Icons.article_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        '$userName viewed "$resourceTitle"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                      text: 'Duration: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  TextSpan(
                                      text: _formatDuration(
                                          activity['duration_seconds'])),
                                ],
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                      text: 'Status: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  TextSpan(
                                      text: isCompleted
                                          ? 'Completed'
                                          : 'In Progress'),
                                ],
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat.yMMMd().add_jm().format(
                                    DateTime.parse(activity['created_at'])
                                        .toLocal(),
                                  ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
