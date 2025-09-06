import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:amde_haymanot_abalat_guday/models/roles.dart';
import '../models/courses.dart';

class AdminUserEditorScreen extends StatefulWidget {
  final String userId;
  const AdminUserEditorScreen({super.key, required this.userId});

  @override
  State<AdminUserEditorScreen> createState() => _AdminUserEditorScreenState();
}

class _AdminUserEditorScreenState extends State<AdminUserEditorScreen> {
  // State variables
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profileData;
  XFile? _profileImage;
  bool _isUploadingImage = false;
  Uint8List? _imageBytes;

  // Text Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _academicClassController = TextEditingController();
  final _visionController = TextEditingController();

  // Dropdown/Switch state
  bool _isVerified = false;
  AppDepartment? _selectedDepartment;
  AppPosition? _selectedPosition;
  String? _selectedSpiritualClass;

  // Branding colors
  final Color _primaryDark = const Color(0xFF101820);
  final Color _primaryAccent = const Color(0xFFFFD700);
  final Color _textOnDark = Colors.white;
  final Color _textOnLight = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      if (!mounted) return;

      setState(() {
        _profileData = response;
        _fullNameController.text = response['full_name'] ?? '';
        _emailController.text = response['email'] ?? '';
        _phoneController.text = response['phone_number'] ?? '';
        _ageController.text = response['age']?.toString() ?? '';
        _academicClassController.text = response['academic_class'] ?? '';
        _visionController.text = response['vision'] ?? '';
        _isVerified = response['is_verified'] ?? false;

        try {
          final departmentStr = response['department']?.toString() ?? 'other';
          _selectedDepartment = AppDepartment.values.firstWhere(
            (d) => d.name.toLowerCase() == departmentStr.toLowerCase(),
            orElse: () => AppDepartment.other,
          );
        } catch (e) {
          _selectedDepartment = AppDepartment.other;
        }

        try {
          final positionStr = response['position']?.toString() ?? 'other';
          _selectedPosition = AppPosition.values.firstWhere(
            (p) => p.name.toLowerCase() == positionStr.toLowerCase(),
            orElse: () => AppPosition.other,
          );
        } catch (e) {
          _selectedPosition = AppPosition.other;
        }

        _selectedSpiritualClass =
            spiritualClassOptions.contains(response['spiritual_class'])
                ? response['spiritual_class']
                : null;
      });
    } catch (e, stackTrace) {
      debugPrint('--- FETCH USER DATA FAILED ---');
      debugPrint('Error: ${e.toString()}');
      debugPrint('StackTrace: ${stackTrace.toString()}');

      if (mounted) {
        final errorMessage = "Failed to load user data: ${e.toString()}";
        setState(() => _error = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImageToCloudinary(Uint8List bytes) async {
    const cloudName = 'dbdekgotx';
    const uploadPreset = 'profile_pictures';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: '${widget.userId}_profile.jpg',
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      return jsonResponse['secure_url'] as String?;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }

  Future<void> _updateProfileWithImage(String imageUrl) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({'profile_image_url': imageUrl})
          .eq('id', widget.userId)
          .select()
          .single();

      if (mounted) {
        setState(() {
          _profileData = response;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Supabase update error: ${e.message}');
      throw Exception('Failed to update profile: ${e.message}');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isUploadingImage = true;
      });

      final imageUrl = await _uploadImageToCloudinary(bytes);
      if (imageUrl != null) {
        await _updateProfileWithImage(imageUrl);
        _showSuccessSnackBar('Profile image updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await supabase.rpc(
        'update_user_profile',
        params: {
          'p_user_id': widget.userId,
          'p_full_name': _fullNameController.text.trim(),
          'p_phone': _phoneController.text.trim(),
          'p_age': int.tryParse(_ageController.text.trim()),
          'p_academic_class': _academicClassController.text.trim(),
          'p_spiritual_class': _selectedSpiritualClass,
          'p_vision': _visionController.text.trim(),
          'p_department': _selectedDepartment?.name ?? 'other',
          'p_position': _selectedPosition?.name ?? 'other',
          'p_is_verified': _isVerified,
        },
      );

      if (!mounted) return;
      _showSuccessSnackBar('Profile updated successfully!');

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      debugPrint('--- SAVE CHANGES FAILED ---');
      debugPrint('Error: ${e.toString()}');
      if (e is PostgrestException) {
        debugPrint('Supabase Error Details: ${e.details}');
      }
      debugPrint('StackTrace: ${stackTrace.toString()}');

      if (!mounted) return;
      final errorMessage = e is PostgrestException
          ? 'Database Error: ${e.message}'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _academicClassController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Widget _buildProfilePicture() {
    final imageUrl = _profileData?['avatar_url'];
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          child: _isUploadingImage
              ? CircularProgressIndicator(color: _primaryAccent)
              : hasImage
                  ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : Center(
                                    child: CircularProgressIndicator(
                                        color: _primaryAccent)),
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 50,
                          color: _primaryDark,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: _primaryDark,
                    ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: _primaryAccent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: Icon(Icons.camera_alt, size: 20, color: _primaryDark),
              onPressed: _pickAndUploadImage,
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, String title,
      {bool showLoading = false}) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: _textOnDark),
      ),
      backgroundColor: _primaryDark,
      iconTheme: IconThemeData(color: _textOnDark),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      actions: [
        if (showLoading)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: _textOnDark,
                strokeWidth: 3.0,
              ),
            ),
          )
        else if (title != "Error")
          IconButton(
            icon: Icon(Icons.save, color: _textOnDark),
            onPressed: _saveChanges,
          ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryDark.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
        labelStyle: TextStyle(color: _primaryDark),
      ),
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: _textOnLight),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String labelText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryDark.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
        labelStyle: TextStyle(color: _primaryDark),
      ),
      dropdownColor: Colors.white,
      style: TextStyle(color: _textOnLight),
      icon: Icon(Icons.arrow_drop_down, color: _primaryDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profileData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: _primaryAccent),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: _buildAppBar(context, "Error"),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryAccent,
                    foregroundColor: _primaryDark,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(
        context,
        "Edit: ${_profileData?['full_name'] ?? 'User'}",
        showLoading: _isLoading,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
            MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _buildProfilePicture()),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  title: Text('Verified User',
                      style: TextStyle(color: _primaryDark)),
                  value: _isVerified,
                  activeColor: _primaryAccent,
                  onChanged: (value) => setState(() => _isVerified = value),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_fullNameController, 'Full Name'),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', enabled: false),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Phone Number',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(_ageController, 'Age',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_academicClassController, 'Academic Class'),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                value: _selectedSpiritualClass,
                items: spiritualClassOptions
                    .map(
                        (cls) => DropdownMenuItem(value: cls, child: Text(cls)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedSpiritualClass = value),
                labelText: 'Spiritual Class',
              ),
              const SizedBox(height: 16),
              _buildTextField(_visionController, 'Vision', maxLines: 3),
              const SizedBox(height: 20),
              _buildDropdown<AppDepartment>(
                value: _selectedDepartment,
                items: AppDepartment.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value),
                labelText: 'Department',
              ),
              const SizedBox(height: 16),
              _buildDropdown<AppPosition>(
                value: _selectedPosition,
                items: AppPosition.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPosition = value),
                labelText: 'Position',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryAccent,
                  foregroundColor: _primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
