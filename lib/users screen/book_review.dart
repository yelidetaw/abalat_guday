import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import 'book_review_detail_screen.dart';

// Assuming supabase is initialized in your main.dart
final supabase = Supabase.instance.client;

class UserLibraryScreen extends StatefulWidget {
  const UserLibraryScreen({super.key});
  @override
  State<UserLibraryScreen> createState() => _UserLibraryScreenState();
}

class _UserLibraryScreenState extends State<UserLibraryScreen> {
  List<Book> _books = []; // Use a direct list instead of a Future
  bool _isLoading = true; // Add a loading state
  String _searchQuery = '';
  bool _showReviewedOnly = false;
  Timer? _debounce;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _refreshBooks(); // Initial fetch
    _fetchUserRole();
  }

  // THIS IS THE CRITICAL FIX: The async work is done FIRST.
  Future<void> _refreshBooks() async {
    if (!mounted) return;
    setState(() => _isLoading = true); // Set loading state

    try {
      // 1. Await the Future to get the actual data.
      final fetchedBooks = await _fetchBooks();
      
      // 2. Now that we have the data, call setState synchronously.
      if (mounted) {
        setState(() {
          _books = fetchedBooks;
          _isLoading = false;
        });
      }
    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to refresh books: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      if (supabase.auth.currentUser == null) {
        if (mounted) setState(() => _currentUserRole = 'user');
        return;
      }
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      if (mounted) setState(() => _currentUserRole = response['role']);
    } catch (e) {
      if (mounted) setState(() => _currentUserRole = 'user');
    }
  }

  Future<List<Book>> _fetchBooks() async {
    try {
      final response = await supabase.rpc('get_books_with_details', params: {
        'search_text': _searchQuery,
        'reviewed_only': _showReviewedOnly
      });
      return (response as List).map((data) => Book.fromMap(data)).toList();
    } catch (e, s) {
      developer.log('Error fetching books', name: 'UserLibraryScreen', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error fetching books: $e'),
            backgroundColor: Colors.red));
      }
      return [];
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _refreshBooks();
    });
  }

  void _toggleReviewedOnly(bool value) {
    setState(() {
      _showReviewedOnly = value;
    });
    _refreshBooks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Library Books')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                      hintText: 'Search books...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)))),
              SwitchListTile(
                  title: const Text('Show only reviewed books'),
                  value: _showReviewedOnly,
                  onChanged: _toggleReviewedOnly,
                  contentPadding: EdgeInsets.zero)
            ])),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _books.isEmpty
                  ? const Center(child: Text('No books found.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.7),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return _BookCard(
                            book: book,
                            onTap: () => _navigateToReviewScreen(book));
                      }),
        )
      ]));

  void _navigateToReviewScreen(Book book) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BookReviewScreen(
                  book: book,
                  isAdmin: ['admin', 'superior_admin'].contains(_currentUserRole)))
      ).then((_) => _refreshBooks());
}

// _BookCard widget remains the same as your last provided version.
class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const _BookCard({required this.book, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
                child: Container(
                    color: Colors.grey.shade200,
                    child: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                        ? Image.network(book.coverUrl!, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, color: Colors.grey))
                        : const Icon(Icons.menu_book,
                            size: 40, color: Colors.grey))),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(book.author ?? 'Unknown Author',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                    ]))
          ])));
}