import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'package:amde_haymanot_abalat_guday/models/ethiopian_date_picker.dart'; // Your date utility
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

// --- UI Theme Constants ---
const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
const Color accentColor = Color(0xFFFFD700);
const Color kCardColor =Color.fromARGB(255, 1, 37, 100);
const Color kAdminSecondaryText = Color(0xFFFFD700);

// --- MODELS for this screen ---
class UserReadingSummary {
  final String id;
  final String fullName;
  final String? profileImageUrl;
  final String? kifil;
  final String? budin;
  final String? agelgilotKifil;
  final int totalAssignedBooks;
  final int overdueBooksCount;

  UserReadingSummary({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.kifil,
    this.budin,
    this.agelgilotKifil,
    required this.totalAssignedBooks,
    required this.overdueBooksCount,
  });

  factory UserReadingSummary.fromMap(Map<String, dynamic> map) {
    return UserReadingSummary(
      id: map['id'],
      fullName: map['full_name'] ?? 'ስም የለም',
      profileImageUrl: map['profile_image_url'],
      kifil: map['kifil'],
      budin: map['budin'],
      agelgilotKifil: map['agelgilot_kifil'],
      totalAssignedBooks: (map['total_assigned_books'] as num?)?.toInt() ?? 0,
      overdueBooksCount: (map['overdue_books_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReadingHistoryItem {
  final String bookTitle;
  final String status;
  final String? assignedBy;
  final DateTime? finishBy;
  final DateTime? readAt;
  final DateTime createdAt;

  ReadingHistoryItem({
    required this.bookTitle,
    required this.status,
    this.assignedBy,
    this.finishBy,
    this.readAt,
    required this.createdAt,
  });

  factory ReadingHistoryItem.fromMap(Map<String, dynamic> map) {
    return ReadingHistoryItem(
      bookTitle: map['book_title'] ?? 'ርዕስ የለም',
      status: map['status'] ?? 'unknown',
      assignedBy: map['assigned_by'],
      finishBy: map['finish_by'] != null ? DateTime.parse(map['finish_by']) : null,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}


class ReadingDashboardScreen extends StatefulWidget {
  const ReadingDashboardScreen({super.key});

  @override
  State<ReadingDashboardScreen> createState() => _ReadingDashboardScreenState();
}

class _ReadingDashboardScreenState extends State<ReadingDashboardScreen> {
  late Future<List<UserReadingSummary>> _usersFuture;
  List<UserReadingSummary> _allUsers = [];
  List<UserReadingSummary> _filteredUsers = [];

  // --- State for Filters ---
  final _searchController = TextEditingController();
  String? _selectedKifil;
  String? _selectedBudin;
  bool _showOnlyOverdue = false;
  List<String> _kifilOptions = [];
  List<String> _budinOptions = [];

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsersSummary();
    _searchController.addListener(_performFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<UserReadingSummary>> _fetchUsersSummary() async {
    try {
      final response = await supabase.rpc('get_all_users_reading_summary');
      final users = (response as List).map((data) => UserReadingSummary.fromMap(data)).toList();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _populateDropdowns(users);
        });
      }
      return users;
    } catch (e) {
      debugPrint('Error fetching reading summary: $e');
      throw 'የተጠቃሚ የንባብ መረጃን መጫን አልተሳካም።';
    }
  }

  void _populateDropdowns(List<UserReadingSummary> users) {
    setState(() {
      _kifilOptions = users.map((u) => u.kifil).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()..sort();
      _budinOptions = users.map((u) => u.budin).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()..sort();
    });
  }

  void _performFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = user.fullName.toLowerCase();
        final matchesSearch = name.contains(query);
        final matchesKifil = _selectedKifil == null || user.kifil == _selectedKifil;
        final matchesBudin = _selectedBudin == null || user.budin == _selectedBudin;
        final matchesOverdue = !_showOnlyOverdue || user.overdueBooksCount > 0;
        return matchesSearch && matchesKifil && matchesBudin && matchesOverdue;
      }).toList();
    });
  }

  void _showReadingHistorySheet(BuildContext context, UserReadingSummary user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReadingHistorySheet(userId: user.id, userName: user.fullName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 27, 151),
      appBar: AppBar(
        title: Text('የንባብ ዳሽቦርድ', style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: const Color.fromARGB(255, 25, 25, 187),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<UserReadingSummary>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingShimmer();
                if (snapshot.hasError) return Center(child: Text(snapshot.error.toString(), style: GoogleFonts.notoSansEthiopic(color: Colors.redAccent)));
                if (_filteredUsers.isEmpty) return Center(child: Text('ምንም ተጠቃሚ አልተገኘም', style: GoogleFonts.notoSansEthiopic()));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return FadeInUp(
                      from: 20, delay: Duration(milliseconds: index * 40),
                      child: Card(
                        color: kCardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _showReadingHistorySheet(context, user),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: accentColor.withOpacity(0.2),
                            backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                            child: user.profileImageUrl == null ? Text(user.fullName[0], style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold)) : null,
                          ),
                          title: Text(user.fullName, style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600, color: Colors.white)),
                          subtitle: Text('የተመደቡ: ${user.totalAssignedBooks}', style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText, fontSize: 12)),
                          trailing: user.overdueBooksCount > 0
                            ? Chip(
                                label: Text(user.overdueBooksCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.red.shade400,
                                avatar: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                              )
                            : const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
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

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ተጠቃሚ ፈልግ...',
              hintStyle: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText),
              prefixIcon: const Icon(Icons.search, color: kAdminSecondaryText),
              filled: true,
              fillColor: kCardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // THIS IS THE FIX: Using Flexible instead of Expanded
              Flexible(child: _buildDropdown(_selectedKifil, _kifilOptions, (val) => setState(() { _selectedKifil = val; _performFilter(); }), 'ክፍል')),
              const SizedBox(width: 12),
              Flexible(child: _buildDropdown(_selectedBudin, _budinOptions, (val) => setState(() { _selectedBudin = val; _performFilter(); }), 'ልዩ ኅብረት')),
            ],
          ),
           const SizedBox(height: 12),
          SwitchListTile(
            title: Text("ያለፈባቸው ብቻ", style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
            value: _showOnlyOverdue,
            onChanged: (val) {
              setState(() {
                _showOnlyOverdue = val;
                _performFilter();
              });
            },
            activeColor: accentColor,
            tileColor: kCardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String? value, List<String> items, ValueChanged<String?> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true, // This is okay inside a Flexible widget
      hint: Text(label, style: GoogleFonts.notoSansEthiopic(fontSize: 14, color: kAdminSecondaryText)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true, fillColor: kCardColor,
      ),
      dropdownColor: kCardColor,
      iconEnabledColor: accentColor,
      style: GoogleFonts.notoSansEthiopic(color: Colors.white),
      items: [
        DropdownMenuItem(value: null, child: Text("ሁሉም", style: GoogleFonts.notoSansEthiopic())),
        ...items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.notoSansEthiopic(), overflow: TextOverflow.ellipsis)))
      ],
      onChanged: onChanged,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _ReadingHistorySheet extends StatefulWidget {
  final String userId;
  final String userName;
  const _ReadingHistorySheet({required this.userId, required this.userName});

  @override
  State<_ReadingHistorySheet> createState() => _ReadingHistorySheetState();
}

