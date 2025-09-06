// library_management_system/screens/book_list_screen.dart
import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/book_card.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  // Sample Book Data (Replace with your API data)
  List<Map<String, dynamic>> books = [
    {
      'id': '1',
      'title': 'The Lord of the Rings',
      'author': 'J.R.R. Tolkien',
      'imageUrl':
          'https://m.media-amazon.com/images/I/71XWdD+c5CL._AC_UF1000,1000_QL80_.jpg',
      'description': 'An epic fantasy novel...',
      'isbn': '978-0618260253',
      'publicationDate': '1954',
      'publisher': 'George Allen & Unwin',
    },
    {
      'id': '2',
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'imageUrl':
          'https://m.media-amazon.com/images/I/51V0R0hM4pL._SX329_BO1,204,203,200_.jpg',
      'description': 'A romantic novel of manners...',
      'isbn': '978-0141439518',
      'publicationDate': '1813',
      'publisher': 'Penguin Classics',
    },
    // Add more books here. Remember to include description.
  ];

  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchResults = List.from(
      books,
    ); // Initialize search results with all books
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to perform the search
  void _searchBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = List.from(
          books,
        ); // Show all books if the search is empty
      } else {
        _searchResults = books.where((book) {
          final title = book['title']!.toLowerCase();
          final author = book['author']!.toLowerCase();
          final queryLower = query.toLowerCase();
          return title.contains(queryLower) || author.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book List'),
        // Search Bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or author',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25), // Rounded corners
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ), // Increase padding
              ),
              onChanged: (value) {
                _searchBooks(value);
              },
            ),
          ),
        ),
      ),
      body: _searchResults.isEmpty
          ? const Center(child: Text('No books found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final book = _searchResults[index];
                return BookCard(
                  // Use the BookCard widget
                  title: book['title']!,
                  author: book['author']!,
                  imageUrl: book['imageUrl'],
                  description: book['description']!,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/book_detail', // The route name for the detail screen
                      arguments: book, // Pass the book data
                    );
                  },
                );
              },
            ),
    );
  }
}
