import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart'; // Your date utility
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

// --- YOUR BRANDING COLORS ---
const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
const Color accentColor = Color(0xFFFFD700);
const Color kCardColor =Color.fromARGB(255, 1, 37, 100);
const Color kAdminSecondaryText = Color(0xFFFFD700);

// --- MODELS ---
class StudentDetail {
  final String id;
  final String fullName;
  final String? profileImageUrl, vision, agelgilotKifil, kifil, spiritualClass;
  final String? yesraDirisha, budin, phoneNumber, birthday, academicClass, role, department;
  final bool isVerified;
  final int? age;
  final double totalStars;

  StudentDetail({
    required this.id, required this.fullName, this.profileImageUrl, this.vision,
    this.agelgilotKifil, this.kifil, this.spiritualClass, this.yesraDirisha,
    this.budin, this.phoneNumber, this.birthday, this.academicClass,
    this.role, required this.isVerified, this.department, this.age,
    required this.totalStars,
  });

  factory StudentDetail.fromMap(Map<String, dynamic> map) {
    return StudentDetail(
      id: map['id'], fullName: map['full_name'] ?? 'ስም የለም', profileImageUrl: map['profile_image_url'],
      vision: map['vision'], agelgilotKifil: map['agelgilot_kifil'], kifil: map['kifil'],
      spiritualClass: map['spiritual_class'], yesraDirisha: map['yesra_dirisha'], budin: map['budin'],
      phoneNumber: map['phone_number'], birthday: map['birthday'], academicClass: map['academic_class'],
      role: map['role'], isVerified: map['is_verified'] ?? false, department: map['department'], age: map['age'],
      totalStars: (map['total_stars'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AttendanceRecord {
  final String date;
  final String session;
  final String status;
  final String? lateTime;
  final String? topic;

  AttendanceRecord({required this.date, required this.session, required this.status, this.lateTime, this.topic});

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      date: map['date'] ?? '', session: map['session'] ?? '', status: map['status'] ?? 'unknown',
      lateTime: map['late_time'], topic: map['topic'],
    );
  }
}
// --- END MODELS ---


class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});
  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late Future<List<StudentDetail>> _studentsFuture;
  final _searchController = TextEditingController();
  List<StudentDetail> _allStudents = [];
  List<StudentDetail> _filteredStudents = [];

  String? _selectedKifil;
  String? _selectedBudin;
  String? _selectedAgelgilotKifil;
  String? _selectedStarRangeKey; // Use String to represent the range key

  List<String> _kifilOptions = [];
  List<String> _budinOptions = [];
  List<String> _agelgilotKifilOptions = [];
  
