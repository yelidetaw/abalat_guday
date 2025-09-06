// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// // 
// // Use your branding colors for consistency
// const Color kPrimaryColor = Color.fromARGB(255, 1, 37, 100);
// const Color kAccentColor = Color(0xFFFFD700);

// class DebugResourceScreen extends StatelessWidget {
//   final Map<String, dynamic> resourceData;

//   const DebugResourceScreen({super.key, required this.resourceData});

//   @override
//   Widget build(BuildContext context) {
//     // Use the JsonEncoder to format the map into a readable, indented string
//     const jsonEncoder = JsonEncoder.withIndent('  ');
//     final prettyJson = jsonEncoder.convert(resourceData);

//     return Scaffold(
//       backgroundColor: kPrimaryColor,
//       appBar: AppBar(
//         backgroundColor: kPrimaryColor,
//         title: Text('Debug: Resource Data', style: GoogleFonts.poppins()),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Raw Data for Tapped Resource:',
//               style: GoogleFonts.poppins(
//                 color: kAccentColor,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '(Long-press to select and copy the text)',
//               style: GoogleFonts.poppins(
//                 color: Colors.white70,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               color: Colors.black26,
//               child: SelectableText(
//                 prettyJson,
//                 style: GoogleFonts.sourceCodePro( // A monospace font is best for code
//                   color: Colors.white,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }