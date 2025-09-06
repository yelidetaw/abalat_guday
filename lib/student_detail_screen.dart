import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amde_haymanot_abalat_guday/student.dart'; // Import the Student class

// Add the StringExtension here
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class StudentDetailsScreen extends StatelessWidget {
  final Student student;
  final List<Map<String, dynamic>> attendanceRecords;

  const StudentDetailsScreen({
    super.key,
    required this.student,
    required this.attendanceRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${student.name} - Attendance Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student ID: ${student.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Group: ${student.group ?? 'N/A'}', // Access the group property
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Attendance Records:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = attendanceRecords[index];
                  final date = DateTime.parse(record['date'] as String);
                  final status = record['status'] as String;
                  final lateTime = record['late_time'] as String?;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(DateFormat.yMMMd().format(date)),
                      subtitle: Text(
                        'Status: ${status.capitalize()}${lateTime != null ? ', Late: $lateTime' : ''}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
