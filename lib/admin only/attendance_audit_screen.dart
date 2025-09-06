// lib/screens/audit_screen.dart (FINAL - Polished UI)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

import '../role based/attendance_conclusion.dart';

// --- UI Theme Constants ---
const Color kAdminBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kAdminPrimaryAccent = Color(0xFFFFD700);
const Color kAdminSecondaryText =Color(0xFFFFD700);

enum DateRangeMode { day, week, month, year }

// --- DATA MODELS ---
class GradeLog {
  final DateTime eventTime; final String adminName; final String studentName; final String action; final String courseName; final String spiritualClass; final int academicYear; final Map<String, dynamic> oldValues; final Map<String, dynamic> newValues;
  GradeLog({ required this.eventTime, required this.adminName, required this.studentName, required this.action, required this.courseName, required this.spiritualClass, required this.academicYear, required this.oldValues, required this.newValues });
  factory GradeLog.fromJson(Map<String, dynamic> json) {
    return GradeLog( eventTime: DateTime.parse(json['changed_at']), adminName: json['admin_name'] ?? 'Unknown Admin', studentName: json['student_name'] ?? 'Unknown Student', action: json['action'] ?? 'UNKNOWN', courseName: json['course_name'] ?? 'N/A', spiritualClass: json['spiritual_class'] ?? 'N/A', academicYear: json['academic_year'] ?? DateTime.now().year, oldValues: _parseJsonb(json['old_values']), newValues: _parseJsonb(json['new_values']), );
  }
  static Map<String, dynamic> _parseJsonb(dynamic value) {
    if (value == null) return {}; if (value is Map<String, dynamic>) return value; if (value is String) { try { return Map<String, dynamic>.from(json.decode(value)); } catch (e) { return {}; } } return {};
  }
}

class AttendanceLog {
  final DateTime eventTime; final String attendanceDate;
  final String adminName; final String studentName; final String session; final String? topic;
  final Map<String, dynamic> oldValues; final Map<String, dynamic> newValues;
  AttendanceLog({ required this.eventTime, required this.attendanceDate, required this.adminName, required this.studentName, required this.session, this.topic, required this.oldValues, required this.newValues });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      eventTime: DateTime.parse(json['event_time']),
      attendanceDate: json['attendance_date'] ?? '',
      adminName: json['admin_name'] ?? 'Unknown Admin',
      studentName: json['student_name'] ?? 'Unknown Student',
      session: json['session'] ?? '',
      topic: json['topic'],
      oldValues: GradeLog._parseJsonb(json['old_values']),
      newValues: GradeLog._parseJsonb(json['new_values']));
  }
}

