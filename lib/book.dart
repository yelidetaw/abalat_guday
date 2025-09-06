// models/user.dart
class User {
  final String? id;
  final String? username;
  final String? email;
  // Add other user properties here (e.g., role, borrowedBooks, etc.)

  User({this.id, this.username, this.email});

  // Factory constructor for creating a User from a JSON object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
    );
  }

  // Convert a User object to a JSON map
  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'email': email};
  }
}
