import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

// --- NEW: Import our reliable, self-contained utility ---


// --- UI Theme Constants ---
const Color kBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kPrimaryAccentColor = Color(0xFFFFD700);
const Color kSecondaryTextColor = Color(0xFFFFD700);

// --- Models ---
class StudentDetails {
  final Map<String, dynamic> profile;
  final List<dynamic> allGrades;
  final List<dynamic> allAttendance;
  final List<dynamic> readingList;

  StudentDetails({ required this.profile, required this.allGrades, required this.allAttendance, required this.readingList});

  factory StudentDetails.fromMap(Map<String, dynamic> map) {
    return StudentDetails(
      profile: map['profile_data'] ?? {},
      allGrades: map['all_grades'] ?? [],
      allAttendance: map['all_attendance'] ?? [],
      readingList: map['reading_list'] ?? [],
    );
  }
}

class DailyAttendance {
  final DateTime date;
  Map<String, dynamic> morning;
  Map<String, dynamic> afternoon;
  DailyAttendance({required this.date, required this.morning, required this.afternoon});
}

// --- ENUM FOR FILTERING ---
enum DateFilter { week, month, year, custom }

class FamilyStudentDetailScreen extends StatefulWidget {
  final String studentId;
  const FamilyStudentDetailScreen({super.key, required this.studentId});

  @override
  State<FamilyStudentDetailScreen> createState() =>
      _FamilyStudentDetailScreenState();
}

