import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'dart:developer' as developer;

// Import the EthiopianDate utility
import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';

// --- DATA IN AMHARIC ---
const List<String> spiritualClassOptions = [
  '1ኛ ክፍል', '2ኛ ክፍል', '3ኛ ክፍል', '4ኛ ክፍል', '5ኛ ክፍል', '6ኛ ክፍል',
  '7ኛ ክፍል', '8ኛ ክፍል', '9ኛ ክፍል', '10ኛ ክፍል', '11ኛ ክፍል', '12ኛ ክፍል',
];
const List<String> semesterOptions = ['የመጀመሪያ ሴሚስተር', 'ሁለተኛ ሴሚስተር'];
const Map<String, List<String>> spiritualGradeCurriculum = {
  '1ኛ ክፍል': ['መሠረተ ሃይማኖት 1', 'ልሳነ ግዕዝ 1','የመጽሐፍ ቅዱስ ጥናት 1', 'ክርስትያናዊ ሥነ ምግባር 1','ሥርዓተ ቤተክርስቲያን 1', 'የቤተክርስቲያን ታሪክ 1', ],
  '2ኛ ክፍል': ['መሠረተ ሃይማኖት 2', 'ልሳነ ግዕዝ 2','የመጽሐፍ ቅዱስ ጥናት 2', 'ክርስትያናዊ ሥነ ምግባር 2','ሥርዓተ ቤተክርስቲያን 2', 'የቤተክርስቲያን ታሪክ 2', ],
  '3ኛ ክፍል':['መሠረተ ሃይማኖት 3', 'ልሳነ ግዕዝ 3','የመጽሐፍ ቅዱስ ጥናት 3', 'ክርስትያናዊ ሥነ ምግባር 3','ሥርዓተ ቤተክርስቲያን 3', 'የቤተክርስቲያን ታሪክ 3', ],
  '4ኛ ክፍል': ['መሠረተ ሃይማኖት 4', 'ልሳነ ግዕዝ 4','የመጽሐፍ ቅዱስ ጥናት 4', 'ክርስትያናዊ ሥነ ምግባር 4','ሥርዓተ ቤተክርስቲያን 4', 'የቤተክርስቲያን ታሪክ 4', ],
  '5ኛ ክፍል':['መሠረተ ሃይማኖት 5', 'ልሳነ ግዕዝ 5','የመጽሐፍ ቅዱስ ጥናት 5', 'ክርስትያናዊ ሥነ ምግባር 5','ሥርዓተ ቤተክርስቲያን 5', 'የቤተክርስቲያን ታሪክ 5', ],
  '6ኛ ክፍል':['መሠረተ ሃይማኖት 6', 'ልሳነ ግዕዝ 6','የመጽሐፍ ቅዱስ ጥናት 6', 'ክርስትያናዊ ሥነ ምግባር 6','ሥርዓተ ቤተክርስቲያን 6', 'የቤተክርስቲያን ታሪክ 6', ],
  '7ኛ ክፍል': ['መሠረተ ሃይማኖት 7', 'ልሳነ ግዕዝ 7','የመጽሐፍ ቅዱስ ጥናት 7', 'ክርስትያናዊ ሥነ ምግባር 7','ሥርዓተ ቤተክርስቲያን 7', 'የቤተክርስቲያን ታሪክ 7', ],
  '8ኛ ክፍል': ['መሠረተ ሃይማኖት 8', 'ልሳነ ግዕዝ 8','የመጽሐፍ ቅዱስ ጥናት 8', 'ክርስትያናዊ ሥነ ምግባር 8','ሥርዓተ ቤተክርስቲያን 8', 'የቤተክርስቲያን ታሪክ 8', ],
  '9ኛ ክፍል':['መሠረተ ሃይማኖት 9', 'ልሳነ ግዕዝ 9','የመጽሐፍ ቅዱስ ጥናት 9', 'ክርስትያናዊ ሥነ ምግባር 9','ሥርዓተ ቤተክርስቲያን 9', 'የቤተክርስቲያን ታሪክ 9', ],
  '10ኛ ክፍል': ['መሠረተ ሃይማኖት 10', 'ልሳነ ግዕዝ 10','የመጽሐፍ ቅዱስ ጥናት 10', 'ክርስትያናዊ ሥነ ምግባር 10','ሥርዓተ ቤተክርስቲያን 10', 'የቤተክርስቲያን ታሪክ 10', ],
  '11ኛ ክፍል':['መሠረተ ሃይማኖት 11', 'ልሳነ ግዕዝ 11','የመጽሐፍ ቅዱስ ጥናት 11', 'ክርስትያናዊ ሥነ ምግባር 11','ሥርዓተ ቤተክርስቲያን 11', 'የቤተክርስቲያን ታሪክ 11', ],
  '12ኛ ክፍል':['መሠረተ ሃይማኖት 12', 'ልሳነ ግዕዝ 12','የመጽሐፍ ቅዱስ ጥናት 12', 'ክርስትያናዊ ሥነ ምግባር 12','ሥርዓተ ቤተክርስቲያን 12', 'የቤተክርስቲያን ታሪክ 12', ],
};

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});
  @override State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  bool _isLoading = false;
  String? _selectedSpiritualClass;
  int? _selectedYear;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  static const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
  static const Color accentColor = Color(0xFFFFD700);

  // --- THIS IS THE FIX ---
  // 1. Get the current Ethiopian year.
  static get currentEthiopianYear => EthiopianDate.now().year;

  // 2. Generate the year options based on the correct Ethiopian year.
  final List<int> _yearOptions = List.generate(
      12, (index) => currentEthiopianYear + 5 - index)
    ..sort((a, b) => b.compareTo(a));
  // --- END OF FIX ---
  
  @override
  void initState() {
    super.initState();
    // Set the initial selected year to the correct current Ethiopian year
    _selectedYear = currentEthiopianYear;
  }

  void _logError(String functionName, Object e, StackTrace s) {
    final errorMessage = 'Failed in $functionName: ${e.toString()}';
    developer.log(errorMessage, name: 'GradeManagementScreen', error: e, stackTrace: s, );
    if (mounted) { setState(() => _error = "ስህተት ተፈጥሯል: $e"); }
  }

  Future<void> _fetchGrades() async {
    if (_selectedSpiritualClass == null || _selectedYear == null) { setState(() => _students = []); return; }
    setState(() { _isLoading = true; _error = null; _students = []; });
    try {
      final response = await supabase.rpc(
        'get_student_grades_by_class',
        params: { 'p_class_name': _selectedSpiritualClass!, 'p_academic_year': _selectedYear!, },
      ).select('student_id, full_name, spiritual_class, grades');
      if (!mounted) return;
      final processedStudents = _processStudentData( List<Map<String, dynamic>>.from(response), );
      setState(() => _students = processedStudents);
    } catch (e, stackTrace) {
      _logError('_fetchGrades', e, stackTrace);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _processStudentData(List<Map<String, dynamic>> students) {
    final List<Map<String, dynamic>> processedStudents = [];
    for (var student in students) {
      final studentGrades = (student['grades'] as List<dynamic>?)?.map((g) => Map<String, dynamic>.from(g)).toList() ?? [];
      double totalScore = 0;
      for (var grade in studentGrades) {
        totalScore += (grade['mid_exam'] ?? 0).toDouble() + (grade['final_exam'] ?? 0).toDouble() + (grade['assignment'] ?? 0).toDouble();
      }
      final totalPossiblePoints = studentGrades.isNotEmpty ? studentGrades.length * 100 : 1;
      final averageScore = (totalScore / totalPossiblePoints) * 100;
      processedStudents.add({ ...student, 'grades': studentGrades, 'total_score': totalScore, 'average_score': averageScore.isNaN ? 0.0 : averageScore, });
    }
    processedStudents.sort((a, b) => (b['total_score'] as double).compareTo(a['total_score'] as double));
    for (int i = 0; i < processedStudents.length; i++) {
      processedStudents[i]['rank'] = i + 1;
    }
    return processedStudents;
  }

  void _showEditDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditGradesDialog(
        student: student,
        academicYear: _selectedYear!,
        primaryColor: primaryColor,
        accentColor: accentColor,
        onSave: (updatedScores) {
          setState(() {
            final index = _students.indexWhere((s) => s['student_id'] == student['student_id']);
            if (index != -1) {
              _students[index]['total_score'] = updatedScores['total_score'];
              _students[index]['average_score'] = updatedScores['average_score'];
              _students.sort((a, b) => (b['total_score'] as double).compareTo(a['total_score'] as double));
              for (int i = 0; i < _students.length; i++) { _students[i]['rank'] = i + 1; }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('የውጤት አስተዳደር', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold, color: accentColor)),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton( icon: const Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.of(context).pop()) : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    hint: Text('ዓ.ም.', style: GoogleFonts.notoSansEthiopic(color: accentColor.withOpacity(0.7))),
                    dropdownColor: primaryColor,
                    style: GoogleFonts.notoSansEthiopic(color: accentColor),
                    items: _yearOptions.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
                    onChanged: (value) { setState(() => _selectedYear = value); _fetchGrades(); },
                    decoration: InputDecoration(
                      labelText: 'ዓ.ም.',
                      labelStyle: GoogleFonts.notoSansEthiopic(color: accentColor.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accentColor.withOpacity(0.7))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSpiritualClass,
                    hint: Text('ክፍል', style: GoogleFonts.notoSansEthiopic(color: accentColor.withOpacity(0.7))),
                    dropdownColor: primaryColor,
                    style: GoogleFonts.notoSansEthiopic(color: accentColor),
                    items: spiritualClassOptions.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
                    onChanged: (value) { setState(() => _selectedSpiritualClass = value); _fetchGrades(); },
                    decoration: InputDecoration(
                      labelText: 'መንፈሳዊ ክፍል',
                      labelStyle: GoogleFonts.notoSansEthiopic(color: accentColor.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accentColor.withOpacity(0.7))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: accentColor))),
          if (_error != null) Expanded( child: Center( child: Padding( padding: const EdgeInsets.all(16.0), child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.notoSansEthiopic(color: Colors.red, fontSize: 16)), ), ), ),
          if (!_isLoading && _error == null && _students.isEmpty && _selectedSpiritualClass != null && _selectedYear != null) Expanded( child: Center( child: Text( 'ለተመረጠው ክፍል እና ዓ.ም. ምንም ተማሪዎች አልተገኙም', textAlign: TextAlign.center, style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: accentColor), ), ), ),
          if (!_isLoading && _error == null && _students.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Card(
                  color: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [ DataColumn(label: Text('ደረጃ')), DataColumn(label: Text('ስም')), DataColumn(label: Text('ጠቅላላ')), DataColumn(label: Text('አማካይ %')), DataColumn(label: Text('ሁኔታ')), DataColumn(label: Text('ድርጊቶች')), ].map((c) => DataColumn(label: DefaultTextStyle(style: GoogleFonts.notoSansEthiopic(color: accentColor, fontWeight: FontWeight.bold), child: c.label))).toList(),
                      rows: _students.map((student) {
                        final average = student['average_score'] as double;
                        final status = average >= 50 ? 'አልፏል' : 'ወድቋል';
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(Text(student['rank'].toString())),
                            DataCell(Text(student['full_name'] ?? 'N/A')),
                            DataCell(Text((student['total_score'] as double).toStringAsFixed(1))),
                            DataCell(Text(average.toStringAsFixed(1))),
                            DataCell( Chip( label: Text(status, style: GoogleFonts.notoSansEthiopic()), backgroundColor: status == 'አልፏል' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), labelStyle: TextStyle(color: status == 'አልፏል' ? Colors.green.shade200 : Colors.red.shade200, fontWeight: FontWeight.bold), ), ),
                            DataCell( IconButton( icon: const Icon(Icons.edit_note, color: accentColor), onPressed: () => _showEditDialog(student), ), ),
                          ].map((c) => DataCell(DefaultTextStyle(style: GoogleFonts.notoSansEthiopic(color: accentColor.withOpacity(0.9)), child: c.child))).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// The _EditGradesDialog widget remains unchanged.
class _EditGradesDialog extends StatefulWidget {
  final Map<String, dynamic> student; final int academicYear; final Function(Map<String, dynamic> updatedScores) onSave; final Color primaryColor; final Color accentColor;
  const _EditGradesDialog({ required this.student, required this.academicYear, required this.onSave, required this.primaryColor, required this.accentColor, super.key, });
  @override State<_EditGradesDialog> createState() => _EditGradesDialogState();
}
class _EditGradesDialogState extends State<_EditGradesDialog> {
  late Map<String, Map<String, TextEditingController>> _controllers; late Map<String, String> _selectedSemesters; late List<String> _courses; bool _isSaving = false;
  @override void initState() { super.initState(); _initializeData(); }
  void _logError(String functionName, Object e, StackTrace s) { final errorMessage = 'Failed in $functionName: ${e.toString()}'; developer.log(errorMessage, name: 'EditGradesDialog', error: e, stackTrace: s); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar( content: Text("ውጤቶችን በማስቀመጥ ላይ ስህተት ተፈጥሯል", style: GoogleFonts.notoSansEthiopic()), backgroundColor: Colors.red)); } }
  void _initializeData() { _controllers = {}; _selectedSemesters = {}; final studentClass = widget.student['spiritual_class'] as String?; _courses = spiritualGradeCurriculum[studentClass] ?? []; final grades = (widget.student['grades'] as List<dynamic>?) ?.map((g) => Map<String, dynamic>.from(g)).toList() ?? []; for (var course in _courses) { final courseGrade = grades.firstWhere((g) => g['course_name'] == course, orElse: () => {}); _controllers[course] = { 'mid_exam': TextEditingController(text: (courseGrade['mid_exam'] ?? 0).toString()), 'final_exam': TextEditingController(text: (courseGrade['final_exam'] ?? 0).toString()), 'assignment': TextEditingController(text: (courseGrade['assignment'] ?? 0).toString()), }; _selectedSemesters[course] = courseGrade['semester'] ?? semesterOptions.first; } }
  @override void dispose() { _controllers.values.forEach((controllers) => controllers.values.forEach((controller) => controller.dispose())); super.dispose(); }
  Future<void> _saveGrades() async {
    setState(() => _isSaving = true);
    try {
      final gradesToSave = _courses.map((course) {
        return { 'course_name': course, 'semester': _selectedSemesters[course]!, 'mid_exam': int.tryParse(_controllers[course]!['mid_exam']!.text) ?? 0, 'final_exam': int.tryParse(_controllers[course]!['final_exam']!.text) ?? 0, 'assignment': int.tryParse(_controllers[course]!['assignment']!.text) ?? 0, 'spiritual_class': widget.student['spiritual_class'], 'academic_year': widget.academicYear, };
      }).toList();
      final result = await supabase.rpc(
        'update_student_grades_and_get_scores',
        params: { 'p_student_id': widget.student['student_id'], 'p_grades_data': gradesToSave },
      ).single();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('ውጤቶች በተሳካ ሁኔታ ተዘምነዋል!', style: GoogleFonts.notoSansEthiopic(color: widget.primaryColor)), backgroundColor: widget.accentColor, ), );
        widget.onSave({ 'total_score': (result['new_total_score'] as num).toDouble(), 'average_score': (result['new_average_score'] as num).toDouble(), });
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      _logError('_saveGrades', e, stackTrace);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  @override Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: widget.accentColor.withOpacity(0.5))),
      title: Text('የ ${widget.student['full_name']} ውጤቶችን ያርትዑ', style: GoogleFonts.notoSansEthiopic(color: widget.accentColor, fontSize: 20), ),
      content: SizedBox(
        width: double.maxFinite,
        child: _courses.isEmpty ? Center(child: Text('ለዚህ ክፍል ምንም ኮርሶች የሉም', style: GoogleFonts.notoSansEthiopic(color: widget.accentColor)))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return Card(
                    color: const Color(0xFF2A0F2E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course, style: GoogleFonts.notoSansEthiopic(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSemesters[course],
                            items: semesterOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.notoSansEthiopic()))).toList(),
                            onChanged: (v) { if (v != null) setState(() => _selectedSemesters[course] = v); },
                            style: GoogleFonts.notoSansEthiopic(color: widget.accentColor),
                            dropdownColor: widget.primaryColor,
                            decoration: _buildInputDecoration('ሴሚስተር'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildGradeField('ሚድ', _controllers[course]!['mid_exam']!),
                              const SizedBox(width: 8),
                              _buildGradeField('ፍጻሜ', _controllers[course]!['final_exam']!),
                              const SizedBox(width: 8),
                              _buildGradeField('አሳይመንት', _controllers[course]!['assignment']!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic(color: widget.accentColor)), ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveGrades,
          style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: widget.primaryColor),
          child: _isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.primaryColor)) : Text('አስቀምጥ', style: GoogleFonts.notoSansEthiopic()),
        ),
      ],
    );
  }
  Widget _buildGradeField(String label, TextEditingController controller) {
    return Expanded( child: TextFormField( controller: controller, style: GoogleFonts.notoSansEthiopic(color: widget.accentColor), decoration: _buildInputDecoration(label), keyboardType: TextInputType.number, ), );
  }
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSansEthiopic(color: widget.accentColor.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accentColor.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accentColor)),
    );
  }
}