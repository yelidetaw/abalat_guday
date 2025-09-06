import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Added for DateFormat

class CommentsScreen extends StatefulWidget {
  final int resourceId;
  final String resourceTitle;

  const CommentsScreen({
    Key? key,
    required this.resourceId,
    required this.resourceTitle,
  }) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('resource_comments')
          .select('*, profiles(username, avatar_url)')
          .eq('resource_id', widget.resourceId)
          .order('created_at', ascending: false);

      setState(() {
        _comments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load comments';
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _supabase.from('resource_comments').insert({
        'resource_id': widget.resourceId,
        'user_id': _supabase.auth.currentUser?.id,
        'content': _commentController.text.trim(),
      });

      _commentController.clear();
      await _fetchComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments: ${widget.resourceTitle}')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final user = comment['profiles'] ?? {};
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatar_url'] != null
                                ? NetworkImage(user['avatar_url'])
                                : null,
                            child: user['avatar_url'] == null
                                ? Text(
                                    user['username']?.toString().substring(
                                          0,
                                          1,
                                        ) ??
                                        '?',
                                  )
                                : null,
                          ),
                          title: Text(user['username'] ?? 'Anonymous'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment['content']),
                              Text(
                                DateFormat(
                                  'MMM d, y - h:mm a',
                                ).format(DateTime.parse(comment['created_at'])),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall, // Changed from caption to bodySmall
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
