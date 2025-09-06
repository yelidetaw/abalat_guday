import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';

// --- UI Constants for consistency with ProfileScreen ---
const kPrimaryColor = Color(0xFF673AB7);
const kAccentColor = Color(0xFF7C4DFF);
const kTextColor = Color(0xFF333333);
const kSubtleTextColor = Color(0xFF666666);

enum AttendanceStatus { present, absent, late, permission, unknown }

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  Map<DateTime, AttendanceStatus> _attendanceData = {};
  bool _isLoading = true;
  String? _error;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "User not logged in.";

      final response = await supabase
          .from('attendance')
          .select('date, status')
          .eq('student_id', user.id);

      final Map<DateTime, AttendanceStatus> fetchedData = {};
      for (var record in response) {
        final date = DateTime.parse(record['date']);
        final statusStr = record['status'];
        fetchedData[DateTime(date.year, date.month, date.day)] =
            _statusFromString(statusStr);
      }

      if (mounted) {
        setState(() {
          _attendanceData = fetchedData;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = "Could not load history: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  AttendanceStatus _statusFromString(String status) {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'permission':
        return AttendanceStatus.permission;
      default:
        return AttendanceStatus.unknown;
    }
  }

  Color _getColorForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green.shade400;
      case AttendanceStatus.absent:
        return Colors.red.shade400;
      case AttendanceStatus.late:
        return Colors.orange.shade400;
      case AttendanceStatus.permission:
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Column(
              children: [
                _buildCalendar(),
                const Divider(height: 1),
                _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2022, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: kTextColor,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final status = _attendanceData[date];
              if (status != null) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getColorForStatus(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.center,
        children: AttendanceStatus.values
            .where((s) => s != AttendanceStatus.unknown)
            .map(
              (status) => _buildLegendItem(
                status.name.replaceFirst(
                  status.name[0],
                  status.name[0].toUpperCase(),
                ),
                _getColorForStatus(status),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 14, color: kSubtleTextColor),
        ),
      ],
    );
  }
}
