import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/content_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- BRANDING COLORS (As requested) ---
const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
const Color accentColor = Color(0xFFFFD700);
const Color cardBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color secondaryTextColor = Color(0xFFFFD700);

class HomePageAdminScreen extends StatefulWidget {
  const HomePageAdminScreen({super.key});

  @override
  _HomePageAdminScreenState createState() => _HomePageAdminScreenState();
}

class _HomePageAdminScreenState extends State<HomePageAdminScreen> {
  // Global Keys for Forms
  final _generalContentFormKey = GlobalKey<FormState>();
  final _servicesFormKey = GlobalKey<FormState>();
  final _newsFormKey = GlobalKey<FormState>();

  // Controllers
  final _controllers = <String, TextEditingController>{};
  final _contentKeys = ['hero_image_url', 'about_us_text', 'learning_card_image_url', 'sunday_school_image_url', 'sunday_school_text', 'history_image_url', 'history_text'];
  final _serviceTitleController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _serviceScheduleController = TextEditingController();
  final _serviceIconController = TextEditingController();
  final _newsTitleController = TextEditingController();
  final _newsDateController = TextEditingController();
  final _newsDescController = TextEditingController();
  final _newsImageUrlController = TextEditingController();

  // State
  bool _isSavingGeneral = false;
  bool _isSavingService = false;
  bool _isSavingNews = false;
  int? _editingServiceId;
  int? _editingNewsId;
  
  List<Map<String, dynamic>> _serviceTimes = [];
  List<Map<String, dynamic>> _newsEvents = [];

