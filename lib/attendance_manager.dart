import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // To get the global 'supabase' client

// ===============================================================
// 1. MODELS
// ===============================================================

class Student {
  final String id;
  final String name;
  Student({required this.id, required this.name});
}

enum AttendanceStatus { present, absent, late, permission }

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// ===============================================================
// 2. THE MAIN ATTENDANCE SCREEN WIDGET
// ===============================================================

class attendance extends StatelessWidget {
  attendance({super.key});

  final List<Student> _studentsForClass = [
    Student(id: 'st_001', name: 'Biniam Mekonnin'),
    Student(id: 'st_002', name: 'Eyob Zewdu'),
    Student(id: 'st_003', name: 'Abel Mebiratu'),
    Student(id: 'st_004', name: 'Etsub Dink'),
    Student(id: 'st_005', name: 'Rakeb Getachew'),
    Student(id: 'st_006', name: 'Dawit Temesgen'),
  ];

  Future<void> _handleSave(
    BuildContext context,
    DateTime date,
    Map<String, AttendanceStatus> attendanceData,
    Map<String, TimeOfDay?> lateTimes,
  ) async {
    final List<Map<String, dynamic>> recordsToSave = [];
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      // First delete any existing records for this date
      await supabase.from('attendance').delete().eq('date', formattedDate);

      // Prepare new records to save
      for (var entry in attendanceData.entries) {
        final studentId = entry.key;
        final status = entry.value;
        final lateTime = lateTimes[studentId];
        final student = _studentsForClass.firstWhere((s) => s.id == studentId);

        recordsToSave.add({
          'student_id': student.id,
          'student_name': student.name,
          'date': formattedDate,
          'status': status.name,
          'late_time': lateTime != null
              ? '${lateTime.hour.toString().padLeft(2, '0')}:${lateTime.minute.toString().padLeft(2, '0')}:00'
              : null,
        });
      }

      // Insert all new records
      await supabase.from('attendance').insert(recordsToSave);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved/updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print("--- SUPABASE SAVE ERROR ---");
      print(error);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving attendance. Check debug console for details.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Class Attendance')),
      body: AttendanceManager(
        students: _studentsForClass,
        onSave: (date, attendanceData, lateTimes) =>
            _handleSave(context, date, attendanceData, lateTimes),
      ),
    );
  }
}

// ===============================================================
// 3. THE ATTENDANCE MANAGER LOGIC WIDGET
// ===============================================================

class AttendanceManager extends StatefulWidget {
  final List<Student> students;
  final Future<void> Function(
    DateTime date,
    Map<String, AttendanceStatus> attendanceData,
    Map<String, TimeOfDay?> lateTimes,
  )
  onSave;

  const AttendanceManager({
    super.key,
    required this.students,
    required this.onSave,
  });

  @override
  _AttendanceManagerState createState() => _AttendanceManagerState();
}

class _AttendanceManagerState extends State<AttendanceManager> {
  final Map<DateTime, Map<String, AttendanceStatus>> _dailyAttendance = {};
  final Map<DateTime, Map<String, TimeOfDay?>> _dailyLateTimes = {};

  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadInitialData();
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadAttendanceForDate(_selectedDate);
    _ensureAttendanceDataForDate(_selectedDate);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final formattedDate = DateFormat('yyyy-MM-dd').format(normalizedDate);

