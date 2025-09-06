import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformAdminScreen extends StatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  State<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends State<PlatformAdminScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _platformLinks = [];
  List<Map<String, dynamic>> _socialLinks = [];
  bool _dataChanged = false;

  // --- BRANDING COLORS ---
  static const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
  static const Color accentColor = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final platforms = await _supabase
          .from('platform_links')
          .select()
          .order('sort_order', ascending: true);
      final socials = await _supabase
          .from('social_media_links')
          .select()
          .order('sort_order', ascending: true);

      if (mounted) {
        setState(() {
          _platformLinks = List.from(platforms);
          _socialLinks = List.from(socials);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error fetching data: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _upsertLink(String table, Map<String, dynamic> data) async {
    try {
      await _supabase.from(table).upsert(data);
      _setDataChanged();
      _fetchData(); // Refresh data after upsert
      _showSuccessSnackbar("Link saved successfully!");
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Save failed: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteLink(String table, int id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
      _setDataChanged();
      _fetchData(); // Refresh data after delete
      _showSuccessSnackbar("Link deleted successfully!");
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Delete failed: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
    ));
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: primaryColor)),
      backgroundColor: accentColor,
    ));
  }

  void _setDataChanged() {
    if (!_dataChanged) {
      setState(() => _dataChanged = true);
    }
  }

  void _showEditDialog(String table, {Map<String, dynamic>? link}) {
    final isPlatform = table == 'platform_links';
    final formKey = GlobalKey<FormState>();
    final data = Map<String, dynamic>.from(link ?? {});

    // Helper to create styled TextFormField
    Widget buildTextField({
      required String initialValue,
      required String label,
      required FormFieldSetter<String> onSaved,
      bool isNumeric = false,
      bool isRequired = true,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          initialValue: initialValue,
          style: const TextStyle(color: accentColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: accentColor.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor.withOpacity(0.5)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
            floatingLabelStyle: const TextStyle(color: accentColor),
          ),
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onSaved: onSaved,
          validator: (val) =>
              isRequired && (val == null || val.isEmpty) ? 'Required' : null,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(color: accentColor.withOpacity(0.5)),
          ),
          title: Text(
            link == null ? 'Add New Link' : 'Edit Link',
            style: GoogleFonts.poppins(
                color: accentColor, fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTextField(
                    initialValue:
                        data[isPlatform ? 'label' : 'platform_name'] ?? '',
                    label: isPlatform ? 'Label' : 'Platform Name',
                    onSaved: (val) =>
                        data[isPlatform ? 'label' : 'platform_name'] = val,
                  ),
                  if (isPlatform)
                    buildTextField(
                      initialValue: data['link_text'] ?? '',
                      label: 'Link Text (e.g., Playstore)',
                      onSaved: (val) => data['link_text'] = val,
                    ),
                  buildTextField(
                    initialValue: data['url'] ?? '',
                    label: 'URL',
                    onSaved: (val) => data['url'] = val,
                  ),
                  buildTextField(
                    initialValue: data['icon_name'] ?? '',
                    label: 'Icon Name (e.g., youtube)',
                    onSaved: (val) => data['icon_name'] = val,
                  ),
                  buildTextField(
                    initialValue: data['color_hex'] ?? '',
                    label: 'Color Hex (e.g., #FF0000)',
                    onSaved: (val) => data['color_hex'] = val,
                  ),
                  buildTextField(
                    initialValue: (data['sort_order'] ?? 0).toString(),
                    label: 'Sort Order',
                    isNumeric: true,
                    onSaved: (val) =>
                        data['sort_order'] = int.tryParse(val ?? '0') ?? 0,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: primaryColor,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  _upsertLink(table, data);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinkList(
    String title,
    String table,
    List<Map<String, dynamic>> links,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                    color: accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _showEditDialog(table),
                icon:
                    const Icon(Icons.add_circle, color: accentColor, size: 30),
              ),
            ],
          ),
        ),
        if (links.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Center(
                child: Text("No links added yet.",
                    style: TextStyle(
                        color: accentColor.withOpacity(0.7), fontSize: 16))),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return Card(
                color: primaryColor.withOpacity(0.8),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accentColor.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Text(
                    link[table == 'platform_links' ? 'label' : 'platform_name'],
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: accentColor),
                  ),
                  subtitle: Text(
                    link['url'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: accentColor.withOpacity(0.8)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showEditDialog(table, link: link),
                        icon: const Icon(Icons.edit_note, color: accentColor),
                      ),
                      IconButton(
                        onPressed: () => _deleteLink(table, link['id']),
                        icon: Icon(Icons.delete_forever,
                            color: Colors.red.shade400),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_dataChanged);
      },
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: Text('Manage Links',
              style: GoogleFonts.poppins(color: accentColor)),
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: accentColor),
            onPressed: () => Navigator.of(context).pop(_dataChanged),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLinkList(
                      'Platform Links',
                      'platform_links',
                      _platformLinks,
                    ),
                    const Divider(
                        color: accentColor,
                        height: 32,
                        indent: 16,
                        endIndent: 16),
                    _buildLinkList(
                      'Social Media Links',
                      'social_media_links',
                      _socialLinks,
                    ),
                    const SizedBox(height: 32), // Add padding at the bottom
                  ],
                ),
              ),
      ),
    );
  }
}
