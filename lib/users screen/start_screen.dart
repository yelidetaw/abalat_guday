import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amde_haymanot_abalat_guday/users%20screen/social_media_url.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double breakpoint = 600.0;
            return constraints.maxWidth < breakpoint
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            _buildContent(context),
            const Spacer(flex: 3),
            const SocialMediaUrl(),
            const SizedBox(height: 42),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/images/login_person.png',
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 200),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildContent(context),
                    const SizedBox(height: 30),
                    const SocialMediaUrl(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.of(context).size.width < 600)
          Image.asset(
            'assets/images/login_person.png',
            height: 250,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 150),
          ),
        const SizedBox(height: 24),
        const Text(
          'ሰላም',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 90, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'በሰመ አብ ወወልድ ወመንፈስቅዱስ አሐዱ አምላክ አሜን በኢትዮጵያ ኦርቶዶክስ ተዋህዶ ቤተክርስቲያን በጅማ ሀገረ ስብከት የጅማ ደ/ኤ/ቅ/ድ ማርያም ካቴድራል ዓምደ ሃይማኖት ሰ/ት/ቤት',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            debugPrint('Login button pressed');
            context.push('/login');
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('ይግቡ'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            debugPrint('Sign up button pressed');
            context.push('/signup');
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('ይመዝገቡ'),
        ),
      ],
    );
  }
}
