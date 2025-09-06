import 'package:amde_haymanot_abalat_guday/social_media_url.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // To access the global 'supabase' client
import 'package:supabase_flutter/supabase_flutter.dart'; // Import for AuthException and other types

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // State variables for each dropdown
  String? _selectedKifil;
  String? _selectedYesraDirisha;
  String? _selectedBudin;
  String? _selectedAgelgilotKifil;

  // Text field controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Loading state for user feedback
  bool _isLoading = false;

  // State variables to hold real-time validation errors
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;

  void _validatePasswords(String value) {
    setState(() {
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text.length < 6) {
        _passwordErrorText = 'Password must be at least 6 characters';
      } else {
        _passwordErrorText = null;
      }

      if (_confirmPasswordController.text.isNotEmpty &&
          _passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordErrorText = "Passwords don't match";
      } else {
        _confirmPasswordErrorText = null;
      }
    });
  }

  void _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    setState(() {
      if (value.isEmpty) {
        _emailErrorText = null;
      } else if (!emailRegex.hasMatch(value)) {
        _emailErrorText = 'Invalid email address';
      } else {
        _emailErrorText = null;
      }
    });
  }

  Future<void> _signup() async {
    // Comprehensive final validation before submitting
    if (_emailErrorText != null ||
        _passwordErrorText != null ||
        _confirmPasswordErrorText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the errors before submitting"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedKifil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _fullNameController.text.trim()},
      );

      if (authResponse.user != null) {
        await supabase
            .from('profiles')
            .update({
              'full_name': _fullNameController.text.trim(),
              'phone_number': _phoneController.text.trim(),
              'kifil': _selectedKifil,
              'yesra_dirisha': _selectedYesraDirisha,
              'budin': _selectedBudin,
              'agelgilot_kifil': _selectedAgelgilotKifil,
            })
            .eq('id', authResponse.user!.id);

        // --- THIS IS THE KEY CHANGE ---
        if (mounted) {
          // This will navigate to your home screen.
          // Assumes your home route is '/home' in your GoRouter setup.
          context.go('/home');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      print('--- SUPABASE SIGNUP ERROR ---');
      print(error);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An unexpected error occurred. Check debug console."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Since we are navigating away, this part might not be visible, which is fine.
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3),
      appBar: AppBar(
        title: Text(
          'Sign Up to Amde Haymanot',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF673AB7),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F3),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade500,
                    offset: const Offset(5, 5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-5, -5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Image.asset(
                  "assets/images/am-11.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Welcome to Amde Haymanot',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please fill out the following information:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            _buildNeumorphicInputField(
              controller: _fullNameController,
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 15),
            _buildNeumorphicInputField(
              controller: _emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged: _validateEmail,
            ),
            if (_emailErrorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailErrorText!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            _buildNeumorphicInputField(
              controller: _phoneController,
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildNeumorphicInputField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              icon: Icons.lock_outline,
              obscureText: true,
              onChanged: _validatePasswords,
            ),
            if (_passwordErrorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passwordErrorText!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            _buildNeumorphicInputField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: true,
              onChanged: _validatePasswords,
            ),
            if (_confirmPasswordErrorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _confirmPasswordErrorText!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            _buildNeumorphicDropdown(
              labelText: 'Kifil',
              hintText: 'Select Kifil',
              value: _selectedKifil,
              items: _kifilat,
              onChanged: (value) => setState(() => _selectedKifil = value),
            ),
            const SizedBox(height: 15),
            _buildNeumorphicDropdown(
              labelText: 'Yesra Dirisha',
              hintText: 'Select Yesra Dirisha',
              value: _selectedYesraDirisha,
              items: Yesra_dirisha,
              onChanged: (value) =>
                  setState(() => _selectedYesraDirisha = value),
            ),
            const SizedBox(height: 15),
            _buildNeumorphicDropdown(
              labelText: 'Liyu Yeagelgilot Hibiret',
              hintText: 'Select Liyu Yeagelgilot Hibiret',
              value: _selectedBudin,
              items: budin,
              onChanged: (value) => setState(() => _selectedBudin = value),
            ),
            const SizedBox(height: 15),
            _buildNeumorphicDropdown(
              labelText: 'Ye Agelgilot Kifil',
              hintText: 'Select Ye Agelgilot Kifil',
              value: _selectedAgelgilotKifil,
              items: yeagelgilotkifil,
              onChanged: (value) =>
                  setState(() => _selectedAgelgilotKifil = value),
            ),
            const SizedBox(height: 20),
            _buildNeumorphicButton(
              onPressed: _isLoading ? () {} : _signup,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Sign Up',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SocialMediaUrl(),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
      ),
    );
  }

  Widget _buildNeumorphicButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          color: const Color(0xFF673AB7),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade500,
              offset: const Offset(5, 5),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildNeumorphicDropdown({
    required String labelText,
    required String hintText,
    required List<String> items,
    required void Function(String?) onChanged,
    required String? value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        isExpanded: true,
      ),
    );
  }
}

// --- Dropdown Data Lists ---
final List<String> _kifilat = [
  'Golimasa',
  'Wetat',
  'Tadagi',
  'Hitsanat',
  'Dekik',
];
final List<String> Yesra_dirisha = ['Abal', 'Sra_Asifetsami (Neus)'];
final List<String> budin = [
  'Abune Tewofilos',
  'Abune Gorgoriyos',
  'Abune Shinoda',
  'Habib Giyorgis',
];
final List<String> yeagelgilotkifil = [
  'Sebisabi',
  'Timihrt Kifil',
  'Mezmur Kifil',
  'Abalat Guday',
];