class AuditScreen extends StatefulWidget { const AuditScreen({super.key}); @override State<AuditScreen> createState() => _AuditScreenState(); }
class _AuditScreenState extends State<AuditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController; EthiopianDate _selectedDate = EthiopianDate.now();
  DateRangeMode _dateRangeMode = DateRangeMode.day;
  @override void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override void dispose() { _tabController.dispose(); super.dispose(); }
  Future<void> _selectDate(BuildContext context) async {
    final EthiopianDate? picked = await showDialog<EthiopianDate>( context: context, builder: (context) => EthiopianDatePickerDialog(initialDate: _selectedDate), );
    if (picked != null && (picked.year != _selectedDate.year || picked.month != _selectedDate.month || picked.day != _selectedDate.day)) { setState(() { _selectedDate = picked; _dateRangeMode = DateRangeMode.day; }); }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAdminBackgroundColor,
      appBar: AppBar( title: Text('የአስተዳደር ታሪክ', style: GoogleFonts.notoSansEthiopic()), backgroundColor: kAdminBackgroundColor, elevation: 0,
        bottom: TabBar( controller: _tabController, indicatorColor: kAdminPrimaryAccent, labelColor: kAdminPrimaryAccent, unselectedLabelColor: kAdminSecondaryText,
          tabs: const [ Tab(icon: Icon(Icons.history_edu_outlined), text: 'የውጤት ለውጦች'), Tab(icon: Icon(Icons.event_available_outlined), text: 'የክትትል መዝገቦች'), ],
        ),
      ),
      body: Column( children: [ _buildDateRangeSelector(), _buildDatePicker(), Expanded( child: TabBarView( controller: _tabController, children: [ _GradeLogView(key: ValueKey('grades_${_selectedDate.toDatabaseString()}_${_dateRangeMode.name}'), selectedDate: _selectedDate, rangeMode: _dateRangeMode), _AttendanceLogView(key: ValueKey('attendance_${_selectedDate.toDatabaseString()}_${_dateRangeMode.name}'), selectedDate: _selectedDate, rangeMode: _dateRangeMode), ], ), ), ], ),
    );
  }
  Widget _buildDateRangeSelector() {
    return Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: DateRangeMode.values.map((mode) {
          return ChoiceChip(
            label: Text(mode.name.substring(0, 1).toUpperCase() + mode.name.substring(1)),
            selected: _dateRangeMode == mode,
            onSelected: (isSelected) { if (isSelected) { setState(() { _dateRangeMode = mode; }); } },
            selectedColor: kAdminPrimaryAccent,
            labelStyle: TextStyle(color: _dateRangeMode == mode ? Colors.white : kAdminSecondaryText),
            backgroundColor: kAdminCardColor,
          );
        }).toList(),
      ),
    );
  }

  // --- THIS IS THE FINAL, POLISHED WIDGET ---
  Widget _buildDatePicker() {
    final gregorianDate = _selectedDate.toGregorian();
    String titleText;
    String subtitleText;

    switch (_dateRangeMode) {
      case DateRangeMode.day:
        titleText = _selectedDate.toString();
        subtitleText = DateFormat('EEEE, MMM d, y').format(gregorianDate);
        break;
      case DateRangeMode.week:
        // For Gregorian, Sunday is 7, Monday is 1. We'll adjust to a Monday-start week.
        final weekDay = gregorianDate.weekday == 7 ? 0 : gregorianDate.weekday;
        final startOfWeek = gregorianDate.subtract(Duration(days: weekDay -1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        // Convert start and end back to Ethiopian for display
        final ethiopianStart = EthiopianDate.fromGregorian(startOfWeek);
        final ethiopianEnd = EthiopianDate.fromGregorian(endOfWeek);
        titleText = "ሳምንት"; // "Week" in Amharic
        subtitleText = "${ethiopianStart.toString()} - ${ethiopianEnd.toString()}";
        break;
      case DateRangeMode.month:
        // Use the Ethiopian month name
        titleText = EthiopianDate.monthNames[_selectedDate.month - 1];
        subtitleText = "ወር ${_selectedDate.year} ዓ.ም."; // "Month of YEAR"
        break;
      case DateRangeMode.year:
        titleText = "${_selectedDate.year} ዓ.ም.";
        subtitleText = "ሙሉ ዓመት"; // "Full Year"
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kAdminCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kAdminPrimaryAccent.withOpacity(0.5))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titleText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(subtitleText, style: const TextStyle(fontSize: 14, color: kAdminSecondaryText)),
                  ],
                ),
              ),
              const Icon(Icons.calendar_month_outlined, color: kAdminPrimaryAccent, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (The rest of the file is unchanged)
class _GradeLogView extends StatefulWidget {
  final EthiopianDate selectedDate; final DateRangeMode rangeMode;
  const _GradeLogView({super.key, required this.selectedDate, required this.rangeMode});
  @override State<_GradeLogView> createState() => _GradeLogViewState();
}
class _GradeLogViewState extends State<_GradeLogView> {
  late Future<List<GradeLog>> _logFuture;
  @override void initState() { super.initState(); _logFuture = _fetchGradeLog(); }
  @override void didUpdateWidget(covariant _GradeLogView oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.selectedDate.toDatabaseString() != widget.selectedDate.toDatabaseString() || oldWidget.rangeMode != widget.rangeMode) { setState(() { _logFuture = _fetchGradeLog(); }); } }
  Future<List<GradeLog>> _fetchGradeLog() async {
    try {
      final gregorianAnchor = widget.selectedDate.toGregorian(); DateTime startTime; DateTime endTime;
      switch (widget.rangeMode) {
        case DateRangeMode.day: startTime = DateTime.utc(gregorianAnchor.year, gregorianAnchor.month, gregorianAnchor.day, 0, 0, 0); endTime = DateTime.utc(gregorianAnchor.year, gregorianAnchor.month, gregorianAnchor.day, 23, 59, 59); break;
        case DateRangeMode.week:
          final weekDay = gregorianAnchor.weekday == 7 ? 0 : gregorianAnchor.weekday;
          final startOfWeek = gregorianAnchor.subtract(Duration(days: weekDay - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          startTime = DateTime.utc(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0); endTime = DateTime.utc(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59); break;
        case DateRangeMode.month:
          final ethiopianMonthStart = EthiopianDate(year: widget.selectedDate.year, month: widget.selectedDate.month, day: 1);
          final ethiopianMonthEnd = EthiopianDate(year: widget.selectedDate.year, month: widget.selectedDate.month, day: 30); // All months have 30 days except Pagume
          startTime = ethiopianMonthStart.toGregorian();
          endTime = ethiopianMonthEnd.toGregorian();
          startTime = DateTime.utc(startTime.year, startTime.month, startTime.day, 0, 0, 0);
          endTime = DateTime.utc(endTime.year, endTime.month, endTime.day, 23, 59, 59);
          if (widget.selectedDate.month == 13) { // Handle Pagume
             final pagumeEndDate = EthiopianDate(year: widget.selectedDate.year, month: 13, day: widget.selectedDate.isLeapYear ? 6 : 5).toGregorian();
             endTime = DateTime.utc(pagumeEndDate.year, pagumeEndDate.month, pagumeEndDate.day, 23, 59, 59);
          }
          break;
        case DateRangeMode.year:
          final ethiopianYearStart = EthiopianDate(year: widget.selectedDate.year, month: 1, day: 1);
          final ethiopianYearEnd = EthiopianDate(year: widget.selectedDate.year, month: 13, day: ethiopianYearStart.isLeapYear ? 6: 5);
          startTime = ethiopianYearStart.toGregorian();
          endTime = ethiopianYearEnd.toGregorian();
          startTime = DateTime.utc(startTime.year, startTime.month, startTime.day, 0, 0, 0);
          endTime = DateTime.utc(endTime.year, endTime.month, endTime.day, 23, 59, 59);
          break;
      }
      final response = await supabase.rpc('get_grade_audit_log_details_for_day', params: { 'start_time': startTime.toIso8601String(), 'end_time': endTime.toIso8601String(), });
      final List<dynamic> data = response;
      return data.map((item) => GradeLog.fromJson(item)).toList();
    } catch (e) { if (kDebugMode) { print("Grade Log Fetch FAILED: $e"); } throw "Could not fetch grade logs. See console."; }
  }
  @override Widget build(BuildContext context) {
    return FutureBuilder<List<GradeLog>>(
      future: _logFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const _LoadingShimmer(); }
        if (snapshot.hasError) { return Center( child: Padding( padding: const EdgeInsets.all(16.0), child: Text("Error:\n\n${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), )); }
        if (snapshot.data == null || snapshot.data!.isEmpty) { return Center( child: Text('ምንም የውጤት ለውጥ አልተገኘም', style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText))); }
        final logs = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), itemCount: logs.length,
          itemBuilder: (context, index) { final log = logs[index]; return FadeInUp( from: 20, delay: Duration(milliseconds: 50 * index), child: _GradeLogCard(log: log), ); },
        );
      },
    );
  }
}
class _AttendanceLogView extends StatefulWidget {
  final EthiopianDate selectedDate; final DateRangeMode rangeMode;
  const _AttendanceLogView({super.key, required this.selectedDate, required this.rangeMode});
  @override State<_AttendanceLogView> createState() => _AttendanceLogViewState();
}
class _AttendanceLogViewState extends State<_AttendanceLogView> {
  late Future<List<AttendanceLog>> _logFuture;
  @override void initState() { super.initState(); _logFuture = _fetchAttendanceLog(); }
  @override void didUpdateWidget(covariant _AttendanceLogView oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.selectedDate.toDatabaseString() != widget.selectedDate.toDatabaseString() || oldWidget.rangeMode != widget.rangeMode) { setState(() { _logFuture = _fetchAttendanceLog(); }); } }
  Future<List<AttendanceLog>> _fetchAttendanceLog() async {
    try {
      final gregorianAnchor = widget.selectedDate.toGregorian(); DateTime startTime; DateTime endTime;
      switch (widget.rangeMode) {
        case DateRangeMode.day: startTime = DateTime.utc(gregorianAnchor.year, gregorianAnchor.month, gregorianAnchor.day, 0, 0, 0); endTime = DateTime.utc(gregorianAnchor.year, gregorianAnchor.month, gregorianAnchor.day, 23, 59, 59); break;
        case DateRangeMode.week:
          final weekDay = gregorianAnchor.weekday == 7 ? 0 : gregorianAnchor.weekday;
          final startOfWeek = gregorianAnchor.subtract(Duration(days: weekDay-1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          startTime = DateTime.utc(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0); endTime = DateTime.utc(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59); break;
        case DateRangeMode.month:
          final ethiopianMonthStart = EthiopianDate(year: widget.selectedDate.year, month: widget.selectedDate.month, day: 1);
          final ethiopianMonthEnd = EthiopianDate(year: widget.selectedDate.year, month: widget.selectedDate.month, day: 30); // All months have 30 days except Pagume
          startTime = ethiopianMonthStart.toGregorian();
          endTime = ethiopianMonthEnd.toGregorian();
          startTime = DateTime.utc(startTime.year, startTime.month, startTime.day, 0, 0, 0);
          endTime = DateTime.utc(endTime.year, endTime.month, endTime.day, 23, 59, 59);
           if (widget.selectedDate.month == 13) { // Handle Pagume
             final pagumeEndDate = EthiopianDate(year: widget.selectedDate.year, month: 13, day: widget.selectedDate.isLeapYear ? 6 : 5).toGregorian();
             endTime = DateTime.utc(pagumeEndDate.year, pagumeEndDate.month, pagumeEndDate.day, 23, 59, 59);
          }
          break;
        case DateRangeMode.year:
          final ethiopianYearStart = EthiopianDate(year: widget.selectedDate.year, month: 1, day: 1);
          final ethiopianYearEnd = EthiopianDate(year: widget.selectedDate.year, month: 13, day: ethiopianYearStart.isLeapYear ? 6: 5);
          startTime = ethiopianYearStart.toGregorian();
          endTime = ethiopianYearEnd.toGregorian();
          startTime = DateTime.utc(startTime.year, startTime.month, startTime.day, 0, 0, 0);
          endTime = DateTime.utc(endTime.year, endTime.month, endTime.day, 23, 59, 59);
          break;
      }
      final response = await supabase.rpc('get_attendance_audit_for_day', params: { 'start_time': startTime.toIso8601String(), 'end_time': endTime.toIso8601String(), });
      final List<dynamic> data = response;
      return data.map((item) => AttendanceLog.fromJson(item)).toList();
    } catch (e) { debugPrint("Error fetching attendance log: $e"); throw "የክትትል ታሪክን መጫን አልተሳካም።"; }
  }
  @override Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceLog>>(
      future: _logFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const _LoadingShimmer(); }
        if (snapshot.hasError) { return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error:\n\n${snapshot.error}", style: const TextStyle(color: Colors.red)))); }
        if (snapshot.data == null || snapshot.data!.isEmpty) { return Center(child: Text('ምንም የክትትል መዝገብ አልተገኘም', style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText))); }
        final logs = snapshot.data!;
        return ListView.builder( padding: const EdgeInsets.symmetric(horizontal: 16.0), itemCount: logs.length,
          itemBuilder: (context, index) { final log = logs[index]; return FadeInUp( from: 20, delay: Duration(milliseconds: 50 * index), child: _AttendanceLogCard(log: log), ); },
        );
      },
    );
  }
}
class _GradeLogCard extends StatelessWidget {
  final GradeLog log; const _GradeLogCard({required this.log});
  Color _getActionColor(String action) { switch (action) { case 'INSERT': return Colors.green.shade300; case 'UPDATE': return Colors.orange.shade300; case 'DELETE': return Colors.red.shade300; default: return kAdminSecondaryText; } }
  IconData _getActionIcon(String action) { switch (action) { case 'INSERT': return Icons.add_circle_outline; case 'UPDATE': return Icons.edit_outlined; case 'DELETE': return Icons.remove_circle_outline; default: return Icons.help_outline; } }
  @override Widget build(BuildContext context) {
    final action = log.action; final actionColor = _getActionColor(action);
    return Card( color: kAdminCardColor, margin: const EdgeInsets.only(bottom: 12), child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Row( children: [ Icon(_getActionIcon(action), color: actionColor), const SizedBox(width: 8), Text("የውጤት ለውጦች", style: TextStyle(color: actionColor, fontWeight: FontWeight.bold)), const Spacer(), Text(DateFormat.jm().format(log.eventTime.toLocal()), style: const TextStyle(color: kAdminSecondaryText, fontSize: 12)), ], ), const Divider(height: 20, color: kAdminSecondaryText), _buildLogDetailRow(Icons.person, "ተማሪ:", log.studentName), _buildLogDetailRow(Icons.class_, "ክፍል:", "${log.spiritualClass} (${log.academicYear})"), _buildLogDetailRow(Icons.book, "ትምህርት:", log.courseName), _buildLogDetailRow(Icons.admin_panel_settings, "በ:", log.adminName), const SizedBox(height: 12), _buildChangeSummary(action, log.oldValues, log.newValues), ], ), ), );
  }
  Widget _buildChangeSummary(String action, Map<String, dynamic> oldValues, Map<String, dynamic> newValues) {
    if (action == 'INSERT') { return _buildValueChip("የተጨመረው", "Mid: ${newValues['mid_exam']}, Final: ${newValues['final_exam']}, Assign: ${newValues['assignment']}", Colors.green); } if (action == 'DELETE') { return _buildValueChip("የተሰረዘው", "Mid: ${oldValues['mid_exam']}, Final: ${oldValues['final_exam']}, Assign: ${oldValues['assignment']}", Colors.red); } final changes = <Widget>[]; if (oldValues['mid_exam'] != newValues['mid_exam']) { changes.add(_buildValueChanged('ሚድ', oldValues['mid_exam'], newValues['mid_exam'])); } if (oldValues['final_exam'] != newValues['final_exam']) { changes.add(_buildValueChanged('ፍጻሜ', oldValues['final_exam'], newValues['final_exam'])); } if (oldValues['assignment'] != newValues['assignment']) { changes.add(_buildValueChanged('አሳይመንት', oldValues['assignment'], newValues['assignment'])); } if (changes.isEmpty) { return _buildValueChip("ለውጥ", "ምንም ለውጥ አልተመዘገበም", Colors.grey); } return Container( padding: const EdgeInsets.all(12), width: double.infinity, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text("የተቀየሩት", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), ...changes, ], ), );
  }
  Widget _buildValueChanged(String label, dynamic oldValue, dynamic newValue) { return Padding( padding: const EdgeInsets.symmetric(vertical: 2.0), child: Row( children: [ Text("$label: ", style: const TextStyle(color: kAdminSecondaryText)), Text("$oldValue", style: const TextStyle(color: Colors.redAccent, decoration: TextDecoration.lineThrough)), const Icon(Icons.arrow_right_alt, color: kAdminSecondaryText), Text("$newValue", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)), ], ), ); }
  Widget _buildValueChip(String label, String value, Color color) { return Container( padding: const EdgeInsets.all(12), width: double.infinity, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: kAdminSecondaryText, fontSize: 14)), ], ), ); }
}
class _AttendanceLogCard extends StatelessWidget {
  final AttendanceLog log;
  const _AttendanceLogCard({required this.log});
  String _getStatusText(dynamic status) { switch (status) { case 'present': return 'ተገኝቷል'; case 'absent': return 'ቀርቷል'; case 'late': return 'አርፍዷል'; case 'permission': return 'በፍቃድ'; default: return 'N/A'; } }
  Color _getStatusColor(dynamic status) { switch (status) { case 'present': return Colors.green.shade300; case 'absent': return Colors.red.shade300; case 'late': return Colors.orange.shade300; case 'permission': return Colors.blue.shade300; default: return kAdminSecondaryText; } }
  Widget _buildChangeSummary() {
    final oldStatus = log.oldValues['status']; final newStatus = log.newValues['status'];
    if (oldStatus == null || oldStatus == newStatus) { return _buildValueChip( _getStatusText(newStatus), "No change recorded for this entry.", _getStatusColor(newStatus) ); }
    return Container( padding: const EdgeInsets.all(12), width: double.infinity, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text("የተቀየረው", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Row( children: [ Text("${_getStatusText(oldStatus)}", style: const TextStyle(color: Colors.redAccent, decoration: TextDecoration.lineThrough)), const Padding( padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.arrow_right_alt, color: kAdminSecondaryText), ), Text("${_getStatusText(newStatus)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)), ], ), ], ),
    );
  }
  @override Widget build(BuildContext context) {
    String ethiopianDateString = 'Invalid Date';
    try {
      final parts = log.attendanceDate.split('-');
      if (parts.length == 3) { final year = int.parse(parts[0]); final month = int.parse(parts[1]); final day = int.parse(parts[2]); ethiopianDateString = EthiopianDate(year: year, month: month, day: day).toString(); } else { ethiopianDateString = log.attendanceDate; }
    } catch (e) { ethiopianDateString = log.attendanceDate; }
    return Card(
      color: kAdminCardColor, margin: const EdgeInsets.only(bottom: 12),
      child: Padding( padding: const EdgeInsets.all(16.0),
        child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row( children: [ Icon(_getStatusIcon(_getStatusText(log.newValues['status'])), color: _getStatusColor(log.newValues['status'])), const SizedBox(width: 8), Text("የክትትል ለውጥ", style: TextStyle(color: _getStatusColor(log.newValues['status']), fontWeight: FontWeight.bold, fontSize: 16)), const Spacer(), Text(DateFormat.jm().format(log.eventTime.toLocal()), style: const TextStyle(color: kAdminSecondaryText, fontSize: 12)), ], ),
            const Divider(height: 20, color: kAdminSecondaryText),
            _buildLogDetailRow(Icons.calendar_today, "የክትትል ቀን:", ethiopianDateString),
            _buildLogDetailRow(Icons.person, "ተማሪ:", log.studentName),
            _buildLogDetailRow(Icons.access_time, "ክፍለ ጊዜ:", log.session == 'morning' ? 'ጥዋት' : 'ከሰዓት'),
            _buildLogDetailRow(Icons.admin_panel_settings, "በ:", log.adminName),
            if (log.topic != null && log.topic!.isNotEmpty) _buildLogDetailRow(Icons.topic_outlined, "ርዕስ:", log.topic),
            const SizedBox(height: 12),
            _buildChangeSummary(),
          ],
        ),
      ),
    );
  }
  IconData _getStatusIcon(dynamic status) {
    switch (status) { case 'ተገኝቷል': return Icons.check_circle_outline; case 'ቀርቷል': return Icons.highlight_off_outlined; case 'አርፍዷል': return Icons.schedule_outlined; case 'በፍቃድ': return Icons.assignment_turned_in_outlined; default: return Icons.help_outline; }
  }
    Widget _buildValueChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), width: double.infinity, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: kAdminSecondaryText, fontSize: 14)), ], ),
    );
  }
}
Widget _buildLogDetailRow(IconData icon, String label, String? value) { return Padding( padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ Icon(icon, color: kAdminSecondaryText, size: 18), const SizedBox(width: 12), Text(label, style: const TextStyle(color: kAdminSecondaryText, fontWeight: FontWeight.w600)), const SizedBox(width: 8), Expanded(child: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white))), ], ), ); }
class _LoadingShimmer extends StatelessWidget { const _LoadingShimmer(); @override Widget build(BuildContext context) { return Shimmer.fromColors( baseColor: kAdminCardColor, highlightColor: kAdminBackgroundColor, child: ListView.builder( padding: const EdgeInsets.all(16.0), itemCount: 6, itemBuilder: (context, index) => Card( color: Colors.white, margin: const EdgeInsets.only(bottom: 12), child: Container(height: 150), ), ), ); } }