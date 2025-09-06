import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:amde_haymanot_abalat_guday/models/student.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shimmer/shimmer.dart';

// --- Import our reliable, self-contained utility ---

// --- The calendar_picker_ghe import has been REMOVED ---


// A constant for our responsive breakpoint.
const double kTabletBreakpoint = 700.0;

// Local model to hold detailed attendance records for easier handling.
class AttendanceRecord {
  final String date; // Stored as "YYYY-MM-DD" Ethiopian date string
  final String status;
  final String? session;
  final String? topic;

  AttendanceRecord({
    required this.date,
    required this.status,
    this.session,
    this.topic,
  });
}

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  _AttendanceSummaryScreenState createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<String> _kifilList = ['ሁሉም'];
  String _selectedKifil = 'ሁሉም';
  
  // We manage dates as Gregorian DateTime objects in the state for filtering logic
  DateTime _selectedDate = DateTime.now();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  Map<String, List<AttendanceRecord>> _attendanceData = {};

  int _totalStudents = 0;
  int _absentCount = 0;
  int _permissionCount = 0;
  int _lateCount = 0;
  int _presentCount = 0;
  bool _isLoading = true;
  bool _showChart = false;
  String _viewMode = 'ዕለታዊ';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final studentsResponse = await supabase.from('profiles').select('*');
      _allStudents = (studentsResponse as List)
          .map((profile) => Student.fromMap(profile))
          .toList();
      _initializeGroups();

      // Convert the state's Gregorian dates to Ethiopian date strings for the query
      final String formattedRangeStart;
      final String formattedRangeEnd;

      if (_viewMode == 'ዕለታዊ') {
        formattedRangeStart = EthiopianDate.fromGregorian(_selectedDate).toDatabaseString();
        formattedRangeEnd = formattedRangeStart;
      } else {
        formattedRangeStart = EthiopianDate.fromGregorian(_dateRange.start).toDatabaseString();
        formattedRangeEnd = EthiopianDate.fromGregorian(_dateRange.end).toDatabaseString();
      }

      final responses = await Future.wait([
        supabase.from('attendance').select('student_id, date, status, session').gte('date', formattedRangeStart).lte('date', formattedRangeEnd),
        supabase.from('daily_topics').select('date, session, topic').gte('date', formattedRangeStart).lte('date', formattedRangeEnd)
      ]);
      
      final attendanceResponse = responses[0] as List;
      final topicsResponse = responses[1] as List;
      final topicMap = <String, String?>{};
      for (var topicRecord in topicsResponse) {
        final key = '${topicRecord['date']}-${topicRecord['session']}';
        topicMap[key] = topicRecord['topic'] as String?;
      }
      final processedAttendance = <String, List<AttendanceRecord>>{};
      for (var record in attendanceResponse) {
        final studentId = record['student_id'] as String;
        final date = record['date'] as String;
        final session = record['session'] as String?;
        final topicKey = '$date-$session';
        final topic = topicMap[topicKey];
        processedAttendance.putIfAbsent(studentId, () => []).add(AttendanceRecord(date: date, status: record['status'] as String, session: session, topic: topic));
      }
      _attendanceData = processedAttendance;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('መረጃ በማምጣት ላይ ስህተት ተፈጥሯል: ${error.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      _filterStudents();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeGroups() {
    final uniqueGroups = _allStudents.map((s) => s.group).whereType<String>().toSet().toList()..sort();
    _kifilList = ['ሁሉም', ...uniqueGroups];
  }

  void _filterStudents() {
    _filteredStudents = _selectedKifil == 'ሁሉም' ? _allStudents : _allStudents.where((s) => s.group == _selectedKifil).toList();
    _calculateSummaryStats();
  }

  void _calculateSummaryStats() {
    _totalStudents = _filteredStudents.length;
    _absentCount = 0; _permissionCount = 0; _lateCount = 0; _presentCount = 0;
    for (final student in _filteredStudents) {
      final records = _attendanceData[student.id] ?? [];
      for (var record in records) {
        switch (record.status) {
          case 'present': _presentCount++; break;
          case 'absent': _absentCount++; break;
          case 'late': _lateCount++; break;
          case 'permission': _permissionCount++; break;
        }
      }
    }
    setState(() {});
  }

  // --- FUNCTION UPDATE #1: Use our custom Ethiopian Date Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final EthiopianDate? picked = await showDialog<EthiopianDate>(
      context: context,
      builder: (_) => EthiopianDatePickerDialog(
        initialDate: EthiopianDate.fromGregorian(_selectedDate),
      ),
    );
    if (picked != null) {
      final newGregorianDate = picked.toGregorian();
      if (!DateUtils.isSameDay(newGregorianDate, _selectedDate)) {
        setState(() => _selectedDate = newGregorianDate);
        await _fetchData();
      }
    }
  }

  // --- FUNCTION UPDATE #2: Use our custom Ethiopian Date Picker twice ---
  Future<void> _selectDateRange(BuildContext context) async {
    final EthiopianDate? pickedStart = await showDialog<EthiopianDate>(
      context: context,
      builder: (_) => EthiopianDatePickerDialog(
        initialDate: EthiopianDate.fromGregorian(_dateRange.start),
        title: "የመጀመሪያ ቀን ይምረጡ",
      ),
    );
    if (pickedStart == null) return;

    final EthiopianDate? pickedEnd = await showDialog<EthiopianDate>(
      context: context,
      builder: (_) => EthiopianDatePickerDialog(
        initialDate: EthiopianDate.fromGregorian(_dateRange.end),
        title: "የመጨረሻ ቀን ይምረጡ",
      ),
    );
    if (pickedEnd == null) return;

    DateTime newStartDate = pickedStart.toGregorian();
    DateTime newEndDate = pickedEnd.toGregorian();

    if (newStartDate.isAfter(newEndDate)) {
      final temp = newStartDate;
      newStartDate = newEndDate;
      newEndDate = temp;
    }

    final newRange = DateTimeRange(start: newStartDate, end: newEndDate);
    if (newRange != _dateRange) {
      setState(() => _dateRange = newRange);
      await _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('የክትትል ማጠቃለያ'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list_alt_rounded : Icons.pie_chart_outline_rounded),
            tooltip: _showChart ? 'ማጠቃለያ ካርዶችን አሳይ' : 'ገበታውን አሳይ',
            onPressed: () => setState(() => _showChart = !_showChart),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= kTabletBreakpoint;
          if (_isLoading) return _buildLoadingShimmer(isWide);
          return isWide ? _buildWideLayout() : _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      children: [
        _buildFilters(),
        _buildSummarySection(isWide: false),
        _buildStudentList(),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 350,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 24),
                _buildSummarySection(isWide: true),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildStudentList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ዕለታዊ', label: Text('ዕለታዊ'), icon: Icon(Icons.calendar_view_day)),
              ButtonSegment(value: 'የጊዜ ክልል', label: Text('የጊዜ ክልል'), icon: Icon(Icons.date_range)),
            ],
            selected: {_viewMode},
            onSelectionChanged: (newSelection) {
              setState(() => _viewMode = newSelection.first);
              _fetchData();
            },
          ),
          const SizedBox(height: 16),
          if (_viewMode == 'ዕለታዊ')
            _buildDatePicker()
          else
            _buildDateRangePicker(),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedKifil,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'በክፍል አጣራ', border: OutlineInputBorder()),
            items: _kifilList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedKifil = newValue);
                _filterStudents();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final ethiopianDate = EthiopianDate.fromGregorian(_selectedDate);
    final gregorianDateString = DateFormat('EEEE, MMM d, y').format(_selectedDate);
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ethiopianDate.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(gregorianDateString, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    final ethiopianStart = EthiopianDate.fromGregorian(_dateRange.start);
    final ethiopianEnd = EthiopianDate.fromGregorian(_dateRange.end);
    final gregorianStartString = DateFormat('MMM d').format(_dateRange.start);
    final gregorianEndString = DateFormat('MMM d, y').format(_dateRange.end);
    return InkWell(
      onTap: () => _selectDateRange(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ethiopianStart.toString()} - ${ethiopianEnd.toString()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text('$gregorianStartString - $gregorianEndString', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  // ... (All other _build methods from here down are correct and unchanged) ...
  Widget _buildSummarySection({required bool isWide}) {
    if (_showChart) return _buildAttendanceChart();
    final cards = _buildSummaryCards();
    if (isWide) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.0),
        itemCount: cards.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => cards[index],
      );
    } else {
      return SizedBox(
        height: 100,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: cards),
      );
    }
  }

  List<Widget> _buildSummaryCards() {
    return [
      _buildSummaryCard('ጠቅላላ', _totalStudents, Icons.people, Theme.of(context).colorScheme.secondary),
      _buildSummaryCard('ተገኝቷል', _presentCount, Icons.check_circle_outline_rounded, Colors.green.shade400),
      _buildSummaryCard('ቀሪ', _absentCount, Icons.highlight_off_rounded, Colors.red.shade400),
      _buildSummaryCard('ዘግይቷል', _lateCount, Icons.schedule_rounded, Colors.orange.shade400),
      _buildSummaryCard('በፍቃድ', _permissionCount, Icons.assignment_turned_in_rounded, Colors.blue.shade400),
    ];
  }

  Widget _buildSummaryCard(String title, int count, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: color),
                Text(count.toString(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Spacer(),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final theme = Theme.of(context);
    final data = [
      {'status': 'ተገኝቷል', 'count': _presentCount, 'color': Colors.green.shade400},
      {'status': 'ቀሪ', 'count': _absentCount, 'color': Colors.red.shade400},
      {'status': 'ዘግይቷል', 'count': _lateCount, 'color': Colors.orange.shade400},
      {'status': 'በፍቃድ', 'count': _permissionCount, 'color': Colors.blue.shade400},
    ];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: SfCircularChart(
          title: ChartTitle(text: 'የአቴንዳንስ ስርጭት', textStyle: theme.textTheme.titleLarge),
          legend: const Legend(isVisible: true, position: LegendPosition.bottom, overflowMode: LegendItemOverflowMode.wrap),
          series: <CircularSeries>[
            DoughnutSeries<Map<String, dynamic>, String>(
              dataSource: data.where((d) => (d['count'] as int) > 0).toList(),
              xValueMapper: (data, _) => data['status'],
              yValueMapper: (data, _) => data['count'],
              pointColorMapper: (data, _) => data['color'],
              dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              innerRadius: '60%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_filteredStudents.isEmpty) {
      return const Center(child: Text('በተመረጠው ማጣሪያ ምንም ተማሪዎች አልተገኙም።'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final records = _attendanceData[student.id] ?? [];
        final present = records.where((r) => r.status == 'present').length;
        final absent = records.where((r) => r.status == 'absent').length;
        final late = records.where((r) => r.status == 'late').length;
        final permission = records.where((r) => r.status == 'permission').length;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
              child: student.photoUrl == null ? const Icon(Icons.person, size: 28) : null,
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ጠቅላላ መረጃ: ${records.length}', style: Theme.of(context).textTheme.bodySmall),
            trailing: Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.end, children: [
              if (present > 0) Chip(avatar: Icon(Icons.check, color: Colors.green, size: 16), label: Text('$present'), padding: const EdgeInsets.symmetric(horizontal: 4)),
              if (absent > 0) Chip(avatar: Icon(Icons.close, color: Colors.red, size: 16), label: Text('$absent'), padding: const EdgeInsets.symmetric(horizontal: 4)),
              if (late > 0) Chip(avatar: Icon(Icons.schedule, color: Colors.orange, size: 16), label: Text('$late'), padding: const EdgeInsets.symmetric(horizontal: 4)),
              if (permission > 0) Chip(avatar: Icon(Icons.assignment, color: Colors.blue, size: 16), label: Text('$permission'), padding: const EdgeInsets.symmetric(horizontal: 4)),
              const Icon(Icons.keyboard_arrow_down),
            ]),
            children: records.isEmpty ? [const ListTile(title: Center(child: Text('ምንም የክትትል መረጃ አልተገኘም')))] : records.map((record) => _buildAttendanceRecordTile(record)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRecordTile(AttendanceRecord record) {
    final Map<String, dynamic> statusInfo = {
      'present': {'text': 'ተገኝቷል', 'color': Colors.green, 'icon': Icons.check_circle},
      'absent': {'text': 'ቀሪ', 'color': Colors.red, 'icon': Icons.cancel},
      'late': {'text': 'ዘግይቷል', 'color': Colors.orange, 'icon': Icons.schedule},
      'permission': {'text': 'በፍቃድ', 'color': Colors.blue, 'icon': Icons.assignment_turned_in},
    };
    final info = statusInfo[record.status] ?? {'text': record.status, 'color': Colors.grey, 'icon': Icons.help};
    
    String ethiopianDateString = record.date; // Fallback
    try {
      final parts = record.date.split('-');
      if (parts.length == 3) {
        final etYear = int.parse(parts[0]);
        final etMonth = int.parse(parts[1]);
        final etDay = int.parse(parts[2]);
        ethiopianDateString = EthiopianDate(year: etYear, month: etMonth, day: etDay).toString();
      }
    } catch(e) {/* ignore parse error, use fallback */}

    return Container(
      color: Theme.of(context).splashColor.withOpacity(0.03),
      child: ListTile(
        title: Row(
          children: [
            Icon(info['icon'], color: info['color'], size: 20),
            const SizedBox(width: 8),
            Text(info['text'], style: TextStyle(color: info['color'], fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              '${record.session == 'morning' ? 'ጥዋት' : 'ከሰዓት'} - $ethiopianDateString',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        subtitle: record.topic != null && record.topic!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('የዕለቱ ርዕስ: ${record.topic}', style: const TextStyle(fontStyle: FontStyle.italic)),
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isWide) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: isWide ? _buildWideShimmer() : _buildMobileShimmer(),
    );
  }

  Widget _buildMobileShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(height: 40, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 16),
                Container(height: 56, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 16),
                Container(height: 56, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              children: List.generate(5, (_) => Card(child: Container(width: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))))),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideShimmer() {
    return Row(
      children: [
        SizedBox(
          width: 350,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(height: 40, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 16),
                Container(height: 56, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 16),
                Container(height: 56, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (_) => Card(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))))),
                )
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Container(height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        )
      ],
    );
  }
}

extension StudentParsing on Student {
  static Student fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['full_name'] as String,
      group: map['kifil'] as String?,
      photoUrl: map['avatar_url'] as String?,
    );
  }
}

// ===============================================================
// COPIED FROM YOUR WORKING FILE: OUR CUSTOM DATE PICKER DIALOG WIDGET
// ===============================================================

class EthiopianDatePickerDialog extends StatefulWidget {
  final EthiopianDate initialDate;
  final String? title;
  const EthiopianDatePickerDialog({super.key, required this.initialDate, this.title});

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
      title: Text(widget.title ?? 'ቀን ይምረጡ', textAlign: TextAlign.center),
      content: SizedBox(
        width: 300, // Constrain width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeYear(-1)),
                Text('$_selectedYear ዓ.ም.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeYear(1)),
              ],
            ),
            const Divider(),
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
                    final newDaysInMonth = EthiopianDate(year: _selectedYear, month: _selectedMonth, day: 1).daysInMonth;
                    if (_selectedDay > newDaysInMonth) {
                      _selectedDay = newDaysInMonth;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
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