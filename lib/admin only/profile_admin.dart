import 'dart:io';
import 'dart:convert';
import 'package:amde_haymanot_abalat_guday/users%20screen/attendance_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/grade_management_screen.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/library_director_screen.dart'; // Import the new screen
import 'package:supabase_flutter/supabase_flutter.dart';

// --- BRANDING COLORS ---
const Color primaryColor = Color(0xFF101820);
const Color accentColor = Color(0xFFFFD700);

// --- Predefined Options For Dropdowns ---
final List<String> _spiritualClassOptions = List.generate(
  12,
  (i) => 'Grade ${i + 1}',
);
const List<String> _kifilOptions = [
  'Wetat',
  'Teguḥan',
  'Lideta',
  'Beʻata',
  'Filsata',
];
const List<String> _yesraDirishaOptions = [
  'Sra_Asifetsami (Neus)',
  'Sra_Asifetsami (Tsom)',
  'Hibre_Bete-Krestiyan',
  'Maḥibere-Tibeban',
];
const List<String> _budinOptions = [
  'Abune Gorgoriyos',
  'Abune Mikaʼel',
  'Abune Tekle Haymanot',
  'Abune Gebre Menfes Qidus',
  'Abune Areggawi',
];
const List<String> _agelgilotKifilOptions = [
  'Timihrt Kifil',
  'Hizb Ginuninet',
  'Maḥibere-Tibeban',
  'Gimigina',
  'Dirssét',
  'Zena wuțib',
  'Planina Biujét',
];

class AdminScreenp extends StatefulWidget {
  const AdminScreenp({super.key});

