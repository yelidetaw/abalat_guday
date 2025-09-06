// library_management_system/screens/admin_learning_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For video launching

class AdminLearningScreen extends StatefulWidget {
  const AdminLearningScreen({super.key});

  @override
  _AdminLearningScreenState createState() => _AdminLearningScreenState();
}

class _AdminLearningScreenState extends State<AdminLearningScreen> {
  // Controllers for adding new content (Text, URLs, etc.)
  final TextEditingController _holidayTitleController = TextEditingController();
  final TextEditingController _longTextController = TextEditingController();
  final TextEditingController _deeperAnswersController =
      TextEditingController();
  final TextEditingController _videoTitleController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _writtenTextFilePathController =
      TextEditingController();

  // Sample data for editing and adding content, Replace with API calls, etc.
  String holidayTitle = 'Christmas';
  String longText = '''
    Christmas, celebrated annually on December 25th, commemorates the birth of Jesus Christ, a central figure in Christianity. The holiday is marked by religious and cultural traditions worldwide.
    ... (Your long text describing the holiday in depth)
    ''';
  String deeperAnswers = '''
    *   **What is the significance of the date?**  December 25th is the traditional date, although the exact birth date is not specified in the Bible.
    *   **What are the key religious rituals?**  Church services, prayer, and participation in the Eucharist are common practices.
    *   **How does Christmas relate to other faiths?**  Christmas has influenced secular celebrations, such as gift-giving and festive decorations.
    *   **(Explain other related questions in depth) ...''';
  List<Map<String, String>> videoLinks = [
    {
      'title': 'Christmas Preaching 1',
      'url': 'https://www.youtube.com/watch?v=your_youtube_video_id_1',
    }, // Replace with actual IDs
    {
      'title': 'Christmas Preaching 2',
      'url': 'https://www.youtube.com/watch?v=your_youtube_video_id_2',
    },
    // Add more video links here
  ];
  List<String> writtenTexts = [
    'assets/texts/christmas_text_1.txt', // Use assets, or replace with URLs
    'assets/texts/christmas_text_2.txt',
    // Add more written texts here
  ];

  @override
  void dispose() {
    // Dispose of controllers
    _holidayTitleController.dispose();
    _longTextController.dispose();
    _deeperAnswersController.dispose();
    _videoTitleController.dispose();
    _videoUrlController.dispose();
    _writtenTextFilePathController.dispose();
    super.dispose();
  }

  // Helper function to launch URLs
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Handle the error (e.g., show a message to the user)
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Editing Section
          const Text(
            'Edit Content',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Title Field
          const Text(
            'Holiday Title',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _holidayTitleController,
              decoration: InputDecoration(
                labelText: 'Holiday Title',
                border: const OutlineInputBorder(),
                hintText: holidayTitle, // Show the current value
              ),
              onChanged: (value) {
                setState(() {
                  holidayTitle = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Long Text Field
          const Text(
            'Overview Text',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _longTextController,
              maxLines: 5, // Allow multiple lines
              decoration: InputDecoration(
                labelText: 'Overview Text',
                border: const OutlineInputBorder(),
                hintText: longText, // Show the current value
              ),
              onChanged: (value) {
                setState(() {
                  longText = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Deeper Answer Field
          const Text(
            'Deeper Dive Answers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _deeperAnswersController,
              maxLines: 5, // Allow multiple lines
              decoration: InputDecoration(
                labelText: 'Deeper Dive',
                border: const OutlineInputBorder(),
                hintText: deeperAnswers, // Show the current value
              ),
              onChanged: (value) {
                setState(() {
                  deeperAnswers = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Video Section
          const Text(
            'Add Video',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _videoTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Video Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Video URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      videoLinks.add({
                        'title': _videoTitleController.text,
                        'url': _videoUrlController.text,
                      });
                      _videoTitleController.clear();
                      _videoUrlController.clear();
                    });
                  },
                  child: const Text('Add Video'),
                ),
              ],
            ),
          ),
          // List of Videos
          const Text(
            'Videos List',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Column(
            children: videoLinks.map((video) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(video['title']!),
                  leading: const Icon(Icons.play_circle_filled),
                  onTap: () {
                    _launchURL(video['url']!);
                  },
                  trailing: IconButton(
                    // Delete button for each video
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        videoLinks.remove(video);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Written Text Section
          const Text(
            'Add Written Text File Path',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _writtenTextFilePathController,
                  decoration: const InputDecoration(
                    labelText: 'Text File Path (e.g., assets/texts/...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      writtenTexts.add(_writtenTextFilePathController.text);
                      _writtenTextFilePathController.clear();
                    });
                  },
                  child: const Text('Add Text File'),
                ),
              ],
            ),
          ),
          // List of Written Texts
          const Text(
            'Written Text Files',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Column(
            children: writtenTexts.map((filePath) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(filePath),
                  leading: const Icon(Icons.article),
                  trailing: IconButton(
                    // Delete button for each text file
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        writtenTexts.remove(filePath);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          // (Add more sections for editing other content)
        ],
      ),
    );
  }
}
