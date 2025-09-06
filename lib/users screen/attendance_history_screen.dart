import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

// --- NEW: Import our reliable, self-contained utility ---

// --- ENUM & MODEL for cleaner code ---
enum AttendanceStatus { present, absent, late, permission, unknown }
enum DateFilter { week, month, year, custom }

class AttendanceRecord {
  // We will now store the correctly parsed Gregorian date.
  final DateTime date; 
  final AttendanceStatus status;
  final String? topic;
  final String? session;

  AttendanceRecord({
    required this.date,
    required this.status,
    this.topic,
    this.session,
  });
}

// --- MAIN WIDGET ---
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceRecord> _allRecords = [];
  bool _isLoading = true;
  String? _error;
  DateFilter _selectedFilter = DateFilter.month;
  DateTimeRange? _customDateRange;
  List<AttendanceRecord> _filteredRecords = [];
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  int _permissionCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  // --- THIS IS THE PERMANENT FIX FOR DATA FETCHING ---
  Future<void> _fetchAttendanceHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "ተጠቃሚው አልገባም።";

      // Fetch all records without a date filter initially.
      // We will filter in the app after correct conversion.
      final responses = await Future.wait([
        supabase.from('attendance').select('date, status, session').eq('student_id', user.id),
        supabase.from('daily_topics').select('date, session, topic'),
      ]);

      final attendanceResponse = responses[0];
      final topicsResponse = responses[1];
      final Map<String, String?> topicMap = {
        for (var record in topicsResponse) '${record['date']}-${record['session']}': record['topic'] as String?
      };

      final List<AttendanceRecord> fetchedRecords = [];
      for (var record in attendanceResponse) {
        final dateString = record['date'] as String?;
        if (dateString == null) continue;

        try {
          // 1. Parse the Ethiopian date string into components
          final parts = dateString.split('-');
          if (parts.length != 3) continue;
          
          final etYear = int.parse(parts[0]);
          final etMonth = int.parse(parts[1]);
          final etDay = int.parse(parts[2]);

          // 2. Convert to a true Gregorian DateTime using our reliable converter
          final gregorianDate = EthiopianDate(year: etYear, month: etMonth, day: etDay).toGregorian();

          // 3. Create the record with the CORRECT date object
          final session = record['session'] as String?;
          final key = '$dateString-$session'; // Use original string for topic key
          
          fetchedRecords.add(AttendanceRecord(
            date: gregorianDate, // Store the correct DateTime
            status: _statusFromString(record['status']),
            session: session,
            topic: topicMap[key],
          ));

        } catch(e) {
          debugPrint("Skipping invalid date format: $dateString");
        }
      }

      fetchedRecords.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allRecords = fetchedRecords;
        });
        _filterData(); // Now this will work correctly
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "ታሪክን መጫን አልተቻለም: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    final now = DateTime.now();
    DateTimeRange range;
    switch (_selectedFilter) {
      case DateFilter.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        range = DateTimeRange(start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day), end: now);
        break;
      case DateFilter.month:
        range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
        break;
      case DateFilter.year:
        range = DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
        break;
      case DateFilter.custom:
        range = _customDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
        break;
    }

    final filtered = _allRecords.where((record) {
      final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
      final startDate = DateTime(range.start.year, range.start.month, range.start.day);
      final endDate = DateTime(range.end.year, range.end.month, range.end.day);
      return !recordDate.isBefore(startDate) && !recordDate.isAfter(endDate);
    }).toList();

    setState(() {
      _filteredRecords = filtered;
      _calculateStats(filtered);
    });
  }

  void _calculateStats(List<AttendanceRecord> records) {
    _presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
    _absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;
    _lateCount = records.where((r) => r.status == AttendanceStatus.late).length;
    _permissionCount = records.where((r) => r.status == AttendanceStatus.permission).length;
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'የጊዜ ክልል ይምረጡ',
      fieldStartHintText: 'የመጀመሪያ ቀን',
      fieldEndHintText: 'የመጨረሻ ቀን',
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = DateFilter.custom;
      });
      _filterData();
    }
  }

  void _navigateToManagerAndRefresh() {
    context.push('/admin/attendance/manager').then((result) {
      if (result == true && mounted) {
        _fetchAttendanceHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('የክትትል ታሪክ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAttendanceHistory,
            tooltip: 'Refresh History',
          )
        ],
      ),
      body: _isLoading
          ? const _LoadingShimmer()
          : _error != null
              ? _ErrorDisplay(error: _error!, onRetry: _fetchAttendanceHistory)
              : Column(
                  children: [
                    _buildFilterChips(),
                    _buildSummarySection(),
                    const Divider(height: 1),
                    Expanded(child: _buildAttendanceList()),
                  ],
                ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<DateFilter>(
              segments: const [
                ButtonSegment(value: DateFilter.week, label: Text('ሳምንት')),
                ButtonSegment(value: DateFilter.month, label: Text('ወር')),
                ButtonSegment(value: DateFilter.year, label: Text('ዓመት')),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                   _customDateRange = null;
                });
                _filterData();
              },
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _selectCustomDateRange,
            child: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final totalRecords = _filteredRecords.length;
    final totalPresent = _presentCount + _lateCount;
    final percentage =
        totalRecords > 0 ? (totalPresent / totalRecords * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.8,
            children: [
              _buildStatCard(
                  '${percentage.toStringAsFixed(0)}%',
                  'የተገኘ',
                  _getPercentageColor(percentage.toInt()),
                  Icons.pie_chart_outline_rounded),
              _buildStatCard(
                  _absentCount.toString(),
                  'ቀሪ',
                  _getStatusColor(AttendanceStatus.absent),
                  _getIconForStatus(AttendanceStatus.absent)),
              _buildStatCard(
                  _lateCount.toString(),
                  'ዘግይቷል',
                  _getStatusColor(AttendanceStatus.late),
                  _getIconForStatus(AttendanceStatus.late)),
              _buildStatCard(
                  _permissionCount.toString(),
                  'በፍቃድ',
                  _getStatusColor(AttendanceStatus.permission),
                  _getIconForStatus(AttendanceStatus.permission)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAttendanceList() {
    if (_filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 60, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('በዚህ ጊዜ ውስጥ ምንም መረጃ አልተገኘም።'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        
        // This display logic now works because `record.date` is a correct DateTime
        final String ethiopianDateString = EthiopianDate.fromGregorian(record.date).toString();
        final String gregorianDateString = DateFormat.yMMMEd('en_US').format(record.date);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(_getIconForStatus(record.status),
                color: _getStatusColor(record.status)),
            title: Text(
                '$ethiopianDateString (${_sessionToAmharic(record.session)})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(gregorianDateString),
                if (record.topic != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                     child: Text('ርዕስ: ${record.topic!}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic)),
                   ),
              ],
            ),
            trailing: Text(_statusToAmharic(record.status),
                style: TextStyle(
                    color: _getStatusColor(record.status),
                    fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  // --- HELPER METHODS ---
  String _sessionToAmharic(String? session) {
    if (session == 'morning') return 'ጥዋት';
    if (session == 'afternoon') return 'ከሰዓት';
    return '';
  }

  String _statusToAmharic(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return 'ተገኝቷል';
      case AttendanceStatus.absent: return 'ቀሪ';
      case AttendanceStatus.late: return 'ዘግይቷል';
      case AttendanceStatus.permission: return 'በፍቃድ';
      default: return 'ያልታወቀ';
    }
  }

  AttendanceStatus _statusFromString(String? status) {
    return AttendanceStatus.values.firstWhere((e) => e.name == status,
          orElse: () => AttendanceStatus.unknown);
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green.shade400;
      case AttendanceStatus.absent: return Colors.red.shade400;
      case AttendanceStatus.late: return Colors.orange.shade400;
      case AttendanceStatus.permission: return Colors.blue.shade400;
      default: return Colors.grey.shade400;
    }
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 90) return Colors.green.shade400;
    if (percentage >= 75) return Colors.lightGreen.shade400;
    if (percentage >= 50) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  IconData _getIconForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Icons.check_circle_rounded;
      case AttendanceStatus.absent: return Icons.highlight_off_rounded;
      case AttendanceStatus.late: return Icons.watch_later_rounded;
      case AttendanceStatus.permission: return Icons.assignment_turned_in_rounded;
      default: return Icons.help_outline_rounded;
    }
  }
}

// --- DEDICATED WIDGETS FOR STATES ---
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(child: Container(height: 120))),
          Expanded(
              child: ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(height: 60)),
          )),
        ],
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorDisplay({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red.shade300, size: 60),
          const SizedBox(height: 20),
          Text("ታሪክን መጫን አልተቻለም", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(error,
              textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('እንደገና ሞክር')),
        ]),
      ),
    );
  }
}