// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../attendance_models.dart'; // Corrected path
// import 'attendance_manager.dart'; // Corrected path

// class attendance extends StatelessWidget {
//   attendance({super.key});

//   // In a real app, this data would come from an API or state management
//   final List<Student> _studentsForClass = [
//     Student(id: 'st_001', name: 'Biniam Mekonnin'),
//     Student(id: 'st_002', name: 'Eyob Zewdu'),
//     Student(id: 'st_003', name: 'Abel Mebiratu'),
//     Student(id: 'st_004', name: 'etsub dink'),
//     Student(id: 'st_005', name: 'Rakeb Getachew'),
//     Student(id: 'st_006', name: 'Dawit Temesgen'),
//   ];

//   void _handleSave(
//     BuildContext context,
//     DateTime date,
//     Map<String, AttendanceStatus> attendanceData,
//     Map<String, TimeOfDay?> lateTimes,
//   ) {
//     print("--- Controller Saving Attendance ---");
//     print("Date: ${DateFormat.yMMMd().format(date)}");
//     attendanceData.forEach((studentId, status) {
//       print("Student ID $studentId: ${status.name}");
//       if (status == AttendanceStatus.late) {
//         final time = lateTimes[studentId];
//         print(
//           "Late Time for $studentId: ${time?.format(context) ?? 'Not late'}",
//         );
//       }
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Attendance Saved!'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Mark Class Attendance')),
//       body: AttendanceManager(
//         students: _studentsForClass,
//         onSave: (date, attendanceData, lateTimes) =>
//             _handleSave(context, date, attendanceData, lateTimes),
//       ),
//     );
//   }
// }
