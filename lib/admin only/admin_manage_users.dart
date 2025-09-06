import 'package:amde_haymanot_abalat_guday/role%20based/grade_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'package:amde_haymanot_abalat_guday/role%20based/learning_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For spiritualClassOptions

// --- UI Theme Constants ---
const Color kAdminBackgroundColor =Color.fromARGB(255, 1, 37, 100);
const Color kAdminCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminPrimaryAccent = Color(0xFFFFD700);
const Color kAdminSecondaryText = Color(0xFFFFD700);

class UnifiedAdminScreen extends StatefulWidget {
  const UnifiedAdminScreen({super.key});

  @override
  State<UnifiedAdminScreen> createState() => _UnifiedAdminScreenState();
}

class _UnifiedAdminScreenState extends State<UnifiedAdminScreen> {
  bool _isLoading = true;
  String? _loadingError;

  String? _selectedUserId;
  Map<String, dynamic>? _selectedUserData;

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  bool _isActionInProgress = false;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _academicClassController = TextEditingController();
  final _visionController = TextEditingController();
  String? _kifilValue;
  String? _yesraDirishaValue;
  String? _budinValue;
  String? _agelgilotKifilValue;
  String? _spiritualClassValue;
  bool _isVerified = false;

  static const List<String> _kifilOptions = [
    'ጎልማሳ',
    'ወጣት',
    'ታዳጊ',
    'ሕፃናት',
    'ደቂቅ'
  ];
  static const List<String> _yesraDirishaOptions = [
    'ንኡስ',
    'ስራ አስፈጻሚ ',
    'አባል',
  ];
  static const List<String> _budinOptions = [
    'አቡነ ቴዎፍሎስ',
    'አቡነ ጎርጎርዮስ',
    'አቡነ ሺኖዳ',
    'ሀቢብ ጊዮርጊስ'
  ];
  static const List<String> _agelgilotKifilOptions = [
    'ሰብሳቢ ',
    'ምክትል ሰብሳቢ',
    'ጸሀፊ',
    'ቁጥጥር ክፍል',
    'ትምህርት ክፍል',
    'ልማት ክፍል',
    'መዝሙር ክፍል',
    'አባላት ጉዳይ',
    'መባእና መስተንግዶ ',
    'ኪነ ጥበብ ክፍል',
    'ቤተ መጻሕፍት',
    'ግንኙነት ክፍል',
    'ንብረት ክፍል',
    'ሂሳብ ክፍል',
    'ገንዘብ ያዥ',
  ];
  static final List<String> _spiritualClassOptions = spiritualClassOptions;

