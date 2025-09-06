import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:developer' as developer;

// --- MODELS ---
class FamilyLink {
  // --- FIX #1: Changed linkId from String to int ---
  final int linkId;
  final String familyMemberName;
  final String studentName;
  final bool notifyOnAbsent;
  final bool notifyOnLowGrade;

  FamilyLink({
    required this.linkId,
    required this.familyMemberName,
    required this.studentName,
    required this.notifyOnAbsent,
    required this.notifyOnLowGrade,
  });

  factory FamilyLink.fromRpc(Map<String, dynamic> data) {
    return FamilyLink(
      // This will now work correctly as linkId is an int.
      linkId: data['link_id'],
      familyMemberName: data['family_member_name'],
      studentName: data['student_name'],
      notifyOnAbsent: data['notify_on_absent'] ?? true,
      notifyOnLowGrade: data['notify_on_low_grade'] ?? true,
    );
  }
}

class SimpleProfile {
  final String id;
  final String fullName;
  SimpleProfile({required this.id, required this.fullName});
}

class FamilyLinkingScreen extends StatefulWidget {
  const FamilyLinkingScreen({super.key});

  @override
  State<FamilyLinkingScreen> createState() => _FamilyLinkingScreenState();
}

class _FamilyLinkingScreenState extends State<FamilyLinkingScreen> {
  bool _isLoading = true;
  String? _error;
  List<FamilyLink> _links = [];
  List<SimpleProfile> _allProfiles = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final linksResponse =
          await supabase.rpc('get_all_family_links_with_names') as List;
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, full_name')
          .order('full_name') as List;

      final fetchedLinks = linksResponse
          .map((data) => FamilyLink.fromRpc(data as Map<String, dynamic>))
          .toList();

      final fetchedProfiles = profilesResponse.map((profile) {
        return SimpleProfile(
            id: profile['id'], fullName: profile['full_name'] ?? 'No Name');
      }).toList();

