import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase instance
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart'; // Ensure GoRouter is imported for navigation

import 'package:amde_haymanot_abalat_guday/admin only/user_provider.dart';

// --- Branding Colors ---
const Color kPrimaryColor = Color.fromARGB(255, 1, 37, 100);
const Color kAccentColor = Color(0xFFFFD700);
const Color kCardColor = Color.fromARGB(255, 4, 48, 125);
const Color kSecondaryTextColor = Color.fromARGB(255, 255, 255, 255);

// --- Data Model ---
class ProfileScreenData {
  final Map<String, dynamic> profileData;
  final List<dynamic> allGrades;
  final List<dynamic> toReadBooks;
  final List<dynamic> readBooks;
  final List<dynamic> allAttendance;

  ProfileScreenData({
    required this.profileData,
    required this.allGrades,
    required this.toReadBooks,
    required this.readBooks,
    required this.allAttendance,
  });
}

// --- Main Screen Widget ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileScreenData> _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _fetchProfileData();
  }

  Future<ProfileScreenData> _fetchProfileData() async {
    try {
      final response = await supabase.rpc('get_my_profile').single();

      if (response['profile_data'] == null) {
        throw Exception('Profile data is null.');
      }

      final readingList = response['reading_list'] as List<dynamic>? ?? [];
      final toReadBooks = readingList.where((b) => (b['status'] as String?)?.toLowerCase() == 'to_read').toList();
      final readBooks = readingList.where((b) => (b['status'] as String?)?.toLowerCase() == 'read').toList();
      
      final profileData = response['profile_data'] as Map<String, dynamic>;
      if (profileData['profile_image_url'] != null && mounted) {
        Provider.of<UserProvider>(context, listen: false)
            .setAvatarUrl(profileData['profile_image_url']);
      }

      return ProfileScreenData(
        profileData: profileData,
        allGrades: response['all_grades'] as List<dynamic>? ?? [],
        toReadBooks: toReadBooks,
        readBooks: readBooks,
        allAttendance: response['all_attendance'] as List<dynamic>? ?? [],
      );
    } catch (e, stackTrace) {
      developer.log('Failed in _fetchProfileData: ${e.toString()}', name: 'ProfileScreen', error: e, stackTrace: stackTrace);
      throw Exception('የፕሮፋይል መረጃን በማምጣት ላይ ስህተት ተፈጥሯል');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _profileDataFuture = _fetchProfileData();
    });
  }

  Future<void> _markBookAsRead(int bookId) async {
    try {
      await supabase.from('reading_list').update({
        'status': 'read',
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', bookId);
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('የመጽሐፉን ሁኔታ ማዘመን አልተቻለም'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: FutureBuilder<ProfileScreenData>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ProfileShimmer(key: ValueKey('loading'));
          }
          if (snapshot.hasError) {
            return _ErrorDisplay(
              key: const ValueKey('error'),
              error: snapshot.error.toString(),
              onRetry: _refreshData,
            );
          }
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshData,
              backgroundColor: kCardColor,
              color: kAccentColor,
              child: CustomScrollView(
                slivers: [
                  _ProfileSliverAppBar(profileData: data.profileData),
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // --- RESTORED ORIGINAL WIDGETS ---
                        FadeInUp(from: 20, child: _buildStatsRow(data.profileData)),
                        const SizedBox(height: 24),
                        FadeInUp(from: 20, delay: const Duration(milliseconds: 50), child: _buildSectionTitle('የማኅበር መረጃ')),
                        FadeInUp(from: 20, delay: const Duration(milliseconds: 100), child: _buildMahberInfoCard(data.profileData)),
                        const SizedBox(height: 24),
                        FadeInUp(from: 20, delay: const Duration(milliseconds: 150), child: _buildSectionTitle('የግል መረጃ')),
                        FadeInUp(from: 20, delay: const Duration(milliseconds: 200), child: _buildAboutCard(data.profileData)),
                        const SizedBox(height: 24),
                        
                        // --- REBUILT & CORRECTED CARDS ---
                        _buildSection(
                          title: "የትምህርት አፈጻጸም",
                          icon: Icons.school_outlined,
                          child: _GradesSection(grades: data.allGrades),
                        ),
                        _buildSection(
                          title: "የንባብ ጉዞ",
                          icon: Icons.book_outlined,
                          child: _ReadingSection(
                            toReadBooks: data.toReadBooks,
                            readBooks: data.readBooks,
                            onMarkAsRead: _markBookAsRead,
                          ),
                        ),
                        _buildSection(
                          title: "የክትትል ታሪክ",
                          icon: Icons.event_available_outlined,
                          // --- CORRECTED: Using the new Attendance Summary Card ---
                          child: _AttendanceSummaryCard(attendance: data.allAttendance),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }
          return _ErrorDisplay(
            key: const ValueKey('no_data'),
            error: 'ምንም መረጃ አልተገኘም',
            onRetry: _refreshData,
          );
        },
      ),
    );
  }

  // --- HELPER METHODS FOR RESTORED WIDGETS ---
  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
        child: Text(title,
            style: GoogleFonts.notoSansEthiopic(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );

  Widget _buildStatsRow(Map<String, dynamic> profileData) => Card(
        color: kCardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('የአገልግሎት ክፍል', profileData['agelgilot_kifil']),
              _buildStatItem('ክፍል', profileData['kifil']),
              _buildStatItem('መንፈሳዊ ክፍል', profileData['spiritual_class']),
            ],
          ),
        ),
      );

  Widget _buildStatItem(String label, String? value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value ?? 'N/A',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kAccentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 14,
              color: kSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMahberInfoCard(Map<String, dynamic> profileData) => Card(
        color: kCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInfoItem(Icons.work_outline_rounded, 'የስራ ድርሻ',
                  profileData['yesra_dirisha']),
              const Divider(height: 24, color: Colors.white12),
              _buildInfoItem(Icons.diversity_3_rounded, 'ልዩ የአገልግሎት ቡድን',
                  profileData['budin']),
            ],
          ),
        ),
      );

  Widget _buildAboutCard(Map<String, dynamic> profileData) => Card(
        color: kCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInfoItem(Icons.email_outlined, 'ኢሜይል',
                  supabase.auth.currentUser?.email),
              const Divider(height: 24, color: Colors.white12),
              _buildInfoItem(
                  Icons.phone_outlined, 'ስልክ', profileData['phone_number']),
              const Divider(height: 24, color: Colors.white12),
              _buildBirthdayInfoItem(profileData),
              const Divider(height: 24, color: Colors.white12),
              _buildInfoItem(Icons.school_outlined, 'የትምህርት ደረጃ',
                  profileData['academic_class']),
            ],
          ),
        ),
      );

  Widget _buildBirthdayInfoItem(Map<String, dynamic> profileData) {
    final age = profileData['age'] as int?;
    String displayValue = 'አልተሞላም';
    if (age != null) {
      displayValue = '$age ዓመት';
    }
    return _buildInfoItem(Icons.cake_outlined, 'ዕድሜ', displayValue);
  }

  Widget _buildInfoItem(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: kAccentColor),
        const SizedBox(width: 16),
        Text(label, style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: kSecondaryTextColor)),
        const Spacer(),
        Expanded(
          child: Text(
            value ?? 'አልተሞላም',
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kAccentColor, size: 22),
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
          FadeInUp(from: 20, child: child),
        ],
      ),
    );
  }
}

