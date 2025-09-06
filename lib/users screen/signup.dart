import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

// Import the new calendar picker package
import 'package:calendar_picker_ghe/calendar_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedKifil;
  String? _selectedYesraDirisha;
  String? _selectedBudin;
  String? _selectedAgelgilotKifil;

  // Use the Ethiopian class from the new package
  Ethiopian? _selectedBirthday;
  final _birthdayController = TextEditingController();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // We still need these for formatting the text field
  final List<String> _ethiopianMonths = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ'
  ];

  String _toEthiopic(int number) {
    // This function remains very useful for displaying the date nicely.
    final ethiopicNumerals = ['፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱', '፲'];
    if (number <= 0) return number.toString();
    if (number <= 10) return ethiopicNumerals[number - 1];
    if (number < 20) return '፲${number == 10 ? '' : ethiopicNumerals[number - 11]}';
    // ... [Your existing Ethiopic number conversion logic remains here]
    return number.toString();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // A new, much simpler function to show the Ethiopian date picker
  Future<void> _selectBirthday(BuildContext context) async {
    FocusScope.of(context).unfocus();

    // Use the showUnifiedDatePicker function from the package
    final Ethiopian? result = await showUnifiedDatePicker(
      context: context,
      calendarType: CalendarType.ethiopian,
      // Set initial, first, and last selectable years
      initialYear: _selectedBirthday?.year ?? Ethiopian.now().year,
      firstYear: 1920, // A reasonable earliest birth year
      lastYear: Ethiopian.now().year, // Users can't be born in the future
      // Set the locale to Amharic for the picker's UI
      locale: 'am',
    );

    // If the user picked a date, update the state and the text field
    if (result != null) {
      setState(() {
        _selectedBirthday = result;
        // Format the display text beautifully using our helper functions
        _birthdayController.text =
            "${_ethiopianMonths[result.month - 1]} ${_toEthiopic(result.day)}, ${_toEthiopic(result.year)}";
      });
    }
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("እባክዎ ሁሉንም የተጠየቁ መረጃዎች ይሙሉ"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format the Ethiopian date for storage. This logic remains the same.
      final String? birthdayString = _selectedBirthday != null
          ? "${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}"
          : null;

      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'kifil': _selectedKifil,
          'yesra_dirisha': _selectedYesraDirisha,
          'budin': _selectedBudin,
          'agelgilot_kifil': _selectedAgelgilotKifil,
          'birthday': birthdayString,
        },
      );

      if (mounted && authResponse.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ምዝገባው ተሳክቷል! እባክዎ ኢሜልዎን ያረጋግጡ።'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/start');
      }
    } on AuthException catch (error, stackTrace) {
      developer.log('Supabase Auth Error Occurred',
          name: 'SignUpScreen', error: error, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.message), backgroundColor: Colors.red));
      }
    } catch (error, stackTrace) {
      developer.log('An unexpected error occurred',
          name: 'SignUpScreen', error: error, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("ያልተጠበቀ ስህተት ተከስቷል"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The entire build method remains unchanged as it was already
    // set up to call the _selectBirthday function.
    return Scaffold(
      appBar: AppBar(
        title: const Text('አዲስ መለያ ይፍጠሩ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset("assets/images/am-11.png", height: 120),
              const SizedBox(height: 20),
              const Text('ወደ አምደ ሃይማኖት እንኳን በደህና መጡ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('እባክዎ የሚከተሉትን መረጃዎች ይሙሉ',
                  style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 32),

              TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                      labelText: 'ሙሉ ስም*',
                      prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'እባክዎ ሙሉ ስምዎን ያስገቡ'
                      : null),
              const SizedBox(height: 16),

              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'የትውልድ ቀን',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: () => _selectBirthday(context),
                  ),
                ),
                onTap: () => _selectBirthday(context),
              ),
              const SizedBox(height: 16),

              // ... [Rest of your UI widgets remain unchanged] ...
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'ኢሜይል*',
                      prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'እባክዎ ኢሜይልዎን ያስገቡ';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                      labelText: 'ስልክ ቁጥር',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'የይለፍ ቃል*',
                      prefixIcon: Icon(Icons.lock_outline_rounded)),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'እባክዎ የይለፍ ቃል ያስገቡ';
                    }
                    if (value.length < 6) {
                      return 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                      labelText: 'የይለፍ ቃል ያረጋግጡ*',
                      prefixIcon: Icon(Icons.lock_outline_rounded)),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'የይለፍ ቃሎች አይዛመዱም';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  value: _selectedKifil,
                  items: _kifilat
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedKifil = value),
                  decoration: const InputDecoration(
                      labelText: 'ክፍል*',
                      prefixIcon: Icon(Icons.group_work_outlined)),
                  validator: (value) =>
                      value == null ? 'እባክዎ ክፍልዎን ይምረጡ' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  value: _selectedYesraDirisha,
                  items: _yesraDirisha
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedYesraDirisha = value),
                  decoration: const InputDecoration(
                      labelText: 'የስራ ድርሻ',
                      prefixIcon: Icon(Icons.work_outline_rounded))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  value: _selectedBudin,
                  items: _budin
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedBudin = value),
                  decoration: const InputDecoration(
                      labelText: 'ልዩ የአገልግሎት ቡድን',
                      prefixIcon: Icon(Icons.diversity_3_rounded))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  value: _selectedAgelgilotKifil,
                  items: _yeagelgilotkifil
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedAgelgilotKifil = value),
                  decoration: const InputDecoration(
                      labelText: 'የአገልግሎት ክፍል',
                      prefixIcon: Icon(Icons.volunteer_activism_outlined))),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('መለያ ይፍጠሩ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dropdown constants (remain unchanged)
const List<String> _kifilat = ['ጎልማሳ', 'ወጣት', 'ታዳጊ', 'ሕፃናት', 'ደቂቅ'];
const List<String> _yesraDirisha = ['ንኡስ', 'ስራ አስፈጻሚ ', 'አባል'];
const List<String> _budin = ['አቡነ ቴዎፍሎስ', 'አቡነ ጎርጎርዮስ', 'አቡነ ሺኖዳ', 'ሀብተ ጊዮርጊስ'];
const List<String> _yeagelgilotkifil = [
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
  'ገንዘብ ያዥ'
];