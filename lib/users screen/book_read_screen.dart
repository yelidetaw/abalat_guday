import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amde_haymanot_abalat_guday/users screen/bottom_nav_bar.dart';

// --- Using YOUR BookCard Widget ---
// You should move this to its own file like `lib/widgets/book_card.dart`
// and import it here. For now, I'm including it directly for a single-file fix.
class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String? imageUrl;
  final String description;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    this.imageUrl,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By $author',
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(Icons.book, size: 60, color: Colors.grey),
    );
  }
}

// --- Using YOUR Book Model ---
// You should move this to its own file like `lib/models/book_model.dart`
// and import it here.
enum BookStatus { available, borrowed, reserved }

class Book {
  final String id; // Changed back to non-nullable to match the error fix
  final String title;
  final String author;
  final String description;
  final String? imageUrl;
  final String? isbn;
  final String? publicationDate;
  final String? publisher;
  BookStatus status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    this.imageUrl,
    this.isbn,
    this.publicationDate,
    this.publisher,
    this.status = BookStatus.available,
  });

  // Added a factory constructor to parse data from Supabase
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      isbn: json['isbn'] as String?,
      publicationDate: json['publication_date'] as String?,
      publisher: json['publisher'] as String?,
      status: BookStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookStatus.available,
      ),
    );
  }
}

// --- YOUR MAIN SCREEN, NOW FIXED ---
class ModernBookListScreen extends StatefulWidget {
  const ModernBookListScreen({super.key});

  @override
  State<ModernBookListScreen> createState() => _ModernBookListScreenState();
}

class _ModernBookListScreenState extends State<ModernBookListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 2; // Assuming this is the 'Learning' tab

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _searchController.addListener(_filterBooks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('books')
          .select('*')
          .order('created_at', ascending: false);

      // Use the Book.fromJson factory constructor to create Book objects
      final books =
          (response as List).map((data) => Book.fromJson(data)).toList();

      setState(() {
        _books = books;
        _filteredBooks = books;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching books: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterBooks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBooks = _books.where((book) {
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) context.go('/home');
    if (index == 3) context.go('/profile');
  }

  // _showBookDetails is no longer needed here, as navigation happens on tap.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modern Book Library',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or author...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? Center(
                        child: Text('No books found.',
                            style: GoogleFonts.poppins()))
                    : ListView.builder(
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];

                          // --- THIS IS THE FIX ---
                          // We now use YOUR BookCard and pass the correct properties from the Book object.
                          return BookCard(
                            title: book.title,
                            author: book.author,
                            description: book.description,
                            imageUrl: book.imageUrl,
                            onTap: () {
                              // Ensure we navigate with a valid ID
                              if (book.id.isNotEmpty) {
                                context.go('/book-reviews/${book.id}');
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
