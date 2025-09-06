// library_management_system/widgets/book_card.dart
import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Rounded corners for the card
      child: InkWell(
        onTap: onTap, // Use the onTap callback
        borderRadius: BorderRadius.circular(
          12,
        ), // Match the card's rounded corners
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align items to the top
            children: [
              // Book Cover (Left side)
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  8,
                ), // Rounded corners for the image
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: 80,
                        height: 120, // Adjust height as needed
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.book,
                              size: 80,
                            ), // Placeholder if image fails
                      )
                    : Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.book,
                          size: 80,
                        ), // Placeholder if no image
                      ),
              ),
              const SizedBox(width: 16), // Space between image and text
              // Book Information (Right side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ), // Title with max lines
                    const SizedBox(height: 4),
                    Text(
                      'By $author',
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ), // Author with max lines
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis, // Description with max lines
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
}
