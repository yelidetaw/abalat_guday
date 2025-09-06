import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:amde_haymanot_abalat_guday/content_manager.dart';

class HomePageAdminScreen extends StatefulWidget {
  const HomePageAdminScreen({Key? key}) : super(key: key);

  @override
  _HomePageAdminScreenState createState() => _HomePageAdminScreenState();
}

class _HomePageAdminScreenState extends State<HomePageAdminScreen> {
  // Controllers for ContentManager
  final _controllers = <String, TextEditingController>{
    'hero_image_url': TextEditingController(),
    'about_us_text': TextEditingController(),
    'sunday_school_image_url': TextEditingController(),
    'sunday_school_text': TextEditingController(),
    'history_text': TextEditingController(),
    'learning_card_image_url': TextEditingController(),
  };

  // Controllers for Service Times
  final _serviceTitleController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _serviceScheduleController = TextEditingController();
  final _serviceIconController = TextEditingController();
  int? _editingServiceId;

  // Controllers for News & Events
  final _newsTitleController = TextEditingController();
  final _newsDateController = TextEditingController();
  final _newsDescController = TextEditingController();
  final _newsImageUrlController = TextEditingController();
  int? _editingNewsId;

  bool _isSavingContent = false;
  bool _isLoadingLists = true;

  List<Map<String, dynamic>> _serviceTimes = [];
  List<Map<String, dynamic>> _newsEvents = [];