// ==========================================================================
// SECTION 1: GRADES (STABLE)
// ==========================================================================
class _GradesSection extends StatefulWidget {
  final List<dynamic> grades;
  const _GradesSection({required this.grades});

  @override
  State<_GradesSection> createState() => _GradesSectionState();
}

class _GradesSectionState extends State<_GradesSection> {
  String? _selectedYearAndClass;
  
  @override
  void initState() {
    super.initState();
    final availableOptions = _getAvailableOptions(widget.grades);
    if (availableOptions.isNotEmpty) {
      _selectedYearAndClass = availableOptions.first;
    }
  }

  List<String> _getAvailableOptions(List<dynamic> grades) {
    final options = grades
        .where((g) => g['spiritual_class'] != null && g['academic_year'] != null)
        .map((g) => "${g['spiritual_class']} - ${g['academic_year']}")
        .toSet()
        .toList();
    options.sort((a, b) {
      final yearA = int.tryParse(a.split(' - ').last) ?? 0;
      final yearB = int.tryParse(b.split(' - ').last) ?? 0;
      return yearB.compareTo(yearA);
    });
    return options;
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.grades.isEmpty) {
      return _EmptyCard(message: "ምንም ውጤቶች እስካሁን አልተመዘገቡም");
    }

    final availableOptions = _getAvailableOptions(widget.grades);
    if (!availableOptions.contains(_selectedYearAndClass) && availableOptions.isNotEmpty) {
        _selectedYearAndClass = availableOptions.first;
    }