  @override
  void initState() {
    super.initState();
    final contentManager = Provider.of<ContentManager>(context, listen: false);
    for (var key in _contentKeys) {
      _controllers[key] = TextEditingController(text: contentManager.siteContent[key] ?? '');
    }
    _serviceTimes = List<Map<String, dynamic>>.from(contentManager.content.serviceTimes);
    _newsEvents = List<Map<String, dynamic>>.from(contentManager.content.newsAndEvents);
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

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.notoSansEthiopic()),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green,
    ));
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('እርግጠኛ ኖት?', style: GoogleFonts.notoSansEthiopic()),
        content: Text('ይህ ድርጊት የማይቀለበስ ሲሆን መረጃውን በቋሚነት ያጠፋል።', style: GoogleFonts.notoSansEthiopic()),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic())),
          TextButton(onPressed: () => context.pop(true), child: Text('አጥፋ', style: GoogleFonts.notoSansEthiopic(color: Colors.red.shade700))),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(String contentKey, TextEditingController controllerToUpdate) async {
    final isGeneralSection = _controllers.containsValue(controllerToUpdate);

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (imageFile == null) return;

    if (mounted) setState(() => isGeneralSection ? _isSavingGeneral = true : _isSavingNews = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${contentKey}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await Supabase.instance.client.storage.from('site-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(upsert: false, contentType: imageFile.mimeType),
      );
      
      final imageUrl = Supabase.instance.client.storage.from('site-images').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          controllerToUpdate.text = imageUrl;
        });
      }
      _showSnackbar('ምስሉ በተሳካ ሁኔታ ተጭኗል!');

    } catch (e, s) {
      developer.log('Image Upload Error', name: 'HomePageAdmin', error: e, stackTrace: s);
      _showSnackbar('ምስሉን መጫን አልተቻለም: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => isGeneralSection ? _isSavingGeneral = false : _isSavingNews = false);
    }
  }

  Future<void> _saveAllContent() async {
    if (!_generalContentFormKey.currentState!.validate()) return;
    setState(() => _isSavingGeneral = true);
    final contentMap = {for (var e in _controllers.entries) e.key: e.value.text.trim()};
    try {
      await Supabase.instance.client.rpc('update_site_content', params: {'p_content': contentMap});
      await context.read<ContentManager>().fetchContent();
      _showSnackbar('የመነሻ ገጽ ይዘት በተሳካ ሁኔታ ተቀምጧል!');
      if (mounted) context.pop();
    } catch (e) {
      _showSnackbar('ይዘቱን በማስቀመጥ ላይ ስህተት ተፈጥሯል: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingGeneral = false);
    }
  }

  Future<void> _addOrUpdateService({int? id}) async {
    if (!_servicesFormKey.currentState!.validate()) return;
    setState(() => _isSavingService = true);
    final data = {'title': _serviceTitleController.text.trim(), 'description': _serviceDescController.text.trim(), 'schedule': _serviceScheduleController.text.trim(), 'icon_name': _serviceIconController.text.trim()};
    try {
      if (id == null) {
        await Supabase.instance.client.from('service_times').insert(data);
      } else {
        await Supabase.instance.client.from('service_times').update(data).eq('id', id);
      }
      _clearServiceForm();
      await context.read<ContentManager>().fetchContent();
      if(mounted) setState(() => _serviceTimes = context.read<ContentManager>().content.serviceTimes);
      _showSnackbar('የአገልግሎት ሰዓት በተሳካ ሁኔታ ተቀምጧል።');
    } catch (e) {
      _showSnackbar('የአገልግሎት ሰዓቱን በማስቀመጥ ላይ ስህተት ተፈጥሯል', isError: true);
    } finally {
      if(mounted) setState(() => _isSavingService = false);
    }
  }

  Future<void> _deleteService(int id) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('service_times').delete().eq('id', id);
      await context.read<ContentManager>().fetchContent();
      if(mounted) setState(() => _serviceTimes = context.read<ContentManager>().content.serviceTimes);
      _showSnackbar('የአገልግሎት ሰዓት ተሰርዟል።');
    } catch (e) {
      _showSnackbar('የአገልግሎት ሰዓቱን በመሰረዝ ላይ ስህተት ተፈጥሯል', isError: true);
    }
  }

  void _clearServiceForm() {
    _servicesFormKey.currentState?.reset();
    _serviceTitleController.clear(); _serviceDescController.clear();
    _serviceScheduleController.clear(); _serviceIconController.clear();
    setState(() => _editingServiceId = null);
  }

  void _editService(Map<String, dynamic> service) {
    setState(() {
      _editingServiceId = service['id'];
      _serviceTitleController.text = service['title'] ?? '';
      _serviceDescController.text = service['description'] ?? '';
      _serviceScheduleController.text = service['schedule'] ?? '';
      _serviceIconController.text = service['icon_name'] ?? '';
    });
  }

  Future<void> _addOrUpdateNews({int? id}) async {
    if (!_newsFormKey.currentState!.validate()) return;
    setState(() => _isSavingNews = true);
    final data = {'title': _newsTitleController.text.trim(), 'event_date': _newsDateController.text.trim(), 'description': _newsDescController.text.trim(), 'image_url': _newsImageUrlController.text.trim()};
    try {
      if (id == null) {
        await Supabase.instance.client.from('news_and_events').insert(data);
      } else {
        await Supabase.instance.client.from('news_and_events').update(data).eq('id', id);
      }
      _clearNewsForm();
      await context.read<ContentManager>().fetchContent();
      if(mounted) setState(() => _newsEvents = context.read<ContentManager>().content.newsAndEvents);
      _showSnackbar('ዜና/ዝግጅት በተሳካ ሁኔታ ተቀምጧል።');
    } catch (e) {
      _showSnackbar('ዜና/ዝግጅቱን በማስቀመጥ ላይ ስህተት ተፈጥሯል', isError: true);
    } finally {
      if(mounted) setState(() => _isSavingNews = false);
    }
  }

  Future<void> _deleteNews(int id) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('news_and_events').delete().eq('id', id);
      await context.read<ContentManager>().fetchContent();
      if(mounted) setState(() => _newsEvents = context.read<ContentManager>().content.newsAndEvents);
      _showSnackbar('ዜና/ዝግጅት ተሰርዟል።');
    } catch (e) {
      _showSnackbar('ዜና/ዝግጅቱን በመሰረዝ ላይ ስህተት ተፈጥሯል', isError: true);
    }
  }

  void _clearNewsForm() {
    _newsFormKey.currentState?.reset();
    _newsTitleController.clear(); _newsDateController.clear();
    _newsDescController.clear(); _newsImageUrlController.clear();
    setState(() => _editingNewsId = null);
  }

  void _editNews(Map<String, dynamic> event) {
    setState(() {
      _editingNewsId = event['id'];
      _newsTitleController.text = event['title'] ?? '';
      _newsDateController.text = event['event_date'] ?? '';
      _newsDescController.text = event['description'] ?? '';
      _newsImageUrlController.text = event['image_url'] ?? '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: Text('የመነሻ ገጽ አስተዳደር', style: GoogleFonts.notoSansEthiopic()),
          backgroundColor: primaryColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: accentColor, labelColor: accentColor, unselectedLabelColor: secondaryTextColor,
            labelStyle: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'ዋና ይዘት'),
              Tab(text: 'የአገልግሎት ሰዓቶች'),
              Tab(text: 'ዜና እና ዝግጅቶች'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralContentSection(),
            _buildServiceTimesSection(),
            _buildNewsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralContentSection() {
    return Form(
      key: _generalContentFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('ዋና ክፍል'),
          _buildImageUploader('hero_image_url', 'የጀግና ምስል', controller: _controllers['hero_image_url']!, isSaving: _isSavingGeneral),
          _buildTextField('about_us_text', 'ስለ እኛ', maxLines: 5),
          _buildSectionTitle('የትምህርት ካርድ'),
          _buildImageUploader('learning_card_image_url', 'የትምህርት ካርድ ምስል', controller: _controllers['learning_card_image_url']!, isSaving: _isSavingGeneral),
          _buildSectionTitle('ሰንበት ትምህርት ቤት'),
          _buildImageUploader('sunday_school_image_url', 'የሰ/ት/ቤት ምስል', controller: _controllers['sunday_school_image_url']!, isSaving: _isSavingGeneral),
          _buildTextField('sunday_school_text', 'የሰ/ት/ቤት ገለጻ', maxLines: 4),
          _buildSectionTitle('ታሪክ'),
          _buildImageUploader('history_image_url', 'የታሪክ ምስል', controller: _controllers['history_image_url']!, isSaving: _isSavingGeneral),
          _buildTextField('history_text', 'የታሪክ ገለጻ', maxLines: 4),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSavingGeneral ? null : _saveAllContent,
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSavingGeneral ? const CircularProgressIndicator(color: primaryColor) : Text('ዋና ይዘትን አስቀምጥ', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildServiceTimesSection() {
    return _buildListManagementSection(
      formKey: _servicesFormKey,
      formFields: Column(
        children: [
          _buildTextField('title', 'የአገልግሎት ርዕስ', controller: _serviceTitleController, validator: (v) => v!.isEmpty ? 'ርዕስ ያስፈልጋል' : null),
          _buildTextField('description', 'መግለጫ', controller: _serviceDescController, maxLines: 2),
          _buildTextField('schedule', 'መርሐግብር', controller: _serviceScheduleController),
          _buildTextField('icon_name', 'የአዶ ስም (e.g., church, people)', controller: _serviceIconController),
        ],
      ),
      isEditing: _editingServiceId != null,
      onClearForm: _clearServiceForm,
      isSaving: _isSavingService,
      onSave: () => _addOrUpdateService(id: _editingServiceId),
      listItems: _serviceTimes,
      itemBuilder: (item) => ListTile(
        title: Text(item['title'], style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(item['schedule'], style: GoogleFonts.notoSansEthiopic(color: secondaryTextColor)),
        onTap: () => _editService(item),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteService(item['id'])),
      ),
    );
  }

  Widget _buildNewsSection() {
    return _buildListManagementSection(
      formKey: _newsFormKey,
      formFields: Column(
        children: [
          _buildTextField('title', 'የዝግጅት ርዕስ', controller: _newsTitleController, validator: (v) => v!.isEmpty ? 'ርዕስ ያስፈልጋል' : null),
          _buildTextField('event_date', 'ቀን', controller: _newsDateController),
          _buildTextField('description', 'የዝግጅት መግለጫ', controller: _newsDescController, maxLines: 3),
          _buildImageUploader('image_url', 'የዝግጅት ምስል', controller: _newsImageUrlController, isSaving: _isSavingNews),
        ],
      ),
      isEditing: _editingNewsId != null,
      onClearForm: _clearNewsForm,
      isSaving: _isSavingNews,
      onSave: () => _addOrUpdateNews(id: _editingNewsId),
      listItems: _newsEvents,
      itemBuilder: (item) => ListTile(
        leading: _isValidUrl(item['image_url']) ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover) : null,
        title: Text(item['title'], style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(item['event_date'], style: GoogleFonts.notoSansEthiopic(color: secondaryTextColor)),
        onTap: () => _editNews(item),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteNews(item['id'])),
      ),
    );
  }

  Widget _buildListManagementSection({
    required GlobalKey<FormState> formKey,
    required Widget formFields,
    required bool isEditing,
    required VoidCallback onClearForm,
    required bool isSaving,
    required VoidCallback onSave,
    required List<Map<String, dynamic>> listItems,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(key: formKey, child: formFields),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isEditing) TextButton(onPressed: onClearForm, child: Text('ሰርዝ', style: GoogleFonts.notoSansEthiopic())),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: primaryColor),
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                  : Text(isEditing ? 'አዘምን' : 'ጨምር', style: GoogleFonts.notoSansEthiopic()),
            ),
          ],
        ),
        const Divider(height: 32, color: secondaryTextColor),
        Text('ያሉ ዝርዝሮች', style: GoogleFonts.notoSansEthiopic(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        listItems.isEmpty
            ? Center(child: Text('ምንም አልተገኘም', style: GoogleFonts.notoSansEthiopic(color: secondaryTextColor)))
            : Card(
                color: cardBackgroundColor,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) => itemBuilder(listItems[index]),
                  separatorBuilder: (_, __) => const Divider(height: 1, color: primaryColor),
                ),
              )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(title, style: GoogleFonts.notoSansEthiopic(fontSize: 20, color: accentColor, fontWeight: FontWeight.bold)),
    );
  }
  
  Widget _buildTextField(String key, String label, {int maxLines = 1, TextEditingController? controller, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller ?? _controllers[key],
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.notoSansEthiopic(), border: const OutlineInputBorder(), fillColor: cardBackgroundColor, filled: true),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildImageUploader(String key, String label, {required TextEditingController controller, required bool isSaving}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSansEthiopic(color: secondaryTextColor, fontSize: 16)),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final hasUrl = value.text.isNotEmpty && _isValidUrl(value.text);
              return hasUrl
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: value.text, fit: BoxFit.cover, height: 180, width: double.infinity, placeholder: (c, u) => const Center(child: CircularProgressIndicator()), errorWidget: (c, u, e) => const Center(child: Icon(Icons.error, color: Colors.redAccent))))
                  : Container();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: 'የምስል URL እዚህ ይለጥፉ', hintStyle: GoogleFonts.notoSansEthiopic(), border: const OutlineInputBorder(), fillColor: cardBackgroundColor, filled: true),
          ),
          const SizedBox(height: 8),
          Center(child: Text('ወይም', style: GoogleFonts.notoSansEthiopic(color: secondaryTextColor))),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text('ከመሳሪያዎ ላይ ምስል ይጫኑ', style: GoogleFonts.notoSansEthiopic()),
              onPressed: isSaving ? null : () => _pickAndUploadImage(key, controller),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidUrl(String? url) => (url != null && url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true);
}