  @override
  void initState() {
    super.initState();
    final contentManager = Provider.of<ContentManager>(context, listen: false);
    _controllers.forEach((key, controller) {
      controller.text = contentManager.siteContent[key] ?? '';
    });
    _loadLists();
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    _serviceTitleController.dispose();
    _serviceDescController.dispose();
    _serviceScheduleController.dispose();
    _serviceIconController.dispose();
    _newsTitleController.dispose();
    _newsDateController.dispose();
    _newsDescController.dispose();
    _newsImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoadingLists = true);
    try {
      final serviceRes = await Supabase.instance.client
          .from('service_times')
          .select('*')
          .order('display_order');
      final newsRes = await Supabase.instance.client
          .from('news_and_events')
          .select('*')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _serviceTimes = List<Map<String, dynamic>>.from(serviceRes);
          _newsEvents = List<Map<String, dynamic>>.from(newsRes);
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error loading lists: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLists = false);
    }
  }

  Future<void> _saveAllContent() async {
    setState(() => _isSavingContent = true);
    final recordsToUpsert = <Map<String, dynamic>>[];
    _controllers.forEach(
      (key, controller) =>
          recordsToUpsert.add({'key': key, 'value': controller.text.trim()}),
    );

    try {
      await Supabase.instance.client
          .from('site_content')
          .upsert(recordsToUpsert);
      final newContentMap = <String, String>{};
      _controllers.forEach(
        (key, controller) => newContentMap[key] = controller.text.trim(),
      );
      context.read<ContentManager>().updateAllContent(newContentMap);
      if (mounted) {
        _showSnackBar('Homepage content saved successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error saving content: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingContent = false);
    }
  }

  // --- Service Time Functions ---
  Future<void> _addOrUpdateService({int? id}) async {
    final title = _serviceTitleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Title cannot be empty.', isError: true);
      return;
    }
    try {
      final data = {
        'title': title,
        'description': _serviceDescController.text.trim(),
        'schedule': _serviceScheduleController.text.trim(),
        'icon_name': _serviceIconController.text.trim(),
      };
      if (id == null) {
        await Supabase.instance.client.from('service_times').insert(data);
      } else {
        await Supabase.instance.client
            .from('service_times')
            .update(data)
            .eq('id', id);
      }
      _clearServiceForm();
      await _loadLists();
      _showSnackBar('Service time saved.');
    } catch (e) {
      _showSnackBar('Error saving service: $e', isError: true);
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      await Supabase.instance.client
          .from('service_times')
          .delete()
          .eq('id', id);
      await _loadLists();
      _showSnackBar('Service time deleted.');
    } catch (e) {
      _showSnackBar('Error deleting service: $e', isError: true);
    }
  }

  void _clearServiceForm() {
    _serviceTitleController.clear();
    _serviceDescController.clear();
    _serviceScheduleController.clear();
    _serviceIconController.clear();
    setState(() => _editingServiceId = null);
  }

  // --- News & Events Functions ---
  Future<void> _addOrUpdateNews({int? id}) async {
    final title = _newsTitleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Title cannot be empty.', isError: true);
      return;
    }
    try {
      final data = {
        'title': title,
        'event_date': _newsDateController.text.trim(),
        'description': _newsDescController.text.trim(),
        'image_url': _newsImageUrlController.text.trim(),
      };
      if (id == null) {
        await Supabase.instance.client.from('news_and_events').insert(data);
      } else {
        await Supabase.instance.client
            .from('news_and_events')
            .update(data)
            .eq('id', id);
      }
      _clearNewsForm();
      await _loadLists();
      _showSnackBar('News/Event saved.');
    } catch (e) {
      _showSnackBar('Error saving news/event: $e', isError: true);
    }
  }

  Future<void> _deleteNews(int id) async {
    try {
      await Supabase.instance.client
          .from('news_and_events')
          .delete()
          .eq('id', id);
      await _loadLists();
      _showSnackBar('News/Event deleted.');
    } catch (e) {
      _showSnackBar('Error deleting news/event: $e', isError: true);
    }
  }

  void _clearNewsForm() {
    _newsTitleController.clear();
    _newsDateController.clear();
    _newsDescController.clear();
    _newsImageUrlController.clear();
    setState(() => _editingNewsId = null);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
    ),
  );
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
    child: Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Homepage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('General Content'),
            ..._controllers.entries.map(
              (entry) => _buildTextField(
                label: entry.key.replaceAll('_', ' ').toUpperCase(),
                controller: entry.value,
                maxLines: entry.key.contains('text') ? 3 : 1,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSavingContent ? null : _saveAllContent,
              child: _isSavingContent
                  ? const CircularProgressIndicator()
                  : const Text('Save General Content'),
            ),
            const Divider(height: 40, thickness: 2),

            _buildSectionTitle('Service Times'),
            _buildTextField(
              label: 'Service Title',
              controller: _serviceTitleController,
            ),
            _buildTextField(
              label: 'Service Description',
              controller: _serviceDescController,
            ),
            _buildTextField(
              label: 'Schedule (e.g., Every Sunday at 10 AM)',
              controller: _serviceScheduleController,
            ),
            _buildTextField(
              label: 'Icon Name (e.g., church, people)',
              controller: _serviceIconController,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_editingServiceId != null)
                  TextButton(
                    onPressed: _clearServiceForm,
                    child: const Text('CANCEL'),
                  ),
                ElevatedButton(
                  onPressed: () => _addOrUpdateService(id: _editingServiceId),
                  child: Text(
                    _editingServiceId == null
                        ? 'Add Service'
                        : 'Update Service',
                  ),
                ),
              ],
            ),
            _isLoadingLists
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _serviceTimes.length,
                    itemBuilder: (context, index) {
                      final service = _serviceTimes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(service['title']),
                          subtitle: Text(service['schedule']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => setState(() {
                                  _editingServiceId = service['id'];
                                  _serviceTitleController.text =
                                      service['title'];
                                  _serviceDescController.text =
                                      service['description'];
                                  _serviceScheduleController.text =
                                      service['schedule'];
                                  _serviceIconController.text =
                                      service['icon_name'];
                                }),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteService(service['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const Divider(height: 40, thickness: 2),

            _buildSectionTitle('News & Events'),
            _buildTextField(
              label: 'Event Title',
              controller: _newsTitleController,
            ),
            _buildTextField(
              label: 'Event Date (e.g., July 25, 2025)',
              controller: _newsDateController,
            ),
            _buildTextField(
              label: 'Event Description',
              controller: _newsDescController,
              maxLines: 2,
            ),
            _buildTextField(
              label: 'Event Image URL',
              controller: _newsImageUrlController,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_editingNewsId != null)
                  TextButton(
                    onPressed: _clearNewsForm,
                    child: const Text('CANCEL'),
                  ),
                ElevatedButton(
                  onPressed: () => _addOrUpdateNews(id: _editingNewsId),
                  child: Text(
                    _editingNewsId == null ? 'Add Event' : 'Update Event',
                  ),
                ),
              ],
            ),
            _isLoadingLists
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _newsEvents.length,
                    itemBuilder: (context, index) {
                      final event = _newsEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(event['title']),
                          subtitle: Text(event['event_date']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => setState(() {
                                  _editingNewsId = event['id'];
                                  _newsTitleController.text = event['title'];
                                  _newsDateController.text =
                                      event['event_date'];
                                  _newsDescController.text =
                                      event['description'];
                                  _newsImageUrlController.text =
                                      event['image_url'] ?? '';
                                }),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteNews(event['id']),
                              ),
                            ],
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
