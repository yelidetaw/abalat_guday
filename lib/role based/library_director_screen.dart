import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase instance
import 'package:shimmer/shimmer.dart';
import 'dart:developer' as developer;

class LibraryDirectorScreen extends StatefulWidget {
  const LibraryDirectorScreen({super.key});

  @override
  State<LibraryDirectorScreen> createState() => _LibraryDirectorScreenState();
}

class _LibraryDirectorScreenState extends State<LibraryDirectorScreen> {
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  String? _selectedUserId;

  final _bookTitleController = TextEditingController();
  EthiopianDate? _finishByDate;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _bookTitleController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('profiles')
          .select('id, full_name')
          .order('full_name');
      if (mounted) {
        setState(
            () => _users = List<Map<String, dynamic>>.from(response as List));
      }
    } catch (e, s) {
      _showErrorSnackBar('Could not fetch users: $e');
      developer.log('Failed in _fetchUsers', name: 'LibraryDirectorScreen', error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectFinishDate(BuildContext context) async {
    final EthiopianDate? picked = await showDialog<EthiopianDate>(
      context: context,
      builder: (_) => EthiopianDatePickerDialog(
        initialDate: _finishByDate ?? EthiopianDate.fromGregorian(DateTime.now().add(const Duration(days: 14))),
      ),
    );
    if (picked != null) {
      setState(() => _finishByDate = picked);
    }
  }

  // THIS IS THE FINAL, CORRECTED SAVE LOGIC
  Future<void> _assignBook() async {
    final bookTitle = _bookTitleController.text.trim();
    final selectedId = _selectedUserId;
    final finishDate = _finishByDate;

    if (selectedId == null) {
      _showErrorSnackBar('እባክዎ መጽሐፉን የሚመደብለትን ተጠቃሚ ይምረጡ');
      return;
    }
    if (bookTitle.isEmpty) {
      _showErrorSnackBar('እባክዎ የመጽሐፉን ርዕስ ያስገቡ');
      return;
    }
    if (finishDate == null) {
      _showErrorSnackBar('እባክዎ የማለቂያ ቀን ይምረጡ');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final directorName =
          supabase.auth.currentUser?.userMetadata?['full_name'] as String? ??
              'ላይብረሪ ዳይሬክተር';

      // THE FIX IS HERE: Call the new, safe RPC function
      await supabase.rpc('assign_book_to_student', params: {
        'p_user_id': selectedId,
        'p_book_title': bookTitle,
        'p_assigned_by': directorName,
        'p_finish_by_ethiopian_text': finishDate.toDatabaseString(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('መጽሐፉ ለ "${_selectedUser?['full_name'] ?? 'User'}" ተመድቧል!',
                style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: Colors.green,
          ),
        );
        _bookTitleController.clear();
        setState(() {
          _finishByDate = null;
          _selectedUserId = null;
          _selectedUser = null;
        });
      }
    } catch (e, s) {
      _showErrorSnackBar('Failed to assign book. Check console for details.');
      developer.log('Failed in _assignBook', name: 'LibraryDirectorScreen', error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('መጽሐፍትን መመደብ', style: GoogleFonts.notoSansEthiopic()),
      ),
      body: _isLoading
          ? const _LoadingShimmer()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'የንባብ ተግባር ይመድቡ',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: theme.textTheme.headlineSmall?.fontSize,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedUserId,
                        hint: Text('ተጠቃሚ ይምረጡ...',
                            style: GoogleFonts.notoSansEthiopic()),
                        items: _users
                            .map((user) => DropdownMenuItem(
                                  value: user['id'] as String?,
                                  child: Text(user['full_name'] ?? 'No Name',
                                      style: GoogleFonts.notoSansEthiopic()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUserId = value;
                            _selectedUser = _users.firstWhere((u) => u['id'] == value, orElse: () => {});
                          });
                        },
                        decoration: InputDecoration(
                            labelText: 'ተጠቃሚ',
                            labelStyle: GoogleFonts.notoSansEthiopic()),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _bookTitleController,
                        style: GoogleFonts.notoSansEthiopic(),
                        decoration: InputDecoration(
                            labelText: 'የመጽሐፍ ርዕስ',
                            labelStyle: GoogleFonts.notoSansEthiopic()),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Icon(Icons.calendar_today_rounded,
                            color: theme.colorScheme.secondary),
                        title: Text('የማለቂያ ቀን',
                            style: GoogleFonts.notoSansEthiopic()),
                        subtitle: Text(
                          _finishByDate == null
                              ? 'ቀን ይምረጡ'
                              : _finishByDate.toString(),
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: theme.textTheme.titleMedium?.fontSize,
                            color: _finishByDate == null
                                ? Colors.white.withOpacity(0.7)
                                : theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: () => _selectFinishDate(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white38),
                        ),
                        tileColor: theme.primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox.shrink()
                              : const Icon(Icons.assignment_turned_in_outlined),
                          label: _isSaving
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.onSecondary,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text('መጽሐፉን መድብ',
                                  style: GoogleFonts.notoSansEthiopic()),
                          onPressed: _isSaving ? null : _assignBook,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.primaryColor,
      highlightColor: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 28, width: 250, color: Colors.white, margin: const EdgeInsets.only(bottom: 24)),
                Container(height: 56, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 20)),
                Container(height: 56, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 20)),
                Container(height: 70, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 32)),
                Container(height: 52, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EthiopianDatePickerDialog extends StatefulWidget {
  final EthiopianDate initialDate;
  final String? title;
  const EthiopianDatePickerDialog({super.key, required this.initialDate, this.title});

  @override
  State<EthiopianDatePickerDialog> createState() => _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<EthiopianDatePickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }
  
  void _changeYear(int amount) {
    setState(() {
      _selectedYear += amount;
      final daysInMonth = EthiopianDate(year: _selectedYear, month: _selectedMonth, day: 1).daysInMonth;
      if (_selectedDay > daysInMonth) {
        _selectedDay = daysInMonth;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tempDate = EthiopianDate(year: _selectedYear, month: _selectedMonth, day: 1);
    final daysInMonth = tempDate.daysInMonth;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title ?? 'ቀን ይምረጡ', textAlign: TextAlign.center),
      content: SizedBox(
        width: 300, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeYear(-1)),
                Text('$_selectedYear ዓ.ም.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeYear(1)),
              ],
            ),
            const Divider(),
            DropdownButton<int>(
              value: _selectedMonth,
              isExpanded: true,
              items: List.generate(13, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(EthiopianDate.monthNames[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                    final newDaysInMonth = EthiopianDate(year: _selectedYear, month: _selectedMonth, day: 1).daysInMonth;
                    if (_selectedDay > newDaysInMonth) {
                      _selectedDay = newDaysInMonth;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220, 
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = day == _selectedDay;
                  return InkWell(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ይቅር')),
        ElevatedButton(
          onPressed: () {
            final selectedDate = EthiopianDate(year: _selectedYear, month: _selectedMonth, day: _selectedDay);
            Navigator.of(context).pop(selectedDate);
          },
          child: const Text('ምረጥ'),
        ),
      ],
    );
  }
}