  final Map<String, List<double>> starRanges = {
    '0-1 ★': [0.0, 1.0],
    '1-2 ★': [1.01, 2.0],
    '2-3 ★': [2.01, 3.0],
    '3-4 ★': [3.01, 4.0],
    '4-5 ★': [4.01, 5.0],
  };

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudents();
    _searchController.addListener(_performFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<StudentDetail>> _fetchStudents() async {
    try {
      final response = await supabase.rpc('get_all_student_details_for_list_v2');
      final students = (response as List).map((data) => StudentDetail.fromMap(data)).toList();
      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _populateDropdowns(students);
        });
      }
      return students;
    } catch (e) {
      debugPrint('Error fetching student list: $e');
      throw 'የተማሪዎችን ዝርዝር መጫን አልተሳካም።';
    }
  }

  void _populateDropdowns(List<StudentDetail> students) {
    setState(() {
      _kifilOptions = students.map((s) => s.kifil).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()..sort();
      _budinOptions = students.map((s) => s.budin).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()..sort();
      _agelgilotKifilOptions = students.map((s) => s.agelgilotKifil).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()..sort();
    });
  }

  void _performFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = student.fullName.toLowerCase();
        final phone = student.phoneNumber?.toLowerCase() ?? '';
        final matchesSearch = name.contains(query) || phone.contains(query);
        final matchesKifil = _selectedKifil == null || student.kifil == _selectedKifil;
        final matchesBudin = _selectedBudin == null || student.budin == _selectedBudin;
        final matchesAgelgilot = _selectedAgelgilotKifil == null || student.agelgilotKifil == _selectedAgelgilotKifil;
        
        bool matchesStars = true;
        if (_selectedStarRangeKey != null) {
          final range = starRanges[_selectedStarRangeKey]!;
          matchesStars = student.totalStars >= range[0] && student.totalStars <= range[1];
        }

        return matchesSearch && matchesKifil && matchesBudin && matchesAgelgilot && matchesStars;
      }).toList();
    });
  }

  void _showStudentDetailsDialog(BuildContext context, StudentDetail student) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return FadeIn(
          duration: const Duration(milliseconds: 300),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ListView(
                          padding: const EdgeInsets.all(24.0),
                          children: [
                            _buildDialogHeader(student),
                            const SizedBox(height: 24),
                            _buildDetailSection("የግል መረጃ", [
                              _buildDetailRow(Icons.person_outline, "ሙሉ ስም", student.fullName),
                              _buildDetailRow(Icons.cake_outlined, "ዕድሜ", student.age != null ? "${student.age} ዓመት" : "አልተሞላም"),
                              _buildDetailRow(Icons.phone_outlined, "ስልክ ቁጥር", student.phoneNumber),
                              _buildDetailRow(Icons.school_outlined, "የትምህርት ደረጃ", student.academicClass),
                              _buildDetailRow(Icons.visibility_outlined, "ራዕይ", student.vision, isLongText: true),
                            ]),
                            const SizedBox(height: 24),
                            _buildDetailSection("የማኅበር ምድብ", [
                              _buildDetailRow(Icons.group_work_outlined, "ክፍል", student.kifil),
                              _buildDetailRow(Icons.class_outlined, "መንፈሳዊ ክፍል", student.spiritualClass),
                              _buildDetailRow(Icons.work_outline_rounded, "የስራ ድርሻ", student.yesraDirisha),
                              _buildDetailRow(Icons.diversity_3_rounded, "ልዩ ኅብረት (ቡድን)", student.budin),
                              _buildDetailRow(Icons.volunteer_activism_outlined, "የአገልግሎት ክፍል", student.agelgilotKifil),
                              _buildDetailRow(Icons.business_outlined, "ዋና ቡድን", student.department),
                            ]),
                            const SizedBox(height: 24),
                            _buildDetailSection("የአካውንት ሁኔታ", [
                              _buildDetailRow(Icons.shield_outlined, "ሚና", student.role),
                              _buildDetailRow(Icons.verified_user_outlined, "የተረጋገጠ", student.isVerified ? "አዎ" : "አይደለም",
                              highlightColor: student.isVerified ? Colors.green.shade300 : Colors.orange.shade300),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showAttendanceDetailsSheet(context, student.id, student.fullName);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: _buildDetailRow(Icons.event_note_outlined, "የክትትል ታሪክ", "ሙሉ መረጃ ለማየት ይጫኑ", highlightColor: accentColor),
                              )
                            ]),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: kAdminSecondaryText),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 20,
                          tooltip: 'Close',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttendanceDetailsSheet(BuildContext context, String studentId, String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttendanceDetailsSheet(studentId: studentId, studentName: studentName),
    );
  }
  
  Widget _buildDialogHeader(StudentDetail student) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50, backgroundColor: accentColor.withOpacity(0.1),
          backgroundImage: student.profileImageUrl != null ? NetworkImage(student.profileImageUrl!) : null,
          child: student.profileImageUrl == null ? Text(student.fullName[0], style: const TextStyle(fontSize: 40, color: accentColor, fontWeight: FontWeight.bold)) : null,
        ),
        const SizedBox(height: 16),
        Text(student.fullName, style: GoogleFonts.notoSansEthiopic(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Chip(
          avatar: Icon(Icons.star, color: Colors.amber.shade300, size: 18),
          label: Text(student.totalStars.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.amber.withOpacity(0.2),
          shape: StadiumBorder(side: BorderSide(color: Colors.amber.withOpacity(0.4))),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.notoSansEthiopic(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF2a2a45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: children)),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value, {bool isLongText = false, Color? highlightColor}) {
    final displayValue = (value == null || value.isEmpty) ? "አልተሞላም" : value;
    final displayColor = (value == null || value.isEmpty) ? kAdminSecondaryText.withOpacity(0.5) : highlightColor ?? Colors.white;
    Widget valueWidget = Text(displayValue, style: GoogleFonts.notoSansEthiopic(fontSize: 15, fontWeight: FontWeight.w500, color: displayColor), textAlign: isLongText ? TextAlign.start : TextAlign.end);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: kAdminSecondaryText, size: 20),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.notoSansEthiopic(fontSize: 15, color: kAdminSecondaryText)),
          const SizedBox(width: 16),
          Expanded(child: isLongText ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [valueWidget]) : valueWidget),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1c1c2e),
      appBar: AppBar(
        title: Text('የተማሪዎች ዝርዝር', style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: const Color(0xFF1c1c2e),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'በስም ወይም በስልክ ቁጥር ይፈልጉ...',
                hintStyle: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText),
                prefixIcon: const Icon(Icons.search, color: kAdminSecondaryText),
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(child: _buildDropdown(_selectedKifil, _kifilOptions, (val) => setState(() { _selectedKifil = val; _performFilter(); }), 'ክፍል')),
                    const SizedBox(width: 12),
                    Flexible(child: _buildDropdown(_selectedBudin, _budinOptions, (val) => setState(() { _selectedBudin = val; _performFilter(); }), 'ልዩ ኅብረት')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStarDropdown(),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StudentDetail>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingShimmer();
                if (snapshot.hasError) return Center(child: Text(snapshot.error.toString(), style: GoogleFonts.notoSansEthiopic(color: Colors.redAccent)));
                if (_filteredStudents.isEmpty) return Center(child: Text('ምንም ተማሪ አልተገኘም', style: GoogleFonts.notoSansEthiopic()));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    return FadeInUp(
                      from: 20, delay: Duration(milliseconds: index * 40),
                      child: Card(
                        color: kCardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _showStudentDetailsDialog(context, student),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: accentColor.withOpacity(0.2),
                            backgroundImage: student.profileImageUrl != null ? NetworkImage(student.profileImageUrl!) : null,
                            child: student.profileImageUrl == null ? Text(student.fullName[0], style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold)) : null,
                          ),
                          title: Text(student.fullName, style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600, color: Colors.white)),
                          subtitle: Text('ክፍል: ${student.kifil ?? 'የለም'}', style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText, fontSize: 12)),
                          trailing: Chip(
                            avatar: const Icon(Icons.star, color: accentColor, size: 16),
                            label: Text(student.totalStars.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: kCardColor,
                            side: BorderSide(color: accentColor.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String? value, List<String> items, ValueChanged<String?> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: value, isExpanded: true,
      hint: Text(label, style: GoogleFonts.notoSansEthiopic(fontSize: 14, color: kAdminSecondaryText)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true, fillColor: kCardColor,
      ),
      dropdownColor: kCardColor, iconEnabledColor: accentColor,
      style: GoogleFonts.notoSansEthiopic(color: Colors.white),
      items: [
        DropdownMenuItem(value: null, child: Text("ሁሉም", style: GoogleFonts.notoSansEthiopic())),
        ...items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.notoSansEthiopic(), overflow: TextOverflow.ellipsis)))
      ],
      onChanged: onChanged,
    );
  }
  
  Widget _buildStarDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStarRangeKey,
      hint: Text("በኮከብ ደረጃ", style: GoogleFonts.notoSansEthiopic(fontSize: 14, color: kAdminSecondaryText)),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.star, color: kAdminSecondaryText, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true, fillColor: kCardColor,
      ),
      dropdownColor: kCardColor,
      iconEnabledColor: accentColor,
      style: GoogleFonts.notoSansEthiopic(color: Colors.white),
      items: [
        DropdownMenuItem(value: null, child: Text("ሁሉም", style: GoogleFonts.notoSansEthiopic())),
        ...starRanges.keys.map((key) => DropdownMenuItem(value: key, child: Text(key, style: GoogleFonts.notoSansEthiopic()))),
      ],
      onChanged: (val) {
        setState(() {
          _selectedStarRangeKey = val;
          _performFilter();
        });
      },
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kCardColor,
      highlightColor: const Color(0xFF1c1c2e),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: const CircleAvatar(),
            title: Container(height: 16, width: 150, color: Colors.white),
            subtitle: Container(height: 12, width: 100, color: Colors.white, margin: const EdgeInsets.only(top: 8)),
          ),
        ),
      ),
    );
  }
}

