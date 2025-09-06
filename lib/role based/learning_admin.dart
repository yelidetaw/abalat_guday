import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:shimmer/shimmer.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- UI Theme Constants ---
const Color kAdminBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminCardColor = Color.fromARGB(255, 4, 48, 125);
const Color kAdminPrimaryAccent = Color(0xFFFFD700);
const Color kAdminSecondaryText = Color(0xFF9A9A9A);


enum ContentType { video, article, direct_video }

class LearningAdminScreen extends StatefulWidget {
  const LearningAdminScreen({super.key});

  @override
  State<LearningAdminScreen> createState() => _LearningAdminScreenState();
}

class _LearningAdminScreenState extends State<LearningAdminScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _resources = [];

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
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
  final Map<String, String> _categoryDisplayNames = {
    'is_orthodox_preach': 'ኦርቶዶክሳዊ ስብከት',
    'is_personal_dev': 'የግል እድገት',
    'is_training': 'ስልጠና',
  };

  String? _videoFilePath;
  String? _videoFileName;
  double? _uploadProgress;
  
  final cloudinary = CloudinaryPublic(
      dotenv.env['CLOUDINARY_CLOUD_NAME']!, 
      dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
      cache: false);

  @override
  void initState() {
    super.initState();
    _fetchAdminResources();
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

  Future<void> _fetchAdminResources() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await supabase.rpc('get_all_learning_resources_for_admin');
      if (mounted) {
        setState(() => _resources = List<Map<String, dynamic>>.from(response));
      }
    } catch (e, stackTrace) {
      final errorMessage = "Failed to load resources: ${e.toString()}";
      developer.log(errorMessage,
          name: 'LearningAdminScreen._fetchAdminResources', error: e, stackTrace: stackTrace);
      if (mounted) setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResource(int resourceId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'ማጥፋትን ያረጋግጡ',
      content: 'ይህን መርጃ ለማጥፋት እርግጠኛ ኖት? ይህን ድርጊት መቀልበስ አይቻልም።',
      confirmText: 'አጥፋ',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      await supabase.from('learning_resources').delete().eq('id', resourceId);
      _showSnackbar('መርጃው በተሳካ ሁኔታ ተወግዷል።', isError: false);
      await _fetchAdminResources(); // Use await to ensure data is fresh
    } catch (e, stackTrace) {
      final errorMessage = "Failed to delete resource: ${e.toString()}";
      developer.log(errorMessage,
          name: 'LearningAdminScreen._deleteResource', error: e, stackTrace: stackTrace);
      _showSnackbar(errorMessage, isError: true);
    }
  }
  
  Future<void> _deleteComment(int commentId, int resourceId) async {
    // CRITICAL FIX: Capture context before async gap
    final currentContext = context;
    final confirmed = await _showConfirmationDialog(
      title: 'አስተያየቱን ያጥፉ',
      content: 'ይህን አስተያየት በቋሚነት ለማጥፋት እርግጠኛ ኖት?',
      confirmText: 'አጥፋ',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      await supabase.rpc('admin_delete_comment', params: {'p_comment_id': commentId});
      
      // CRITICAL FIX: Check if widget is still mounted before using context
      if (!mounted) return;
      _showSnackbar('አስተያየቱ በተሳካ ሁኔታ ተወግዷል።', isError: false);
      await _fetchAdminResources();
      
      Navigator.of(currentContext).pop();
      await _showComments(resourceId);
    } catch (e, stackTrace) {
       final errorMessage = 'አስተያየቱን ማጥፋት አልተቻለም: $e';
       developer.log('Failed to delete comment', name: 'LearningAdminScreen._deleteComment', error: e, stackTrace: stackTrace);
       if (mounted) _showSnackbar(errorMessage, isError: true);
    }
  }

  String? _extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
        r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
        caseSensitive: false);
    final match = regExp.firstMatch(url);
    return (match != null && match.group(2)!.length == 11)
        ? match.group(2)
        : null;
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null) {
        setState(() {
          _videoFilePath = result.files.single.path;
          _videoFileName = result.files.single.name;
        });
      }
    } catch (e, stackTrace) {
      final errorMessage = 'ቪዲዮ መምረጥ አልተቻለም: $e';
      developer.log('Failed to pick video', name: 'LearningAdminScreen._pickVideo', error: e, stackTrace: stackTrace);
      if (mounted) _showSnackbar(errorMessage, isError: true);
    }
  }

  Future<String> _uploadVideoToCloudinary() async {
    if (_videoFilePath == null) throw Exception("Video file path is null.");
    try {
      setState(() => _uploadProgress = 0.0);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_videoFilePath!,
            resourceType: CloudinaryResourceType.Video),
        onProgress: (count, total) {
          if (mounted) setState(() => _uploadProgress = count / total);
        },
      );
      return response.secureUrl;
    } catch (e, stackTrace) {
      developer.log('Failed to upload video to Cloudinary', name: 'LearningAdminScreen._uploadVideo', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_categories.values.contains(true)) {
      _showSnackbar('እባክዎ ቢያንስ አንድ ምድብ ይምረጡ', isError: true);
      return;
    }
    if (_selectedContentType == ContentType.direct_video &&
        _videoFilePath == null) {
      _showSnackbar('እባክዎ የሚጫን ቪዲዮ ይምረጡ', isError: true);
      return;
    }
    
    // CRITICAL FIX: Capture context before async gap
    final currentContext = context;
    setState(() => _isSubmitting = true);

    try {
      final dataToInsert = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'content_type': _selectedContentType.name,
        'is_orthodox_preach': _categories['is_orthodox_preach']!,
        'is_personal_dev': _categories['is_personal_dev']!,
        'is_training': _categories['is_training']!,
      };

      if (_selectedContentType == ContentType.video) {
        dataToInsert['youtube_id'] =
            _extractYoutubeId(_youtubeUrlController.text.trim());
      } else if (_selectedContentType == ContentType.article) {
        dataToInsert['content_body'] = _articleBodyController.text.trim();
        if (_imageUrlController.text.trim().isNotEmpty)
          dataToInsert['image_url'] = _imageUrlController.text.trim();
      } else if (_selectedContentType == ContentType.direct_video) {
        final videoUrl = await _uploadVideoToCloudinary();
        dataToInsert['video_url'] = videoUrl;
        if (_imageUrlController.text.trim().isNotEmpty)
          dataToInsert['image_url'] = _imageUrlController.text.trim();
      }

      await supabase.from('learning_resources').insert(dataToInsert);
      
      // CRITICAL FIX: Check if widget is still mounted
      if (!mounted) return;

      _showSnackbar('ይዘቱ በተሳካ ሁኔታ ተጭኗል!', isError: false);
      await _fetchAdminResources();
      _clearForm();
      DefaultTabController.of(currentContext).animateTo(1);
    } catch (e, stackTrace) {
      final errorMessage = "Upload failed: ${e.toString()}";
      developer.log(errorMessage,
          name: 'LearningAdminScreen._submitForm', error: e, stackTrace: stackTrace);
      if (mounted) _showSnackbar(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _youtubeUrlController.clear();
    _articleBodyController.clear();
    _imageUrlController.clear();
    setState(() {
      _categories.updateAll((key, value) => false);
      _videoFilePath = null;
      _videoFileName = null;
    });
  }

  // All other helper methods (_showViewers, _showLikers, etc.) remain the same.
  Future<void> _showViewers(int resourceId) async {
    try {
      final response = await supabase.rpc('get_engagement_details_for_resource',
          params: {'p_resource_id': resourceId});
      final viewers = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;
      await _showInfoDialog(
        context: context,
        title: 'እይታዎች እና ተሳትፎ',
        itemCount: viewers.length,
        emptyContent: Text("ምንም የእይታ እንቅስቃሴ አልተመዘገበም።",
            style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText)),
        itemBuilder: (context, index) {
          final activity = viewers[index];
          final duration = Duration(seconds: activity['duration_seconds'] ?? 0);
          final durationText =
              '${duration.inMinutes}ደ ${duration.inSeconds % 60}ሰ';

          return ListTile(
            title: Text(activity['user_name'] ?? 'ስም የሌለው',
                style: GoogleFonts.notoSansEthiopic(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              'ቆይታ: $durationText',
              style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText),
            ),
            trailing: activity['is_completed'] == true
                ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                : null,
          );
        },
      );
    } catch (e, stackTrace) {
      final errorMessage = 'የተመልካቾችን ዝርዝር ማምጣት አልተቻለም: $e';
      developer.log("Failed to show viewers", name: "LearningAdminScreen", error: e, stackTrace: stackTrace);
      if (mounted) _showSnackbar(errorMessage, isError: true);
    }
  }

  Future<void> _showLikers(int resourceId) async {
    try {
      final response = await supabase.rpc('get_likers_for_resource',
          params: {'p_resource_id': resourceId});
      final likers = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;
      await _showInfoDialog(
        context: context,
        title: 'የወደዱት',
        itemCount: likers.length,
        emptyContent: Text("ይህን ይዘት እስካሁን ማንም አልወደደውም።",
            style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText)),
        itemBuilder: (context, index) {
          final liker = likers[index];
          return ListTile(
            title: Text(liker['user_name'] ?? 'ስም የሌለው',
                style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
          );
        },
      );
    } catch (e, stackTrace) {
      final errorMessage = 'የወደዱትን ዝርዝር ማምጣት አልተቻለም: $e';
      developer.log("Failed to show likers", name: "LearningAdminScreen", error: e, stackTrace: stackTrace);
      if (mounted) _showSnackbar(errorMessage, isError: true);
    }
  }

  Future<void> _showComments(int resourceId) async {
    try {
      final response = await supabase.rpc('get_comments_for_resource',
          params: {'p_resource_id': resourceId});
      final comments = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;
      await _showInfoDialog(
        context: context,
        title: 'አስተያየቶች',
        itemCount: comments.length,
        emptyContent: Text("በዚህ ይዘት ላይ ምንም አስተያየት የለም።",
            style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText)),
        itemBuilder: (context, index) {
          final comment = comments[index];
          return ListTile(
            title: Text(comment['full_name'] ?? 'ስም የሌለው',
                style: GoogleFonts.notoSansEthiopic(
                    color: kAdminPrimaryAccent, fontWeight: FontWeight.bold)),
            subtitle: Text(comment['content'] ?? '',
                style: GoogleFonts.notoSansEthiopic(color: Colors.white70)),
           // in _showComments...
trailing: IconButton(
  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
  // FIX: Cast the comment_id to int
  onPressed: () => _deleteComment((comment['comment_id'] as num).toInt(), resourceId),
  tooltip: 'አስተያየቱን አጥፋ',
),
          );
        },
      );
    } catch (e, stackTrace) {
      final errorMessage = "አስተያየቶችን ማምጣት አልተቻለም: ${e.toString()}";
      developer.log(errorMessage, name: 'LearningAdminScreen.showComments', error: e, stackTrace: stackTrace);
      if (mounted) _showSnackbar(errorMessage, isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.notoSansEthiopic()),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  Future<bool?> _showConfirmationDialog(
      {required String title,
      required String content,
      required String confirmText,
      bool isDestructive = false}) {
    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: kAdminCardColor,
              title: Text(title, style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
              content: Text(content, style: GoogleFonts.notoSansEthiopic(color: Colors.white70)),
              actions: [
                TextButton(
                    child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText)),
                    onPressed: () => Navigator.of(context).pop(false)),
                TextButton(
                  style: TextButton.styleFrom(
                      backgroundColor: isDestructive ? Colors.red.withOpacity(0.1) : kAdminPrimaryAccent.withOpacity(0.1),
                      foregroundColor:
                          isDestructive ? Colors.redAccent : kAdminPrimaryAccent),
                  child:
                      Text(confirmText, style: GoogleFonts.notoSansEthiopic()),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ));
  }

  Future<void> _showInfoDialog(
      {required BuildContext context,
      required String title,
      required int itemCount,
      required Widget emptyContent,
      required Widget Function(BuildContext, int) itemBuilder}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAdminCardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: kAdminPrimaryAccent.withOpacity(0.5))),
        title: Text(title,
            style: GoogleFonts.notoSansEthiopic(
                color: kAdminPrimaryAccent, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: itemCount == 0
              ? emptyContent
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: itemCount,
                  itemBuilder: itemBuilder),
        ),
        actions: [
          TextButton(
            child: Text('ዝጋ',
                style:
                    GoogleFonts.notoSansEthiopic(color: kAdminPrimaryAccent)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kAdminBackgroundColor,
        appBar: AppBar(
          title: Text('የትምህርት አስተዳደር', style: GoogleFonts.notoSansEthiopic()),
          backgroundColor: kAdminBackgroundColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: kAdminPrimaryAccent,
            labelColor: kAdminPrimaryAccent,
            unselectedLabelColor: kAdminSecondaryText.withOpacity(0.7),
            labelStyle:
                GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'አዲስ ጨምር'),
              Tab(icon: Icon(Icons.storage_rounded), text: 'ያቀናብሩ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddContentTab(),
            _buildManageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ContentType>(
              style: SegmentedButton.styleFrom(
                backgroundColor: kAdminCardColor,
                foregroundColor: kAdminSecondaryText,
                selectedForegroundColor: kAdminBackgroundColor,
                selectedBackgroundColor: kAdminPrimaryAccent,
              ),
              segments: [
                ButtonSegment(
                    value: ContentType.video,
                    label:
                        Text('YouTube', style: GoogleFonts.notoSansEthiopic()),
                    icon: const Icon(Icons.smart_display_rounded)),
                ButtonSegment(
                    value: ContentType.direct_video,
                    label:
                        Text('ቪዲዮ ጫን', style: GoogleFonts.notoSansEthiopic()),
                    icon: const Icon(Icons.upload_file_rounded)),
                ButtonSegment(
                    value: ContentType.article,
                    label: Text('ጽሑፍ', style: GoogleFonts.notoSansEthiopic()),
                    icon: const Icon(Icons.article)),
              ],
              selected: {_selectedContentType},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedContentType = selection.first),
            ),
            const SizedBox(height: 24),
            TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                    labelText: 'ርዕስ',
                    labelStyle: GoogleFonts.notoSansEthiopic()),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: 'መግለጫ',
                    labelStyle: GoogleFonts.notoSansEthiopic()),
                maxLines: 3),
            const SizedBox(height: 16),
            if (_selectedContentType == ContentType.video)
              TextFormField(
                  controller: _youtubeUrlController,
                  decoration: InputDecoration(
                      labelText: 'YouTube URL',
                      labelStyle: GoogleFonts.notoSansEthiopic()),
                  validator: (v) => v?.isEmpty ?? true
                      ? 'Required'
                      : (_extractYoutubeId(v!) == null
                          ? 'Invalid YouTube URL'
                          : null))
            else if (_selectedContentType == ContentType.article)
              Column(children: [
                TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                        labelText: 'ምስል URL (አማራጭ)',
                        labelStyle: GoogleFonts.notoSansEthiopic())),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _articleBodyController,
                    decoration: InputDecoration(
                        labelText: 'የጽሑፉ ይዘት',
                        labelStyle: GoogleFonts.notoSansEthiopic()),
                    maxLines: 10,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
              ])
            else if (_selectedContentType == ContentType.direct_video)
              Column(children: [
                TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                        labelText: 'ጥፍር ምስል URL (አማራጭ)',
                        labelStyle: GoogleFonts.notoSansEthiopic())),
                const SizedBox(height: 16),
                _buildVideoPicker(),
              ]),
            const SizedBox(height: 24),
            Text('ምድቦች',
                style: GoogleFonts.notoSansEthiopic(
                    fontSize: 18, color: kAdminPrimaryAccent)),
            const Divider(color: kAdminPrimaryAccent, thickness: 0.5),
            ..._categories.keys.map((key) => CheckboxListTile(
                  title: Text(_categoryDisplayNames[key] ?? key,
                      style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
                  value: _categories[key],
                  onChanged: (value) =>
                      setState(() => _categories[key] = value ?? false),
                  activeColor: kAdminPrimaryAccent,
                  checkColor: kAdminBackgroundColor,
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kAdminPrimaryAccent,
                  foregroundColor: kAdminBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: kAdminBackgroundColor))
                  : Text('ይዘቱን ይጫኑ',
                      style: GoogleFonts.notoSansEthiopic(
                          fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: kAdminCardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('ቪዲዮ ፋይል',
                      style: GoogleFonts.notoSansEthiopic(
                          color: kAdminSecondaryText))),
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.attach_file),
                label: Text('ይምረጡ', style: GoogleFonts.notoSansEthiopic()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kAdminCardColor,
                    foregroundColor: kAdminPrimaryAccent),
              ),
            ],
          ),
          if (_videoFileName != null)
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('የተመረጠው: $_videoFileName',
                    style: const TextStyle(color: kAdminPrimaryAccent, fontStyle: FontStyle.italic))),
          if (_uploadProgress != null)
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                    value: _uploadProgress, color: kAdminPrimaryAccent, backgroundColor: kAdminCardColor,))
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    if (_isLoading) return const _AdminListShimmer();
    if (_error != null)
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_resources.isEmpty)
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('ምንም የትምህርት መርጃ አልተገኘም። እባክዎ አዲስ ይጨምሩ።',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText)),
          ));

    return RefreshIndicator(
      onRefresh: _fetchAdminResources,
      color: kAdminPrimaryAccent,
      backgroundColor: kAdminCardColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _ResourceStatCard(
            resource: resource,
            onEdit: () {
              _showEditDialog(resource);
            },
            onDelete: () => _deleteResource(resource['id']),
            onShowViewers: () => _showViewers(resource['id']),
            onShowLikers: () => _showLikers(resource['id']),
            onShowComments: () => _showComments(resource['id']),
          );
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> resource) {
    final editFormKey = GlobalKey<FormState>();
    final editTitleController = TextEditingController(text: resource['title']);
    final editDescriptionController = TextEditingController(text: resource['description']);
    final editYoutubeUrlController = TextEditingController(text: resource['youtube_id'] != null ? 'https://www.youtube.com/watch?v=${resource['youtube_id']}' : '');
    final editImageUrlController = TextEditingController(text: resource['image_url']);
    final editArticleBodyController = TextEditingController(text: resource['content_body']);

    final Map<String, bool> editCategories = {
      'is_orthodox_preach': resource['is_orthodox_preach'] ?? false,
      'is_personal_dev': resource['is_personal_dev'] ?? false,
      'is_training': resource['is_training'] ?? false,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: kAdminBackgroundColor,
              title: Text('መርጃ አስተካክል', style: GoogleFonts.notoSansEthiopic(color: kAdminPrimaryAccent)),
              content: Form(
                key: editFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: editTitleController,
                        decoration: InputDecoration(labelText: 'ርዕስ', labelStyle: GoogleFonts.notoSansEthiopic()),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: editDescriptionController,
                        decoration: InputDecoration(labelText: 'መግለጫ', labelStyle: GoogleFonts.notoSansEthiopic()),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      if (resource['content_type'] == 'video')
                        TextFormField(
                          controller: editYoutubeUrlController,
                          decoration: InputDecoration(labelText: 'YouTube URL', labelStyle: GoogleFonts.notoSansEthiopic()),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : (_extractYoutubeId(v!) == null ? 'Invalid URL' : null),
                        ),
                      if (resource['content_type'] == 'article' || resource['content_type'] == 'direct_video')
                         TextFormField(
                          controller: editImageUrlController,
                          decoration: InputDecoration(labelText: 'ምስል URL (አማራጭ)', labelStyle: GoogleFonts.notoSansEthiopic()),
                        ),
                      if (resource['content_type'] == 'article')
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: TextFormField(
                            controller: editArticleBodyController,
                            decoration: InputDecoration(labelText: 'የጽሑፉ ይዘት', labelStyle: GoogleFonts.notoSansEthiopic()),
                            maxLines: 8,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('ምድቦች', style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: kAdminPrimaryAccent)),
                      ...editCategories.keys.map((key) => CheckboxListTile(
                            title: Text(_categoryDisplayNames[key] ?? key, style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
                            value: editCategories[key],
                            onChanged: (value) => setDialogState(() => editCategories[key] = value ?? false),
                            activeColor: kAdminPrimaryAccent,
                            checkColor: kAdminBackgroundColor,
                          )),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic(color: kAdminPrimaryAccent))),
                ElevatedButton(
                  onPressed: () {
                    if (editFormKey.currentState!.validate()) {
                      final updatedData = {
                        'title': editTitleController.text.trim(),
                        'description': editDescriptionController.text.trim(),
                        'youtube_id': resource['content_type'] == 'video' ? _extractYoutubeId(editYoutubeUrlController.text.trim()) : null,
                        'image_url': editImageUrlController.text.trim(),
                        'content_body': resource['content_type'] == 'article' ? editArticleBodyController.text.trim() : null,
                        'is_orthodox_preach': editCategories['is_orthodox_preach']!,
                        'is_personal_dev': editCategories['is_personal_dev']!,
                        'is_training': editCategories['is_training']!,
                      };
                      _updateResource(resource['id'], updatedData);
                      Navigator.of(context).pop();
                    }
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
  
  Future<void> _updateResource(int resourceId, Map<String, dynamic> updatedData) async {
    try {
      await supabase.from('learning_resources').update(updatedData).eq('id', resourceId);
      _showSnackbar('መርጃው በተሳካ ሁኔታ ተዘምኗል።', isError: false);
      _fetchAdminResources();
    } catch (e, stackTrace) {
      final errorMessage = "Failed to update resource: ${e.toString()}";
      developer.log(errorMessage, name: 'LearningAdminScreen._updateResource', error: e, stackTrace: stackTrace);
      _showSnackbar(errorMessage, isError: true);
    }
  }
}

class _ResourceStatCard extends StatelessWidget {
  final Map<String, dynamic> resource;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowViewers;
  final VoidCallback onShowLikers;
  final VoidCallback onShowComments;

  const _ResourceStatCard({
    required this.resource,
    required this.onEdit,
    required this.onDelete,
    required this.onShowViewers,
    required this.onShowLikers,
    required this.onShowComments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kAdminCardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource['title'] ?? 'No Title',
              style: GoogleFonts.notoSansEthiopic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                    icon: Icons.visibility_outlined,
                    value: (resource['view_count'] ?? 0).toString(),
                    label: 'እይታዎች',
                    onTap: onShowViewers),
                _StatItem(
                    icon: Icons.thumb_up_alt_outlined,
                    value: (resource['like_count'] ?? 0).toString(),
                    label: 'አውራ ጣት',
                    onTap: onShowLikers),
                _StatItem(
                    icon: Icons.comment_outlined,
                    value: (resource['comment_count'] ?? 0).toString(),
                    label: 'አስተያየቶች',
                    onTap: onShowComments),
              ],
            ),
            const Divider(height: 24, color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  label: Text('አጥፋ', style: GoogleFonts.notoSansEthiopic()),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('አስተካክል', style: GoogleFonts.notoSansEthiopic()),
                  style: TextButton.styleFrom(
                      foregroundColor: kAdminPrimaryAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  const _StatItem(
      {required this.icon,
      required this.value,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: kAdminSecondaryText, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12, color: kAdminSecondaryText)),
          ],
        ),
      ),
    );
  }
}

class _AdminListShimmer extends StatelessWidget {
  const _AdminListShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kAdminCardColor.withOpacity(0.5),
      highlightColor: kAdminBackgroundColor.withOpacity(0.5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          color: Colors.black,
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(height: 150),
        ),
      ),
    );
  }
}