class _FamilyStudentDetailScreenState extends State<FamilyStudentDetailScreen> {
  late Future<StudentDetails?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchStudentDetails();
  }

  Future<StudentDetails?> _fetchStudentDetails() async {
    try {
      final response = await supabase.rpc('get_family_student_profile_details',
          params: {'p_student_id': widget.studentId}).single();
      debugPrint('Supabase Response: $response');
      return StudentDetails.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching student details: $e');
      throw 'የተማሪውን ዝርዝር መረጃ መጫን አልተሳካም።';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FutureBuilder<StudentDetails?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _DetailShimmer();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
                child: Text('ዝርዝር መረጃን መጫን አልተሳካም',
                    style: GoogleFonts.notoSansEthiopic(color: Colors.white)));
          }

          final details = snapshot.data!;
          return CustomScrollView(
            slivers: [
              _buildAppBar(details.profile),
              SliverList(
                delegate: SliverChildListDelegate([
                  _GradesSection(grades: details.allGrades),
                  _buildSection(
                    title: "የንባብ ጉዞ",
                    icon: Icons.book_outlined,
                    child: _ReadingSection(readingList: details.readingList),
                  ),
                  _buildSection(
                    title: "የክትትል ታሪክ",
                    icon: Icons.event_available_outlined,
                    child:
                        _AttendanceSection(attendance: details.allAttendance),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> profile) {
    final imageUrl = profile['avatar_url'];
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      backgroundColor: kBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(profile['full_name'] ?? 'No Name',
            style: GoogleFonts.notoSansEthiopic(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
        titlePadding:
            const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: kCardColor)),
            if (!hasImage) Container(color: kCardColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kBackgroundColor,
                    kBackgroundColor.withOpacity(0.5),
                    Colors.transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required IconData icon, required Widget child}) {
    return FadeInUp(
      from: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kPrimaryAccentColor, size: 22),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(title,
                      style: GoogleFonts.notoSansEthiopic(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _GradesSection extends StatefulWidget {
  final List<dynamic> grades;
  const _GradesSection({required this.grades});

  @override
  State<_GradesSection> createState() => _GradesSectionState();
}

class _GradesSectionState extends State<_GradesSection> {
  late List<dynamic> _allGrades;
  List<String> _availableYearAndClasses = [];
  String? _selectedYearAndClass;
  List<dynamic> _filteredGrades = [];

  @override
  void initState() {
    super.initState();
    _allGrades = widget.grades;
    _processGradesAndYears(_allGrades);
  }

  void _processGradesAndYears(List<dynamic>? allGrades) {
    if (!mounted || allGrades == null || allGrades.isEmpty) {
      setState(() {
        _availableYearAndClasses = [];
        _selectedYearAndClass = null;
        _filteredGrades = [];
      });
      return;
    }
    final Set<String> yearAndClassCombinations = allGrades
        .where((grade) =>
            grade['academic_year'] != null && grade['spiritual_class'] != null)
        .map((grade) {
      final year = grade['academic_year'];
      final spiritualClass = grade['spiritual_class'];
      return '$spiritualClass - $year';
    }).toSet();

    final List<String> sortedCombinations = yearAndClassCombinations.toList();
    sortedCombinations.sort((a, b) {
      final yearA = int.tryParse(a.split(' - ').last) ?? 0;
      final yearB = int.tryParse(b.split(' - ').last) ?? 0;
      if (yearA != yearB) return yearB.compareTo(yearA);
      final classA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final classB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return classA.compareTo(classB);
    });

    setState(() {
      _availableYearAndClasses = sortedCombinations;
      _selectedYearAndClass =
          sortedCombinations.isNotEmpty ? sortedCombinations.first : null;
      _updateFilteredGrades();
    });
  }

  void _updateFilteredGrades() {
    if (_selectedYearAndClass == null) {
      setState(() => _filteredGrades =
          _availableYearAndClasses.isEmpty ? _allGrades : []);
      return;
    }
    final parts = _selectedYearAndClass!.split(' - ');
    final selectedClass = parts[0];
    final selectedYear = int.tryParse(parts[1]);
    setState(() {
      _filteredGrades = _allGrades.where((g) {
        return g['spiritual_class'] == selectedClass &&
            g['academic_year'] == selectedYear;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      from: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined,
                    color: kPrimaryAccentColor, size: 22),
                const SizedBox(width: 12),
                Flexible(
                  child: Text("የትምህርት አፈጻጸም",
                      style: GoogleFonts.notoSansEthiopic(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                if (_availableYearAndClasses.length > 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedYearAndClass,
                        isExpanded: true,
                        items: _availableYearAndClasses
                            .map((yearAndClass) => DropdownMenuItem(
                                value: yearAndClass,
                                child: Text(yearAndClass,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedYearAndClass = newValue;
                            _updateFilteredGrades();
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kCardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style:
                            GoogleFonts.notoSansEthiopic(color: Colors.white),
                        dropdownColor: kCardColor,
                        iconEnabledColor: kPrimaryAccentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGradesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesList() {
    if (_allGrades.isEmpty) {
      return _EmptyCard(message: "ምንም ውጤቶች እስካሁን አልተመዘገቡም");
    }
    if (_filteredGrades.isEmpty && _availableYearAndClasses.isNotEmpty) {
      return _EmptyCard(message: "በተመረጠው ጊዜ ውስጥ ምንም ውጤቶች አልተገኙም");
    }
    return Card(
      color: kCardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredGrades.length,
        itemBuilder: (context, index) =>
            _buildGradeItem(_filteredGrades[index]),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.white12),
      ),
    );
  }

  Widget _buildGradeItem(Map<String, dynamic> grade) {
    final int total = ((grade['mid_exam'] ?? 0) as num).toInt() +
        ((grade['final_exam'] ?? 0) as num).toInt() +
        ((grade['assignment'] ?? 0) as num).toInt();
    final status = total >= 50 ? 'አልፏል' : 'ወድቋል';
    final statusColor =
        status == 'አልፏል' ? Colors.green.shade400 : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(grade['course_name'] ?? 'N/A',
                      style: GoogleFonts.notoSansEthiopic(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(status,
                    style: GoogleFonts.notoSansEthiopic(
                        fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGradeScore('ሚድ', (grade['mid_exam'] ?? 0).toString()),
              _buildGradeScore('ፍጻሜ', (grade['final_exam'] ?? 0).toString()),
              _buildGradeScore('አሳይመንት', (grade['assignment'] ?? 0).toString()),
              _buildGradeScore('ጠቅላላ', total.toString(), isTotal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeScore(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.notoSansEthiopic(
                fontSize: 12, color: kSecondaryTextColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.notoSansEthiopic(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? kPrimaryAccentColor : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ReadingSection extends StatelessWidget {
  final List<dynamic> readingList;
  const _ReadingSection({required this.readingList});

  @override
  Widget build(BuildContext context) {
    if (readingList.isEmpty) {
      return _EmptyCard(message: "ምንም የተመደቡ መጽሐፍት የሉም");
    }

    final toReadBooks =
        readingList.where((b) => b['status'] == 'to_read').toList();
    final readBooks = readingList.where((b) => b['status'] == 'read').toList();

    return Card(
      color: kCardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: kCardColor.withOpacity(0.5),
              child: TabBar(
                tabs: [
                  Tab(
                      child: Text('ለማንበብ (${toReadBooks.length})',
                          style: GoogleFonts.notoSansEthiopic())),
                  Tab(
                      child: Text('የተጠናቀቁ (${readBooks.length})',
                          style: GoogleFonts.notoSansEthiopic())),
                ],
                labelColor: kPrimaryAccentColor,
                unselectedLabelColor: kSecondaryTextColor,
                indicatorColor: kPrimaryAccentColor,
              ),
            ),
            SizedBox(
              height: 250,
              child: TabBarView(
                children: [
                  _BookList(books: toReadBooks, isCompletable: true),
                  _BookList(books: readBooks, isCompletable: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<dynamic> books;
  final bool isCompletable;
  const _BookList({required this.books, required this.isCompletable});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            isCompletable
                ? 'በዝርዝሩ ላይ ምንም መጽሐፍ የለም!'
                : 'እስካሁን የተጠናቀቁ መጻሕፍት የሉም።',
            style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(
          height: 1, indent: 16, endIndent: 16, color: Colors.white12),
      itemBuilder: (context, index) =>
          _BookListTile(book: books[index], isCompletable: isCompletable),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final Map<String, dynamic> book;
  final bool isCompletable;
  const _BookListTile({required this.book, required this.isCompletable});

  @override
  Widget build(BuildContext context) {
    final finishByStr = book['finish_by'] as String?;
    DateTime? finishByDate;
    bool isOverdue = false;
    if (finishByStr != null) {
      finishByDate = DateTime.tryParse(finishByStr);
      if (finishByDate != null) {
        isOverdue = finishByDate.isBefore(DateTime.now()) && isCompletable;
      }
    }

    final readAtStr = book['read_at'] as String?;
    String completedText = 'ተጠናቋል';
    if (readAtStr != null) {
      try {
        completedText =
            'የተጠናቀቀው በ: ${DateFormat.yMMMd().format(DateTime.parse(readAtStr).toLocal())}';
      } catch (_) {}
    }

    return ListTile(
      leading: Icon(
        isCompletable
            ? (isOverdue ? Icons.warning_amber_rounded : Icons.book_outlined)
            : Icons.check_circle_outline_rounded,
        color: isCompletable
            ? (isOverdue ? Colors.orange.shade600 : kPrimaryAccentColor)
            : Colors.green.shade400,
      ),
      title: Text(book['book_title'] ?? 'ርዕስ የሌለው መጽሐፍ',
          style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
      subtitle: Text(
        isCompletable
            ? (finishByDate != null
                ? 'የመጨረሻ ቀን: ${DateFormat.yMMMd().format(finishByDate)}'
                : 'የመጨረሻ ቀን የለውም')
            : completedText,
        style: GoogleFonts.notoSansEthiopic(
          color: isOverdue ? Colors.red.shade400 : kSecondaryTextColor,
          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AttendanceSection extends StatefulWidget {
  final List<dynamic> attendance;
  const _AttendanceSection({required this.attendance});

  @override
  State<_AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends State<_AttendanceSection> {
  DateFilter _selectedFilter = DateFilter.month;
  DateTimeRange? _customDateRange;
  List<DailyAttendance> _filteredAttendance = [];

  @override
  void initState() {
    super.initState();
    _filterAttendanceData();
  }

  // --- THIS IS THE PERMANENT FIX ---
  void _filterAttendanceData() {
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

    final Map<DateTime, DailyAttendance> groupedByDate = {};
    for (var record in widget.attendance) {
      try {
        final dateString = record['date'] as String?;
        if (dateString == null) continue;

        // 1. Parse the Ethiopian date string into components
        final parts = dateString.split('-');
        if (parts.length != 3) continue;
        
        final etYear = int.tryParse(parts[0]);
        final etMonth = int.tryParse(parts[1]);
        final etDay = int.tryParse(parts[2]);

        if (etYear == null || etMonth == null || etDay == null) continue;

        // 2. Convert the Ethiopian components to a true Gregorian DateTime
        final date = EthiopianDate(year: etYear, month: etMonth, day: etDay).toGregorian();

        // 3. The rest of the logic now works correctly
        final recordDate = DateTime(date.year, date.month, date.day);
        final startDate = DateTime(range.start.year, range.start.month, range.start.day);
        final endDate = DateTime(range.end.year, range.end.month, range.end.day);

        if (!recordDate.isBefore(startDate) && !recordDate.isAfter(endDate)) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          final session = record['session'];

          if (!groupedByDate.containsKey(dateOnly)) {
            groupedByDate[dateOnly] = DailyAttendance(date: dateOnly, morning: {}, afternoon: {});
          }

          if (session == 'morning') {
            groupedByDate[dateOnly]!.morning = record;
          } else if (session == 'afternoon') {
            groupedByDate[dateOnly]!.afternoon = record;
          }
        }
      } catch (e) {
        debugPrint("Could not process attendance record: $record. Error: $e");
      }
    }

    final sortedDays = groupedByDate.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _filteredAttendance = sortedDays;
    });
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = DateFilter.custom;
      });
      _filterAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attendance.isEmpty) {
      return _EmptyCard(message: "ምንም የክትትል መረጃ የለም");
    }

    return Column(
      children: [
        _buildFilterChips(),
        const SizedBox(height: 16),
        if (_filteredAttendance.isEmpty)
          _EmptyCard(message: "በተመረጠው ጊዜ ውስጥ ምንም መረጃ አልተገኘም")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredAttendance.length,
            itemBuilder: (context, index) {
              final day = _filteredAttendance[index];
              return FadeInUp(
                from: 20,
                delay: Duration(milliseconds: 50 * index),
                child: _AttendanceDayCard(day: day),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<DateFilter>(
        segments: [
          ButtonSegment(
              value: DateFilter.week,
              label: Text('ሳምንት', style: GoogleFonts.notoSansEthiopic())),
          ButtonSegment(
              value: DateFilter.month,
              label: Text('ወር', style: GoogleFonts.notoSansEthiopic())),
          ButtonSegment(
              value: DateFilter.year,
              label: Text('ዓመት', style: GoogleFonts.notoSansEthiopic())),
          ButtonSegment(
            value: DateFilter.custom,
            icon: const Icon(Icons.calendar_month_outlined),
            label: _selectedFilter == DateFilter.custom
                ? Text('ልዩ', style: GoogleFonts.notoSansEthiopic())
                : null,
          ),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (newSelection) {
          if (newSelection.first == DateFilter.custom) {
            _selectCustomDateRange();
          } else {
            setState(() {
              _selectedFilter = newSelection.first;
              _customDateRange =
                  null;
            });
            _filterAttendanceData();
          }
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: kCardColor,
          foregroundColor: kSecondaryTextColor,
          selectedForegroundColor: kPrimaryAccentColor,
          selectedBackgroundColor: kBackgroundColor,
        ),
      ),
    );
  }
}

class _AttendanceDayCard extends StatelessWidget {
  final DailyAttendance day;
  const _AttendanceDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    // This display logic is now correct because _filterAttendanceData provides a valid Gregorian date.
    final String ethiopianDateString = EthiopianDate.fromGregorian(day.date).toString();
    
    final gregorianDate = DateFormat.yMMMEd().format(day.date);
    final topic = day.morning['topic'] as String?;

    return Card(
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$ethiopianDateString ($gregorianDate)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            if (topic != null && topic.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("ርዕስ: $topic",
                    style: GoogleFonts.notoSansEthiopic(
                        color: kSecondaryTextColor)),
              ),
            const Divider(height: 24, color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SessionStatus(label: 'ጥዋት', record: day.morning),
                _SessionStatus(label: 'ከሰዓት', record: day.afternoon),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SessionStatus extends StatelessWidget {
  final String label;
  final Map<String, dynamic> record;
  const _SessionStatus({required this.label, required this.record});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green.shade400;
      case 'absent': return Colors.red.shade400;
      case 'late': return Colors.orange.shade400;
      case 'permission': return Colors.blue.shade400;
      default: return kSecondaryTextColor;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present': return 'ተገኝቷል';
      case 'absent': return 'ቀርቷል';
      case 'late': return 'አርፍዷል';
      case 'permission': return 'በፍቃድ';
      default: return 'N/A';
    }
  }

  String? _formatLateTime(BuildContext context, String? lateTimeStr) {
    if (lateTimeStr == null) return null;
    try {
      final parts = lateTimeStr.split(':');
      final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      return time.format(context);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? 'unknown';
    final lateTime = record['late_time'] as String?;
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    final formattedLateTime = _formatLateTime(context, lateTime);

    return Column(
      children: [
        Text(label,
            style: GoogleFonts.notoSansEthiopic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        Chip(
          label: Text(text,
              style: GoogleFonts.notoSansEthiopic(
                  color: color, fontWeight: FontWeight.bold)),
          backgroundColor: color.withOpacity(0.2),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        if (status == 'late' && formattedLateTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              formattedLateTime,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor)),
        ),
      ),
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kCardColor,
      highlightColor: kBackgroundColor.withOpacity(0.5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(height: 250, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: List.generate(
                    3,
                    (index) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Container(
                                height: 24,
                                width: 200,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8))),
                            const SizedBox(height: 16),
                            Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12))),
                          ],
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}