enum DateFilter { week, month, year, custom }

class _AttendanceDetailsSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  const _AttendanceDetailsSheet({required this.studentId, required this.studentName});

  @override
  State<_AttendanceDetailsSheet> createState() => _AttendanceDetailsSheetState();
}

class _AttendanceDetailsSheetState extends State<_AttendanceDetailsSheet> {
  Future<List<AttendanceRecord>>? _attendanceFuture;
  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> _filteredRecords = [];

  DateFilter _selectedFilter = DateFilter.month;
  DateTimeRange? _customDateRange;
  
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  int _permissionCount = 0;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _fetchAttendance();
  }

  Future<List<AttendanceRecord>> _fetchAttendance() async {
    try {
      final response = await supabase.rpc('get_student_attendance_details', params: {'p_student_id': widget.studentId});
      final records = (response as List).map((data) => AttendanceRecord.fromMap(data)).toList();
      if(mounted) {
        setState(() {
          _allRecords = records;
          _filterAndSummarizeAttendance();
        });
      }
      return records;
    } catch (e) {
      debugPrint("Error fetching attendance details: $e");
      throw "የክትትል መረጃን መጫን አልተቻለም";
    }
  }

  void _filterAndSummarizeAttendance() {
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

    final List<AttendanceRecord> currentlyFiltered = [];
    for (var record in _allRecords) {
       try {
        final parts = record.date.split('-');
        if (parts.length != 3) continue;
        final etYear = int.parse(parts[0]);
        final etMonth = int.parse(parts[1]);
        final etDay = int.parse(parts[2]);
        final gregorianDate = EthiopianDate(year: etYear, month: etMonth, day: etDay).toGregorian();

        final recordDate = DateTime(gregorianDate.year, gregorianDate.month, gregorianDate.day);
        final startDate = DateTime(range.start.year, range.start.month, range.start.day);
        final endDate = DateTime(range.end.year, range.end.month, range.end.day);

        if (!recordDate.isBefore(startDate) && !recordDate.isAfter(endDate)) {
          currentlyFiltered.add(record);
        }
      } catch (e) {/* ignore */}
    }
    
    int present = 0, absent = 0, late = 0, permission = 0;
    for (var record in currentlyFiltered) {
      switch(record.status) {
        case 'present': present++; break;
        case 'absent': absent++; break;
        case 'late': late++; break;
        case 'permission': permission++; break;
      }
    }

    setState(() {
      _filteredRecords = currentlyFiltered;
      _presentCount = present;
      _absentCount = absent;
      _lateCount = late;
      _permissionCount = permission;
    });
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = DateFilter.custom;
        _filterAndSummarizeAttendance();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green.shade300;
      case 'absent': return Colors.red.shade300;
      case 'late': return Colors.orange.shade300;
      case 'permission': return Colors.blue.shade300;
      default: return kAdminSecondaryText;
    }
  }

  IconData _getStatusIcon(String status) {
     switch (status) {
      case 'present': return Icons.check_circle_outline;
      case 'absent': return Icons.highlight_off_outlined;
      case 'late': return Icons.schedule_outlined;
      case 'permission': return Icons.assignment_turned_in_outlined;
      default: return Icons.help_outline;
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

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Container(
        decoration: const BoxDecoration(color: primaryColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 56, 16),
                  child: Text(
                    "${widget.studentName}\nየክትትል ታሪክ",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(fontSize: 20, color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SegmentedButton<DateFilter>(
                    segments: [
                      ButtonSegment(value: DateFilter.week, label: Text('ሳምንት', style: GoogleFonts.notoSansEthiopic())),
                      ButtonSegment(value: DateFilter.month, label: Text('ወር', style: GoogleFonts.notoSansEthiopic())),
                      ButtonSegment(value: DateFilter.year, label: Text('ዓመት', style: GoogleFonts.notoSansEthiopic())),
                      ButtonSegment(value: DateFilter.custom, icon: const Icon(Icons.calendar_month_outlined)),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (newSelection) {
                      if (newSelection.first == DateFilter.custom) {
                        _selectCustomDateRange();
                      } else {
                        setState(() {
                          _selectedFilter = newSelection.first;
                          _customDateRange = null;
                          _filterAndSummarizeAttendance();
                        });
                      }
                    },
                     style: SegmentedButton.styleFrom(
                      backgroundColor: kCardColor,
                      foregroundColor: kAdminSecondaryText,
                      selectedForegroundColor: accentColor,
                      selectedBackgroundColor: primaryColor,
                      side: const BorderSide(color: kCardColor)
                    ),
                  ),
                ),
                const Divider(color: accentColor, thickness: 0.5, height: 32, indent: 16, endIndent: 16),
                Expanded(
                  child: FutureBuilder<List<AttendanceRecord>>(
                    future: _attendanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && _allRecords.isEmpty) return const Center(child: CircularProgressIndicator(color: accentColor));
                      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString(), style: GoogleFonts.notoSansEthiopic(color: Colors.redAccent)));

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _buildSummaryGrid()),
                          SliverToBoxAdapter(child: const SizedBox(height: 24)),
                          if (_filteredRecords.isEmpty)
                            SliverFillRemaining(child: Center(child: Text("በተመረጠው ጊዜ ውስጥ ምንም መረጃ አልተገኘም", style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText))))
                          else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final record = _filteredRecords[index];
                                return _buildAttendanceRecordCard(record);
                              },
                              childCount: _filteredRecords.length,
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.close, color: kAdminSecondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildSummaryCard(_presentCount, "ተገኝቷል", Icons.check_circle_outline, Colors.green.shade300),
        _buildSummaryCard(_absentCount, "ቀርቷል", Icons.highlight_off_outlined, Colors.red.shade300),
        _buildSummaryCard(_lateCount, "አርፍዷል", Icons.schedule_outlined, Colors.orange.shade300),
        _buildSummaryCard(_permissionCount, "በፍቃድ", Icons.assignment_turned_in_outlined, Colors.blue.shade300),
      ],
    );
  }

  Widget _buildSummaryCard(int count, String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordCard(AttendanceRecord record) {
     final statusColor = _getStatusColor(record.status);
    String ethiopianDateString = record.date;
    String gregorianDateString = '';
    try {
      final parts = record.date.split('-');
      if (parts.length == 3) {
        final etYear = int.parse(parts[0]);
        final etMonth = int.parse(parts[1]);
        final etDay = int.parse(parts[2]);
        final etDate = EthiopianDate(year: etYear, month: etMonth, day: etDay);
        ethiopianDateString = etDate.toString();
        gregorianDateString = DateFormat('EEEE, MMM d, y').format(etDate.toGregorian());
      }
    } catch (e) {/* ignore */}

    return FadeInUp(
      from: 20,
      child: Card(
        color: kCardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_getStatusIcon(record.status), color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getStatusText(record.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(ethiopianDateString, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        Text(gregorianDateString, style: const TextStyle(color: kAdminSecondaryText, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(record.session == 'morning' ? 'ጥዋት' : 'ከሰዓት', style: const TextStyle(color: kAdminSecondaryText, fontSize: 12)),
                ],
              ),
              if (record.topic != null && record.topic!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text("የዕለቱ ርዕስ:", style: TextStyle(color: accentColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       Text(record.topic!, style: const TextStyle(color: kAdminSecondaryText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}