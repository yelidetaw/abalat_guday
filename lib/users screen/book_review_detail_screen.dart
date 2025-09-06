import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Make sure this is imported
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/review_models.dart';

// Assuming supabase is initialized in your main.dart
final supabase = Supabase.instance.client;

// --- Branding Colors ---
const Color kPrimaryColor = Color.fromARGB(255, 1, 37, 100);
const Color kAccentColor = Color(0xFFFFD700);
const Color kCardColor = Color.fromARGB(255, 4, 48, 125);
const Color kSecondaryTextColor = Color(0xFF9A9A9A);

class BookReviewScreen extends StatefulWidget {
  final Book book;
  final bool isAdmin;
  const BookReviewScreen({super.key, required this.book, this.isAdmin = false});
  @override
  State<BookReviewScreen> createState() => _BookReviewScreenState();
}

class _BookReviewScreenState extends State<BookReviewScreen> {
  List<BookReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshReviews();
  }

  Future<void> _refreshReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final fetchedReviews = await _loadReviews();
      if (mounted) {
        setState(() {
          _reviews = fetchedReviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('ዳሰሳዎችን ማደስ አልተቻለም: $e'), // TRANSLATED
            backgroundColor: Colors.red));
      }
    }
  }

  Future<List<BookReview>> _loadReviews() async {
    try {
      final response = await supabase
          .from('book_reviews')
          .select('*')
          .eq('book_id', int.parse(widget.book.id))
          .order('created_at', ascending: false);
      return (response as List).map((r) => BookReview.fromMap(r)).toList();
    } catch (e, s) {
      developer.log('Error loading reviews', name: 'BookReviewScreen', error: e, stackTrace: s);
      throw Exception('Failed to load reviews from the database.');
    }
  }
  
  void _showAddReviewDialog() {
    final titleController = TextEditingController();
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: kAccentColor.withOpacity(0.5))
        ),
        title: Text('ዳሰሳ ይጻፉ', style: GoogleFonts.notoSansEthiopic(color: kAccentColor)), // TRANSLATED
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('የዳሰሳ ርዕስ'), // TRANSLATED
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ርዕሱ ባዶ መሆን አይችልም' : null, // TRANSLATED
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('የእርስዎ ማጠቃለያ / ጽሑፍ'), // TRANSLATED
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ይዘቱ ባዶ መሆን አይችልም' : null, // TRANSLATED
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            child: Text('ይቅር', style: GoogleFonts.notoSansEthiopic(color: kAccentColor.withOpacity(0.8))) // TRANSLATED
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: kPrimaryColor
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _addReview(
                  title: titleController.text.trim(),
                  comment: commentController.text.trim(),
                );
              }
            },
            child: Text('ግምገማ አስገባ', style: GoogleFonts.notoSansEthiopic()), // TRANSLATED
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSansEthiopic(color: kAccentColor.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kAccentColor.withOpacity(0.5))
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: kAccentColor)
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent)
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 2)
      ),
    );
  }

  Future<void> _addReview({required String title, required String comment}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.rpc('admin_add_review', params: {
        'p_book_id': int.parse(widget.book.id),
        'p_user_id': user.id,
        'p_title': title,
        'p_comment': comment,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ዳሰሳዉ በተሳካ ሁኔታ ገብቷል!', style: GoogleFonts.notoSansEthiopic()), // TRANSLATED
          backgroundColor: Colors.green));
      _refreshReviews();
    } catch (e, s) {
      developer.log('Error adding review', name: 'BookReviewScreen', error: e, stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ዳሰሳ በማስገባት ላይ ስህተት ተፈጥሯል: ${e.toString()}', style: GoogleFonts.notoSansEthiopic()), // TRANSLATED
          backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    try {
      await supabase.from('book_reviews').delete().eq('id', reviewId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ግምገማው ተሰርዟል', style: GoogleFonts.notoSansEthiopic()), backgroundColor: Colors.green)); // TRANSLATED
      _refreshReviews();
    } catch (e, s) {
      developer.log('Error deleting review', name: 'BookReviewScreen', error: e, stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ዳሰሳዉን መሰረዝ አልተቻለም: ${e.toString()}', style: GoogleFonts.notoSansEthiopic()), // TRANSLATED
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kPrimaryColor,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: Text(widget.book.title, style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (widget.isAdmin)
              IconButton(
                  icon: const Icon(Icons.rate_review_outlined, color: kAccentColor),
                  tooltip: 'ዳሰሳ ይጻፉ', // TRANSLATED
                  onPressed: _showAddReviewDialog)
          ],
        ),
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _BookDetailsSection(book: widget.book))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('ዳሰሳዎች እና ማጠቃለያዎች (${_reviews.length})', // TRANSLATED
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontFamily: GoogleFonts.notoSansEthiopic().fontFamily)))),
          _isLoading
              ? SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: kAccentColor)))
              : _ReviewsList(
                  reviews: _reviews,
                  isAdmin: widget.isAdmin,
                  onDeleteReview: (id) => _deleteReview(id as int))
        ]),
      );
}

