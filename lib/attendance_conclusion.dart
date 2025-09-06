import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:amde_haymanot_abalat_guday/student_detail_screen.dart';
import 'package:amde_haymanot_abalat_guday/student.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  _AttendanceSummaryScreenState createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<String> _groups = ['All'];
  String? _selectedGroup = 'All';
  DateTime _selectedDate = DateTime.now();
  List<Student> _filteredStudents = [];
  Map<String, List<Map<String, dynamic>>> _attendanceData = {};
  List<Student> _allStudents = [];
  int _totalStudents = 0;
  int _absentCount = 0;
  int _permissionCount = 0;
  int _lateCount = 0;
  int _presentCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndAttendance();
  }

  Future<void> _fetchStudentsAndAttendance() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Students
      final studentsResponse = await supabase.from('profiles').select('*');
      _allStudents = (studentsResponse as List)
          .map(
            (profile) => Student(
              id: profile['id'] as String,
              name: profile['full_name'] as String,
              group: profile['kifil'] as String?,
            ),
          )
          .toList();

      _initializeGroups();

      // Fetch Attendance Data
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceResponse = await supabase
          .from('attendance')
          .select('*')
          .eq('date', formattedDate);

      final attendanceMap = <String, List<Map<String, dynamic>>>{};
      for (var record in attendanceResponse) {
        final studentId = record['student_id'] as String;
        attendanceMap.putIfAbsent(studentId, () => []).add(record);
      }
      setState(() => _attendanceData = attendanceMap);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _filterStudents();
      setState(() => _isLoading = false);
    }
  }

  void _initializeGroups() {
    final uniqueGroups = _allStudents
        .map((s) => s.group)
        .whereType<String>()
        .toSet();
    setState(() => _groups = ['All', ...uniqueGroups]);
  }

  void _filterStudents() {
    _filteredStudents = _selectedGroup == 'All'
        ? _allStudents
        : _allStudents.where((s) => s.group == _selectedGroup).toList();
    _calculateSummaryStats();
  }

  void _calculateSummaryStats() {
    _totalStudents = _filteredStudents.length;
    _absentCount = _permissionCount = _lateCount = _presentCount = 0;

    for (final student in _filteredStudents) {
      final attendance = _attendanceData[student.id] ?? [];
      _absentCount += attendance.where((r) => r['status'] == 'absent').length;
      _permissionCount += attendance
          .where((r) => r['status'] == 'permission')
          .length;
      _lateCount += attendance.where((r) => r['status'] == 'late').length;
      _presentCount += attendance.where((r) => r['status'] == 'present').length;
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _fetchStudentsAndAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      DateFormat(
                                        'MMM d, yyyy',
                                      ).format(_selectedDate),
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedGroup,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 18),
                              hint: const Text(
                                'Kifil',
                                style: TextStyle(fontSize: 14),
                              ),
                              onChanged: (newValue) => setState(() {
                                _selectedGroup = newValue;
                                _filterStudents();
                              }),
                              items: _groups
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(
                                        g,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards - Single Row
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildSummaryCard(
                          'Total',
                          _totalStudents,
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildSummaryCard(
                          'Present',
                          _presentCount,
                          Icons.check,
                          Colors.green,
                        ),
                        _buildSummaryCard(
                          'Absent',
                          _absentCount,
                          Icons.close,
                          Colors.red,
                        ),
                        _buildSummaryCard(
                          'Late',
                          _lateCount,
                          Icons.schedule,
                          Colors.orange,
                        ),
                        _buildSummaryCard(
                          'Permit',
                          _permissionCount,
                          Icons.note,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  // Students List
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Student',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.note,
                                    size: 16,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: _filteredStudents.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('No students found'),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filteredStudents.length,
                                  itemBuilder: (context, index) =>
                                      _buildStudentRow(
                                        _filteredStudents[index],
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student) {
    final attendance = _attendanceData[student.id] ?? [];
    final counts = {
      'present': attendance.where((r) => r['status'] == 'present').length,
      'absent': attendance.where((r) => r['status'] == 'absent').length,
      'late': attendance.where((r) => r['status'] == 'late').length,
      'permission': attendance.where((r) => r['status'] == 'permission').length,
    };

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDetailsScreen(
            student: student,
            attendanceRecords: attendance,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                student.name,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  counts['present'].toString(),
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  counts['absent'].toString(),
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  counts['late'].toString(),
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  counts['permission'].toString(),
                  style: TextStyle(
                    color: Colors.purple,
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
