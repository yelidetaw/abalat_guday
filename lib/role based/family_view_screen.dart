import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

// --- UI Theme Constants ---
const Color kBackgroundColor = Color.fromARGB(255, 1, 37, 100);
const Color kCardColor = Color.fromARGB(255, 1, 37, 100);
const Color kPrimaryAccentColor = Color(0xFFFFD700);
const Color kSecondaryTextColor = Color(0xFFFFD700);

// --- Model ---
// This class perfectly matches the data returned by the 'get_my_linked_students' function.
class LinkedStudent {
  final String id;
  final String fullName;
  final String? profileImageUrl;
  final String? spiritualClass;

  LinkedStudent({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.spiritualClass,
  });

  factory LinkedStudent.fromMap(Map<String, dynamic> map) {
    return LinkedStudent(
      id: map['student_id'],
      fullName: map['full_name'] ?? 'ስም የለም',
      profileImageUrl: map['profile_image_url'],
      spiritualClass: map['current_spiritual_class'] ?? 'የለም',
    );
  }
}

class FamilyViewScreen extends StatefulWidget {
  const FamilyViewScreen({super.key});

  @override
  State<FamilyViewScreen> createState() => _FamilyViewScreenState();
}

class _FamilyViewScreenState extends State<FamilyViewScreen> {
  late Future<List<LinkedStudent>> _linkedStudentsFuture;

  @override
  void initState() {
    super.initState();
    _linkedStudentsFuture = _fetchLinkedStudents();
  }

  Future<List<LinkedStudent>> _fetchLinkedStudents() async {
    try {
      final response = await supabase.rpc('get_my_linked_students');
      return (response as List)
          .map((data) => LinkedStudent.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching linked students: $e');
      throw 'የተማሪ መረጃን መጫን አልተሳካም።';
    }
  }

  Future<void> _handleRefresh() async {
    final newFuture = _fetchLinkedStudents();
    setState(() {
      _linkedStudentsFuture = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("የቤተሰብ ክትትል",
            style: GoogleFonts.notoSansEthiopic(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        backgroundColor: kCardColor,
        color: kPrimaryAccentColor,
        child: FutureBuilder<List<LinkedStudent>>(
          future: _linkedStudentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _LoadingShimmer();
            }
            if (snapshot.hasError) {
              return _ErrorDisplay(
                  error: snapshot.error.toString(), onRetry: _handleRefresh);
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _EmptyState(onRefresh: _handleRefresh);
            }

            final students = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: students.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  from: 20,
                  delay: Duration(milliseconds: 100 * index),
                  child: _StudentInfoCard(student: students[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final LinkedStudent student;
  const _StudentInfoCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/family-view/${student.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.1),
              backgroundImage: student.profileImageUrl != null &&
                      student.profileImageUrl!.isNotEmpty
                  ? NetworkImage(student.profileImageUrl!)
                  : null,
              child: (student.profileImageUrl == null ||
                      student.profileImageUrl!.isEmpty)
                  ? Text(
                      student.fullName.isNotEmpty ? student.fullName[0] : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: GoogleFonts.notoSansEthiopic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('መንፈሳዊ ክፍል: ${student.spiritualClass}',
                      style: GoogleFonts.notoSansEthiopic(
                          color: kSecondaryTextColor, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: kSecondaryTextColor, size: 16),
          ],
        ),
      ),
    );
  }
}

// --- UI Helper Widgets (Shimmer, Error, Empty) ---

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kCardColor,
      highlightColor: kBackgroundColor.withOpacity(0.5),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded,
              color: Colors.redAccent, size: 60),
          const SizedBox(height: 20),
          Text("ስህተት ተፈጥሯል",
              style: GoogleFonts.notoSansEthiopic(
                  fontSize: 22, color: Colors.white)),
          const SizedBox(height: 10),
          Text(error,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('እንደገና ሞክር', style: GoogleFonts.notoSansEthiopic())),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off_rounded,
                        color: kPrimaryAccentColor, size: 60),
                    const SizedBox(height: 20),
                    Text('ከተማሪ ጋር አልተገናኙም',
                        style: GoogleFonts.notoSansEthiopic(
                            fontSize: 22, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text("እስካሁን ከተማሪ መረጃ ጋር አልተገናኙም።",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansEthiopic(
                            color: kSecondaryTextColor)),
                  ]),
            ),
          ),
        ),
      );
    });
  }
}