class _BookDetailsSection extends StatelessWidget {
  final Book book;
  const _BookDetailsSection({required this.book});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: kCardColor,
                image: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(book.coverUrl!), fit: BoxFit.cover)
                    : null),
            child: (book.coverUrl == null || book.coverUrl!.isEmpty)
                ? Icon(Icons.menu_book, size: 40, color: kSecondaryTextColor)
                : null),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(book.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('በ ${book.author ?? 'ያልታወቀ ደራሲ'}', // TRANSLATED
              style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: kSecondaryTextColor)),
          const SizedBox(height: 8),
          if (book.genre != null && book.genre!.isNotEmpty)
            Text('ዓይነት: ${book.genre}', // TRANSLATED
                style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor)),
          if (book.publishedYear != null && book.publishedYear != 0)
            Text('ዓመት: ${book.publishedYear}', // TRANSLATED
                style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor)),
        ]))
      ]);
}

class _ReviewsList extends StatelessWidget {
  final List<BookReview> reviews;
  final bool isAdmin;
  final Function(dynamic) onDeleteReview;
  const _ReviewsList(
      {required this.reviews,
      required this.isAdmin,
      required this.onDeleteReview});
  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return SliverToBoxAdapter(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('እስካሁን ምንም ዳሰሳ የለም።', style: GoogleFonts.notoSansEthiopic(color: kSecondaryTextColor))))); // TRANSLATED
    }
    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      final review = reviews[index];
      return Card(
          color: kCardColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
              title: Text(review.title ?? 'ርዕስ የለም', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold, color: Colors.white)), // TRANSLATED
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.comment ?? 'ይዘት የለም', maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansEthiopic(color: Colors.white70)), // TRANSLATED
                    const SizedBox(height: 8),
                    Text(
                      'የተለጠፈው በ ${DateFormat.yMMMd().format(review.createdAt.toLocal())}', // TRANSLATED
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kSecondaryTextColor, fontFamily: GoogleFonts.notoSansEthiopic().fontFamily),
                    ),
                  ],
                ),
              ),
              trailing: isAdmin
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => onDeleteReview(review.id))
                  : null,
              onTap: () {
                showDialog(context: context, builder: (context) => AlertDialog(
                  backgroundColor: kPrimaryColor,
                  title: Text(review.title ?? 'ርዕስ የለም', style: GoogleFonts.notoSansEthiopic(color: kAccentColor)), // TRANSLATED
                  content: SingleChildScrollView(child: Text(review.comment ?? 'ይዘት የለም', style: GoogleFonts.notoSansEthiopic(color: Colors.white))), // TRANSLATED
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('ዝጋ', style: GoogleFonts.notoSansEthiopic(color: kAccentColor)) )], // TRANSLATED
                ));
              },
          ));
    }, childCount: reviews.length));
  }
}