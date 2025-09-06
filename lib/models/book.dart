class Book {
  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? reviewCount;
  // averageRating is removed as it no longer exists in the database function
  // You can add it back if you decide to calculate it in the app

  Book({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.reviewCount,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'].toString(),
      title: map['title'] as String,
      author: map['author'] as String?,
      coverUrl: map['cover_url'] as String?,
      reviewCount: (map['review_count'] as num?)?.toInt(),
    );
  }

  get publishedYear => null;

  get genre => null;
}