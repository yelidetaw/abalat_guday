import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Sample data (replace with API calls or data management)
  List<Map<String, dynamic>> books = [
    {
      'id': '1',
      'title': 'The Lord of the Rings',
      'author': 'J.R.R. Tolkien',
      'imageUrl':
          'https://m.media-amazon.com/images/I/71XWdD+c5CL._AC_UF1000,1000_QL80_.jpg',
      'isbn': '978-0618260253',
      'publicationDate': '1954',
      'publisher': 'George Allen & Unwin',
      'description': 'An epic fantasy novel...',
    },
    {
      'id': '2',
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'imageUrl':
          'https://m.media-amazon.com/images/I/51V0R0hM4pL._SX329_BO1,204,203,200_.jpg',
      'isbn': '978-0141439518',
      'publicationDate': '1813',
      'publisher': 'Penguin Classics',
      'description': 'A romantic novel of manners...',
    },
    // Add more book data here
  ];

  // Form controllers for adding a new book
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Image selection state
  File? _imageFile;
  String? _imageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
      });
    }
  }

  // Function to pick a file from the file system (e.g., image files)
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
        _imageUrl = null;
      });
    } else {
      // User canceled the picker
      print("File picking cancelled");
    }
  }

  // Function to handle image upload
  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      // Implement the API call to upload the image to your backend here.
      // Example:  _imageUrl = await uploadImageToBackend(_imageFile!);
      print('Uploading image...');
      // You will implement the API call to upload the image to your backend here
      // Replace the code.
      setState(() {
        // _imageUrl =  // Get the URL of the uploaded image from your backend (important!)
      });
    } else {
      print('No image selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Management Section
            const Text(
              'Book Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Add Book Form
            const Text(
              'Add New Book',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('File'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Display the selected image
                  if (_imageFile != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text('Selected Image:'),
                            const SizedBox(height: 8),
                            Image.file(
                              _imageFile!, // Display the image
                              height: 100, // Adjust height as needed
                              width: 100, // Adjust width as needed
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error),
                                ); // Handle errors
                              },
                            ),
                            ElevatedButton(
                              onPressed: _uploadImage,
                              child: const Text('Upload Image'),
                            ), // Button for uploading to the backend
                          ],
                        ),
                      ),
                    ),
                  if (_imageUrl != null) // Displays images from the web.
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text('Selected Image:'),
                            const SizedBox(height: 8),
                            Image.network(
                              _imageUrl!, // Display the image from the web
                              height: 100, // Adjust height as needed
                              width: 100, // Adjust width as needed
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error),
                                ); // Handle errors
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () {
                      // Implement adding the book to the list.  (Add API call!)
                      setState(() {
                        books.add({
                          'id': DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          'title': _titleController.text,
                          'author': _authorController.text,
                          'imageUrl':
                              _imageUrl ??
                              (_imageFile != null ? _imageFile!.path : null),
                          'description': _descriptionController
                              .text, // Use the description from the controller
                          // Add other book details (isbn, publicationDate, publisher) as needed
                        });
                        // Clear the form
                        _titleController.clear();
                        _authorController.clear();
                        _imageUrlController.clear();
                        _descriptionController
                            .clear(); // Clear the description field as well
                        _imageFile = null;
                        _imageUrl = null;
                      });
                    },
                    child: const Text('Add Book'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Book List
            const Text(
              'Book List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            ListView.builder(
              shrinkWrap: true, // Important for nested scrollable views
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for the inner list
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: book['imageUrl'] != null
                        ? Image.network(
                            book['imageUrl']!,
                            width: 50,
                            height: 75, // Adjust as needed
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.book),
                    title: Text(book['title']!),
                    subtitle: Text('By ${book['author']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Implement edit functionality
                            print('Edit book at index $index');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // Implement delete functionality
                            setState(() {
                              books.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // New: Navigate to book detail on tap
                      Navigator.pushNamed(
                        context,
                        '/book_detail',
                        arguments: {
                          'title': book['title'],
                          'author': book['author'],
                          'imageUrl': book['imageUrl'],
                          'description':
                              book['description'], // Pass description here
                          'isbn':
                              '...', //  Replace with actual book data, if available
                          'publicationDate': '...', // Replace
                          'publisher': '...', // Replace
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