    final filteredGrades = widget.grades.where((g) {
      if (_selectedYearAndClass == null) return false;
      final parts = _selectedYearAndClass!.split(' - ');
      return g['spiritual_class'] == parts[0] && g['academic_year'].toString() == parts[1];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableOptions.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedYearAndClass,
              items: availableOptions
                  .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (newValue) {
                setState(() => _selectedYearAndClass = newValue);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: kCardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: GoogleFonts.notoSansEthiopic(color: Colors.white),
              dropdownColor: kCardColor,
              iconEnabledColor: kAccentColor,
            ),
          ),
        
        if (filteredGrades.isEmpty && _selectedYearAndClass != null)
          _EmptyCard(message: "በተመረጠው ጊዜ ውስጥ ምንም ውጤቶች አልተገኙም")
        else
          Card(
            color: kCardColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGrades.length,
              itemBuilder: (context, index) => _buildGradeItem(filteredGrades[index]),
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
            ),
          ),
      ],
    );
  }

  Widget _buildGradeItem(Map<String, dynamic> grade) {
    final int total = ((grade['mid_exam'] ?? 0) as num).toInt() +
        ((grade['final_exam'] ?? 0) as num).toInt() +
        ((grade['assignment'] ?? 0) as num).toInt();
    final status = total >= 50 ? 'አልፏል' : 'ወድቋል';
    final statusColor = status == 'አልፏል' ? Colors.green.shade400 : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(grade['course_name'] ?? 'N/A',
                      style: GoogleFonts.notoSansEthiopic(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            color: isTotal ? kAccentColor : Colors.white,
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// SECTION 2: READING (STABLE)
// ==========================================================================
class _ReadingSection extends StatelessWidget {
  final List<dynamic> toReadBooks;
  final List<dynamic> readBooks;
  final Function(int) onMarkAsRead;

  const _ReadingSection({
    required this.toReadBooks,
    required this.readBooks,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    if (toReadBooks.isEmpty && readBooks.isEmpty) {
      return _EmptyCard(message: "ምንም የተመደቡ መጽሐፍት የሉም");
    }

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
                  Tab(child: Text('ለማንበብ (${toReadBooks.length})', style: GoogleFonts.notoSansEthiopic())),
                  Tab(child: Text('የተጠናቀቁ (${readBooks.length})', style: GoogleFonts.notoSansEthiopic())),
                ],
                labelColor: kAccentColor,
                unselectedLabelColor: kSecondaryTextColor,
                indicatorColor: kAccentColor,
              ),
            ),
            SizedBox(
              height: 250, 
              child: TabBarView(
                children: [
                  _BookList(
                    books: toReadBooks,
                    onMarkAsRead: onMarkAsRead,
                    emptyMessage: 'በዝርዝሩ ላይ ምንም መጽሐፍ የለም!',
                  ),
                  _BookList(
                    books: readBooks,
                    emptyMessage: 'እስካሁን የተጠናቀቁ መጻሕፍት የሉም።',
                  ),
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
  final String emptyMessage;
  final Function(int)? onMarkAsRead;

  const _BookList({required this.books, required this.emptyMessage, this.onMarkAsRead});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(emptyMessage, style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor), textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white12),
      itemBuilder: (context, index) => _BookListTile(book: books[index], onMarkAsRead: onMarkAsRead),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final Map<String, dynamic> book;
  final Function(int)? onMarkAsRead;
  const _BookListTile({required this.book, this.onMarkAsRead});

  @override
  Widget build(BuildContext context) {
    final isCompletable = onMarkAsRead != null;
    final bookId = book['id'] as int?;

    String subtitleText = '';
    bool isOverdue = false;
    if (isCompletable) {
      final finishByStr = book['finish_by'] as String?;
      if (finishByStr != null) {
        try {
          final finishByDate = DateTime.parse(finishByStr);
          subtitleText = 'የመጨረሻ ቀን: ${DateFormat.yMMMd().format(finishByDate)}';
          isOverdue = finishByDate.isBefore(DateTime.now());
        } catch (_) {
          subtitleText = 'የመጨረሻ ቀን የለውም';
        }
      } else {
        subtitleText = 'የመጨረሻ ቀን የለውም';
      }
    } else {
      final readAtStr = book['read_at'] as String?;
      if (readAtStr != null) {
        try {
          subtitleText = 'የተጠናቀቀው በ: ${DateFormat.yMMMd().format(DateTime.parse(readAtStr).toLocal())}';
        } catch (_) {
          subtitleText = 'ተጠናቋል';
        }
      } else {
        subtitleText = 'ተጠናቋል';
      }
    }

    return ListTile(
      leading: Icon(
        isCompletable ? (isOverdue ? Icons.warning_amber_rounded : Icons.book_outlined) : Icons.check_circle_outline_rounded,
        color: isCompletable ? (isOverdue ? Colors.orange.shade600 : kAccentColor) : Colors.green.shade400,
      ),
      title: Text(book['book_title'] ?? 'ርዕስ የሌለው መጽሐፍ', style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
      subtitle: Text(
        subtitleText,
        style: GoogleFonts.notoSansEthiopic(
          color: isOverdue ? Colors.red.shade400 : kSecondaryTextColor,
        ),
      ),
       trailing: (isCompletable && bookId != null) ? IconButton(
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
        tooltip: 'Mark as Read',
        onPressed: () => onMarkAsRead!(bookId),
      ) : null,
    );
  }
}

// ==========================================================================
// SECTION 3: ATTENDANCE (NEW SUMMARY CARD)
// ==========================================================================
class _AttendanceSummaryCard extends StatelessWidget {
  final List<dynamic> attendance;

  const _AttendanceSummaryCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return _EmptyCard(message: "ምንም የክትትል መረጃ የለም");
    }

    // --- Calculations for the summary ---
    final totalSessions = attendance.length;
    final presentCount = attendance.where((r) => r['status'] == 'present').length;
    final lateCount = attendance.where((r) => r['status'] == 'late').length;
    final absentCount = attendance.where((r) => r['status'] == 'absent').length;
    
    final presentAndLate = presentCount + lateCount;
    final percentage = totalSessions > 0 ? (presentAndLate / totalSessions * 100) : 0.0;
    
    Color getPercentageColor(double perc) {
      if (perc >= 90) return Colors.green.shade400;
      if (perc >= 75) return Colors.lightGreen.shade400;
      if (perc >= 50) return Colors.orange.shade400;
      return Colors.red.shade400;
    }

    return Card(
      color: kCardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // --- NAVIGATION ---
          // Make sure your GoRouter route is defined for this path.
          context.push('/attendance-history');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Percentage
              _buildSummaryStat(
                value: '${percentage.toStringAsFixed(0)}%',
                label: 'የተገኘ',
                color: getPercentageColor(percentage),
              ),
              // 2. Present
              _buildSummaryStat(
                value: presentAndLate.toString(),
                label: 'ተገኝቷል',
                icon: Icons.check_circle_outline_rounded,
              ),
              // 3. Absent
              _buildSummaryStat(
                value: absentCount.toString(),
                label: 'ቀሪ',
                icon: Icons.highlight_off_rounded,
              ),
              // 4. Late
              _buildSummaryStat(
                value: lateCount.toString(),
                label: 'ዘግይቷል',
                icon: Icons.watch_later_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat({
    required String value, 
    required String label, 
    Color? color, 
    IconData? icon
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null)
          Icon(icon, color: kSecondaryTextColor, size: 24),
        
        Text(
          value,
          style: GoogleFonts.notoSansEthiopic(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSansEthiopic(
            fontSize: 14,
            color: kSecondaryTextColor,
          ),
        ),
      ],
    );
  }
}


// --- ALL OTHER WIDGETS (UNCHANGED AND STABLE) ---

class _ProfileSliverAppBar extends StatelessWidget {
  final Map<String, dynamic> profileData;
  const _ProfileSliverAppBar({required this.profileData});

   Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      double starValue = rating - i;
      IconData iconData = Icons.star_border;
      Color color = Colors.grey.shade600;
      if (starValue >= 0.95) {
        iconData = Icons.star;
        color = kAccentColor;
      } else if (starValue >= 0.25) {
        iconData = Icons.star_half;
        color = kAccentColor;
      }
      stars.add(Icon(iconData, color: color, size: 24));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileData['profile_image_url'];
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final double totalStars = (profileData['total_stars'] as num?)?.toDouble() ?? 0.0;

    return SliverAppBar(
      expandedHeight: 290.0,
      pinned: true,
      stretch: true,
      backgroundColor: kPrimaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(profileData['full_name'] ?? 'No Name',
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
                    kPrimaryColor,
                    kPrimaryColor.withOpacity(0.5),
                    Colors.transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
             Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: kCardColor,
                    backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                    child: !hasImage ? Icon(Icons.person, size: 50, color: kAccentColor) : null,
                  ),
                  const SizedBox(height: 12),
                  FadeIn(
                    child: Column(
                      children: [
                        Text(
                          totalStars.toStringAsFixed(2),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAccentColor.withAlpha(220)),
                        ),
                        const SizedBox(height: 4),
                        _buildStarRating(totalStars),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      profileData['vision'] ?? 'ራዕይ አልተቀመጠም',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansEthiopic(
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                   const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kCardColor.withOpacity(0.6),
      highlightColor: kCardColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const CircleAvatar(radius: 50, backgroundColor: Colors.white),
                  const SizedBox(height: 12),
                  Container(height: 16, width: 200,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white)
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                const SizedBox(height: 24),
                Container(height: 20, width: 150,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white)
                ),
                Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorDisplay({required this.error, required this.onRetry, super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: kSecondaryTextColor, size: 60),
            const SizedBox(height: 20),
            Text('ውይ, አንድ ስህተት ተፈጥሯል', textAlign: TextAlign.center, style: GoogleFonts.notoSansEthiopic(fontSize: 22, color: Colors.white)),
            const SizedBox(height: 10),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.notoSansEthiopic(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry, 
              icon: const Icon(Icons.refresh), 
              label: Text('እንደገና ይሞክሩ', style: GoogleFonts.notoSansEthiopic()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}