class _ReadingHistorySheetState extends State<_ReadingHistorySheet> {
  late Future<List<ReadingHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<ReadingHistoryItem>> _fetchHistory() async {
    try {
      final response = await supabase.rpc('get_user_reading_history', params: {'p_user_id': widget.userId});
      return (response as List).map((data) => ReadingHistoryItem.fromMap(data)).toList();
    } catch (e) {
      debugPrint("Error fetching reading history: $e");
      throw "የንባብ ታሪክን መጫን አልተቻለም";
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
                    "${widget.userName}\nየንባብ ታሪክ",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(fontSize: 20, color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(color: accentColor, thickness: 0.5, height: 1, indent: 16, endIndent: 16),
                Expanded(
                  child: FutureBuilder<List<ReadingHistoryItem>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: accentColor));
                      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString(), style: GoogleFonts.notoSansEthiopic(color: Colors.redAccent)));
                      if (snapshot.data == null || snapshot.data!.isEmpty) return Center(child: Text("ምንም የንባብ ታሪክ አልተገኘም", style: GoogleFonts.notoSansEthiopic(color: kAdminSecondaryText)));

                      final records = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final bool isOverdue = record.status == 'to_read' && record.finishBy != null && record.finishBy!.isBefore(DateTime.now());
                          final statusColor = record.status == 'read' ? Colors.green.shade300 : (isOverdue ? Colors.red.shade300 : kAdminSecondaryText);
                          
                          return FadeInUp(
                            from: 20,
                            delay: Duration(milliseconds: index * 40),
                            child: Card(
                              color: kCardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(record.status == 'read' ? Icons.check_circle_outline : (isOverdue ? Icons.warning_amber_rounded : Icons.hourglass_top_outlined), color: statusColor, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(record.bookTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text(record.status == 'read' ? 'ተጠናቋል' : (isOverdue ? 'ጊዜው አልፎበታል' : 'በማንበብ ላይ'), style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: kAdminSecondaryText),
                                    _buildHistoryDetailRow(Icons.person_outline, "የተመደበው በ:", record.assignedBy),
                                    if(record.status == 'read' && record.readAt != null)
                                      _buildHistoryDetailRow(Icons.event_available, "የተጠናቀቀበት ቀን:", DateFormat.yMMMd().format(record.readAt!.toLocal())),
                                    if(record.status == 'to_read' && record.finishBy != null)
                                      _buildHistoryDetailRow(Icons.event_busy, "የመጨረሻ ቀን:", DateFormat.yMMMd().format(record.finishBy!.toLocal())),
                                  ],
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
}

Widget _buildHistoryDetailRow(IconData icon, String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(icon, color: kAdminSecondaryText, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: kAdminSecondaryText, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ],
    ),
  );
}