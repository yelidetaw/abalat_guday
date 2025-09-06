import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';

// --- UI Theme Constants ---
const Color kAdminBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminPrimaryAccent = Color(0xFFFFD700);
const Color kAdminSecondaryText = Color(0xFFFFD700);

// --- View Modes ---
const String kRolePermissionView = 'የሚና ፈቃድ';
const String kDepartmentPermissionView = 'የዕቅድ ክፍል ፈቃድ';
const String kScreenPermissionView = 'የስክሪን ፈቃድ';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  String _currentView = kRolePermissionView;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _allDepartments = [];
  List<Map<String, dynamic>> _allScreens = [];
  final List<Map<String, dynamic>> _allRoles = [
    {'id': 1, 'role_name': 'user', 'display_name': 'ተራ አባል'},
    {'id': 2, 'role_name': 'admin', 'display_name': 'አስተዳዳሪ'},
    {'id': 3, 'role_name': 'superior_admin', 'display_name': 'የላቀ አስተዳዳሪ'}
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _logError(String functionName, Object e, StackTrace s) {
    developer.log('Error in $functionName',
        name: 'SuperAdminDashboard', error: e, stackTrace: s);
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // --- ROBUST, SEQUENTIAL DATA FETCHING ---
      final usersResponse = await supabase.rpc('get_all_users_for_permissions');
      final deptsResponse = await supabase.rpc('get_all_departments');
      final screensResponse = await supabase.rpc('get_all_screens');

      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(usersResponse);
          _allDepartments = List<Map<String, dynamic>>.from(deptsResponse);
          _allScreens = List<Map<String, dynamic>>.from(screensResponse);
        });
      }
    } catch (e, s) {
      _logError('_initializeData', e, s);
      if (mounted) setState(() => _error = 'መረጃን በማምጣት ላይ ስህተት ተፈጥሯል።');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kAdminBackgroundColor,
        appBar: AppBar(
          title: Text('የአስተዳደር ማዕከል', style: GoogleFonts.notoSansEthiopic()),
          backgroundColor: kAdminBackgroundColor,
          elevation: 0,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _initializeData)
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: kAdminPrimaryAccent,
            labelColor: kAdminPrimaryAccent,
            unselectedLabelColor: kAdminSecondaryText,
            labelStyle:
                GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: kRolePermissionView),
              Tab(text: kDepartmentPermissionView),
              Tab(text: kScreenPermissionView),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kAdminPrimaryAccent))
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: GoogleFonts.notoSansEthiopic(
                            color: Colors.redAccent)))
                : TabBarView(
                    children: [
                      RoleManagerView(
                          allUsers: _allUsers,
                          onRefresh: _initializeData,
                          showSnackbar: _showSnackbar),
                      DepartmentManagerView(
                          users: _allUsers,
                          allDepartments: _allDepartments,
                          showSnackbar: _showSnackbar),
                      ScreenManagerView(
                          users: _allUsers,
                          allScreens: _allScreens,
                          allRoles: _allRoles,
                          showSnackbar: _showSnackbar),
                    ],
                  ),
      ),
    );
  }
}

// --- WIDGET FOR ROLE PERMISSION VIEW (Tab 1) ---
class RoleManagerView extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;
  final Future<void> Function() onRefresh;
  final Function(String, {bool isError}) showSnackbar;
  const RoleManagerView(
      {super.key,
      required this.allUsers,
      required this.onRefresh,
      required this.showSnackbar});

  @override
  State<RoleManagerView> createState() => _RoleManagerViewState();
}

