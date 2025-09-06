import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client

// Re-using the branding colors
const Color kPrimaryColor = Color.fromARGB(255, 1, 37, 100);
const Color kAccentColor = Color(0xFFFFD700);
const Color kCardColor = Color.fromARGB(255, 4, 48, 125);

class CommentsScreen extends StatefulWidget {
  final int resourceId;
  final String? resourceTitle;

  const CommentsScreen({
    super.key,
    required this.resourceId,
    this.resourceTitle,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
  }

  Future<List<Map<String, dynamic>>> _fetchComments() async {
    try {
      final response = await supabase.rpc('get_comments_for_resource',
          params: {'p_resource_id': widget.resourceId});
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      throw Exception('አስተያየቶችን መጫን አልተሳካም። እባክዎ እንደገና ይሞክሩ.');
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    final user = supabase.auth.currentUser;

    if (content.isEmpty || user == null) return;
    setState(() => _isSubmitting = true);

    try {
      // --- CRITICAL FIX: Use the correct table name 'comments' ---
      await supabase.from('comments').insert({
        'resource_id': widget.resourceId,
        'user_id': user.id,
        'content': content,
      });
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      _refreshComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('አስተያየት ማስገባት አልተሳካም: ${e.toString()}', style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _refreshComments() {
    setState(() {
      _commentsFuture = _fetchComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: Text(widget.resourceTitle ?? 'አስተያየቶች', style: GoogleFonts.notoSansEthiopic(), overflow: TextOverflow.ellipsis),
        backgroundColor: kPrimaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kAccentColor));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansEthiopic(color: Colors.red.shade400),
                      ),
                    ),
                  );
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _refreshComments(),
                    child: Center(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Center(
                            child: Text(
                              'እስካሁን ምንም አስተያየት የለም። የመጀመሪያው ይሁኑ!',
                              style: GoogleFonts.notoSansEthiopic(
                                  color: kAccentColor.withOpacity(0.8),
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshComments(),
                  color: kAccentColor,
                  backgroundColor: kPrimaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final displayName =
                          comment['full_name']?.toString() ?? 'Anonymous';
                      final avatarUrl = comment['profile_image_url']?.toString();
                      final content = comment['content']?.toString() ?? '';
                      final createdAt = comment['created_at']?.toString();

                      return Card(
                        color: kCardColor,
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: kAccentColor.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kAccentColor,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: kAccentColor),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(content,
                                  style: GoogleFonts.notoSansEthiopic(
                                      color: Colors.white70)),
                              const SizedBox(height: 8),
                              if (createdAt != null)
                                Text(
                                  DateFormat('MMM d, y - h:mm a').format(
                                      DateTime.parse(createdAt).toLocal()),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Comment Input Field
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          hintText: 'አስተያየትዎን ያክሉ...',
                          hintStyle: GoogleFonts.notoSansEthiopic(color: Colors.white54),
                          border: InputBorder.none,
                          fillColor: kCardColor,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: kAccentColor))
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: kAccentColor)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: kAccentColor),
                          onPressed: _addComment,
                          tooltip: 'Send Comment',
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}