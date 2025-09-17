// lib/core/models/user.dart

enum UserType { student, teacher, admin, none }

class User {
  final String id;
  final String? name; // This field is now nullable
  final String email;
  final UserType type;

  User({
    required this.id,
    this.name, // The 'name' field is no longer required
    required this.email,
    required this.type,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as String,
      name: json['name'] as String?, // Updated to handle null values
      email: json['email'] as String,
      type: _stringToUserType(json['user_type'] as String),
    );
  }
}

UserType _stringToUserType(String typeString) {
  switch (typeString.toLowerCase()) {
    case 'student':
      return UserType.student;
    case 'teacher':
      return UserType.teacher;
    case 'admin':
      return UserType.admin;
    default:
      return UserType.none;
  }
}
