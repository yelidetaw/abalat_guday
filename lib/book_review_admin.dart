import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminBookReviewScreen extends StatefulWidget {
  const AdminBookReviewScreen({Key? key}) : super(key: key);

  @override
  _AdminBookReviewScreenState createState() => _AdminBookReviewScreenState();
}

class _AdminBookReviewScreenState extends State<AdminBookReviewScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<Map<String, dynamic>>>? _books;
  Future<List<Map<String, dynamic>>>? _reviews;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _books = _fetchBooks();
      _reviews = _fetchAllReviews();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchBooks() async {
    final response = await _supabase.from('books').select().order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchAllReviews() async {
    final response = await _supabase
        .from('reviews')
        .select('*, book:books(*), user:users(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add New Book',
              onPressed: () => _showAddOrEditBookDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.library_books), text: 'Books'),
              Tab(icon: Icon(Icons.reviews), text: 'All Reviews'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildBooksTab(), _buildReviewsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _books,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No books found.'));
        }

        final books = snapshot.data!;
        final filteredBooks = books.where((book) {
          final title = book['title']?.toString().toLowerCase() ?? '';
          final author = book['author']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || author.contains(query);
        }).toList();

        return ListView.builder(
          itemCount: filteredBooks.length,
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return Dismissible(
              key: Key(book['id'].toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) => _confirmDeleteDialog(
                context,
                'Delete Book?',
                'Are you sure you want to delete this book? All associated reviews will also be deleted.',
              ),
              onDismissed: (direction) async {
                await _supabase.from('books').delete().eq('id', book['id']);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${book['title']}"')),
                  );
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: book['cover_url'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
                  title: Text(book['title'] ?? 'No Title'),
                  subtitle: Text(book['author'] ?? 'No Author'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showAddOrEditBookDialog(context, book: book),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reviews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reviews found.'));
        }

        final reviews = snapshot.data!;
        final filteredReviews = reviews.where((review) {
          final bookTitle =
              review['book']?['title']?.toString().toLowerCase() ?? '';
          final userEmail =
              review['user']?['email']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return bookTitle.contains(query) || userEmail.contains(query);
        }).toList();

        return ListView.builder(
          itemCount: filteredReviews.length,
          itemBuilder: (context, index) {
            final review = filteredReviews[index];
            final book = review['book'] as Map<String, dynamic>?;
            final user = review['user'] as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundImage: user?['avatar_url'] != null
                      ? NetworkImage(user!['avatar_url'])
                      : null,
                  child: user?['avatar_url'] == null
                      ? Text(
                          user?['email']?.substring(0, 1).toUpperCase() ?? 'A',
                        )
                      : null,
                ),
                title: Text(book?['title'] ?? 'Book Not Found'),
                subtitle: Text(user?['email'] ?? 'Anonymous'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteReview(context, review),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (review['text_content'] != null &&
                            (review['text_content'] as String).isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              review['text_content'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        if (review['video_url'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: _buildAdminVideoPreview(review),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminVideoPreview(Map<String, dynamic> review) {
    final videoUrl = review['video_url'] as String;
    final videoType =
        (review['video_type'] as String?)?.capitalize() ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Review ($videoType)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    videoUrl,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddOrEditBookDialog(
    BuildContext context, {
    Map<String, dynamic>? book,
  }) async {
    final isEditing = book != null;
    final titleController = TextEditingController(text: book?['title']);
    final authorController = TextEditingController(text: book?['author']);
    final descriptionController = TextEditingController(
      text: book?['description'],
    );
    String? coverUrl = book?['cover_url'];
    Uint8List? coverFileBytes;
    bool isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Book' : 'Add New Book'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            if (result != null &&
                                result.files.single.bytes != null) {
                              setStateDialog(() {
                                coverFileBytes = result.files.single.bytes;
                                coverUrl = null;
                              });
                            }
                          },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: (coverFileBytes == null && coverUrl == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate, size: 40),
                                Text(
                                  isEditing
                                      ? 'Change Cover'
                                      : 'Add Cover Image',
                                ),
                              ],
                            )
                          : (coverFileBytes != null)
                          ? Image.memory(coverFileBytes!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: coverUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (titleController.text.isEmpty ||
                            authorController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title and author are required'),
                            ),
                          );
                          return;
                        }
                        setStateDialog(() => isUploading = true);

                        try {
                          String? finalCoverUrl = coverUrl;
                          if (coverFileBytes != null) {
                            final fileExt = 'jpg';
                            final fileName =
                                '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                            await _supabase.storage
                                .from('book_covers')
                                .uploadBinary(
                                  fileName,
                                  coverFileBytes!,
                                  fileOptions: FileOptions(
                                    contentType: 'image/$fileExt',
                                    upsert: isEditing,
                                  ),
                                );

                            finalCoverUrl = _supabase.storage
                                .from('book_covers')
                                .getPublicUrl(fileName);
                          }

                          final data = {
                            'title': titleController.text,
                            'author': authorController.text,
                            'description': descriptionController.text,
                            'cover_url': finalCoverUrl,
                          };

                          if (isEditing) {
                            await _supabase
                                .from('books')
                                .update(data)
                                .eq('id', book['id']);
                          } else {
                            await _supabase.from('books').insert(data);
                          }

                          Navigator.of(context).pop();
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Book ${isEditing ? 'updated' : 'added'} successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save book: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setStateDialog(() => isUploading = false);
                          }
                        }
                      },
                child: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Add Book'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteReview(
    BuildContext context,
    Map<String, dynamic> review,
  ) async {
    final confirmed = await _confirmDeleteDialog(
      context,
      'Delete Review?',
      'Are you sure you want to delete this review? This action cannot be undone.',
    );

    if (confirmed == true) {
      await _supabase.from('reviews').delete().eq('id', review['id']);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted')));
      }
    }
  }

  Future<bool?> _confirmDeleteDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
