import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BooksReadScreen extends StatelessWidget {
  final List<String> books;

  const BooksReadScreen({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Reading History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF673AB7),
      ),
      body: books.isEmpty
          ? Center(
              child: Text(
                'No books have been recorded yet.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Color(0xFF673AB7)),
                    title: Text(books[index], style: GoogleFonts.poppins()),
                  ),
                );
              },
            ),
    );
  }
}
