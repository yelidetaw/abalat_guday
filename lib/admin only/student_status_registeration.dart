// lib/screens/batch_management_screen.dart (FINAL - One Click Promotion)

import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';

const List<String> spiritualClassOptions = [
  '1ኛ ክፍል', '2ኛ ክፍል', '3ኛ ክፍል', '4ኛ ክፍል', '5ኛ ክፍል', '6ኛ ክፍል',
  '7ኛ ክፍል', '8ኛ ክፍል', '9ኛ ክፍል', '10ኛ ክፍል', '11ኛ ክፍል', '12ኛ ክፍል',
];

class BatchManagementScreen extends StatefulWidget {
  final VoidCallback onBatchRegistered;
  const BatchManagementScreen({super.key, required this.onBatchRegistered});
  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  static get currentEthiopianYear => EthiopianDate.now().year;
  final List<int> _yearOptions = List.generate(
      12, (index) => currentEthiopianYear + 5 - index)
    ..sort((a, b) => b.compareTo(a));

  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = true;
  String? _newStudentClass;
  int? _newStudentYear;
  final Set<String> _selectedStudentIds = {};

  final _promotionFormKey = GlobalKey<FormState>();
  String? _promotionFromClass;
  int? _promotionFromYear;
  final _passingScoreController = TextEditingController(text: '50.0');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserListForRegistration();
    _newStudentYear = currentEthiopianYear;
    _promotionFromYear = currentEthiopianYear;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserListForRegistration() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await supabase.from('profiles_with_email').select('id, full_name, email').order('full_name');
      if (mounted) {
        setState(() { _allUsers = List<Map<String, dynamic>>.from(response); });
      }
    } catch (e) {
      if (mounted) { _showResultDialog(isError: true, title: 'ስህተት', content: e.toString()); }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _registerNewStudents() async {
    if (_newStudentClass == null || _newStudentYear == null || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('እባክዎ ክፍል፣ ዓ.ም. እና ቢያንስ አንድ ተማሪ ይምረጡ።')));
      return;
    }
    final confirmed = await _showConfirmationDialog(
        title: 'ምዝገባን ያረጋግጡ',
        content: '${_selectedStudentIds.length} ተማሪዎችን በ $_newStudentClass ለ $_newStudentYear ዓ.ም. መመዝገብዎን እርግጠኛ ነዎት?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await supabase.rpc('add_students_to_batch', params: {
        'p_student_ids': _selectedStudentIds.toList(),
        'p_class_name': _newStudentClass,
        'p_academic_year': _newStudentYear
      });
      widget.onBatchRegistered();
      _showResultDialog(
          isError: false,
          title: 'ምዝገባው ተሳክቷል',
          content: '${_selectedStudentIds.length} ተማሪዎች በተሳካ ሁኔታ ተመዝግበዋል።');
      setState(() { _selectedStudentIds.clear(); });
    } catch (e) {
      _showResultDialog(isError: true, title: 'የምዝገባ ስህተት', content: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promoteStudents() async {
    if (!_promotionFormKey.currentState!.validate()) return;
    final passingScore = double.tryParse(_passingScoreController.text);
    final confirmed = await _showConfirmationDialog(
        title: 'ማስተላለፍን ያረጋግጡ',
        content: 'ከ $_promotionFromClass - $_promotionFromYear ዓ.ም. ያሉትን ተማሪዎች በ $passingScore% እና ከዚያ በላይ ውጤት ማስተላለፍ ይፈልጋሉ?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final promotedCount = await supabase.rpc('promote_passed_students_with_score', params: {
        'p_from_class': _promotionFromClass!,
        'p_from_year': _promotionFromYear!,
        'p_passing_score': passingScore,
      });
      widget.onBatchRegistered();
      _showResultDialog(
          isError: false,
          title: 'ማስተላለፉ ተሳክቷል',
          content: '$promotedCount ተማሪዎች ወደ ቀጣዩ ክፍል ተላልፈው ለአዲሱ የትምህርት ዘመን ተመዝግበዋል።\n\nበውጤት አስተዳደር ገጽ ውስጥ ሊያገኟቸው ይችላሉ።'
          // X students have been promoted and enrolled in the new academic year. You can now find them in the Grade Management screen.
      );
    } catch (e) {
      _showResultDialog(isError: true, title: 'የማስተላለፍ ስህተት', content: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmationDialog({required String title, required String content}) {
     return showDialog<bool>( context: context, builder: (context) => AlertDialog( title: Text(title, style: GoogleFonts.notoSansEthiopic()), content: Text(content, style: GoogleFonts.notoSansEthiopic()), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic())), ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text('አረጋግጥ', style: GoogleFonts.notoSansEthiopic())), ], ), );
  }
  void _showResultDialog({required bool isError, required String title, required String content}) {
    showDialog( context: context, builder: (context) => AlertDialog( title: Text(title, style: GoogleFonts.notoSansEthiopic(color: isError ? Colors.red : Colors.green)), content: SelectableText(content, style: GoogleFonts.notoSansEthiopic()), actions: [ TextButton( child: Text('እሺ', style: GoogleFonts.notoSansEthiopic()), onPressed: () => Navigator.of(context).pop(), ), ], ), );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('የቡድን ምዝገባ', style: GoogleFonts.notoSansEthiopic()),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.notoSansEthiopic(),
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'አዲስ ተማሪ'),
            Tab(icon: Icon(Icons.school), text: 'ክፍል ያስተላልፉ'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildNewStudentRegistrationForm(),
              _buildPromotionForm(),
            ],
          ),
          if (_isLoading)
            Container( color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator()), ),
        ],
      ),
    );
  }

  Widget _buildNewStudentRegistrationForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _newStudentClass,
                  hint: Text('ክፍል ይምረጡ', style: GoogleFonts.notoSansEthiopic()),
                  items: spiritualClassOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.notoSansEthiopic()))).toList(),
                  onChanged: (val) => setState(() => _newStudentClass = val),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _newStudentYear,
                  hint: Text('ዓ.ም. ይምረጡ', style: GoogleFonts.notoSansEthiopic()),
                  items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text('$y ዓ.ም.', style: GoogleFonts.notoSansEthiopic()))).toList(),
                  onChanged: (val) => setState(() => _newStudentYear = val),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('የሚመዘገቡ ተማሪዎችን ይምረጡ', style: GoogleFonts.notoSansEthiopic(textStyle: Theme.of(context).textTheme.titleMedium)),
        ),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _allUsers.isEmpty
                  ? Center(child: Text("ምንም ተጠቃሚዎች አልተገኙም።", style: GoogleFonts.notoSansEthiopic()))
                  : ListView.builder(
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final userId = user['id'];
                        return CheckboxListTile(
                          title: Text(user['full_name'] ?? 'ስም የለም'),
                          subtitle: Text(user['email'] ?? 'ኢሜል የለም'),
                          value: _selectedStudentIds.contains(userId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) { _selectedStudentIds.add(userId); }
                              else { _selectedStudentIds.remove(userId); }
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
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _registerNewStudents,
              icon: const Icon(Icons.app_registration),
              label: Text('${_selectedStudentIds.length} ተማሪዎችን መዝግብ', style: GoogleFonts.notoSansEthiopic()),
              style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionForm() {
    final promotableClasses = spiritualClassOptions.take(spiritualClassOptions.length - 1).toList();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _promotionFormKey,
        child: ListView(
          children: [
            Text('የሚተላለፉበትን ክፍል ይምረጡ', style: GoogleFonts.notoSansEthiopic(textStyle: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _promotionFromClass,
              hint: Text('ክፍል ይምረጡ', style: GoogleFonts.notoSansEthiopic()),
              items: promotableClasses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.notoSansEthiopic()))).toList(),
              onChanged: (val) => setState(() => _promotionFromClass = val),
              decoration: InputDecoration(labelText: 'ከ ክፍል', labelStyle: GoogleFonts.notoSansEthiopic(), border: OutlineInputBorder()),
              validator: (v) => v == null ? 'እባክዎ ክፍል ይምረጡ' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _promotionFromYear,
              hint: Text('ዓ.ም. ይምረጡ', style: GoogleFonts.notoSansEthiopic()),
              items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text('$y ዓ.ም.', style: GoogleFonts.notoSansEthiopic()))).toList(),
              onChanged: (val) => setState(() => _promotionFromYear = val),
              decoration: InputDecoration(labelText: 'ከ ዓ.ም.', labelStyle: GoogleFonts.notoSansEthiopic(), border: OutlineInputBorder()),
              validator: (v) => v == null ? 'እባክዎ ዓ.ም. ይምረጡ' : null,
            ),
            const SizedBox(height: 24),
            Text('የማለፊያ መስፈርት', style: GoogleFonts.notoSansEthiopic(textStyle: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passingScoreController,
              decoration: InputDecoration(labelText: 'የማለፊያ ውጤት (%)', labelStyle: GoogleFonts.notoSansEthiopic(), border: OutlineInputBorder(), suffixText: '%',),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'እባክዎ ውጤት ያስገቡ';
                final score = double.tryParse(value);
                if (score == null || score < 0 || score > 100) return 'ከ 0-100 መካከል ቁጥር ያስገቡ';
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _promoteStudents,
              icon: const Icon(Icons.school),
              label: Text('ተማሪዎችን አስተላልፍ', style: GoogleFonts.notoSansEthiopic()),
              style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16), ),
            ),
          ],
        ),
      ),
    );
  }
}