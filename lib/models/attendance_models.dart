enum AttendanceStatus { present, absent, late, permission }

class Student {
  final String id;
  final String name;
  final String? avatarUrl;

  Student({required this.id, required this.name, this.avatarUrl});
}