class _RoleManagerViewState extends State<RoleManagerView> {
  List<Map<String, dynamic>> _filteredUsers = [];
  final _searchController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedBudin;
  String? _selectedAgelgilotKifil;
  List<String> _allDepartmentOptions = [];
  List<String> _allBudinOptions = [];
  List<String> _allAgelgilotKifilOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.allUsers;
    _populateDropdowns();
    _searchController.addListener(_performFilter);
  }

  @override
  void didUpdateWidget(covariant RoleManagerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allUsers != oldWidget.allUsers) {
      _populateDropdowns();
      _performFilter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _populateDropdowns() {
    try {
      _allDepartmentOptions = widget.allUsers
          .map((u) => u['department'])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _allBudinOptions = widget.allUsers
          .map((u) => u['budin'])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _allAgelgilotKifilOptions = widget.allUsers
          .map((u) => u['agelgilot_kifil'])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (e, s) {
      developer.log('Error populating dropdowns',
          name: 'RoleManagerView._populateDropdowns', error: e, stackTrace: s);
    }
  }

  void _performFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = widget.allUsers.where((user) {
        final name = user['full_name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final matchesSearch = name.contains(query) || email.contains(query);
        if (!matchesSearch) return false;
        final matchesDept = _selectedDepartment == null ||
            user['department'] == _selectedDepartment;
        final matchesBudin =
            _selectedBudin == null || user['budin'] == _selectedBudin;
        final matchesAgelgilot = _selectedAgelgilotKifil == null ||
            user['agelgilot_kifil'] == _selectedAgelgilotKifil;
        return matchesDept && matchesBudin && matchesAgelgilot;
      }).toList();
    });
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await supabase.rpc('update_user_role',
          params: {'target_user_id': userId, 'new_role': newRole});
      widget.showSnackbar('የአባሉ ሚና በተሳካ ሁኔታ ተቀይሯል።');
      await widget.onRefresh();
    } catch (e, s) {
      final msg = 'የሚና ለውጥ ስህተት: ${e.toString()}';
      developer.log(msg,
          name: 'RoleManagerView._updateUserRole', error: e, stackTrace: s);
      widget.showSnackbar(msg, isError: true);
    }
  }

  Future<void> _removeUser(String userId, String userName) async {
    final confirmed = await _showConfirmationDialog(
        context: context,
        title: '$userNameን ለማጥፋት',
        content:
            'ማስጠንቀቂያ! ይህ ድርጊት የአባሉን አካውንት እና ሁሉንም ተያያዥ መረጃዎች በቋሚነት ያጠፋል። ይህንን ድርጊት መቀልበስ አይቻልም።',
        confirmText: 'አጥፋ',
        isDestructive: true);
    if (confirmed != true) return;
    try {
      await supabase
          .rpc('delete_user_by_admin', params: {'user_id_to_delete': userId});
      widget.showSnackbar('አባሉ በተሳካ ሁኔታ ተወግዷል።');
      await widget.onRefresh();
    } catch (e, s) {
      final msg = 'የማጥፋት ስህተት: ${e.toString()}';
      developer.log(msg,
          name: 'RoleManagerView._removeUser', error: e, stackTrace: s);
      widget.showSnackbar(msg, isError: true);
    }
  }

  void _showEditRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'user';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kAdminCardColor,
          title: Text('${user['full_name']} - ሚና አስተካክል',
              style: GoogleFonts.notoSansEthiopic(color: kAdminPrimaryAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                  title: Text('ተራ አባል', style: GoogleFonts.notoSansEthiopic()),
                  value: 'user',
                  groupValue: selectedRole,
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  activeColor: kAdminPrimaryAccent),
              RadioListTile<String>(
                  title: Text('አስተዳዳሪ', style: GoogleFonts.notoSansEthiopic()),
                  value: 'admin',
                  groupValue: selectedRole,
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  activeColor: kAdminPrimaryAccent),
              RadioListTile<String>(
                  title:
                      Text('የላቀ አስተዳዳሪ', style: GoogleFonts.notoSansEthiopic()),
                  value: 'superior_admin',
                  groupValue: selectedRole,
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  activeColor: kAdminPrimaryAccent),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeUser(user['id'], user['full_name']);
                },
                child: Text('አባሉን አስወግድ',
                    style:
                        GoogleFonts.notoSansEthiopic(color: Colors.redAccent))),
            const Spacer(),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ይቅር',
                    style: GoogleFonts.notoSansEthiopic(
                        color: kAdminSecondaryText))),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateUserRole(user['id'], selectedRole);
              },
              child: Text('አስቀምጥ', style: GoogleFonts.notoSansEthiopic()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text("በዚህ ማጣሪያ ምንም ተጠቃሚ አልተገኘም።",
                      style: GoogleFonts.notoSansEthiopic(
                          color: kAdminSecondaryText)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final role = user['role'] ?? 'user';
                    return Card(
                      color: kAdminCardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Text(user['full_name']?[0] ?? '?')),
                        title: Text(user['full_name'] ?? 'ስም የሌለው',
                            style: GoogleFonts.notoSansEthiopic(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(user['email'] ?? 'ኢሜይል የለም',
                            style: TextStyle(color: kAdminSecondaryText)),
                        trailing: Chip(
                          label: Text(role,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white)),
                          backgroundColor: role == 'superior_admin'
                              ? Colors.red.shade900
                              : role == 'admin'
                                  ? Colors.orange.shade900
                                  : Colors.blue.shade900,
                          side: BorderSide.none,
                        ),
                        onTap: () => _showEditRoleDialog(user),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
                labelText: 'በስም ወይም በኢሜይል ፈልግ',
                labelStyle: GoogleFonts.notoSansEthiopic(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildDropdown(
                      _selectedDepartment,
                      _allDepartmentOptions,
                      (val) => setState(() {
                            _selectedDepartment = val;
                            _performFilter();
                          }),
                      'ዋና ቡድን')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDropdown(
                      _selectedBudin,
                      _allBudinOptions,
                      (val) => setState(() {
                            _selectedBudin = val;
                            _performFilter();
                          }),
                      'ልዩ ኅብረት')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDropdown(
                      _selectedAgelgilotKifil,
                      _allAgelgilotKifilOptions,
                      (val) => setState(() {
                            _selectedAgelgilotKifil = val;
                            _performFilter();
                          }),
                      'የአገልግሎት ክፍል')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String? value, List<String> items,
      ValueChanged<String?> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text(label,
          style: GoogleFonts.notoSansEthiopic(
              fontSize: 14, color: kAdminSecondaryText)),
      items: [
        DropdownMenuItem(
            value: null,
            child: Text("ሁሉም", style: GoogleFonts.notoSansEthiopic())),
        ...items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item,
                style: GoogleFonts.notoSansEthiopic(),
                overflow: TextOverflow.ellipsis)))
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}

// --- WIDGET FOR DEPARTMENT PERMISSION VIEW (Tab 2) ---
class DepartmentManagerView extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> allDepartments;
  final Function(String, {bool isError}) showSnackbar;
  const DepartmentManagerView(
      {super.key,
      required this.users,
      required this.allDepartments,
      required this.showSnackbar});

  @override
  State<DepartmentManagerView> createState() => _DepartmentManagerViewState();
}

