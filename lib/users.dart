// models/user.dart
class UserProfile {
  final String id; // User's Supabase ID
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? kifil;
  final String? yesraDirisha;
  final String? budin;
  final String? agelgilotKifil;
  final String? role; // e.g., "admin", "user"
  final String? profileImageUrl; // URL to the profile image
  // Add other fields as needed (e.g., confessionHistory, booksRead, etc.)
  // add grade in this
  final int? gradePoints;
  // Add other fields as needed (e.g., confessionHistory, booksRead, etc.)

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.kifil,
    this.yesraDirisha,
    this.budin,
    this.agelgilotKifil,
    this.role,
    this.profileImageUrl,
    this.gradePoints,
  });

  // Factory constructor to create a UserProfile from a Supabase row
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phone_number'] as String?,
      kifil: map['kifil'] as String?,
      yesraDirisha: map['yesra_dirisha'] as String?,
      budin: map['budin'] as String?,
      agelgilotKifil: map['agelgilot_kifil'] as String?,
      role: map['role'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      gradePoints: map['grade_points'] as int?,
      // Map other fields here
    );
  }
}
