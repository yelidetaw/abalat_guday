import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // Assuming 'supabase' is defined here
import 'package:intl/intl.dart'; // For formatting the date

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
  DateTime? _finishByDate; // NEW: To store the due date

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
          () => _users = List<Map<String, dynamic>>.from(response as List),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // NEW: Method to show the date picker dialog
  Future<void> _selectFinishDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _finishByDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _finishByDate) {
      setState(() {
        _finishByDate = picked;
      });
    }
  }

  Future<void> _assignBook() async {
    // Added validation for the due date
    if (_selectedUser == null ||
        _bookTitleController.text.trim().isEmpty ||
        _finishByDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a user, enter a title, and pick a due date.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final directorName =
        supabase.auth.currentUser?.userMetadata?['full_name'] ??
        'Library Director';

    try {
      // UPDATED: Add 'finish_by' to the insert payload
      await supabase.from('reading_list').insert({
        'user_id': _selectedUserId,
        'book_title': _bookTitleController.text.trim(),
        'status': 'to_read',
        'assigned_by': directorName,
        'finish_by': _finishByDate!
            .toIso8601String(), // Convert date to a string
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book assigned to ${_selectedUser!['full_name']}!'),
            backgroundColor: Colors.green,
          ),
        );
        _bookTitleController.clear();
        setState(() {
          _finishByDate = null; // Reset the date after assignment
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assign Books',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedUserId,
                    hint: const Text('Select a User'),
                    items: _users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user['id'] as String,
                            child: Text(user['full_name'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                        _selectedUser = _users.firstWhere(
                          (u) => u['id'] == value,
                        );
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bookTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Book Title to Assign',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // NEW: UI for the date picker
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF1E88E5),
                      ),
                      title: const Text('Due Date'),
                      subtitle: Text(
                        _finishByDate == null
                            ? 'Select a date'
                            : DateFormat.yMMMd().format(_finishByDate!),
                        style: GoogleFonts.poppins(
                          color: _finishByDate == null
                              ? Colors.grey.shade600
                              : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.edit, color: Colors.grey),
                      onTap: () => _selectFinishDate(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox.shrink()
                          : const Icon(Icons.assignment_turned_in_outlined),
                      label: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Assign Book'),
                      onPressed: (_isSaving || _selectedUser == null)
                          ? null
                          : _assignBook,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