    try {
      final response = await supabase
          .from('attendance')
          .select()
          .eq('date', formattedDate);

      if (response.isNotEmpty) {
        final Map<String, AttendanceStatus> attendanceMap = {};
        final Map<String, TimeOfDay?> lateTimesMap = {};

        for (var record in response) {
          final studentId = record['student_id'] as String;
          final statusStr = record['status'] as String;
          final lateTimeStr = record['late_time'] as String?;

          attendanceMap[studentId] = AttendanceStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => AttendanceStatus.absent,
          );

          if (lateTimeStr != null) {
            final parts = lateTimeStr.split(':');
            lateTimesMap[studentId] = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          } else {
            lateTimesMap[studentId] = null;
          }
        }

        setState(() {
          _dailyAttendance[normalizedDate] = attendanceMap;
          _dailyLateTimes[normalizedDate] = lateTimesMap;
        });
      }
    } catch (error) {
      print("Error loading attendance: $error");
    }
  }

  void _ensureAttendanceDataForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    if (!_dailyAttendance.containsKey(normalizedDate)) {
      setState(() {
        _dailyAttendance[normalizedDate] = {
          for (var student in widget.students)
            student.id: AttendanceStatus.absent,
        };
        _dailyLateTimes[normalizedDate] = {
          for (var student in widget.students) student.id: null,
        };
      });
    } else {
      // Ensure all current students are in the map
      final currentAttendance = _dailyAttendance[normalizedDate]!;
      final currentLateTimes = _dailyLateTimes[normalizedDate]!;

      for (var student in widget.students) {
        if (!currentAttendance.containsKey(student.id)) {
          currentAttendance[student.id] = AttendanceStatus.absent;
          currentLateTimes[student.id] = null;
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _isLoading = true);
      await _loadAttendanceForDate(picked);
      setState(() {
        _selectedDate = picked;
        _ensureAttendanceDataForDate(_selectedDate);
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(
    String studentId,
    AttendanceStatus newStatus,
  ) async {
    final normalizedDate = _normalizeDate(_selectedDate);
    final currentStatus = _dailyAttendance[normalizedDate]![studentId];

    if (currentStatus == newStatus) {
      setState(() {
        _dailyAttendance[normalizedDate]![studentId] = AttendanceStatus.absent;
        _dailyLateTimes[normalizedDate]![studentId] = null;
      });
      return;
    }

    if (newStatus == AttendanceStatus.late) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dailyAttendance[normalizedDate]![studentId] = newStatus;
          _dailyLateTimes[normalizedDate]![studentId] = pickedTime;
        });
      }
    } else {
      setState(() {
        _dailyAttendance[normalizedDate]![studentId] = newStatus;
        _dailyLateTimes[normalizedDate]![studentId] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final normalizedSelectedDate = _normalizeDate(_selectedDate);
    final currentAttendanceMap = _dailyAttendance[normalizedSelectedDate] ?? {};
    final currentLateTimesMap = _dailyLateTimes[normalizedSelectedDate] ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.teal),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: widget.students.length,
            itemBuilder: (context, index) {
              final student = widget.students[index];
              return _buildStudentTile(student, currentAttendanceMap);
            },
          ),
        ),
        _buildAttendanceSummary(currentAttendanceMap),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox.shrink()
                  : const Icon(Icons.save_alt_rounded),
              label: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text('Save Attendance'),
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await widget.onSave(
                        _selectedDate,
                        currentAttendanceMap,
                        currentLateTimesMap,
                      );
                      if (mounted) setState(() => _isSaving = false);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(
    Student student,
    Map<String, AttendanceStatus> attendanceMap,
  ) {
    final currentStatus = attendanceMap[student.id] ?? AttendanceStatus.absent;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Text(
            student.name.isNotEmpty ? student.name[0] : '?',
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          currentStatus.name.capitalize(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(currentStatus),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(
              student.id,
              AttendanceStatus.present,
              attendanceMap,
            ),
            _buildStatusIcon(student.id, AttendanceStatus.late, attendanceMap),
            _buildStatusIcon(
              student.id,
              AttendanceStatus.permission,
              attendanceMap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(
    String studentId,
    AttendanceStatus status,
    Map<String, AttendanceStatus> attendanceMap,
  ) {
    final bool isSelected = attendanceMap[studentId] == status;
    const iconMap = {
      AttendanceStatus.present: (
        Icons.check_circle,
        Icons.check_circle_outline,
      ),
      AttendanceStatus.late: (Icons.watch_later, Icons.watch_later_outlined),
      AttendanceStatus.permission: (Icons.gpp_good, Icons.gpp_good_outlined),
    };
    final icons = iconMap[status]!;
    return IconButton(
      icon: Icon(isSelected ? icons.$1 : icons.$2),
      color: isSelected ? _getStatusColor(status) : Colors.grey.shade400,
      onPressed: () => _updateStatus(studentId, status),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green.shade600;
      case AttendanceStatus.absent:
        return Colors.red.shade600;
      case AttendanceStatus.late:
        return Colors.orange.shade700;
      case AttendanceStatus.permission:
        return Colors.blue.shade600;
    }
  }

  Widget _buildAttendanceSummary(Map<String, AttendanceStatus> attendanceMap) {
    int presentCount = attendanceMap.values
        .where((s) => s == AttendanceStatus.present)
        .length;
    int absentCount = attendanceMap.values
        .where((s) => s == AttendanceStatus.absent)
        .length;
    int lateCount = attendanceMap.values
        .where((s) => s == AttendanceStatus.late)
        .length;
    int permissionCount = attendanceMap.values
        .where((s) => s == AttendanceStatus.permission)
        .length;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Present', presentCount, Colors.green.shade700),
            const SizedBox(height: 6),
            _buildSummaryRow('Absent', absentCount, Colors.red.shade700),
            const SizedBox(height: 6),
            _buildSummaryRow('Late', lateCount, Colors.orange.shade700),
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Permission',
              permissionCount,
              Colors.blue.shade700,
            ),
            const Divider(height: 20, thickness: 1),
            _buildSummaryRow(
              'Total Students',
              widget.students.length,
              Colors.black87,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    int count,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