class _DepartmentManagerViewState extends State<DepartmentManagerView> {
  Map<String, dynamic>? _selectedUser;
  Set<String> _currentUserDeptPerms = {};
  bool _isDetailLoading = false;
  bool _isSaving = false;

  Future<void> _selectUser(Map<String, dynamic> user) async {
    setState(() {
      _selectedUser = user;
      _isDetailLoading = true;
    });
    try {
      final response = await supabase.rpc('get_user_department_permissions',
          params: {'p_user_id': user['id']});
      if (mounted)
        setState(() => _currentUserDeptPerms =
            Set<String>.from(response.map((e) => e.toString())));
    } catch (e, s) {
      final msg = 'የተጠቃሚ ፈቃዶችን በማምጣት ላይ ስህተት ተፈጥሯል።: $e';
      developer.log(msg,
          name: 'DepartmentManager._selectUser', error: e, stackTrace: s);
      widget.showSnackbar(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  Future<void> _saveDeptPerms() async {
    if (_selectedUser == null) return;
    setState(() => _isSaving = true);
    try {
      await supabase.rpc('update_user_department_permissions', params: {
        'target_user_id': _selectedUser!['id'],
        'department_ids': _currentUserDeptPerms.toList()
      });
      widget.showSnackbar('የክፍል ፈቃዶች በተሳካ ሁኔታ ተቀምጠዋል');
    } catch (e, s) {
      final msg = 'ፈቃዶችን በማስቀመጥ ላይ ስህተት ተፈጥሯል: $e';
      developer.log(msg,
          name: 'DepartmentManager._saveDeptPerms', error: e, stackTrace: s);
      widget.showSnackbar(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.users.length,
            itemBuilder: (context, index) {
              final user = widget.users[index];
              final isSelected = _selectedUser?['id'] == user['id'];
              return Card(
                color: isSelected
                    ? kAdminPrimaryAccent.withOpacity(0.25)
                    : kAdminCardColor,
                child: ListTile(
                  title: Text(user['full_name'],
                      style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
                  onTap: () => _selectUser(user),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1, color: kAdminCardColor),
        Expanded(
          flex: 3,
          child: _selectedUser == null
              ? Center(
                  child: Text("ፈቃዶችን ለማስተዳደር ተጠቃሚ ይምረጡ",
                      style: GoogleFonts.notoSansEthiopic(
                          color: kAdminPrimaryAccent)))
              : _isDetailLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                              "የ'${_selectedUser!['full_name']}' የክፍል ፈቃዶች",
                              style: GoogleFonts.notoSansEthiopic(
                                  color: kAdminPrimaryAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.allDepartments.length,
                            itemBuilder: (context, index) {
                              final dept = widget.allDepartments[index];
                              return CheckboxListTile(
                                title: Text(dept['name'],
                                    style: GoogleFonts.notoSansEthiopic(
                                        color: Colors.white)),
                                value:
                                    _currentUserDeptPerms.contains(dept['id']),
                                onChanged: (isChecked) {
                                  setState(() {
                                    if (isChecked == true)
                                      _currentUserDeptPerms.add(dept['id']);
                                    else
                                      _currentUserDeptPerms.remove(dept['id']);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveDeptPerms,
                                  child: _isSaving
                                      ? const CircularProgressIndicator(
                                          color: kAdminBackgroundColor,
                                        )
                                      : Text("አስቀምጥ",
                                          style:
                                              GoogleFonts.notoSansEthiopic()))),
                        )
                      ],
                    ),
        ),
      ],
    );
  }
}

// --- WIDGET FOR SCREEN PERMISSION VIEW (Tab 3) ---
class ScreenManagerView extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> allScreens;
  final Function(String, {bool isError}) showSnackbar;
  const ScreenManagerView(
      {super.key,
      required this.users,
      required this.allScreens,
      required this.showSnackbar,
      required List<Map<String, dynamic>> allRoles});

  @override
  State<ScreenManagerView> createState() => _ScreenManagerViewState();
}

class _ScreenManagerViewState extends State<ScreenManagerView> {
  Map<String, dynamic>? _selectedUser;
  Set<int> _currentScreenPerms = {};
  bool _isDetailLoading = false;
  bool _isSaving = false;

  Future<void> _selectUser(Map<String, dynamic> user) async {
    final roleName = user['role'] as String?;
    if (roleName == null || roleName.isEmpty) {
      widget.showSnackbar('ይህ ተጠቃሚ ሚና የለውም። በመጀመሪያ ሚና ይመድቡ።', isError: true);
      return;
    }
    setState(() {
      _selectedUser = user;
      _isDetailLoading = true;
    });
    try {
      final response = await supabase.rpc('get_screen_permissions_for_role',
          params: {'p_role_name': roleName});
      if (mounted)
        setState(() =>
            _currentScreenPerms = Set<int>.from(response.map((e) => e as int)));
    } catch (e, s) {
      final msg = 'የስክሪን ፈቃዶችን በማምጣት ላይ ስህተት ተፈጥሯል: $e';
      developer.log(msg,
          name: 'ScreenManager._selectUser', error: e, stackTrace: s);
      widget.showSnackbar(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  Future<void> _saveScreenPerms() async {
    if (_selectedUser == null) return;
    final roleName = _selectedUser!['role'] as String?;
    if (roleName == null || roleName.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await supabase.rpc('update_role_screen_permissions', params: {
        'p_role_name': roleName,
        'p_screen_ids': _currentScreenPerms.toList()
      });
      widget.showSnackbar('የስክריን ፈቃዶች በተሳካ ሁኔታ ተቀምጠዋል');
    } catch (e, s) {
      final msg = 'ፈቃዶችን በማስቀመጥ ላይ ስህተት ተፈጥሯል: $e';
      developer.log(msg,
          name: 'ScreenManager._saveScreenPerms', error: e, stackTrace: s);
      widget.showSnackbar(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.users.length,
            itemBuilder: (context, index) {
              final user = widget.users[index];
              final isSelected = _selectedUser?['id'] == user['id'];
              return Card(
                color: isSelected
                    ? kAdminPrimaryAccent.withOpacity(0.25)
                    : kAdminCardColor,
                child: ListTile(
                  title: Text(user['full_name'],
                      style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
                  subtitle: Text(user['role'] ?? 'ሚና የለም',
                      style: GoogleFonts.notoSansEthiopic(
                          color: kAdminSecondaryText)),
                  onTap: () => _selectUser(user),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1, color: kAdminCardColor),
        Expanded(
          flex: 3,
          child: _selectedUser == null
              ? Center(
                  child: Text("ፈቃዶችን ለማየት እና ለማስተካከል ተጠቃሚ ይምረጡ",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansEthiopic(
                          color: kAdminPrimaryAccent)))
              : _isDetailLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                              "የ'${_selectedUser!['role']}' ሚና (ለ${_selectedUser!['full_name']})",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansEthiopic(
                                  color: kAdminPrimaryAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.allScreens.length,
                            itemBuilder: (context, index) {
                              final screen = widget.allScreens[index];
                              return CheckboxListTile(
                                title: Text(screen['display_name'],
                                    style: GoogleFonts.notoSansEthiopic(
                                        color: Colors.white)),
                                subtitle: Text(screen['screen_key'],
                                    style: const TextStyle(
                                        color: kAdminSecondaryText)),
                                value:
                                    _currentScreenPerms.contains(screen['id']),
                                onChanged: (isChecked) {
                                  setState(() {
                                    if (isChecked == true)
                                      _currentScreenPerms.add(screen['id']);
                                    else
                                      _currentScreenPerms.remove(screen['id']);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed:
                                      _isSaving ? null : _saveScreenPerms,
                                  child: _isSaving
                                      ? const CircularProgressIndicator()
                                      : Text("አስቀምጥ",
                                          style:
                                              GoogleFonts.notoSansEthiopic()))),
                        )
                      ],
                    ),
        ),
      ],
    );
  }
}

// --- HELPER DIALOG (Used by RoleManagerView) ---
Future<bool?> _showConfirmationDialog(
    {required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false}) {
  return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: kAdminCardColor,
            title: Text(title, style: GoogleFonts.notoSansEthiopic()),
            content: Text(content, style: GoogleFonts.notoSansEthiopic()),
            actions: [
              TextButton(
                  child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic()),
                  onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor:
                        isDestructive ? Colors.redAccent : kAdminPrimaryAccent),
                child: Text(confirmText, style: GoogleFonts.notoSansEthiopic()),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ));
}