      if (mounted) {
        setState(() {
          _links = fetchedLinks;
          _allProfiles = fetchedProfiles;
        });
      }
    } catch (e, stackTrace) {
      final errorMessage = "Failed to load data: ${e.toString()}";
      developer.log(errorMessage,
          name: 'FamilyLinkingScreen.fetchData',
          error: e,
          stackTrace: stackTrace);
      if (mounted) setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createLink(String familyMemberId, String studentId) async {
    try {
      await supabase.from('family_links').insert(
          {'family_member_id': familyMemberId, 'student_id': studentId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Link created successfully!'),
          backgroundColor: Colors.green));
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create link: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  // --- FIX #2: Changed the parameter from String to int ---
  Future<void> _deleteLink(int linkId) async {
    try {
      await supabase.from('family_links').delete().eq('id', linkId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Link removed successfully.'),
          backgroundColor: Colors.blue));
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to remove link: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  // --- FIX #3: Changed the parameter from String to int ---
  Future<void> _updateLinkPreferences(int linkId,
      {bool? notifyOnAbsent, bool? notifyOnLowGrade}) async {
    final updateData = <String, bool>{};
    if (notifyOnAbsent != null) updateData['notify_on_absent'] = notifyOnAbsent;
    if (notifyOnLowGrade != null)
      updateData['notify_on_low_grade'] = notifyOnLowGrade;

    try {
      await supabase.from('family_links').update(updateData).eq('id', linkId);
      setState(() {
        final index = _links.indexWhere((link) => link.linkId == linkId);
        if (index != -1) {
          _links[index] = FamilyLink(
            linkId: _links[index].linkId,
            familyMemberName: _links[index].familyMemberName,
            studentName: _links[index].studentName,
            notifyOnAbsent: notifyOnAbsent ?? _links[index].notifyOnAbsent,
            notifyOnLowGrade:
                notifyOnLowGrade ?? _links[index].notifyOnLowGrade,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update setting: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Family Links')),
      body: _isLoading
          ? const _LoadingShimmer()
          : _error != null
              ? _ErrorDisplay(error: _error!, onRetry: _fetchData)
              : _links.isEmpty
                  ? _EmptyState(onAdd: () => _showAddLinkDialog(context))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _links.length,
                        itemBuilder: (context, index) {
                          final link = _links[index];
                          return FadeInUp(
                            from: 20,
                            delay: Duration(milliseconds: index * 50),
                            child: _LinkCard(
                              link: link,
                              onDelete: () => _deleteLinkWithConfirmation(link),
                              onUpdatePrefs: _updateLinkPreferences,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLinkDialog(context),
        icon: const Icon(Icons.add_link_rounded),
        label: const Text("New Link"),
      ),
    );
  }

  void _deleteLinkWithConfirmation(FamilyLink link) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Confirm Deletion"),
              content: Text(
                  'Are you sure you want to unlink ${link.familyMemberName} from ${link.studentName}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirmed == true) {
      await _deleteLink(link.linkId);
    }
  }

  void _showAddLinkDialog(BuildContext context) {
    String? selectedFamilyId;
    String? selectedStudentId;
    final formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Create a New Family Link"),
            content: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: selectedFamilyId,
                  hint: const Text('Select Family Member...'),
                  items: _allProfiles
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.fullName)))
                      .toList(),
                  onChanged: (value) => selectedFamilyId = value,
                  validator: (value) =>
                      value == null ? 'Please select a family member.' : null,
                  decoration: const InputDecoration(
                      labelText: 'Family Member (Parent)'),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedStudentId,
                  hint: const Text('Select Student...'),
                  items: _allProfiles
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.fullName)))
                      .toList(),
                  onChanged: (value) => selectedStudentId = value,
                  validator: (value) =>
                      value == null ? 'Please select a student.' : null,
                  decoration: const InputDecoration(labelText: 'Student'),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop();
                    _createLink(selectedFamilyId!, selectedStudentId!);
                  }
                },
                child: const Text("Create Link"),
              ),
            ],
          );
        });
  }
}

class _LinkCard extends StatelessWidget {
  final FamilyLink link;
  final VoidCallback onDelete;
  final Future<void> Function(int,
      {bool? notifyOnAbsent, bool? notifyOnLowGrade}) onUpdatePrefs;

  const _LinkCard(
      {required this.link,
      required this.onDelete,
      required this.onUpdatePrefs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        title: Row(
          children: [
            _buildPersonChip(theme, link.familyMemberName,
                Icons.supervisor_account_rounded, "Family Member"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.arrow_forward_rounded,
                  color: theme.colorScheme.secondary),
            ),
            _buildPersonChip(
                theme, link.studentName, Icons.face_rounded, "Student"),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
          onPressed: onDelete,
          tooltip: "Remove Link",
        ),
        children: [
          const Divider(height: 1),
          SwitchListTile.adaptive(
            title: const Text("Notify on Absent"),
            value: link.notifyOnAbsent,
            onChanged: (newValue) =>
                onUpdatePrefs(link.linkId, notifyOnAbsent: newValue),
            activeColor: theme.colorScheme.secondary,
          ),
          SwitchListTile.adaptive(
            title: const Text("Notify on Low Grade"),
            value: link.notifyOnLowGrade,
            onChanged: (newValue) =>
                onUpdatePrefs(link.linkId, notifyOnLowGrade: newValue),
            activeColor: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonChip(
      ThemeData theme, String name, IconData icon, String role) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).primaryColor,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Container(height: 70))),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorDisplay({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          const Text("Failed to Load Data"),
          const SizedBox(height: 10),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again')),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.link_off_rounded, size: 80),
          const SizedBox(height: 20),
          const Text('No Family Links Found'),
          const SizedBox(height: 10),
          const Text(
              "Create the first link between a family member and a student.",
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Create New Link')),
        ]),
      ),
    );
  }
}
