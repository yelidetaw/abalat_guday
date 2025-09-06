// models/student.dart

class Student {
  // All fields should be final for an immutable model class.
  final String id;
  final String name;
  final String? group;
  final String? photoUrl; // FIX: Properly typed as a nullable String.

  // The constructor now correctly initializes all final fields.
  Student({
    required this.id,
    required this.name,
    this.group,
    this.photoUrl, // FIX: This assigns the parameter to the class field.
  });

  // FIX: This factory is now complete and uses the correct keys from your Supabase response.
  // This is the standard way to create an object from a JSON/Map structure.
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      // Use the correct key from your database ('full_name'). Added a fallback for safety.
      name: map['full_name'] as String? ?? 'No Name Provided',
      // Use the correct key from your database ('kifil').
      group: map['kifil'] as String?,
      // Use the correct key from your database ('avatar_url').
      photoUrl: map['avatar_url'] as String?,
    );
  }
}
