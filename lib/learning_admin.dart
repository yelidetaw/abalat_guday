import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// The enum definition was missing from the original snippet.
enum ContentType { video, article }

class AdminScreenL extends StatefulWidget {
  const AdminScreenL({Key? key}) : super(key: key);

  @override
  State<AdminScreenL> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreenL> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _loadingActivities = false;
  List<Map<String, dynamic>> _userActivities = [];
  List<Map<String, dynamic>> _resources = [];

  ContentType _selectedContentType = ContentType.video;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _articleBodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final Map<String, bool> _categories = {
    'is_orthodox_preach': false,
    'is_personal_dev': false,
    'is_training': false,
  };

  // Improvement: Map keys to user-friendly display names for the UI.
  final Map<String, String> _categoryDisplayNames = {
    'is_orthodox_preach': 'Orthodox Preaching',
    'is_personal_dev': 'Personal Development',
    'is_training': 'Training',
  };

  @override
  void initState() {
    super.initState();
    _fetchResources();
    _fetchUserActivities();
  }

  Future<void> _fetchResources() async {
    try {
      final response = await Supabase.instance.client
          .from('learning_resources')
          .select('*')
          .order('created_at', ascending: false);
      // The Supabase client returns a List, so we cast it directly.
      setState(
        () => _resources = List<Map<String, dynamic>>.from(response as List),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading resources: $e')));
      }
    }
  }

  Future<void> _fetchUserActivities() async {
    setState(() => _loadingActivities = true);
    try {
      final response = await Supabase.instance.client
          .from('user_activities')
          .select('*, learning_resources(title)')
          .order('created_at', ascending: false)
          .limit(100);
      setState(() {
        _userActivities = List<Map<String, dynamic>>.from(response as List);
        _loadingActivities = false;
      });
    } catch (e) {
      setState(() => _loadingActivities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
    }
  }

  String? _extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return (match != null && match.group(2)!.length == 11)
        ? match.group(2)
        : null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_categories.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      //
      // ===== FIX IS HERE =====
      //
      // Explicitly define the map to allow nullable Objects (Object?).
      // This solves the error.
      final Map<String, Object?> dataToInsert = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'content_type': _selectedContentType.name,
        'is_orthodox_preach': _categories['is_orthodox_preach']!,
        'is_personal_dev': _categories['is_personal_dev']!,
        'is_training': _categories['is_training']!,
      };

      if (_selectedContentType == ContentType.video) {
        // This assignment is now valid because dataToInsert can accept null values.
        dataToInsert['youtube_id'] = _extractYoutubeId(
          _youtubeUrlController.text,
        );
      } else {
        dataToInsert['content_body'] = _articleBodyController.text;
        if (_imageUrlController.text.isNotEmpty) {
          dataToInsert['image_url'] = _imageUrlController.text;
        }
      }

      await Supabase.instance.client
          .from('learning_resources')
          .insert(dataToInsert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content uploaded successfully!')),
        );
      }
      _fetchResources();
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _youtubeUrlController.clear();
    _articleBodyController.clear();
    _imageUrlController.clear();
    setState(() => _categories.updateAll((key, value) => false));
  }

  String _formatDuration(dynamic seconds) {
    // Safely handle null or non-integer values.
    if (seconds is! int || seconds <= 0) return '0m 0s';
    final duration = Duration(seconds: seconds);
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    _articleBodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: 'Add Content'),
              Tab(icon: Icon(Icons.analytics), text: 'User Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Add Content Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<ContentType>(
                      segments: const [
                        ButtonSegment(
                          value: ContentType.video,
                          label: Text('Video'),
                          icon: Icon(Icons.video_library),
                        ),
                        ButtonSegment(
                          value: ContentType.article,
                          label: Text('Article'),
                          icon: Icon(Icons.article),
                        ),
                      ],
                      selected: {_selectedContentType},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedContentType = selection.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedContentType == ContentType.video)
                      TextFormField(
                        controller: _youtubeUrlController,
                        decoration: const InputDecoration(
                          labelText: 'YouTube URL',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (_extractYoutubeId(value!) == null)
                            return 'Invalid URL';
                          return null;
                        },
                      )
                    else
                      Column(
                        children: [
                          TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Image URL (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _articleBodyController,
                            decoration: const InputDecoration(
                              labelText: 'Article Content',
                            ),
                            maxLines: 10,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Categories:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._categories.keys.map(
                      (key) => CheckboxListTile(
                        // Use the display names map for a cleaner UI.
                        title: Text(_categoryDisplayNames[key] ?? key),
                        value: _categories[key],
                        onChanged: (value) =>
                            setState(() => _categories[key] = value ?? false),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Upload Content'),
                    ),
                  ],
                ),
              ),
            ),
            // User Analytics Tab
            _loadingActivities
                ? const Center(child: CircularProgressIndicator())
                : _userActivities.isEmpty
                ? const Center(child: Text('No activities found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _userActivities[index];
                      // Safely handle potentially null related-record data.
                      final resource =
                          activity['learning_resources']
                              as Map<String, dynamic>? ??
                          {};

                      // Safely handle potentially null values from the database.
                      final title = resource['title'] ?? 'Unknown Resource';
                      final userId =
                          activity['user_id']?.toString() ?? 'Unknown User';
                      final activityType =
                          activity['activity_type'] ?? 'unknown';
                      final duration = _formatDuration(
                        activity['duration_seconds'],
                      );
                      final isCompleted =
                          activity['is_completed'] as bool? ?? false;
                      final createdAt = activity['created_at'] != null
                          ? DateFormat(
                              'MMM d, y - h:mm a',
                            ).format(DateTime.parse(activity['created_at']))
                          : 'Unknown date';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('User: $userId'),
                              Text('Type: $activityType'),
                              if (activity['duration_seconds'] != null &&
                                  activity['duration_seconds'] > 0)
                                Text('Duration: $duration'),
                              Text('Completed: ${isCompleted ? 'Yes' : 'No'}'),
                              Text('Date: $createdAt'),
                            ],
                          ),
                          trailing: Icon(
                            activityType == 'video'
                                ? Icons.video_library
                                : Icons.article,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
