import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';

// --- Predefined lists for consistency ---
final List<String> _spiritualClassOptions = List.generate(
  12,
  (i) => 'Grade ${i + 1}',
);
const List<String> _courseOptions = [
  'Tmhrtä Krestena',
  'Nebiyat',
  'Hadisat',
  'Zewetir',
  'Abew',
  'Tmhrtä Haymanot',
];
const List<String> _semesterOptions = ['1st Semester', '2nd Semester'];

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  bool _isLoading = false;
  String? _selectedSpiritualClass;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  Future<void> _fetchGradesByClass(String spiritualClass) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _students = [];
    });
    try {
      final dynamic response = await supabase.rpc(
        'get_grades_by_spiritual_class',
        params: {'class_name': spiritualClass},
      );
      if (!mounted) return;
      if (response == null) {
        setState(() => _students = []);
      } else if (response is Map && response.containsKey('error')) {
        setState(() => _error = response['error']);
      } else if (response is List) {
        final processedStudents = _processStudentData(
          List<Map<String, dynamic>>.from(response),
        );
        setState(() => _students = processedStudents);
      } else {
        setState(() => _error = "Received an unexpected data format.");
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = 'Failed to fetch grades: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _processStudentData(
    List<Map<String, dynamic>> students,
  ) {
    if (students.isEmpty) return [];
    for (var student in students) {
      double totalScore = 0;
      final studentGrades =
          (student['grades'] as List<dynamic>?)
              ?.map((g) => Map<String, dynamic>.from(g))
              .toList() ??
          [];
      // IMPORTANT: We only calculate totals/averages based on the student's CURRENT class grade.
      final relevantGrades = studentGrades.where(
        (g) => g['spiritual_class'] == student['spiritual_class'],
      );
      for (var grade in relevantGrades) {
        totalScore +=
            (grade['mid_exam'] ?? 0) +
            (grade['final_exam'] ?? 0) +
            (grade['assignment'] ?? 0);
      }
      student['total_score'] = totalScore;
      student['average_score'] = relevantGrades.isNotEmpty
          ? totalScore / relevantGrades.length
          : 0.0;
    }
    students.sort(
      (a, b) =>
          (b['total_score'] as double).compareTo(a['total_score'] as double),
    );
    for (int i = 0; i < students.length; i++) {
      students[i]['rank'] = i + 1;
    }
    return students;
  }

  void _showEditDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) {
        return _EditGradesDialog(
          student: student,
          onSave: () {
            if (_selectedSpiritualClass != null) {
              _fetchGradesByClass(_selectedSpiritualClass!);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grade Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF673AB7),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedSpiritualClass,
              hint: const Text('Select a Spiritual Grade'),
              items: _spiritualClassOptions
                  .map(
                    (grade) =>
                        DropdownMenuItem(value: grade, child: Text(grade)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSpiritualClass = value);
                  _fetchGradesByClass(value);
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (!_isLoading && _error == null)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Average')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _students.map((student) {
                      final average = student['average_score'] as double;
                      final status = average >= 50 ? 'Pass' : 'Failed';
                      return DataRow(
                        cells: [
                          DataCell(Text(student['rank'].toString())),
                          DataCell(Text(student['full_name'] ?? 'N/A')),
                          DataCell(
                            Text(
                              (student['total_score'] as double)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          DataCell(Text(average.toStringAsFixed(2))),
                          DataCell(
                            Text(
                              status,
                              style: TextStyle(
                                color: status == 'Pass'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(student),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Dialog Widget for Editing Grades ---
class _EditGradesDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final VoidCallback onSave;

  const _EditGradesDialog({required this.student, required this.onSave});

  @override
  State<_EditGradesDialog> createState() => _EditGradesDialogState();
}

class _EditGradesDialogState extends State<_EditGradesDialog> {
  late Map<String, Map<String, TextEditingController>> _controllers;
  late Map<String, String> _selectedSemesters;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _selectedSemesters = {};
    final studentSpiritualClass = widget.student['spiritual_class'];
    final allGrades =
        (widget.student['grades'] as List<dynamic>?)
            ?.map((g) => Map<String, dynamic>.from(g))
            .toList() ??
        [];

    final existingGradesForCurrentClass = allGrades
        .where((g) => g['spiritual_class'] == studentSpiritualClass)
        .toList();

    for (var course in _courseOptions) {
      final matchingGrades = existingGradesForCurrentClass.where(
        (g) => g['course_name'] == course,
      );
      final existingGrade = matchingGrades.isEmpty
          ? null
          : matchingGrades.first;

      _controllers[course] = {
        'mid_exam': TextEditingController(
          text: existingGrade?['mid_exam']?.toString() ?? '0',
        ),
        'final_exam': TextEditingController(
          text: existingGrade?['final_exam']?.toString() ?? '0',
        ),
        'assignment': TextEditingController(
          text: existingGrade?['assignment']?.toString() ?? '0',
        ),
      };
      _selectedSemesters[course] =
          existingGrade?['semester'] ?? _semesterOptions.first;
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, value) {
      value.forEach((_, controller) => controller.dispose());
    });
    super.dispose();
  }

  // --- THIS IS THE FINAL, CORRECTED SAVE FUNCTION ---
  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final studentSpiritualClass = widget.student['spiritual_class'];

    if (studentSpiritualClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot save: Student has no spiritual class assigned.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    // Prepare the new grade data as a JSONB array
    final List<Map<String, dynamic>> gradesData = [];
    _controllers.forEach((course, controllerMap) {
      gradesData.add({
        'course_name': course,
        'semester': _selectedSemesters[course]!,
        'mid_exam': int.tryParse(controllerMap['mid_exam']!.text) ?? 0,
        'final_exam': int.tryParse(controllerMap['final_exam']!.text) ?? 0,
        'assignment': int.tryParse(controllerMap['assignment']!.text) ?? 0,
      });
    });

    try {
      // Call the new RPC function to perform the atomic delete-and-insert
      await supabase.rpc(
        'save_student_grades_for_class',
        params: {
          'p_user_id': widget.student['id'],
          'p_spiritual_class': studentSpiritualClass,
          'p_grades_data': gradesData,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grades saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Grades for ${widget.student['full_name']}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: _courseOptions.map((course) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSemesters[course],
                      items: _semesterOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSemesters[course] = val!),
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[course]!['mid_exam'],
                            decoration: const InputDecoration(labelText: 'Mid'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[course]!['final_exam'],
                            decoration: const InputDecoration(
                              labelText: 'Final',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[course]!['assignment'],
                            decoration: const InputDecoration(
                              labelText: 'Assign.',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
