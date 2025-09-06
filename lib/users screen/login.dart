// No direct main.dart import needed; theme is inherited via context.
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/social_media_url.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // The sign-in logic remains exactly the same.
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        context.go('/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(error.message), // Supabase errors are often in English
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ያልተጠበቀ ስህተት ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።',
                style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'እንኳን ደህና መጡ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize:
                        Theme.of(context).textTheme.headlineLarge?.fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ለመቀጠል ወደ መለያዎ ይግቡ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'ኢሜይል',
                    labelStyle: GoogleFonts.notoSansEthiopic(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'እባክዎ ኢሜይልዎን ያስገቡ';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'የይለፍ ቃል',
                    labelStyle: GoogleFonts.notoSansEthiopic(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'እባክዎ የይለፍ ቃልዎን ያስገቡ';
                    }
                    if (value.length < 6) {
                      return 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password Functionality
                    },
                    child: Text('የይለፍ ቃል ረስተዋል?',
                        style: GoogleFonts.notoSansEthiopic()),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 171, 230, 8),
                          ),
                        )
                      : Text('ግባ', style: GoogleFonts.notoSansEthiopic()),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("መለያ የለዎትም?", style: GoogleFonts.notoSansEthiopic()),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text('አዲስ ይፍጠሩ',
                          style: GoogleFonts.notoSansEthiopic(color: Color(0xFFFFD700)),),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SocialMediaUrl(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