  @override
  State<AdminScreenp> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreenp> {
  bool _isLoading = true;
  String? _loadingError;
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  String? _selectedUserId;

  final _phoneController = TextEditingController();
  String? _kifilValue;
  String? _yesraDirishaValue;
  String? _budinValue;
  String? _agelgilotKifilValue;

  final _ageController = TextEditingController();
  final _academicClassController = TextEditingController();
  final _visionController = TextEditingController();
  String? _spiritualClassValue;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _ageController.dispose();
    _academicClassController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });
    try {
      final response = await supabase.from('profiles').select();
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          if (_selectedUserId != null) {
            try {
              _selectedUser = _users.firstWhere(
                (user) => user['id'] == _selectedUserId,
              );
            } on StateError {
              _selectedUser = null;
              _selectedUserId = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = 'Failed to fetch users.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onUserSelected(String? selectedId) {
    setState(() {
      _selectedUserId = selectedId;
      if (selectedId == null) {
        _selectedUser = null;
        _phoneController.clear();
        _ageController.clear();
        _academicClassController.clear();
        _visionController.clear();
        _kifilValue = null;
        _yesraDirishaValue = null;
        _budinValue = null;
        _agelgilotKifilValue = null;
        _spiritualClassValue = null;
        return;
      }

      try {
        _selectedUser = _users.firstWhere((user) => user['id'] == selectedId);
      } on StateError {
        _selectedUser = null;
      }

      if (_selectedUser != null) {
        final user = _selectedUser!;
        _phoneController.text = user['phone_number'] ?? '';
        _ageController.text = user['age']?.toString() ?? '';
        _academicClassController.text = user['academic_class'] ?? '';
        _visionController.text = user['vision'] ?? '';
        final userKifil = user['kifil'];
        _kifilValue = _kifilOptions.contains(userKifil) ? userKifil : null;
        final userYesraDirisha = user['yesra_dirisha'];
        _yesraDirishaValue = _yesraDirishaOptions.contains(userYesraDirisha)
            ? userYesraDirisha
            : null;
        final userBudin = user['budin'];
        _budinValue = _budinOptions.contains(userBudin) ? userBudin : null;
        final userAgelgilotKifil = user['agelgilot_kifil'];
        _agelgilotKifilValue =
            _agelgilotKifilOptions.contains(userAgelgilotKifil)
                ? userAgelgilotKifil
                : null;
        final userSpiritualClass = user['spiritual_class'];
        _spiritualClassValue =
            _spiritualClassOptions.contains(userSpiritualClass)
                ? userSpiritualClass
                : null;
      }
    });
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.redAccent)),
          content: SingleChildScrollView(child: SelectableText(content)),
          actions: [
            TextButton(
              child: const Text('Copy Error'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error copied to clipboard')),
                );
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onUploadAvatar() async {
    if (_selectedUser == null) return;
    const String cloudName = 'YOUR_CLOUD_NAME';
    const String uploadPreset = 'YOUR_UNSIGNED_UPLOAD_PRESET_NAME';
    setState(() => _isUploading = true);
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (imageFile == null) {
      setState(() => _isUploading = false);
      return;
    }
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception(
          'Cloudinary upload failed. Status code: ${response.statusCode}',
        );
      }
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);
      final imageUrl = decodedData['secure_url'];
      try {
        await supabase.from('profiles').update(
            {'profile_image_url': imageUrl}).eq('id', _selectedUser!['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchUsers();
      } on PostgrestException catch (e) {
        if (mounted) {
          final detailedError =
              'Message: ${e.message}\n\nDetails: ${e.details}\n\nHint: ${e.hint}\n\nCode: ${e.code}';
          _showErrorDialog('Supabase Database Error', detailedError);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An Unexpected Error Occurred', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _verifyAndSaveChanges() async {
    if (_selectedUser == null) return;
    try {
      await supabase.rpc(
        'verify_and_update_user_signup_info',
        params: {
          'target_user_id': _selectedUser!['id'],
          'new_phone_number': _phoneController.text.trim(),
          'new_kifil': _kifilValue,
          'new_yesra_dirisha': _yesraDirishaValue,
          'new_budin': _budinValue,
          'new_agelgilot_kifil': _agelgilotKifilValue,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User verified and information updated!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
      await _fetchUsers();
    } catch (error) {
      if (mounted) _showErrorDialog('Verification Error', error.toString());
    }
  }

  Future<void> _promoteToAdmin() async {
    if (_selectedUser == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Promotion'),
        content: Text(
          'Are you sure you want to promote "${_selectedUser!['full_name']}" to an Admin role?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Promote'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase.rpc(
        'promote_user_to_admin',
        params: {'target_user_id': _selectedUser!['id']},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User promoted to Admin!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
      await _fetchUsers();
    } catch (error) {
      if (mounted) _showErrorDialog('Promotion Error', error.toString());
    }
  }

  Future<void> _updateProfileViaRpc() async {
    if (_selectedUser == null) return;
    try {
      await supabase.rpc(
        'update_user_details_by_admin',
        params: {
          'target_user_id': _selectedUser!['id'],
          'new_age': int.tryParse(_ageController.text.trim()),
          'new_academic_class': _academicClassController.text.trim(),
          'new_spiritual_class': _spiritualClassValue,
          'new_vision': _visionController.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admin fields updated successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
      await _fetchUsers();
    } catch (error) {
      if (mounted) _showErrorDialog('Profile Update Error', error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ADDED: Theme data for consistent styling
    final theme = Theme.of(context).copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: primaryColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0, // Flat design
          titleTextStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: accentColor, fontSize: 20),
          iconTheme: const IconThemeData(color: accentColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor, width: 2),
          ),
        ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: accentColor,
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: accentColor,
            foregroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
            textStyle: const TextStyle(color: Colors.white),
            inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(color: accentColor))));

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          // ADDED: Conditional back button
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                )
              : null,
          title: Text(
            'Admin Panel',
            style: theme.appBarTheme.titleTextStyle,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchUsers,
              tooltip: 'Refresh Users',
            ),
            IconButton(
              icon: const Icon(Icons.local_library), // Library Icon
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LibraryDirectorScreen(),
                ),
              ),
              tooltip: 'Assign Books',
            ),
            IconButton(
              icon: const Icon(Icons.how_to_reg_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AttendanceHistoryScreen(),
                ),
              ),
              tooltip: 'Mark Attendance',
            ),
            IconButton(
              icon: const Icon(Icons.school),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GradeManagementScreen(),
                ),
              ),
              tooltip: 'Grade Management',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(
        color: accentColor,
      ));
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _loadingError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // RESPONSIVENESS: Use LayoutBuilder to adapt to screen size
    return LayoutBuilder(builder: (context, constraints) {
      return RefreshIndicator(
        onRefresh: _fetchUsers,
        color: primaryColor,
        backgroundColor: accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 600
                  ? 32.0
                  : 16.0, // More padding on wider screens
              vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('1. Select User'),
              const SizedBox(height: 8),
              _users.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No users found.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _buildUserDropdown(),
              const SizedBox(height: 24),
              if (_selectedUser != null) ...[
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        // RESPONSIVENESS: Avatar size is now relative
                        radius: constraints.maxWidth * 0.15,
                        backgroundColor: Colors.black26,
                        backgroundImage: (_selectedUser!['profile_image_url'] !=
                                    null &&
                                _selectedUser!['profile_image_url']!.isNotEmpty)
                            ? NetworkImage(_selectedUser!['profile_image_url'])
                            : null,
                        child: (_selectedUser!['profile_image_url'] == null ||
                                _selectedUser!['profile_image_url']!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: constraints.maxWidth * 0.15,
                                color: accentColor.withOpacity(0.5),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: _isUploading ? null : _onUploadAvatar,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: primaryColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.edit,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _selectedUser!['full_name'] ?? 'Unnamed User',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_selectedUser != null) ...[
                _buildSectionTitle('2. User Verification & Roles'),
                const SizedBox(height: 12),
                _buildVerificationForm(),
                const SizedBox(height: 24),
                _buildSectionTitle('3. Edit Admin-Managed Profile'),
                const SizedBox(height: 12),
                _buildProfileEditForm(),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: accentColor, // CHANGED: Use accent color for titles
        ),
      );

  Widget _buildUserDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // CHANGED: Themed background
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUserId,
          hint: const Text('Select a user to manage',
              style: TextStyle(color: Colors.white70)),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor:
              primaryColor.withBlue(40), // CHANGED: Themed dropdown background
          icon: const Icon(Icons.arrow_drop_down, color: accentColor),
          items: _users
              .map(
                (user) => DropdownMenuItem<String>(
                  value: user['id'] as String,
                  child: Row(
                    children: [
                      Text(user['full_name'] ?? 'Unnamed User'),
                      const Spacer(),
                      if (user['is_verified'] != true)
                        const Tooltip(
                          message: 'Pending Verification',
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: _onUserSelected,
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    final bool isVerified = _selectedUser?['is_verified'] ?? false;
    final bool isAdmin = _selectedUser?['role'] == 'admin';
    return Card(
      elevation: 4,
      color: primaryColor.withBlue(30), // CHANGED: Themed card color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Status: ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Chip(
                  label: Text(
                    isVerified ? 'Verified' : 'Pending',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  backgroundColor:
                      isVerified ? accentColor : Colors.orangeAccent,
                  avatar: Icon(
                    isVerified ? Icons.check_circle : Icons.warning,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                if (isAdmin)
                  const Chip(
                    label: Text('ADMIN'),
                    backgroundColor: accentColor,
                    labelStyle: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const Divider(
              height: 24,
              color: Colors.white24,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Kifil',
              _kifilOptions,
              _kifilValue,
              (val) => setState(() => _kifilValue = val),
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Yesra Dirisha',
              _yesraDirishaOptions,
              _yesraDirishaValue,
              (val) => setState(() => _yesraDirishaValue = val),
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Budin (Liyu Hibiret)',
              _budinOptions,
              _budinValue,
              (val) => setState(() => _budinValue = val),
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Ye Agelgilot Kifil',
              _agelgilotKifilOptions,
              _agelgilotKifilValue,
              (val) => setState(() => _agelgilotKifilValue = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: Text(isVerified ? 'Save Changes' : 'Verify and Save'),
              onPressed: _verifyAndSaveChanges,
              // CHANGED: Style is now from theme
            ),
            const SizedBox(height: 12),
            if (!isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Promote to Admin'),
                onPressed: _promoteToAdmin,
                // CHANGED: Style is now from theme
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFormField(
    String label,
    List<String> options,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
      ),
      dropdownColor: primaryColor.withBlue(40),
      style: const TextStyle(color: Colors.white),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProfileEditForm() {
    return Card(
      elevation: 4,
      color: primaryColor.withBlue(30), // CHANGED: Themed card color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _academicClassController,
              decoration: const InputDecoration(labelText: 'Academic Class'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Spiritual Class',
              _spiritualClassOptions,
              _spiritualClassValue,
              (val) => setState(() => _spiritualClassValue = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _visionController,
              decoration: const InputDecoration(labelText: 'Vision'),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateProfileViaRpc,
              child: const Text('Save Admin-Managed Info'),
            ),
          ],
        ),
      ),
    );
  }
}