  @override
  void initState() {
    super.initState();
    _fetchUserList();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _academicClassController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserList() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });
    try {
      final response = await supabase.rpc('get_all_user_profiles_for_admin');
      if (!mounted) return;
      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(response);
        _filteredUsers = _allUsers;
      });
    } catch (e, stackTrace) {
      final errorMessage = 'አባላትን መጫን አልተቻለም፡ ${e.toString()}';
      developer.log(errorMessage,
          name: 'UnifiedAdminScreen.fetchUsers',
          error: e,
          stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _loadingError = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = user['full_name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _selectUserForEditing(String userId) {
    final userData =
        _allUsers.firstWhere((user) => user['id'] == userId, orElse: () => {});
    if (userData.isNotEmpty) {
      setState(() {
        _selectedUserId = userId;
        _selectedUserData = userData;
        _populateFormWithUserData(_selectedUserData!);
      });
    } else {
      _showSnackbar('የአባሉን ሙሉ መረጃ ማግኘት አልተቻለም', isError: true);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedUserId = null;
      _selectedUserData = null;
      _fullNameController.clear();
      _phoneController.clear();
      _ageController.clear();
      _academicClassController.clear();
      _visionController.clear();
      _isVerified = false;
      _kifilValue = null;
      _yesraDirishaValue = null;
      _budinValue = null;
      _agelgilotKifilValue = null;
      _spiritualClassValue = null;
    });
  }

  void _populateFormWithUserData(Map<String, dynamic> user) {
    _fullNameController.text = user['full_name'] ?? '';
    _phoneController.text = user['phone_number'] ?? '';
    _ageController.text = user['age']?.toString() ?? '';
    _academicClassController.text = user['academic_class'] ?? '';
    _visionController.text = user['vision'] ?? '';
    _isVerified = user['is_verified'].toString() == 'true'; // Safe conversion
    _kifilValue = _kifilOptions.contains(user['kifil']) ? user['kifil'] : null;
    _yesraDirishaValue = _yesraDirishaOptions.contains(user['yesra_dirisha'])
        ? user['yesra_dirisha']
        : null;
    _budinValue = _budinOptions.contains(user['budin']) ? user['budin'] : null;
    _agelgilotKifilValue =
        _agelgilotKifilOptions.contains(user['agelgilot_kifil'])
            ? user['agelgilot_kifil']
            : null;
    _spiritualClassValue =
        _spiritualClassOptions.contains(user['spiritual_class'])
            ? user['spiritual_class']
            : null;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (imageFile == null || _selectedUserData == null) return;

    setState(() => _isActionInProgress = true);
    try {
      final bytes = await imageFile.readAsBytes();
      final mimeType = 'image/jpeg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${_selectedUserData!['id']}/$fileName';

      await supabase.storage.from('avatars').uploadBinary(filePath, bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true));

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      await supabase.from('profiles').update(
          {'profile_image_url': imageUrl}).eq('id', _selectedUserData!['id']);

      _showSnackbar('ምስሉ በተሳካ ሁኔታ ተቀይሯል።', isError: false);
      // Optimistically update the UI
      setState(() => _selectedUserData!['profile_image_url'] = imageUrl);
      // Find and update the user in the main list as well
      final userIndex = _allUsers
          .indexWhere((user) => user['id'] == _selectedUserData!['id']);
      if (userIndex != -1) {
        setState(() => _allUsers[userIndex]['profile_image_url'] = imageUrl);
      }
      _filterUsers(); // Re-apply search filter
    } catch (e) {
      _showErrorDialog('የምስል ስቀላ ስህተት', e.toString());
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_selectedUserData == null) return;
    setState(() => _isActionInProgress = true);
    try {
      await supabase.rpc('update_user_profile', params: {
        'p_user_id': _selectedUserData!['id'].toString(),
        'p_full_name': _fullNameController.text.trim(),
        'p_phone': _phoneController.text.trim(),
        'p_age': int.tryParse(_ageController.text.trim()),
        'p_academic_class': _academicClassController.text.trim(),
        'p_current_spiritual_class': _spiritualClassValue,
        'p_vision': _visionController.text.trim(),
        'p_is_verified': _isVerified,
        'p_kifil': _kifilValue,
        'p_yesra_dirisha': _yesraDirishaValue,
        'p_budin': _budinValue,
        'p_agelgilot_kifil': _agelgilotKifilValue,
      });
      _showSnackbar('የአባሉ መረጃ በተሳካ ሁኔታ ተቀይሯል።', isError: false);
      await _fetchUserList();
    } catch (e, stackTrace) {
      final msg = 'መረጃውን መቀየር አልተቻለም፡ ${e.toString()}';
      developer.log(msg, name: "SaveChanges", error: e, stackTrace: stackTrace);
      _showErrorDialog('ስህተት', msg);
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
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

  void _showErrorDialog(String title, String content) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title, style: GoogleFonts.notoSansEthiopic()),
              content: SelectableText(content,
                  style: GoogleFonts.notoSansEthiopic()),
              actions: [
                TextButton(
                    child: Text('እሺ', style: GoogleFonts.notoSansEthiopic()),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAdminBackgroundColor,
      appBar: AppBar(
        backgroundColor: kAdminBackgroundColor,
        elevation: 0,
        leading: _selectedUserId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: _clearSelection)
            : null,
        title: Text(
            _selectedUserId == null
                ? 'የአባላት መረጃ ማስተካከያ'
                : (_selectedUserData?['full_name'] ?? 'Edit User'),
            style: GoogleFonts.notoSansEthiopic()),
        actions: [
          if (_selectedUserId == null)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _fetchUserList),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedUserId == null
                ? _buildUserList()
                : _buildUserEditorForm(),
          ),
          if (_isActionInProgress || (_isLoading && _selectedUserId != null))
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading && _allUsers.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_loadingError != null)
      return Center(
          child:
              Text(_loadingError!, style: const TextStyle(color: Colors.red)));

    return Column(
      key: const ValueKey('user_list'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'አባላትን በስም ወይም በኢሜይል ይፈልጉ',
              labelStyle: GoogleFonts.notoSansEthiopic(),
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text('ምንም አባል አልተገኘም',
                      style: GoogleFonts.notoSansEthiopic()))
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final role = user['role'] ?? 'user';
                    final imageUrl = user['profile_image_url'];
                    final bool hasImage =
                        imageUrl != null && imageUrl.isNotEmpty;

                    return Card(
                      color: kAdminCardColor,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              hasImage ? NetworkImage(imageUrl) : null,
                          child: !hasImage
                              ? Text(user['full_name']?[0] ?? '?')
                              : null,
                        ),
                        title: Text(user['full_name'] ?? 'ስም የሌለው',
                            style: GoogleFonts.notoSansEthiopic(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        subtitle: Text(user['email'] ?? 'ኢሜይል የለም',
                            style: TextStyle(color: kAdminSecondaryText)),
                        trailing: Chip(
                          label: Text(role),
                          backgroundColor: role == 'superior_admin'
                              ? Colors.red.shade900
                              : role == 'admin'
                                  ? Colors.orange.shade900
                                  : Colors.blue.shade900,
                        ),
                        onTap: () => _selectUserForEditing(user['id']),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserEditorForm() {
    if (_selectedUserData == null)
      return Center(
          child: Text('የአባሉን መረጃ መጫን አልተቻለም',
              style: GoogleFonts.notoSansEthiopic()));

    return ListView(
      key: ValueKey(_selectedUserId),
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(child: _buildProfilePicture()),
        const SizedBox(height: 24),
        Card(
          color: kAdminCardColor,
          child: SwitchListTile(
            title: Text('የተረጋገጠ አባል', style: GoogleFonts.notoSansEthiopic()),
            value: _isVerified,
            onChanged: (value) => setState(() => _isVerified = value),
            secondary: Icon(
                _isVerified ? Icons.check_circle : Icons.hourglass_top,
                color: _isVerified ? Colors.green : Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('የግል መረጃ'),
        _buildTextField(_fullNameController, 'ሙሉ ስም'),
        _buildTextField(_phoneController, 'ስልክ ቁጥር',
            keyboardType: TextInputType.phone),
        _buildTextField(_ageController, 'ዕድሜ',
            keyboardType: TextInputType.number),
        _buildTextField(_academicClassController, 'የትምህርት ደረጃ'),
        _buildTextField(_visionController, 'ራዕይ', maxLines: 3),
        const SizedBox(height: 24),
        _buildSectionHeader('የማኅበር ምድብ'),
        _buildDropdown(_spiritualClassValue, _spiritualClassOptions,
            (val) => setState(() => _spiritualClassValue = val), 'መንፈሳዊ ክፍል'),
        _buildDropdown(_kifilValue, _kifilOptions,
            (val) => setState(() => _kifilValue = val), 'ክፍል'),
        _buildDropdown(_yesraDirishaValue, _yesraDirishaOptions,
            (val) => setState(() => _yesraDirishaValue = val), 'የስራ ድርሻ'),
        _buildDropdown(_budinValue, _budinOptions,
            (val) => setState(() => _budinValue = val), 'ልዩ ኅብረት (ቡድን)'),
        _buildDropdown(_agelgilotKifilValue, _agelgilotKifilOptions,
            (val) => setState(() => _agelgilotKifilValue = val), 'የአገልግሎት ክፍል'),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: Text('ለውጦችን አስቀምጥ', style: GoogleFonts.notoSansEthiopic()),
          onPressed: _isActionInProgress ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
              backgroundColor: kAdminPrimaryAccent,
              foregroundColor: kAdminBackgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        // Admin actions are now removed from this screen
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: GoogleFonts.notoSansEthiopic(
              fontSize: 20,
              color: kAdminPrimaryAccent,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfilePicture() {
    final imageUrl = _selectedUserData?['profile_image_url'];
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
          child: !hasImage
              ? const Icon(Icons.person, size: 60, color: kAdminSecondaryText)
              : null,
        ),
        Material(
          color: kAdminPrimaryAccent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _isActionInProgress ? null : _pickAndUploadImage,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.camera_alt, color: Colors.black, size: 24),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSansEthiopic(),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDropdown(String? value, List<String> items,
      ValueChanged<String?> onChanged, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: GoogleFonts.notoSansEthiopic())))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSansEthiopic(),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
