import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:developer' as developer;

// --- UI Theme Constants ---
const Color kAdminBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminPrimaryAccent = Color(0xFFFFD700);
const Color kAdminSecondaryText = Color(0xFFFFD700);

class AdminPrivateManagementScreen extends StatefulWidget {
  const AdminPrivateManagementScreen({super.key});

  @override
  State<AdminPrivateManagementScreen> createState() =>
      _AdminPrivateManagementScreenState();
}

class _AdminPrivateManagementScreenState
    extends State<AdminPrivateManagementScreen> {
  // --- State for Tab 1: User Notes ---
  final Map<String, String> _groups = {
    'All': 'ሁሉም',
    'Tadagi': 'ታዳጊ',
    'Hitsanat': 'ሕፃናት',
    'Golimasa': 'ጎልማሳ',
    'Wetat': 'ወጣት',
    'Far from Confession': 'ከንስሐ የራቁ'
  };
  String _selectedGroupKey = 'All';
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  String? _userError;

  // --- State for Tab 2: Group Management ---
  List<String> _allBudinOptions = [];
  List<String> _allAgelgilotKifilOptions = [];
  String? _selectedBudin;
  String? _selectedAgelgilotKifil;
  List<Map<String, dynamic>> _groupFilteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchAllUsersAndGroups();
  }

  Future<void> _fetchAllUsersAndGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsers = true;
      _userError = null;
    });

    try {
      final responses = await Future.wait([
        supabase.rpc('get_all_profiles_for_admin_notes'),
        supabase.from('profiles').select('budin').neq('budin', ''),
        supabase
            .from('profiles')
            .select('agelgilot_kifil')
            .neq('agelgilot_kifil', ''),
      ]);

      final usersResponse = responses[0] as List;
      final budinResponse = responses[1] as List;
      final agelgilotKifilResponse = responses[2] as List;

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(usersResponse);
          _allBudinOptions = budinResponse
              .map((row) => row['budin'] as String)
              .toSet()
              .toList()
            ..sort();
          _allAgelgilotKifilOptions = agelgilotKifilResponse
              .map((row) => row['agelgilot_kifil'] as String)
              .toSet()
              .toList()
            ..sort();
        });
      }
    } catch (e, stackTrace) {
      final errorMessage = "የተጠቃሚዎችን ዝርዝር በማምጣት ላይ ስህተት ተፈጥሯል: ${e.toString()}";
      developer.log(errorMessage,
          name: 'AdminPrivateManagement.fetchAllUsers',
          error: e,
          stackTrace: stackTrace);
      if (mounted) {
        setState(() => _userError = errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsersForNotes() {
    if (_selectedGroupKey == 'All') return _users;
    if (_selectedGroupKey == 'Far from Confession') {
      return _users
          .where((user) => user['is_far_from_confession'] == true)
          .toList();
    }
    return _users
        .where((user) =>
            user['department']?.toString().toLowerCase() ==
            _selectedGroupKey.toLowerCase())
        .toList();
  }

  void _filterUsersByGroup() {
    List<Map<String, dynamic>> filtered = [];
    if (_selectedBudin != null) {
      filtered =
          _users.where((user) => user['budin'] == _selectedBudin).toList();
    } else if (_selectedAgelgilotKifil != null) {
      filtered = _users
          .where((user) => user['agelgilot_kifil'] == _selectedAgelgilotKifil)
          .toList();
    }
    setState(() {
      _groupFilteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kAdminBackgroundColor,
        appBar: AppBar(
          title: Text('የአባላት አስተዳደር', style: GoogleFonts.notoSansEthiopic()),
          backgroundColor: kAdminBackgroundColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: kAdminPrimaryAccent,
            labelColor: kAdminPrimaryAccent,
            unselectedLabelColor: kAdminSecondaryText,
            labelStyle:
                GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'የአባላት ማስታወሻ'), Tab(text: 'የቡድን አስተዳደር')],
          ),
        ),
        body: TabBarView(
          children: [_buildUserNotesTab(), _buildGroupManagementTab()],
        ),
      ),
    );
  }

  Widget _buildUserNotesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedGroupKey,
            items: _groups.entries
                .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value,
                        style: GoogleFonts.notoSansEthiopic())))
                .toList(),
            onChanged: (value) => setState(() => _selectedGroupKey = value!),
            decoration: InputDecoration(
              labelText: 'በዋና ቡድን አጣራ',
              labelStyle:
                  GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAdminPrimaryAccent),
              ),
            ),
          ),
        ),
        Expanded(child: _buildUsersListForNotes()),
      ],
    );
  }

  Widget _buildUsersListForNotes() {
    if (_isLoadingUsers) return const _UserListShimmer();
    if (_userError != null) return _buildErrorWidget();

    final filteredUsers = _getFilteredUsersForNotes();
    if (filteredUsers.isEmpty) {
      return Center(
          child: Text('በዚህ ቡድን ውስጥ ምንም አባላት የሉም።',
              style: GoogleFonts.notoSansEthiopic(
                  color: kAdminSecondaryText, fontSize: 16)));
    }

    return _buildUserListView(filteredUsers);
  }

  Widget _buildGroupManagementTab() {
    if (_isLoadingUsers) return const _UserListShimmer();
    if (_userError != null) return _buildErrorWidget();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBudin,
                  hint: Text('ልዩ ኅብረት (ቡድን)',
                      style: GoogleFonts.notoSansEthiopic(fontSize: 14)),
                  isExpanded: true,
                  items: _allBudinOptions
                      .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text(val,
                              style: GoogleFonts.notoSansEthiopic(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBudin = value;
                      _selectedAgelgilotKifil = null;
                    });
                    _filterUsersByGroup();
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAgelgilotKifil,
                  hint: Text('የአገልግሎት ክፍል',
                      style: GoogleFonts.notoSansEthiopic(fontSize: 14)),
                  isExpanded: true,
                  items: _allAgelgilotKifilOptions
                      .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text(val,
                              style: GoogleFonts.notoSansEthiopic(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAgelgilotKifil = value;
                      _selectedBudin = null;
                    });
                    _filterUsersByGroup();
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
        Expanded(
            child: (_selectedBudin == null && _selectedAgelgilotKifil == null)
                ? Center(
                    child: Text('ለማየት እባክዎ ከላይ ካሉት ማጣሪያዎች አንዱን ይምረጡ።',
                        style: GoogleFonts.notoSansEthiopic(
                            color: kAdminSecondaryText)))
                : _groupFilteredUsers.isEmpty
                    ? Center(
                        child: Text('በተመረጠው ቡድን ውስጥ አባላት የሉም።',
                            style: GoogleFonts.notoSansEthiopic(
                                color: kAdminSecondaryText)))
                    : _buildUserListView(_groupFilteredUsers)),
      ],
    );
  }

  Widget _buildUserListView(List<Map<String, dynamic>> userList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: userList.length,
      itemBuilder: (context, index) {
        final user = userList[index];
        final budin = user['budin'] as String?;
        final agelgilotKifil = user['agelgilot_kifil'] as String?;

        return FadeInUp(
          from: 20,
          delay: Duration(milliseconds: index * 40),
          child: Card(
            color: kAdminCardColor,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: kAdminPrimaryAccent.withOpacity(0.2),
                child: Text(user['full_name'][0],
                    style: const TextStyle(
                        color: kAdminPrimaryAccent,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(user['full_name'],
                  style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('ቡድን: ${user['department'] ?? 'የለም'}',
                      style: GoogleFonts.notoSansEthiopic(
                          color: kAdminSecondaryText, fontSize: 12)),
                  if (budin != null && budin.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('ልዩ ኅብረት: $budin',
                        style: GoogleFonts.notoSansEthiopic(
                            color: kAdminSecondaryText, fontSize: 12)),
                  ],
                  if (agelgilotKifil != null && agelgilotKifil.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('የአገልግሎት ክፍል: $agelgilotKifil',
                        style: GoogleFonts.notoSansEthiopic(
                            color: kAdminSecondaryText, fontSize: 12)),
                  ],
                  if (_selectedGroupKey == 'Far from Confession')
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Chip(
                        label: Text(
                          user['last_confession_date'] != null
                              ? 'የመጨረሻ ንስሐ: ${DateFormat.yMMMd().format(DateTime.parse(user['last_confession_date']))}'
                              : 'ምንም የንስሐ መረጃ የለም',
                          style: GoogleFonts.notoSansEthiopic(
                              color: Colors.white, fontSize: 11),
                        ),
                        backgroundColor: Colors.red.shade400.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: BorderSide.none,
                      ),
                    ),
                ],
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: kAdminSecondaryText),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserNotesScreen(user: user)),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('ዝርዝሩን መጫን አልተቻለም',
                style: GoogleFonts.notoSansEthiopic(
                    fontSize: 20, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_userError!,
                style: TextStyle(color: Colors.red.shade300),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _fetchAllUsersAndGroups,
                icon: const Icon(Icons.refresh),
                label:
                    Text('እንደገና ሞክር', style: GoogleFonts.notoSansEthiopic())),
          ],
        ),
      ),
    );
  }
}

class UserNotesScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserNotesScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserNotesScreen> createState() => _UserNotesScreenState();
}

class _UserNotesScreenState extends State<UserNotesScreen> {
  final _notesController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _error = null;
    try {
      final response = await supabase
          .from('admin_private_notes')
          .select('*')
          .eq('user_id', widget.user['id'])
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _notes = List<Map<String, dynamic>>.from(response);
          if (_notes.isNotEmpty) {
            _notesController.text = _notes.first['content'];
          }
        });
      }
    } catch (e, stackTrace) {
      final errorMessage = "ማስታወሻዎችን መጫን አልተቻለም: ${e.toString()}";
      developer.log(errorMessage,
          name: 'UserNotesScreen.fetchNotes', error: e, stackTrace: stackTrace);
      if (mounted) setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ባዶ ማስታወሻ ማስቀመጥ አይቻልም',
              style: GoogleFonts.notoSansEthiopic()),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'user_id': widget.user['id'],
        'content': _notesController.text.trim(),
        'created_by': supabase.auth.currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_notes.isEmpty) {
        await supabase.from('admin_private_notes').insert(data).select();
      } else {
        await supabase
            .from('admin_private_notes')
            .update(data)
            .eq('id', _notes.first['id']);
      }

      await _fetchNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('ማስታወሻው በተሳካ ሁኔታ ተቀምጧል',
                style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: Colors.green));
      }
    } catch (e, stackTrace) {
      final errorMessage = "ማስታወሻውን በማስቀመጥ ላይ ስህተት ተፈጥሯል: ${e.toString()}";
      developer.log(errorMessage,
          name: 'UserNotesScreen.saveNote', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage, style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final department = widget.user['department'] as String?;
    final budin = widget.user['budin'] as String?;
    final agelgilotKifil = widget.user['agelgilot_kifil'] as String?;

    return Scaffold(
      backgroundColor: kAdminBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.user['full_name']} - ማስታወሻ',
            style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: kAdminBackgroundColor,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.save_alt_rounded),
                  onPressed: _saveNote,
                  tooltip: 'ማስታወሻ አስቀምጥ'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_error!,
                          style: GoogleFonts.notoSansEthiopic(
                              color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      TextButton(
                          onPressed: _fetchNotes,
                          child: Text('እንደገና ሞክር',
                              style: GoogleFonts.notoSansEthiopic()))
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (department != null && department.isNotEmpty)
                        Text('ቡድን: $department',
                            style: GoogleFonts.notoSansEthiopic(
                                fontSize: 14, color: kAdminSecondaryText)),
                      if (budin != null && budin.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('ልዩ ኅብረት: $budin',
                            style: GoogleFonts.notoSansEthiopic(
                                fontSize: 14, color: kAdminSecondaryText)),
                      ],
                      if (agelgilotKifil != null &&
                          agelgilotKifil.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('የአገልግሎት ክፍል: $agelgilotKifil',
                            style: GoogleFonts.notoSansEthiopic(
                                fontSize: 14, color: kAdminSecondaryText)),
                      ],
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          decoration: InputDecoration.collapsed(
                              hintText: 'የግል ማስታወሻዎን እዚህ ያስገቡ...',
                              hintStyle: GoogleFonts.notoSansEthiopic(
                                  color: kAdminSecondaryText.withOpacity(0.5))),
                          maxLines: null,
                          expands: true,
                          style: GoogleFonts.notoSansEthiopic(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                      if (_notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'መጨረሻ የተሻሻለው: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(_notes.first['updated_at'] ?? _notes.first['created_at']).toLocal())}',
                            style: GoogleFonts.notoSansEthiopic(
                                fontSize: 12,
                                color: kAdminSecondaryText.withOpacity(0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _UserListShimmer extends StatelessWidget {
  const _UserListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kAdminCardColor,
      highlightColor: kAdminBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 8,
        itemBuilder: (context, index) => Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: const CircleAvatar(),
            title: Container(height: 16, width: 150, color: Colors.white),
            subtitle: Container(
                height: 12,
                width: 100,
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8)),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
