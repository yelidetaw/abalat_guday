import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:amde_haymanot_abalat_guday/models/student.dart';

// Constants for filter and status strings
const String _kFilterAll = 'All';
const String _kFilterPresent = 'Present';
const String _kFilterAbsent = 'Absent';
const String _kFilterLate = 'Late';
const String _kFilterPermission = 'Permission';

const String _kStatusPresent = 'present';
const String _kStatusAbsent = 'absent';
const String _kStatusLate = 'late';
const String _kStatusPermission = 'permission';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;
  final List<Map<String, dynamic>> attendanceRecords;
  final DateTimeRange? dateRange;

  const StudentDetailsScreen({
    super.key,
    required this.student,
    required this.attendanceRecords,
    this.dateRange,
    // The studentId is available inside the student object, so this parameter is redundant.
    // required String studentId,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  String _selectedFilter = _kFilterAll;
  bool _showChart = false;

  // --- BRANDING COLORS ---
  static const Color primaryColor =Color.fromARGB(255, 1, 37, 100);
  static const Color accentColor = Color(0xFFFFD700);
  static const Color cardBackgroundColor = Color.fromARGB(255, 1, 37, 100);

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filterRecords(widget.attendanceRecords);
    final attendanceStats = _calculateAttendanceStats(widget.attendanceRecords);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('${widget.student.name}',
            style: GoogleFonts.poppins(color: accentColor)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: accentColor),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.bar_chart,
                color: accentColor),
            tooltip: _showChart ? 'Show List' : 'Show Chart',
            onPressed: () => setState(() => _showChart = !_showChart),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(),
            const SizedBox(height: 24),
            if (widget.dateRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Showing data from ${DateFormat('MMM d, y').format(widget.dateRange!.start)} '
                  'to ${DateFormat('MMM d, y').format(widget.dateRange!.end)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: accentColor.withOpacity(0.7)),
                ),
              ),
            _buildAttendanceSummaryCards(attendanceStats),
            const SizedBox(height: 24),
            _buildFilterOptions(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _showChart
                  ? _buildAttendanceChart(widget.attendanceRecords)
                  : _buildAttendanceList(filteredRecords),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: accentColor,
          child: CircleAvatar(
            radius: 28,
            backgroundImage: _getStudentImage(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.student.name,
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor),
              ),
              if (widget.student.group != null)
                Text(
                  'Group: ${widget.student.group}',
                  style:
                      GoogleFonts.poppins(color: accentColor.withOpacity(0.8)),
                ),
              Text(
                'ID: ${widget.student.id}',
                style: GoogleFonts.poppins(color: accentColor.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ImageProvider _getStudentImage() {
    if (widget.student.photoUrl != null &&
        widget.student.photoUrl!.isNotEmpty) {
      try {
        return NetworkImage(widget.student.photoUrl!);
      } catch (e) {
        return const AssetImage(
            'assets/default_avatar.png'); // Ensure you have this asset
      }
    }
    return const AssetImage(
        'assets/default_avatar.png'); // Ensure you have this asset
  }

  Widget _buildAttendanceSummaryCards(Map<String, int> stats) {
    final totalDays = stats['total'] ?? 1;
    final presentDays = stats['present'] ?? 0;
    final percentage = (presentDays / totalDays * 100).round();
    final percentageColor = _getPercentageColor(presentDays / totalDays);

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Total Days', totalDays, Icons.calendar_today,
              Colors.blue.shade200),
          _buildStatCard('Present', presentDays, Icons.check_circle,
              Colors.green.shade300),
          _buildStatCard('Absent', stats['absent'] ?? 0, Icons.cancel,
              Colors.red.shade300),
          _buildStatCard('Late', stats['late'] ?? 0, Icons.schedule,
              Colors.orange.shade300),
          _buildStatCard('Permission', stats['permission'] ?? 0,
              Icons.assignment_turned_in, Colors.purple.shade300),
          _buildStatCard(
              'Attendance %', percentage, Icons.percent, percentageColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accentColor.withOpacity(0.2))),
      elevation: 2,
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Text(
                  title == 'Attendance %' ? '$value%' : value.toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: accentColor.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          backgroundColor: cardBackgroundColor,
          foregroundColor: accentColor.withOpacity(0.7),
          selectedForegroundColor: primaryColor,
          selectedBackgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: accentColor.withOpacity(0.5)),
        ),
        segments: const [
          ButtonSegment(value: _kFilterAll, label: Text(_kFilterAll)),
          ButtonSegment(value: _kFilterPresent, label: Text(_kFilterPresent)),
          ButtonSegment(value: _kFilterAbsent, label: Text(_kFilterAbsent)),
          ButtonSegment(value: _kFilterLate, label: Text(_kFilterLate)),
          ButtonSegment(
              value: _kFilterPermission, label: Text(_kFilterPermission)),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() => _selectedFilter = newSelection.first);
        },
      ),
    );
  }

  Widget _buildAttendanceChart(List<Map<String, dynamic>> records) {
    final monthlyData = _groupByMonth(records);

    if (monthlyData.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
            child: Text('No attendance data available for chart',
                style: TextStyle(color: accentColor))),
      );
    }

    try {
      return Card(
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: accentColor, fontSize: 10),
                labelRotation: -45,
                labelIntersectAction: AxisLabelIntersectAction.rotate45,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: accentColor, fontSize: 10),
                majorGridLines: MajorGridLines(
                    width: 0.2, color: accentColor.withOpacity(0.3)),
              ),
              title: ChartTitle(
                text: 'Monthly Attendance Overview',
                textStyle: GoogleFonts.poppins(
                    color: accentColor, fontWeight: FontWeight.w600),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(
                    color: accentColor.withOpacity(0.9), fontSize: 12),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries>[
                StackedColumnSeries<Map<String, dynamic>, String>(
                    dataSource: monthlyData,
                    xValueMapper: (data, _) => data['month'] as String,
                    yValueMapper: (data, _) =>
                        (data[_kStatusPresent] ?? 0) as int,
                    name: _kFilterPresent,
                    color: Colors.green),
                StackedColumnSeries<Map<String, dynamic>, String>(
                    dataSource: monthlyData,
                    xValueMapper: (data, _) => data['month'] as String,
                    yValueMapper: (data, _) =>
                        (data[_kStatusAbsent] ?? 0) as int,
                    name: _kFilterAbsent,
                    color: Colors.red),
                StackedColumnSeries<Map<String, dynamic>, String>(
                    dataSource: monthlyData,
                    xValueMapper: (data, _) => data['month'] as String,
                    yValueMapper: (data, _) => (data[_kStatusLate] ?? 0) as int,
                    name: _kFilterLate,
                    color: Colors.orange),
                StackedColumnSeries<Map<String, dynamic>, String>(
                    dataSource: monthlyData,
                    xValueMapper: (data, _) => data['month'] as String,
                    yValueMapper: (data, _) =>
                        (data[_kStatusPermission] ?? 0) as int,
                    name: _kFilterPermission,
                    color: Colors.purple),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Chart rendering error: $e');
      return SizedBox(
          height: 300,
          child: Center(
              child: Text('Error displaying chart: ${e.toString()}',
                  style: const TextStyle(color: Colors.red))));
    }
  }

  Widget _buildAttendanceList(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Text(
            'No attendance records for "${_selectedFilter.toLowerCase()}" found.',
            style: const TextStyle(color: accentColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Attendance History',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: accentColor, fontSize: 18),
          ),
        ),
        ListView.builder(
          itemCount: records.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final record = records[index];
            final date = DateTime.tryParse(record['date'] as String? ?? '');
            final status = record['status'] as String? ?? 'unknown';
            final lateTime = record['late_time'] as String?;

            if (date == null) return const SizedBox.shrink();

            return Card(
              color: cardBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(_getStatusIcon(status),
                      color: _getStatusColor(status), size: 16),
                ),
                title: Text(DateFormat('EEEE, MMMM d, y').format(date),
                    style: TextStyle(
                        color: accentColor, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Status: ${status.capitalize()}${lateTime != null ? '\nLate by: $lateTime' : ''}',
                  style: TextStyle(color: accentColor.withOpacity(0.8)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterRecords(
      List<Map<String, dynamic>> records) {
    if (_selectedFilter == _kFilterAll) return records;
    return records
        .where((r) => r['status'] == _selectedFilter.toLowerCase())
        .toList();
  }

  Map<String, int> _calculateAttendanceStats(
      List<Map<String, dynamic>> records) {
    return {
      'total': records.length,
      'present': records.where((r) => r['status'] == _kStatusPresent).length,
      'absent': records.where((r) => r['status'] == _kStatusAbsent).length,
      'late': records.where((r) => r['status'] == _kStatusLate).length,
      'permission':
          records.where((r) => r['status'] == _kStatusPermission).length,
    };
  }

  List<Map<String, dynamic>> _groupByMonth(List<Map<String, dynamic>> records) {
    final Map<String, Map<String, dynamic>> monthlyMap = {};

    for (final record in records) {
      final date = DateTime.tryParse(record['date'] as String? ?? '');
      final status = record['status'] as String?;

      if (date == null || status == null) continue;

      final monthKey = DateFormat('MMM y').format(date);

      monthlyMap.putIfAbsent(
        monthKey,
        () => {
          'month': monthKey,
          _kStatusPresent: 0,
          _kStatusAbsent: 0,
          _kStatusLate: 0,
          _kStatusPermission: 0
        },
      );

      if (monthlyMap[monthKey]!.containsKey(status)) {
        monthlyMap[monthKey]![status] =
            (monthlyMap[monthKey]![status] as int) + 1;
      }
    }

    final sortedList = monthlyMap.values.toList();
    sortedList.sort((a, b) => DateFormat('MMM y')
        .parse(a['month'])
        .compareTo(DateFormat('MMM y').parse(b['month'])));
    return sortedList;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case _kStatusPresent:
        return Colors.green.shade300;
      case _kStatusAbsent:
        return Colors.red.shade300;
      case _kStatusLate:
        return Colors.orange.shade300;
      case _kStatusPermission:
        return Colors.purple.shade300;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case _kStatusPresent:
        return Icons.check;
      case _kStatusAbsent:
        return Icons.close;
      case _kStatusLate:
        return Icons.schedule;
      case _kStatusPermission:
        return Icons.assignment_turned_in;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 0.9) return Colors.green.shade300;
    if (percentage >= 0.75) return Colors.lightGreen.shade300;
    if (percentage >= 0.5) return Colors.orange.shade300;
    return Colors.red.shade300;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
