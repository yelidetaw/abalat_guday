import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Import our new, reliable utility

// ===============================================================
// MODELS AND PARENT WIDGET
// ===============================================================

class Student {
  final String id;
  final String name;
  final String? kifil;
  Student({required this.id, required this.name, this.kifil});
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(id: json['id'] as String, name: json['full_name'] as String, kifil: json['kifil'] as String?);
  }
}

enum AttendanceStatus { present, absent, late, permission }
enum Session { morning, afternoon }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  List<String> _kifilList = ['ሁሉም'];
  String _selectedKifil = 'ሁሉም';
  Session _selectedSession = Session.morning;
  bool _studentsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentsFromSupabase();
  }

  Future<void> _loadStudentsFromSupabase() async {
    // This logic remains the same
    if (!mounted) return;
    setState(() => _studentsLoading = true);
    try {
      final response = await supabase.from('profiles').select('id, full_name, kifil').order('full_name');
      final students = (response as List).map<Student>((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
      final kifils = students.map((s) => s.kifil).whereType<String>().toSet().toList();
      kifils.sort();
      if (mounted) {
        setState(() {
          _allStudents = students; _filteredStudents = students; _kifilList = ['ሁሉም']..addAll(kifils);
        });
      }
    } catch (error) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: $error'), backgroundColor: Colors.red)); }
    } finally {
      if (mounted) setState(() => _studentsLoading = false);
    }
  }

  void _filterStudents(String? kifil) {
    if (!mounted) return;
    setState(() {
      _selectedKifil = kifil ?? 'ሁሉም';
      _filteredStudents = _selectedKifil == 'ሁሉም' ? _allStudents : _allStudents.where((s) => s.kifil == _selectedKifil).toList();
    });
  }
  
  // Now uses our reliable EthiopianDate object
  Future<void> _handleSave(
    BuildContext context,
    EthiopianDate date, // Use our new class
    Map<String, AttendanceStatus> attendanceData,
    Map<String, TimeOfDay?> lateTimes,
    String? topic,
    Session session,
  ) async {
    // The save logic is now clean and guaranteed to be correct.
    final String formattedDate = date.toDatabaseString();
    final sessionStr = session.name;

    try {
      final payload = <Map<String, dynamic>>[];
      for (final student in _filteredStudents) {
        final status = attendanceData[student.id] ?? AttendanceStatus.absent;
        final lateTime = lateTimes[student.id];
        payload.add({
          'student_id': student.id, 'date': formattedDate, 'session': sessionStr, 'status': status.name,
          'late_time': status == AttendanceStatus.late && lateTime != null ? '${lateTime.hour.toString().padLeft(2, '0')}:${lateTime.minute.toString().padLeft(2, '0')}:00' : null,
        });
      }
      final topicPayload = (topic != null && topic.isNotEmpty) ? {'date': formattedDate, 'session': sessionStr, 'topic': topic} : null;
      await supabase.rpc('save_daily_attendance', params: {'records': payload, 'daily_topic': topicPayload});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: Colors.green));
        context.pop(true); // Signal success
      }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: ${e.toString()}'), backgroundColor: Colors.red)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የተማሪዎች ክትትል')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: DropdownButtonFormField<Session>(value: _selectedSession, items: Session.values.map((s) => DropdownMenuItem(value: s, child: Text(s == Session.morning ? 'ጥዋት' : 'ከሰዓት'))).toList(), onChanged: (v) => setState(() => _selectedSession = v!), decoration: const InputDecoration(labelText: 'ክፍለ ጊዜ', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(value: _selectedKifil, items: _kifilList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(), onChanged: _filterStudents, decoration: const InputDecoration(labelText: 'ክፍል', border: OutlineInputBorder()))),
              ],
            ),
          ),
          Expanded(
            child: _studentsLoading ? const Center(child: CircularProgressIndicator()) : AttendanceManager(
              key: ValueKey('${_selectedSession.name}-$_selectedKifil'),
              students: _filteredStudents,
              session: _selectedSession,
              onSave: (date, data, times, topic) => _handleSave(context, date, data, times, topic, _selectedSession),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// ATTENDANCE MANAGER (CHILD WIDGET)
// ===============================================================

class AttendanceManager extends StatefulWidget {
  final List<Student> students;
  final Session session;
  final Future<void> Function(EthiopianDate date, Map<String, AttendanceStatus> attendanceData, Map<String, TimeOfDay?> lateTimes, String? topicOfTheDay) onSave;
  const AttendanceManager({super.key, required this.students, required this.session, required this.onSave});
  @override
  _AttendanceManagerState createState() => _AttendanceManagerState();
}

class _AttendanceManagerState extends State<AttendanceManager> {
  Map<String, AttendanceStatus> _attendanceMap = {};
  Map<String, TimeOfDay?> _lateTimesMap = {};
  final TextEditingController _topicController = TextEditingController();
  late EthiopianDate _selectedDate; // Use our new class
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = EthiopianDate.now();
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _loadDataForDate(EthiopianDate date) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _attendanceMap = {for (var student in widget.students) student.id: AttendanceStatus.absent};
    _lateTimesMap = {};
    _topicController.clear();
    
    final formattedDate = date.toDatabaseString();
    await _loadAttendanceForDate(formattedDate);
    await _loadTopicOfTheDay(formattedDate);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAttendanceForDate(String formattedDate) async {
    // This logic is correct and remains unchanged
    final studentIds = widget.students.map((s) => s.id).toList();
    if (studentIds.isEmpty) return;
    final sessionStr = widget.session.name;
    try {
      final response = await supabase.from('attendance').select('student_id, status, late_time').eq('date', formattedDate).eq('session', sessionStr).inFilter('student_id', studentIds);
      if (!mounted) return;
      final loadedAttendanceMap = <String, AttendanceStatus>{};
      final loadedLateTimesMap = <String, TimeOfDay?>{};
      for (var record in response) {
        final studentId = record['student_id'] as String;
        loadedAttendanceMap[studentId] = AttendanceStatus.values.firstWhere((e) => e.name == record['status'], orElse: () => AttendanceStatus.absent);
        if (record['late_time'] != null) {
          try {
            final parts = (record['late_time'] as String).split(':');
            loadedLateTimesMap[studentId] = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          } catch (e) { /* ignored */ }
        }
      }
      setState(() { _attendanceMap.addAll(loadedAttendanceMap); _lateTimesMap.addAll(loadedLateTimesMap); });
    } catch (e) { /* ignored */ }
  }

  Future<void> _loadTopicOfTheDay(String formattedDate) async {
    // This logic is correct and remains unchanged
    final sessionStr = widget.session.name;
    try {
      final response = await supabase.from('daily_topics').select('topic').eq('date', formattedDate).eq('session', sessionStr).maybeSingle();
      if (mounted && response != null) {
        _topicController.text = (response['topic'] as String?) ?? '';
      }
    } catch (e) { /* ignored */ }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    // This is our new, clean, custom date picker dialog.
    final EthiopianDate? picked = await showDialog<EthiopianDate>(
      context: context,
      builder: (context) => EthiopianDatePickerDialog(initialDate: _selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadDataForDate(picked);
    }
  }

  Future<void> _updateStatus(String studentId, AttendanceStatus newStatus) async {
    // This logic is correct and remains unchanged
    if (!mounted) return;
    if (_attendanceMap[studentId] == newStatus) {
      setState(() { _attendanceMap[studentId] = AttendanceStatus.absent; _lateTimesMap.remove(studentId); });
      return;
    }
    setState(() => _attendanceMap[studentId] = newStatus);
    if (newStatus == AttendanceStatus.late) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null && mounted) {
        setState(() => _lateTimesMap[studentId] = time);
      } else {
        setState(() => _attendanceMap[studentId] = AttendanceStatus.absent);
      }
    } else if (mounted) {
      setState(() => _lateTimesMap.remove(studentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    // Convert to Gregorian for display purposes only.
    final gregorianForDisplay = _selectedDate.toGregorian();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedDate.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(DateFormat.yMMMEd().format(gregorianForDisplay), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              IconButton(icon: const Icon(Icons.calendar_today, color: Colors.teal), onPressed: () => _selectDate(context)),
            ],
          ),
        ),
        const Divider(height: 1),
        if (widget.students.isEmpty)
          const Expanded(child: Center(child: Text("በዚህ ክፍል ውስጥ ምንም ተማሪዎች የሉም።")))
        else
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final status = _attendanceMap[student.id] ?? AttendanceStatus.absent;
                final lateTime = _lateTimesMap[student.id];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: Text((index + 1).toString())),
                    title: Text(student.name),
                    subtitle: Text(student.kifil ?? 'ክፍል የለውም'),
                    trailing: Wrap(spacing: -12, children: [
                      IconButton(icon: Icon(Icons.check_circle, color: status == AttendanceStatus.present ? Colors.green : Colors.grey.shade400), onPressed: () => _updateStatus(student.id, AttendanceStatus.present)),
                      IconButton(icon: Icon(Icons.cancel, color: status == AttendanceStatus.absent ? Colors.red : Colors.grey.shade400), onPressed: () => _updateStatus(student.id, AttendanceStatus.absent)),
                      IconButton(icon: Icon(Icons.schedule, color: status == AttendanceStatus.late ? Colors.orange : Colors.grey.shade400), onPressed: () => _updateStatus(student.id, AttendanceStatus.late)),
                      IconButton(icon: Icon(Icons.assignment_turned_in, color: status == AttendanceStatus.permission ? Colors.blue : Colors.grey.shade400), onPressed: () => _updateStatus(student.id, AttendanceStatus.permission)),
                      if (status == AttendanceStatus.late && lateTime != null) Padding(padding: const EdgeInsets.only(left: 4, top: 12), child: Text(lateTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                  ),
                );
              },
            ),
          ),
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'የዕለቱ ርዕስ', border: OutlineInputBorder()))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save),
              label: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('የተማሪዎችን አቴንዳንስ አስቀምጥ'),
              onPressed: _isSaving ? null : () async {
                if (!mounted) return;
                setState(() => _isSaving = true);
                await widget.onSave(_selectedDate, _attendanceMap, _lateTimesMap, _topicController.text.trim());
                if(mounted) setState(() => _isSaving = false);
              },
            ),
          ),
        ),
      ],
    );
  }
}


// ===============================================================
// OUR NEW CUSTOM DATE PICKER DIALOG WIDGET
// ===============================================================

class EthiopianDatePickerDialog extends StatefulWidget {
  final EthiopianDate initialDate;
  const EthiopianDatePickerDialog({super.key, required this.initialDate});

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
      // Safety check for the day if the year change affects Pagume's leap status
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
      title: const Text('ቀን ይምረጡ', textAlign: TextAlign.center),
      content: SizedBox(
        width: 300, // Constrain width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeYear(-1)),
                Text('$_selectedYear ዓ.ም.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeYear(1)),
              ],
            ),
            const Divider(),
            // Month Selector
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
                    // Adjust day if it's out of bounds for the new month
                    final newDaysInMonth = EthiopianDate(year: _selectedYear, month: _selectedMonth, day: 1).daysInMonth;
                    if (_selectedDay > newDaysInMonth) {
                      _selectedDay = newDaysInMonth;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Day Grid
            SizedBox(
              height: 220, // Constrain height
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