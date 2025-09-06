import 'dart:async';
import 'dart:developer' as developer;
import 'package:amde_haymanot_abalat_guday/users%20screen/book_review_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

// Assuming supabase is initialized in your main.dart
final supabase = Supabase.instance.client;

class AdminLibraryScreen extends StatefulWidget {
  const AdminLibraryScreen({super.key});
  @override
  State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen> {
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
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      if (mounted) setState(() => _currentUserRole = response['role']);
    } catch (e, s) {
      developer.log('Error fetching user role', name: 'AdminLibraryScreen', error: e, stackTrace: s);
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
      developer.log('Error fetching books', name: 'AdminLibraryScreen', error: e, stackTrace: s);
      throw Exception('Failed to load books from the database.');
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

  Future<void> _deleteBook(String bookId, String bookTitle) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text('Are you sure you want to permanently delete "$bookTitle"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))
                ]));
    if (confirmed != true) return;
    try {
      await supabase.from('books').delete().eq('id', int.parse(bookId));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book deleted successfully'), backgroundColor: Colors.green));
      _refreshBooks();
    } on PostgrestException catch (e, s) {
      developer.log('Error deleting book', name: 'AdminLibraryScreen', error: e, stackTrace: s);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting book: ${e.message}'), backgroundColor: Colors.red));
    }
  }

  void _showAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final genreController = TextEditingController();
    final yearController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Add a New Book'),
                content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: authorController, decoration: const InputDecoration(labelText: 'Author Name')),
                        const SizedBox(height: 16),
                        TextFormField(controller: genreController, decoration: const InputDecoration(labelText: 'Genre')),
                        const SizedBox(height: 16),
                        TextFormField(controller: yearController, decoration: const InputDecoration(labelText: 'Published Year'), keyboardType: TextInputType.number),
                      ]),
                    )),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.of(context).pop();
                          await _addBook(
                            title: titleController.text.trim(),
                            author: authorController.text.trim(),
                            genre: genreController.text.trim(),
                            publishedYear: int.tryParse(yearController.text.trim()),
                          );
                        }
                      },
                      child: const Text('Add Book'))
                ]));
  }

  Future<void> _addBook({required String title, String? author, String? genre, int? publishedYear}) async {
    try {
      await supabase.rpc('admin_add_book', params: {
        'new_title': title,
        'new_author': (author == null || author.isEmpty) ? 'Unknown Author' : author,
        'new_genre': genre,
        'new_published_year': publishedYear,
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$title" added successfully!'), backgroundColor: Colors.green));
      _refreshBooks();
    } catch (e, s) {
      developer.log('Error adding book', name: 'AdminLibraryScreen', error: e, stackTrace: s);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding book: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrivilegedUser = ['admin', 'superior_admin'].contains(_currentUserRole);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Library Management')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                      hintText: 'Search books by title or author...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
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
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return _AdminBookCard(
                            book: book,
                            canManage: isPrivilegedUser,
                            onTap: () => _navigateToReviewScreen(book),
                            onDelete: () => _deleteBook(book.id, book.title));
                      }),
        )
      ]),
      floatingActionButton: isPrivilegedUser
          ? FloatingActionButton(
              onPressed: _showAddBookDialog,
              tooltip: 'Add Book',
              child: const Icon(Icons.add))
          : null,
    );
  }

  void _navigateToReviewScreen(Book book) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BookReviewScreen(
              book: book,
              isAdmin: ['admin', 'superior_admin'].contains(_currentUserRole)))
      ).then((_) => _refreshBooks());
}

// _AdminBookCard widget remains the same as your last provided version.
class _AdminBookCard extends StatelessWidget {
  final Book book;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _AdminBookCard(
      {required this.book,
      required this.canManage,
      required this.onTap,
      required this.onDelete});
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
          leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                  ? Image.network(book.coverUrl!,
                      width: 50, height: 70, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 50, height: 70, color: Colors.grey.shade300, child: const Icon(Icons.error)))
                  : Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.book))),
          title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('by ${book.author ?? 'Unknown Author'}'),
          trailing: canManage
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete)
              : null,
          onTap: onTap));
}