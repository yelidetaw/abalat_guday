import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';
import 'package:amde_haymanot_abalat_guday/attendance_history_screen.dart';
import 'package:intl/intl.dart';

// --- UI Constants ---
const kPrimaryColor = Color(0xFF673AB7);
const kAccentColor = Color(0xFF7C4DFF);
const kBackgroundColor = Color(0xFFF8F8F8);
const kCardColor = Colors.white;
const kTextColor = Color(0xFF333333);
const kSubtleTextColor = Color(0xFF666666);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  List<String> _availableClasses = [];
  String? _selectedClass;
  List<dynamic> _filteredGrades = [];

  List<dynamic> _toReadBooks = [];
  List<dynamic> _readBooks = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "Authentication error. Please sign in again.";

      final profileResponse = await supabase
          .from('profiles')
          .select('*, grades(*), attendance(*), reading_list(*)')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _profileData = profileResponse;
          _processGrades();
          _processReadingList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Failed to fetch profile: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processGrades() {
    if (_profileData == null) return;
    final allGrades = (_profileData!['grades'] as List<dynamic>?) ?? [];
    if (allGrades.isEmpty) {
      _availableClasses = [];
      _selectedClass = null;
      _filteredGrades = [];
      return;
    }
    final classes = allGrades
        .map((g) => g['spiritual_class'])
        .whereType<String>()
        .toSet()
        .toList();
    classes.sort();
    _availableClasses = classes;
    _selectedClass = classes.isNotEmpty ? classes.last : null;
    _updateFilteredGrades();
  }

  void _updateFilteredGrades() {
    if (_selectedClass == null) {
      _filteredGrades = [];
      return;
    }
    final allGrades = (_profileData!['grades'] as List<dynamic>?) ?? [];
    setState(() {
      _filteredGrades = allGrades
          .where((g) => g['spiritual_class'] == _selectedClass)
          .toList();
    });
  }

  void _processReadingList() {
    if (_profileData == null) return;
    final allBooks = (_profileData!['reading_list'] as List<dynamic>?) ?? [];
    allBooks.sort(
      (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
    );
    setState(() {
      _toReadBooks = allBooks.where((b) => b['status'] == 'to_read').toList();
      _readBooks = allBooks.where((b) => b['status'] == 'read').toList();
    });
  }

  Future<void> _markBookAsRead(int bookId) async {
    try {
      await supabase
          .from('reading_list')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookId);
      await _fetchProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }
    if (_error != null) {
      return _ErrorDisplay(
        key: const ValueKey('error'),
        error: _error!,
        onRetry: _fetchProfileData,
      );
    }
    if (_profileData == null) {
      return _ErrorDisplay(
        key: const ValueKey('no_data'),
        error: 'Could not load profile data.',
        onRetry: _fetchProfileData,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProfileData,
      color: kPrimaryColor,
      child: CustomScrollView(
        slivers: [
          _ProfileSliverAppBar(
            profileData: _profileData!,
            onRefresh: _fetchProfileData,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildSectionTitle('About Me'),
                _buildAboutCard(),
                const SizedBox(height: 24),
                _buildAcademicSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Reading Journey'),
                _buildReadingListSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Activity'),
                _buildAttendanceCard(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('Academic Performance'),
            if (_availableClasses.length > 1)
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  items: _availableClasses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedClass = newValue;
                      _updateFilteredGrades();
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: kTextColor),
                ),
              ),
          ],
        ),
        _buildGradesList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
    child: Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTextColor,
      ),
    ),
  );

  Widget _buildStatsRow() => Card(
    elevation: 2,
    shadowColor: kPrimaryColor.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: kCardColor,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Class', _profileData!['academic_class'] ?? 'N/A'),
          _buildStatItem('Kifil', _profileData!['kifil'] ?? 'N/A'),
          _buildStatItem('Age', _profileData!['age']?.toString() ?? 'N/A'),
        ],
      ),
    ),
  );

  Widget _buildStatItem(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, color: kSubtleTextColor),
      ),
    ],
  );

  Widget _buildAboutCard() => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: kCardColor,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAboutItem(
            Icons.phone_outlined,
            'Phone',
            _profileData!['phone_number'] ?? 'Not set',
          ),
          const Divider(height: 24),
          _buildAboutItem(
            Icons.school_outlined,
            'Academic Level',
            _profileData!['academic_class'] ?? 'Not set',
          ),
          const Divider(height: 24),
          _buildAboutItem(
            Icons.volunteer_activism_outlined,
            'Spiritual Class',
            _profileData!['spiritual_class'] ?? 'Not set',
          ),
        ],
      ),
    ),
  );

  Widget _buildAboutItem(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 22, color: kAccentColor),
      const SizedBox(width: 16),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: kTextColor,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: GoogleFonts.poppins(fontSize: 15, color: kSubtleTextColor),
      ),
    ],
  );

  Widget _buildGradesList() {
    if (_filteredGrades.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kCardColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              _availableClasses.isEmpty
                  ? "No grades recorded yet."
                  : "No grades found for $_selectedClass.",
              style: GoogleFonts.poppins(color: kSubtleTextColor),
            ),
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: List.generate(_filteredGrades.length, (index) {
            final grade = _filteredGrades[index];
            final total =
                (grade['mid_exam'] ?? 0) +
                (grade['final_exam'] ?? 0) +
                (grade['assignment'] ?? 0);
            final status = total >= 50 ? 'Pass' : 'Failed';
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          grade['course_name'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Pass'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: status == 'Pass'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semester: ${grade['semester'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kSubtleTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGradeScore(
                        'Mid',
                        (grade['mid_exam'] ?? 0).toString(),
                      ),
                      _buildGradeScore(
                        'Final',
                        (grade['final_exam'] ?? 0).toString(),
                      ),
                      _buildGradeScore(
                        'Assign.',
                        (grade['assignment'] ?? 0).toString(),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: kSubtleTextColor,
                            ),
                          ),
                          Text(
                            total.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (index < _filteredGrades.length - 1)
                    const Divider(height: 24),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGradeScore(String label, String value) => Column(
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, color: kSubtleTextColor),
      ),
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: kTextColor,
        ),
      ),
    ],
  );

  Widget _buildAttendanceCard() {
    final attendance = _profileData?['attendance'] as List<dynamic>? ?? [];
    final presentCount = attendance
        .where((a) => a['status'] == 'present')
        .length;
    final absentCount = attendance.where((a) => a['status'] == 'absent').length;
    final totalDays = attendance.length;
    final attendancePercentage = totalDays > 0
        ? (presentCount / totalDays * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AttendanceHistoryScreen(),
          ),
        ),
        splashColor: kAccentColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kCardColor.withOpacity(0.8),
                kCardColor.withOpacity(0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kAccentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: kAccentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Attendance Summary",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kSubtleTextColor.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAttendanceStat(
                    "Present",
                    presentCount,
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildAttendanceStat(
                    "Absent",
                    absentCount,
                    Icons.cancel,
                    Colors.orange,
                  ),
                  _buildAttendanceStat(
                    "Total",
                    totalDays,
                    Icons.calendar_view_day,
                    kAccentColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: attendancePercentage / 100,
                backgroundColor: Colors.grey[200],
                color: _getPercentageColor(attendancePercentage),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Attendance Rate",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: kSubtleTextColor,
                    ),
                  ),
                  Text(
                    "$attendancePercentage%",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _getPercentageColor(attendancePercentage),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: kSubtleTextColor),
        ),
      ],
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 90) return Colors.green[400]!;
    if (percentage >= 75) return Colors.lightGreen[400]!;
    if (percentage >= 60) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Widget _buildReadingListSection() {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: kPrimaryColor,
              unselectedLabelColor: kSubtleTextColor,
              indicatorColor: kPrimaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(child: Text('To Read')),
                Tab(child: Text('Completed')),
              ],
            ),
            SizedBox(
              height: 300, // Adjusted height for better spacing
              child: TabBarView(
                children: [
                  _buildBookList(_toReadBooks, isCompletable: true),
                  _buildBookList(_readBooks, isCompletable: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(List<dynamic> books, {required bool isCompletable}) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            isCompletable
                ? "No books assigned yet!"
                : "No books completed yet.",
            style: GoogleFonts.poppins(color: kSubtleTextColor, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookListTile(book, isCompletable: isCompletable);
      },
    );
  }

  Widget _buildBookListTile(
    Map<String, dynamic> book, {
    required bool isCompletable,
  }) {
    final finishByStr = book['finish_by'] as String?;
    DateTime? finishByDate;
    bool isOverdue = false;

    if (finishByStr != null) {
      finishByDate = DateTime.tryParse(finishByStr);
      if (finishByDate != null) {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        isOverdue = finishByDate.isBefore(todayStart);
      }
    }

    String subtitleText;
    Color subtitleColor = kSubtleTextColor;
    FontWeight subtitleFontWeight = FontWeight.normal;

    if (isCompletable) {
      if (finishByDate != null) {
        if (isOverdue) {
          subtitleText =
              "Overdue! Due date was ${DateFormat.yMMMd().format(finishByDate)}";
          subtitleColor = Colors.red.shade700;
          subtitleFontWeight = FontWeight.bold;
        } else {
          subtitleText = 'Due by: ${DateFormat.yMMMd().format(finishByDate)}';
        }
      } else {
        subtitleText = 'Assigned by: ${book['assigned_by'] ?? 'N/A'}';
      }
    } else {
      subtitleText = 'Assigned by: ${book['assigned_by'] ?? 'N/A'}';
    }

    return ListTile(
      leading: Icon(
        isCompletable
            ? (isOverdue ? Icons.warning_amber_rounded : Icons.book_outlined)
            : Icons.check_circle,
        color: isCompletable
            ? (isOverdue ? Colors.orange.shade800 : kAccentColor)
            : Colors.green,
      ),
      title: Text(
        book['book_title'] ?? 'No Title',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitleText,
        style: GoogleFonts.poppins(
          color: subtitleColor,
          fontSize: 13,
          fontWeight: subtitleFontWeight,
        ),
      ),
      trailing: isCompletable
          ? IconButton(
              icon: const Icon(
                Icons.check_box_outline_blank,
                color: kSubtleTextColor,
              ),
              tooltip: 'Mark as Done',
              onPressed: () => _markBookAsRead(book['id']),
            )
          : null,
    );
  }
}

class _ProfileSliverAppBar extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onRefresh;

  // ===== FIX IS HERE =====
  // Added 'super.key' to the constructor to accept a Key.
  const _ProfileSliverAppBar({
    super.key,
    required this.profileData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileData['profile_image_url'];
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 320.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: kPrimaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh Profile',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        title: Text(
          profileData['full_name'] ?? 'User Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
          textAlign: TextAlign.center,
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                  child: !hasImage
                      ? const Icon(Icons.person, size: 60, color: kPrimaryColor)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  profileData['vision'] ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  // ===== FIX IS HERE =====
  // Added 'super.key' to the constructor to accept a Key.
  const _ErrorDisplay({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
            const SizedBox(height: 20),
            Text(
              'Oops, Something Went Wrong!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: kSubtleTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
