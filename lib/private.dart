import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';

class AdminPrivateManagementScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminPrivateManagementScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminPrivateManagementScreen> createState() =>
      _AdminPrivateManagementScreenState();
}

class _AdminPrivateManagementScreenState
    extends State<AdminPrivateManagementScreen> {
  int _currentTabIndex = 0;
  final List<String> _tabTitles = ['Notes', 'Widgets'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Tools - ${widget.userName}'),
          bottom: TabBar(
            tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
            onTap: (index) => setState(() => _currentTabIndex = index),
          ),
        ),
        body: TabBarView(
          children: [
            PrivateNotesTab(userId: widget.userId),
            PrivateWidgetsTab(userId: widget.userId, userName: widget.userName),
          ],
        ),
      ),
    );
  }
}

class PrivateNotesTab extends StatefulWidget {
  final String userId;

  const PrivateNotesTab({super.key, required this.userId});

  @override
  State<PrivateNotesTab> createState() => _PrivateNotesTabState();
}

class _PrivateNotesTabState extends State<PrivateNotesTab> {
  // ... (same as previous notes implementation)
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with your actual notes implementation
    return const Center(
      child: Text('Private notes for this user will be displayed here.'),
    );
  }
}

class PrivateWidgetsTab extends StatefulWidget {
  final String userId;
  final String userName;

  const PrivateWidgetsTab({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PrivateWidgetsTab> createState() => _PrivateWidgetsTabState();
}

class _PrivateWidgetsTabState extends State<PrivateWidgetsTab> {
  List<dynamic> _widgets = [];
  bool _isLoading = true;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedWidgetType = 'summary';

  @override
  void initState() {
    super.initState();
    _fetchWidgets();
  }

  Future<void> _fetchWidgets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await supabase
          .from('admin_user_widgets')
          .select('*')
          .eq('user_id', widget.userId)
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _widgets = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Failed to fetch widgets: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWidget() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await supabase.from('admin_user_widgets').insert({
        'user_id': widget.userId,
        'widget_type': _selectedWidgetType,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'created_by': supabase.auth.currentUser?.id,
      });

      _titleController.clear();
      _contentController.clear();
      await _fetchWidgets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding widget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWidget(int widgetId) async {
    try {
      await supabase.from('admin_user_widgets').delete().eq('id', widgetId);

      await _fetchWidgets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting widget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWidgetPreview(Map<String, dynamic> widgetData) {
    switch (widgetData['widget_type']) {
      case 'summary':
        return _buildSummaryWidget(widgetData);
      case 'warning':
        return _buildWarningWidget(widgetData);
      case 'achievement':
        return _buildAchievementWidget(widgetData);
      default:
        return _buildGenericWidget(widgetData);
    }
  }

  Widget _buildSummaryWidget(Map<String, dynamic> widgetData) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widgetData['title'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widgetData['content']),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningWidget(Map<String, dynamic> widgetData) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  widgetData['title'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widgetData['content']),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementWidget(Map<String, dynamic> widgetData) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  widgetData['title'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widgetData['content']),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericWidget(Map<String, dynamic> widgetData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widgetData['title'],
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(widgetData['content']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedWidgetType,
                  items: const [
                    DropdownMenuItem(value: 'summary', child: Text('Summary')),
                    DropdownMenuItem(value: 'warning', child: Text('Warning')),
                    DropdownMenuItem(
                      value: 'achievement',
                      child: Text('Achievement'),
                    ),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedWidgetType = value!),
                  decoration: const InputDecoration(
                    labelText: 'Widget Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'Content is required' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _addWidget,
                  child: const Text('Add Widget'),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildWidgetsList()),
      ],
    );
  }

  Widget _buildWidgetsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            TextButton(onPressed: _fetchWidgets, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_widgets.isEmpty) {
      return const Center(child: Text('No widgets created yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _widgets.length,
      itemBuilder: (context, index) {
        final widgetData = _widgets[index];
        return Dismissible(
          key: ValueKey(widgetData['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Widget?'),
                content: const Text(
                  'Are you sure you want to delete this widget?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) => _deleteWidget(widgetData['id']),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildWidgetPreview(widgetData),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
