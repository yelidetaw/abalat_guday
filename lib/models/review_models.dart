class BookReview {
  final dynamic id;
  final dynamic bookId;
  final String userId;
  final String? title; // Added title
  final String? comment;
  final DateTime createdAt;

  BookReview({
    required this.id,
    required this.bookId,
    required this.userId,
    this.title,
    this.comment,
    required this.createdAt,
  });

  factory BookReview.fromMap(Map<String, dynamic> data) {
    return BookReview(
      id: data['id'],
      bookId: data['book_id'],
      userId: data['user_id'],
      title: data['title'], // Added title
      comment: data['comment'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}