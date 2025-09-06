class Student {
  final String id;
  final String name;
  final String? group; // This is the crucial part
  Student({required this.id, required this.name, this.group});
}
