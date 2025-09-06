// // library_management_system/screens/learning_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // For handling orientation
// import 'package:url_launcher/url_launcher.dart'; // For launching URLs

// class LearningScreen extends StatefulWidget {
//   const LearningScreen({super.key});

//   @override
//   _LearningScreenState createState() => _LearningScreenState();
// }

// class _LearningScreenState extends State<LearningScreen> {
//   bool _isLoading = false; // loading for the video, text

//   // Sample Data (Replace with your content from an API or data source)
//   final String holidayTitle = 'Christmas';
//   final String longText = '''
//     Christmas, celebrated annually on December 25th, commemorates the birth of Jesus Christ, a central figure in Christianity. The holiday is marked by religious and cultural traditions worldwide.
//     ... (Your long text describing the holiday in depth)
//     ''';
//   final String deeperAnswers = '''
//     *   **What is the significance of the date?**  December 25th is the traditional date, although the exact birth date is not specified in the Bible.
//     *   **What are the key religious rituals?**  Church services, prayer, and participation in the Eucharist are common practices.
//     *   **How does Christmas relate to other faiths?**  Christmas has influenced secular celebrations, such as gift-giving and festive decorations.
//     *   **(Explain other related questions in depth) ...''';
//   final List<Map<String, String>> videoLinks = [
//     {
//       'title': 'Christmas Preaching 1',
//       'url': 'https://www.youtube.com/watch?v=your_youtube_video_id_1',
//     }, // Replace with actual IDs
//     {
//       'title': 'Christmas Preaching 2',
//       'url': 'https://www.youtube.com/watch?v=your_youtube_video_id_2',
//     },
//     // Add more video links here
//   ];
//   final List<String> writtenTexts = [
//     'assets/texts/christmas_text_1.txt', // Use assets, or replace with URLs
//     'assets/texts/christmas_text_2.txt',
//     // Add more written texts here
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // You might load data from an API here.
//   }

//   // Helper function to open URLs
//   Future<void> _launchURL(String url) async {
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url));
//     } else {
//       // Handle the error (e.g., show a message to the user)
//       print('Could not launch $url');
//     }
//   }

//   // Function to fetch and display the content of a text file
//   Future<String> _loadTextFile(String filePath) async {
//     try {
//       return await rootBundle.loadString(filePath);
//     } catch (e) {
//       return 'Error loading text: $e';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Long Text Section
//           const Text(
//             'Overview',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(longText),
//           const SizedBox(height: 24),

//           // Deeper Answers Section
//           const Text(
//             'Deeper Dive',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(deeperAnswers),
//           const SizedBox(height: 24),

//           // Video Section
//           const Text(
//             'Videos',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Column(
//             children: videoLinks.map((video) {
//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 4),
//                 child: ListTile(
//                   title: Text(video['title']!),
//                   leading: const Icon(Icons.play_circle_filled),
//                   onTap: () {
//                     _launchURL(video['url']!);
//                   },
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 24),

//           // Written Texts Section
//           const Text(
//             'Written Texts',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Column(
//             children: [
//               for (final filePath in writtenTexts)
//                 FutureBuilder<String>(
//                   future: _loadTextFile(filePath),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Center(child: CircularProgressIndicator()),
//                       );
//                     } else if (snapshot.hasError) {
//                       return Text('Error: ${snapshot.error}');
//                     } else {
//                       return Card(
//                         elevation: 2,
//                         margin: const EdgeInsets.symmetric(vertical: 4),
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Text(snapshot.data!),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
